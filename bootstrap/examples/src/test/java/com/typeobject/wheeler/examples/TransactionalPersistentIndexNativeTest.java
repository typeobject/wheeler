package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.runtime.io.DeterministicIo;
import com.typeobject.wheeler.runtime.io.IoCompletion;
import com.typeobject.wheeler.runtime.io.IoLimits;
import com.typeobject.wheeler.runtime.io.IoScope;
import com.typeobject.wheeler.runtime.io.NativePositionalFile;
import com.typeobject.wheeler.runtime.io.OwnedIoBuffer;
import java.nio.file.Path;
import java.time.Duration;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Process-crash qualification for the checked-in transactional index protocol. */
final class TransactionalPersistentIndexNativeTest {
  private static final IoLimits LIMITS = new IoLimits(4, 4, 4, 4, 4, 64);

  @Test
  void abruptWriterLeavesTornRecordAndFreshProcessStateSelectsLatestMarker(
      @TempDir Path temporary) throws Exception {
    Path index = temporary.resolve("index.log");
    Process writer = new ProcessBuilder(
        Path.of(System.getProperty("java.home"), "bin", "java").toString(),
        "-cp",
        System.getProperty("java.class.path"),
        TransactionalIndexCrashWriter.class.getName(),
        index.toString())
        .redirectErrorStream(true)
        .start();
    boolean exited = writer.waitFor(Duration.ofSeconds(10).toMillis(), TimeUnit.MILLISECONDS);
    if (!exited) {
      writer.destroyForcibly();
      throw new AssertionError("transactional index crash writer did not terminate");
    }
    assertEquals(0, writer.exitValue(), new String(writer.getInputStream().readAllBytes()));

    byte[] log;
    try (NativePositionalFile file = NativePositionalFile.open(
        "transactional-index",
        index,
        NativePositionalFile.Rights.READ_ONLY,
        64);
        IoScope scope = new DeterministicIo(DeterministicIo.Delivery.INLINE).scope(LIMITS)) {
      OwnedIoBuffer destination = OwnedIoBuffer.allocate(9);
      IoCompletion<NativePositionalFile.ReadCompleted> completion =
          scope.await(file.readAt(0, destination, 0, 9));
      assertEquals(8, completion.progress());
      log = destination.snapshot();
    }

    assertArrayEquals(new byte[] {7, 0, 1, 11, 1, 1, 19, 2, 0}, log);
    long root = 0;
    long sequence = -1;
    for (int record = 0; record < 3; record++) {
      int base = record * 3;
      if (log[base + 2] == 1 && sequence < log[base + 1]) {
        root = log[base];
        sequence = log[base + 1];
      }
    }
    assertEquals(11, root);
    assertEquals(1, sequence);
  }
}
