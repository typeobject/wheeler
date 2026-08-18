package com.typeobject.wheeler.runtime.io;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import java.util.TreeMap;

/** Bounded native RNIC registration authority with generation-scoped revocation. */
public final class NativeRnicRegistry implements AutoCloseable {
  /** Remote operations admitted by one native memory registration. */
  public enum Rights {
    REMOTE_READ,
    REMOTE_WRITE,
    REMOTE_READ_WRITE;

    private boolean permitsWrite() {
      return this == REMOTE_WRITE || this == REMOTE_READ_WRITE;
    }
  }

  /** Opaque native registration fields returned by an RNIC backend. */
  public record NativeHandle(
      long address,
      int length,
      long localKey,
      long remoteKey,
      long generation) {}

  /** Raw backend completion for one native one-sided write. */
  public record NativeWriteCompletion(
      long generation,
      int relativeOffset,
      int bytes,
      String evidenceIdentity) {}

  /** Host RNIC registration and disconnect boundary. */
  public interface Backend {
    /** Pins or maps the held owner and returns its exact native registration. */
    NativeHandle register(
        OwnedIoBuffer owner,
        int offset,
        int length,
        Rights rights,
        long generation);

    /** Performs one native one-sided write against a current registration. */
    IoProviderResult<NativeWriteCompletion> write(
        NativeHandle target,
        int relativeOffset,
        OwnedIoBuffer source,
        int sourceOffset,
        int length);

    /** Revokes one native registration. */
    void deregister(NativeHandle handle);

    /** Tears down the native association after all registration authority is revoked. */
    void disconnect();
  }

  /** Unforgeable provider-issued registration authority. */
  public static final class Registration {
    private final String providerIdentity;
    private final long generation;
    private final int offset;
    private final int length;
    private final Rights rights;
    private final String identity;

    private Registration(
        String providerIdentity,
        long generation,
        int offset,
        int length,
        Rights rights,
        String identity) {
      this.providerIdentity = providerIdentity;
      this.generation = generation;
      this.offset = offset;
      this.length = length;
      this.rights = rights;
      this.identity = identity;
    }

    /** Returns the issuing provider identity. */
    public String providerIdentity() {
      return providerIdentity;
    }

    /** Returns the monotonically increasing registration generation. */
    public long generation() {
      return generation;
    }

    /** Returns the first registered owner byte. */
    public int offset() {
      return offset;
    }

    /** Returns the exact registered byte count. */
    public int length() {
      return length;
    }

    /** Returns the fixed remote-operation rights. */
    public Rights rights() {
      return rights;
    }

    /** Returns the canonical registration identity. */
    public String identity() {
      return identity;
    }
  }

  /** Exact native completion of one one-sided write, without peer or durability claims. */
  public static final class WriteCompleted {
    private final Registration registration;
    private final int relativeOffset;
    private final int bytes;
    private final String contentIdentity;
    private final String evidenceIdentity;
    private final String identity;

    private WriteCompleted(
        Registration registration,
        int relativeOffset,
        int bytes,
        String contentIdentity,
        String evidenceIdentity,
        String identity) {
      this.registration = registration;
      this.relativeOffset = relativeOffset;
      this.bytes = bytes;
      this.contentIdentity = contentIdentity;
      this.evidenceIdentity = evidenceIdentity;
      this.identity = identity;
    }

    /** Returns the exact target registration. */
    public Registration registration() {
      return registration;
    }

    /** Returns the first registration-relative byte written. */
    public int relativeOffset() {
      return relativeOffset;
    }

    /** Returns the exact completed byte count. */
    public int bytes() {
      return bytes;
    }

    /** Returns the exact source-content identity. */
    public String contentIdentity() {
      return contentIdentity;
    }

    /** Returns the backend completion evidence identity. */
    public String evidenceIdentity() {
      return evidenceIdentity;
    }

    /** Returns the canonical native write-completion identity. */
    public String identity() {
      return identity;
    }
  }

  private record Active(
      Registration registration,
      OwnedIoBuffer owner,
      NativeHandle handle) {}

  private static final int MAX_REGISTRATIONS = 4_096;

  private final String identity;
  private final int maximumRegistrations;
  private final Backend backend;
  private final TreeMap<Long, Active> active = new TreeMap<>();
  private long generation;
  private boolean connected = true;

