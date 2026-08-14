package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import com.typeobject.wheeler.runtime.io.DurabilityProfile.Atomicity;
import com.typeobject.wheeler.runtime.io.DurabilityProfile.FailureModel;
import com.typeobject.wheeler.runtime.io.DurabilityReceipt.Kind;
import com.typeobject.wheeler.runtime.io.NativePositionalFile.Rights;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Native positional-file and process-reopen evidence beneath the portable lifecycle. */
final class NativePositionalFileTest {
  private static final IoLimits LIMITS = new IoLimits(8, 8, 8, 8, 8, 1024);
  private static final IoLimits DIRECT_LIMITS = new IoLimits(8, 8, 8, 8, 8, 8192);

  @Test
  void positionalWriteForceCloseAndFreshReopenPreserveExactBytes(@TempDir Path temporary)
      throws Exception {
    Path path = temporary.resolve("index.bin");
    byte[] content = "committed-root-11".getBytes(StandardCharsets.UTF_8);
    NativePositionalFile.WriteCompleted written;
    DurabilityReceipt fileStable;
    try (NativePositionalFile file = NativePositionalFile.open(
        "native-index", path, Rights.READ_WRITE, 4096);
        IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      OwnedIoBuffer source = OwnedIoBuffer.copyOf(content);
      IoCompletion<NativePositionalFile.WriteCompleted> completion =
          scope.await(file.writeAt(19, source, 0, content.length));
      written = completion.successfulValue().orElseThrow();
      assertEquals(content.length, completion.progress());
      assertArrayEquals(content, source.snapshot());
      DurabilitySubject subject = new DurabilitySubject(
          file.identity(),
          1,
          19,
          content.length,
          identity(content),
          "-");
      DurabilityProfile profile = new DurabilityProfile(
          FailureModel.PROCESS_CRASH,
          Atomicity.RANGE,
          1,
          1,
          identity("native-file-profile".getBytes(StandardCharsets.UTF_8)),
          List.of("filechannel-force-contract"));
      DurabilityProfile unqualifiedPowerLoss = new DurabilityProfile(
          FailureModel.POWER_LOSS,
          Atomicity.RANGE,
          1,
          1,
          identity("native-file-profile".getBytes(StandardCharsets.UTF_8)),
          List.of("filechannel-force-contract"));
      assertThrows(
          IllegalArgumentException.class,
          () -> file.writeCompleted(written, subject, unqualifiedPowerLoss));
      DurabilityReceipt completed = file.writeCompleted(written, subject, profile);
      assertEquals(Kind.WRITE_COMPLETED, completed.kind());
      DurabilityReceipt dataStable = file.forceData(completed);
      assertEquals(Kind.DATA_STABLE, dataStable.kind());
      fileStable = file.forceMetadata(dataStable);
      assertEquals(Kind.FILE_STABLE, fileStable.kind());
      assertEquals(content.length + 19L, file.size());
    }

    try (NativePositionalFile reopened = NativePositionalFile.open(
        "native-index", path, Rights.READ_ONLY, 4096);
        IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      OwnedIoBuffer destination = OwnedIoBuffer.allocate(content.length);
      IoCompletion<NativePositionalFile.ReadCompleted> completion =
          scope.await(reopened.readAt(19, destination, 0, content.length));
      assertEquals(content.length, completion.progress());
      assertArrayEquals(content, destination.snapshot());
      assertEquals(fileStable.subject().contentIdentity(), identity(destination.snapshot()));
      assertThrows(
          IllegalStateException.class,
          () -> reopened.writeAt(0, destination, 0, 1));
    }
  }

  @Test
  void requiredDirectPathUsesAlignedNativeBuffersAndRejectsFallback(
      @TempDir Path temporary) throws Exception {
    Path path = temporary.resolve("direct.bin");
    byte[] content = new byte[4096];
    for (int index = 0; index < content.length; index++) {
      content[index] = (byte) index;
    }
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(content);
    try (NativePositionalFile file = NativePositionalFile.openDirect(
        "native-direct", path, Rights.READ_WRITE, 8192, 4096);
        IoScope scope = new DeterministicIo(Delivery.INLINE).scope(DIRECT_LIMITS)) {
      assertTrue(file.direct());
      assertEquals(4096, file.alignment());
      assertThrows(
          IllegalArgumentException.class,
          () -> file.writeAt(1, source, 0, content.length));
      assertArrayEquals(content, source.snapshot());
      assertEquals(content.length, scope.await(file.writeAt(0, source, 0, content.length)).progress());
    }

    try (NativePositionalFile file = NativePositionalFile.openDirect(
        "native-direct", path, Rights.READ_ONLY, 8192, 4096);
        IoScope scope = new DeterministicIo(Delivery.INLINE).scope(DIRECT_LIMITS)) {
      OwnedIoBuffer destination = OwnedIoBuffer.allocate(content.length);
      assertEquals(
          content.length,
          scope.await(file.readAt(0, destination, 0, content.length)).progress());
      assertArrayEquals(content, destination.snapshot());
    }
  }

  @Test
  void delayedCancellationReleasesBufferAndBlocksCloseUntilReaped(@TempDir Path temporary)
      throws Exception {
    NativePositionalFile file = NativePositionalFile.open(
        "native-cancel", temporary.resolve("cancel.bin"), Rights.READ_WRITE, 64);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {1, 2, 3});
    IoScope scope = new DeterministicIo(Delivery.DELAYED).scope(LIMITS);
    IoOperation<NativePositionalFile.WriteCompleted> operation =
        scope.submit(file.writeAt(0, source, 0, 3));

    assertThrows(IllegalStateException.class, file::close);
    assertTrue(operation.cancel());
    assertEquals(
        IoCompletion.CancellationRelation.CANCELED_BEFORE_EFFECT,
        operation.await().cancellationRelation());
    assertArrayEquals(new byte[] {1, 2, 3}, source.snapshot());
    scope.close();
    file.close();
    assertEquals(0, Files.size(temporary.resolve("cancel.bin")));
  }

  private static String identity(byte[] bytes) throws Exception {
    return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
  }
}
