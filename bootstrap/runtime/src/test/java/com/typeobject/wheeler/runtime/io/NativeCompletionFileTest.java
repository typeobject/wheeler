package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Native asynchronous file operations delivered through bounded completion queues. */
final class NativeCompletionFileTest {
  private static final IoLimits LIMITS = new IoLimits(8, 8, 8, 8, 8, 1024);

  @Test
  void asynchronousProviderUsesFixedWorkersAndPortableCompletionRows(@TempDir Path temporary)
      throws Exception {
    byte[] content = new byte[] {3, 1, 4, 1, 5};
    try (NativeCompletionFile file = NativeCompletionFile.open(
        "native-completion", temporary.resolve("completion.bin"),
        NativeCompletionFile.Rights.READ_WRITE, 1024, 1, 8);
        IoScope scope = new CompletionIo(1, 8).scope(LIMITS)) {
      assertEquals(1, file.workers());
      assertEquals(8, file.maximumInFlight());
      OwnedIoBuffer source = OwnedIoBuffer.copyOf(content);
      IoOperation<NativeCompletionFile.WriteCompleted> write =
          scope.submit(file.writeAt(7, source, 0, content.length));
      assertThrows(IllegalStateException.class, source::snapshot);
      assertEquals(content.length, write.await().progress());
      assertArrayEquals(content, source.snapshot());

      OwnedIoBuffer destination = OwnedIoBuffer.allocate(content.length);
      IoCompletion<NativeCompletionFile.ReadCompleted> read =
          scope.await(file.readAt(7, destination, 0, content.length));
      assertEquals(content.length, read.progress());
      assertArrayEquals(content, destination.snapshot());
    }
  }

  @Test
  void queuedCompletionCancellationSubmitsNoAsynchronousFileWork(@TempDir Path temporary)
      throws Exception {
    NativeCompletionFile file = NativeCompletionFile.open(
        "native-completion-cancel", temporary.resolve("cancel.bin"),
        NativeCompletionFile.Rights.READ_WRITE, 64, 1, 2);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {8, 9});
    IoScope scope = new CompletionIo(1, 2).scope(new IoLimits(2, 2, 2, 2, 2, 16));
    IoOperation<NativeCompletionFile.WriteCompleted> operation =
        scope.submit(file.writeAt(0, source, 0, 2));

    assertThrows(IllegalStateException.class, file::close);
    assertTrue(operation.cancel());
    assertEquals(
        IoCompletion.CancellationRelation.CANCELED_BEFORE_EFFECT,
        operation.await().cancellationRelation());
    assertArrayEquals(new byte[] {8, 9}, source.snapshot());
    scope.close();
    file.close();
    assertEquals(0, java.nio.file.Files.size(temporary.resolve("cancel.bin")));
  }
}