  /** Creates one bounded native registration registry. */
  public NativeRnicRegistry(
      String identity,
      int maximumRegistrations,
      Backend backend) {
    DurabilitySubject.visibleAscii("RNIC provider identity", identity, 160, false);
    if (maximumRegistrations < 1 || MAX_REGISTRATIONS < maximumRegistrations) {
      throw new IllegalArgumentException("RNIC registration bound must be between 1 and 4096");
    }
    this.identity = identity;
    this.maximumRegistrations = maximumRegistrations;
    this.backend = Objects.requireNonNull(backend, "backend");
  }

  /** Registers and holds one exact owner range under fresh native authority. */
  public synchronized Registration register(
      OwnedIoBuffer owner,
      int offset,
      int length,
      Rights rights) {
    requireConnected();
    Objects.requireNonNull(owner, "owner");
    Objects.requireNonNull(rights, "rights");
    int ownerLength = owner.length();
    if (offset < 0 || length < 1 || ownerLength < offset || ownerLength - offset < length) {
      throw new IllegalArgumentException("RNIC registration range is out of bounds");
    }
    if (maximumRegistrations <= active.size()) {
      throw new IllegalStateException("RNIC registration bound exhausted");
    }
    if (generation == Long.MAX_VALUE) {
      throw new IllegalStateException("RNIC registration generation exhausted");
    }

    long nextGeneration = ++generation;
    owner.hold();
    NativeHandle handle = null;
    boolean accepted = false;
    try {
      handle = Objects.requireNonNull(
          backend.register(owner, offset, length, rights, nextGeneration),
          "native registration");
      validateHandle(handle, length, nextGeneration);
      String canonical = identity + '\0' + nextGeneration + '\0' + offset + '\0' + length
          + '\0' + rights + '\0' + handle.address() + '\0' + handle.localKey()
          + '\0' + handle.remoteKey();
      Registration registration = new Registration(
          identity,
          nextGeneration,
          offset,
          length,
          rights,
          digest("wheeler-native-rnic-registration-1", canonical));
      active.put(nextGeneration, new Active(registration, owner, handle));
      accepted = true;
      return registration;
    } finally {
      if (!accepted) {
        try {
          if (handle != null) {
            backend.deregister(handle);
          }
        } finally {
          owner.release();
        }
      }
    }
  }

  /** Prepares one native one-sided write without running backend work. */
  public synchronized IoRequest<WriteCompleted> write(
      Registration target,
      int relativeOffset,
      OwnedIoBuffer source,
      int sourceOffset,
      int length) {
    Active current = requireCurrent(target);
    if (!target.rights.permitsWrite()) {
      throw new IllegalStateException("RNIC registration does not permit remote writes");
    }
    Objects.requireNonNull(source, "source");
    byte[] sourceBytes = source.snapshot();
    int sourceLength = sourceBytes.length;
    if (relativeOffset < 0 || length < 1 || target.length < relativeOffset
        || target.length - relativeOffset < length || sourceOffset < 0
        || sourceLength < sourceOffset || sourceLength - sourceOffset < length) {
      throw new IllegalArgumentException("native RNIC write range is out of bounds");
    }

    byte[] content = new byte[length];
    System.arraycopy(sourceBytes, sourceOffset, content, 0, length);
    String contentIdentity = sha256(content);
    source.hold();
    try {
      return IoRequest.prepare(
          "native-rnic-write:" + target.identity + ':' + relativeOffset + ':' + length,
          length,
          () -> executeWrite(
              target,
              current.handle,
              relativeOffset,
              source,
              sourceOffset,
              length,
              contentIdentity),
          source::release);
    } catch (RuntimeException failure) {
      source.release();
      throw failure;
    }
  }

  /** Reports whether this registry still owns the exact registration generation. */
  public synchronized boolean isCurrent(Registration registration) {
    if (registration == null || !identity.equals(registration.providerIdentity)) {
      return false;
    }
    Active current = active.get(registration.generation);
    return connected && current != null && current.registration == registration;
  }

  /** Revokes one registration before releasing its held owner. */
  public synchronized void revoke(Registration registration) {
    Active current = requireCurrent(registration);
    active.remove(registration.generation);
    try {
      backend.deregister(current.handle);
    } finally {
      current.owner.release();
    }
  }

