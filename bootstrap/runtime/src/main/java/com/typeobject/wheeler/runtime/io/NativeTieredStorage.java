package com.typeobject.wheeler.runtime.io;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** Native file-backed tier placement and drain provider under the portable lifecycle. */
public final class NativeTieredStorage {
  /** Named native tier with one failure domain and positional file capability. */
  public record Tier(
      String name,
      String failureDomain,
      long capacity,
      NativeCompletionFile file) {
    public Tier {
      name = visible(name, "tier");
      failureDomain = visible(failureDomain, "failure domain");
      if (capacity < 1 || 16L * 1024 * 1024 < capacity) {
        throw new IllegalArgumentException("native tier capacity is outside 1 byte through 16 MiB");
      }
      Objects.requireNonNull(file, "file");
    }
  }

  /** Exact file range and nominal placement evidence. */
  public record Placement(Tier tier, long position, StagedData evidence) {
    public Placement {
      Objects.requireNonNull(tier, "tier");
      Objects.requireNonNull(evidence, "evidence");
      if (position < 0 || tier.capacity() < position
          || tier.capacity() - position < evidence.bytes()
          || !tier.name().equals(evidence.tier())
          || !tier.failureDomain().equals(evidence.failureDomain())) {
        throw new IllegalArgumentException("native tier placement is outside its capability");
      }
    }
  }

  /** Complete or known-prefix native drain outcome. */
  public record DrainResult(
      TieredStorage.DrainOutcome outcome,
      Placement placement,
      long requestedBytes,
      boolean sourceRetained) {
    public DrainResult {
      Objects.requireNonNull(outcome, "outcome");
      Objects.requireNonNull(placement, "placement");
      if (requestedBytes < 1 || requestedBytes < placement.evidence().bytes()
          || !sourceRetained
          || (outcome == TieredStorage.DrainOutcome.COMPLETE)
              != (requestedBytes == placement.evidence().bytes())) {
        throw new IllegalArgumentException("native tier drain result is inconsistent");
      }
    }
  }

  private NativeTieredStorage() {}

  /** Prepares one exact initial native placement without making a durability claim. */
  public static IoRequest<Placement> place(
      Tier tier, long position, OwnedIoBuffer source, int bufferOffset, int length) {
    Objects.requireNonNull(tier, "tier");
    Objects.requireNonNull(source, "source");
    byte[] snapshot = source.snapshot();
    if (bufferOffset < 0 || length < 1 || snapshot.length < bufferOffset
        || snapshot.length - bufferOffset < length || position < 0
        || tier.capacity() < position || tier.capacity() - position < length) {
      throw new IllegalArgumentException("native tier placement range is invalid");
    }
    byte[] content = new byte[length];
    System.arraycopy(snapshot, bufferOffset, content, 0, length);
    StagedData evidence = StagedData.initial(
        tier.name(), tier.failureDomain(), sha256(content), length);
    IoRequest<NativeCompletionFile.WriteCompleted> write =
        tier.file().writeAt(position, source, bufferOffset, length);
    try {
      return IoRequest.prepare(
          "native-tier-place:" + evidence.identity(),
          write.work(),
          () -> write.execute().mapSuccess(completed ->
              new Placement(tier, position, evidence)),
          write::releaseResources,
          write::requestCancellation);
    } catch (RuntimeException failure) {
      write.releaseResources();
      throw failure;
    }
  }

  /** Prepares one source-retaining file-to-file drain with exact prefix evidence. */
  public static IoRequest<DrainResult> drain(
      Placement source, Tier target, long targetPosition) {
    Objects.requireNonNull(source, "source");
    Objects.requireNonNull(target, "target");
    int length = Math.toIntExact(source.evidence().bytes());
    if (targetPosition < 0 || target.capacity() < targetPosition
        || target.capacity() - targetPosition < length) {
      throw new IllegalArgumentException("native tier drain exceeds target capacity");
    }
    OwnedIoBuffer transfer = OwnedIoBuffer.allocate(length);
    IoRequest<NativeCompletionFile.ReadCompleted> read =
        source.tier().file().readAt(source.position(), transfer, 0, length);
    try {
      return IoRequest.prepare(
          "native-tier-drain:" + source.evidence().identity() + ':' + target.name(),
          read.work(),
          () -> executeDrain(source, target, targetPosition, transfer, read),
          read::releaseResources,
          read::requestCancellation);
    } catch (RuntimeException failure) {
      read.releaseResources();
      throw failure;
    }
  }

  private static IoProviderResult<DrainResult> executeDrain(
      Placement source,
      Tier target,
      long targetPosition,
      OwnedIoBuffer transfer,
      IoRequest<NativeCompletionFile.ReadCompleted> read) {
    IoProviderResult<NativeCompletionFile.ReadCompleted> readResult = read.execute();
    if (readResult.kind() != IoProviderResult.Kind.SUCCESS) {
      return carryFailure(readResult);
    }
    int readBytes = readResult.value().bytesRead();
    byte[] bytes = new byte[readBytes];
    transfer.copyTo(0, bytes, 0, readBytes);
    if (readBytes != source.evidence().bytes()
        || !sha256(bytes).equals(source.evidence().contentIdentity())) {
      return IoProviderResult.failure("native-tier-source-identity-mismatch", readBytes);
    }
    OwnedIoBuffer targetBuffer = OwnedIoBuffer.copyOf(bytes);
    IoRequest<NativeCompletionFile.WriteCompleted> write =
        target.file().writeAt(targetPosition, targetBuffer, 0, readBytes);
    IoProviderResult<NativeCompletionFile.WriteCompleted> writeResult;
    try {
      writeResult = write.execute();
    } finally {
      write.releaseResources();
    }
    if (writeResult.kind() != IoProviderResult.Kind.SUCCESS) {
      return carryFailure(writeResult);
    }
    int written = writeResult.value().bytesWritten();
    StagedData evidence;
    TieredStorage.DrainOutcome outcome;
    if (written == readBytes) {
      evidence = source.evidence().restage(target.name(), target.failureDomain());
      outcome = TieredStorage.DrainOutcome.COMPLETE;
    } else {
      byte[] prefix = new byte[written];
      System.arraycopy(bytes, 0, prefix, 0, written);
      evidence = StagedData.partialOf(
          source.evidence(), target.name(), target.failureDomain(), sha256(prefix), written);
      outcome = TieredStorage.DrainOutcome.PARTIAL_FAILURE;
    }
    return IoProviderResult.success(
        new DrainResult(outcome, new Placement(target, targetPosition, evidence), readBytes, true),
        written);
  }

  private static <T> IoProviderResult<T> carryFailure(IoProviderResult<?> failure) {
    return switch (failure.kind()) {
      case SUCCESS -> throw new IllegalArgumentException("expected nonsuccess provider result");
      case FAILURE -> IoProviderResult.failure(failure.detail(), failure.progress());
      case CANCELED_BEFORE_EFFECT -> IoProviderResult.canceledBeforeEffect(failure.detail());
      case CANCELED_AFTER_PARTIAL_EFFECT ->
          IoProviderResult.canceledAfterPartial(failure.detail(), failure.progress());
      case UNCERTAIN -> IoProviderResult.uncertain(failure.detail(), failure.progress());
    };
  }

  private static String visible(String value, String field) {
    Objects.requireNonNull(value, field);
    if (value.isBlank() || value.length() > 128 || !value.equals(value.trim())) {
      throw new IllegalArgumentException(field + " must be bounded visible ASCII");
    }
    for (int index = 0; index < value.length(); index++) {
      char character = value.charAt(index);
      if (character < 0x21 || character > 0x7e) {
        throw new IllegalArgumentException(field + " must use visible ASCII");
      }
    }
    return value;
  }

  private static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException impossible) {
      throw new IllegalStateException("SHA-256 is unavailable", impossible);
    }
  }
}