  /** Revokes all registrations and disconnects the native association. */
  @Override
  public synchronized void close() {
    if (!connected) {
      return;
    }
    connected = false;
    List<Active> revoked = List.copyOf(active.values());
    active.clear();
    RuntimeException failure = null;
    for (Active current : revoked) {
      try {
        backend.deregister(current.handle);
      } catch (RuntimeException backendFailure) {
        failure = append(failure, backendFailure);
      } finally {
        current.owner.release();
      }
    }
    try {
      backend.disconnect();
    } catch (RuntimeException backendFailure) {
      failure = append(failure, backendFailure);
    }
    if (failure != null) {
      throw failure;
    }
  }

  private IoProviderResult<WriteCompleted> executeWrite(
      Registration target,
      NativeHandle handle,
      int relativeOffset,
      OwnedIoBuffer source,
      int sourceOffset,
      int length,
      String contentIdentity) {
    synchronized (this) {
      if (!isCurrent(target)) {
        return IoProviderResult.uncertain("native-rnic-registration-became-stale", 0);
      }
    }

    IoProviderResult<NativeWriteCompletion> result = Objects.requireNonNull(
        backend.write(handle, relativeOffset, source, sourceOffset, length),
        "native RNIC write result");
    if (result.kind() != IoProviderResult.Kind.SUCCESS) {
      return carryFailure(result);
    }

    NativeWriteCompletion completion = Objects.requireNonNull(
        result.value(), "native RNIC write completion");
    synchronized (this) {
      if (!isCurrent(target)) {
        return IoProviderResult.uncertain(
            "native-rnic-registration-became-stale", boundedProgress(completion.bytes(), length));
      }
    }
    if (completion.generation() != target.generation
        || completion.relativeOffset() != relativeOffset
        || completion.bytes() != length
        || result.progress() != length
        || !validHash(completion.evidenceIdentity())) {
      return IoProviderResult.uncertain(
          "native-rnic-completion-mismatch", boundedProgress(completion.bytes(), length));
    }

    String canonical = target.identity + '\0' + relativeOffset + '\0' + length
        + '\0' + contentIdentity + '\0' + completion.evidenceIdentity();
    WriteCompleted completed = new WriteCompleted(
        target,
        relativeOffset,
        length,
        contentIdentity,
        completion.evidenceIdentity(),
        digest("wheeler-native-rnic-write-completion-1", canonical));
    return IoProviderResult.success(completed, length);
  }

  private static <T> IoProviderResult<T> carryFailure(IoProviderResult<?> result) {
    return switch (result.kind()) {
      case SUCCESS -> throw new IllegalArgumentException("expected nonsuccess RNIC result");
      case FAILURE -> IoProviderResult.failure(result.detail(), result.progress());
      case CANCELED_BEFORE_EFFECT -> IoProviderResult.canceledBeforeEffect(result.detail());
      case CANCELED_AFTER_PARTIAL_EFFECT ->
          IoProviderResult.canceledAfterPartial(result.detail(), result.progress());
      case UNCERTAIN -> IoProviderResult.uncertain(result.detail(), result.progress());
    };
  }

  private static int boundedProgress(int progress, int length) {
    return Math.max(0, Math.min(progress, length));
  }

  private static boolean validHash(String value) {
    return value != null && value.matches("[0-9a-f]{64}");
  }

  private Active requireCurrent(Registration registration) {
    Objects.requireNonNull(registration, "registration");
    if (!identity.equals(registration.providerIdentity)) {
      throw new IllegalArgumentException("registration belongs to another RNIC provider");
    }
    Active current = active.get(registration.generation);
    if (!connected || current == null || current.registration != registration) {
      throw new IllegalStateException("RNIC registration generation is stale");
    }
    return current;
  }

  private static void validateHandle(
      NativeHandle handle,
      int length,
      long generation) {
    if (handle.address() == 0 || handle.length() != length
        || handle.localKey() < 0 || handle.remoteKey() < 0
        || handle.generation() != generation) {
      throw new IllegalArgumentException("native RNIC registration does not match its request");
    }
  }

  private void requireConnected() {
    if (!connected) {
      throw new IllegalStateException("RNIC provider is disconnected");
    }
  }

  private static RuntimeException append(
      RuntimeException current,
      RuntimeException added) {
    if (current == null) {
      return added;
    }
    current.addSuppressed(added);
    return current;
  }

  private static String digest(String domain, String canonical) {
    return sha256((domain + '\0' + canonical).getBytes(StandardCharsets.UTF_8));
  }

  private static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException impossible) {
      throw new IllegalStateException("SHA-256 is unavailable", impossible);
    }
  }
}
