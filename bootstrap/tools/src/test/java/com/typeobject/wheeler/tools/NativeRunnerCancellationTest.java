package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.Arrays;
import java.util.concurrent.CancellationException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;

/** A cancelled host worker must stop before the native adapter returns report bytes. */
final class NativeRunnerCancellationTest {
  @Test
  void preservesCancellationInsteadOfReturningNativeOutput() {
    Program program = writer();
    Thread.currentThread().interrupt();
    try {
      assertThrows(CancellationException.class,
          () -> NativePackageTestRunner.execute(program, new byte[0], 1));
      assertTrue(Thread.currentThread().isInterrupted());
    } finally {
      Thread.interrupted();
    }
  }

  @Test
  void returnsCompleteOutputFromAnUninterruptedWorker() {
    assertArrayEquals(new byte[] {7}, NativePackageTestRunner.execute(writer(), new byte[0], 1));
  }

  @Test
  void stopsAnActiveInterpreterWithoutReturningItsOutput() throws Exception {
    Program program = new WheelerCompiler().compile("""
        classical class ActiveWriter {
          entry void main(borrow byteview input, borrow mut bytes output) {
            for (long index = 0; index < 1000000000; index += 1) limit 1000000000 {
              setByte(output, 0, 7);
            }
          }
        }
        """);
    AtomicReference<Throwable> failure = new AtomicReference<>();
    AtomicReference<byte[]> returned = new AtomicReference<>();
    Thread worker = Thread.ofPlatform().daemon().unstarted(() -> {
      try {
        returned.set(NativePackageTestRunner.execute(program, new byte[0], 1));
      } catch (Throwable exception) {
        failure.set(exception);
      }
    });
    worker.start();
    try {
      long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(2);
      boolean stepping = false;
      while (worker.isAlive() && !stepping && System.nanoTime() < deadline) {
        stepping = Arrays.stream(worker.getStackTrace()).anyMatch(frame ->
            frame.getClassName().equals(VirtualMachine.class.getName())
                && frame.getMethodName().equals("stepWithoutRewindHistory"));
        if (!stepping) {
          Thread.sleep(1);
        }
      }
      assertTrue(stepping, "worker did not enter native execution");
      worker.interrupt();
      worker.join(2000);
      assertFalse(worker.isAlive(), "native execution ignored cancellation");
      assertInstanceOf(CancellationException.class, failure.get());
      assertNull(returned.get(), "cancelled execution returned report bytes");
    } finally {
      worker.interrupt();
      worker.join(2000);
    }
  }

  private static Program writer() {
    return new WheelerCompiler().compile("""
        classical class Writer {
          entry void main(borrow byteview input, borrow mut bytes output) {
            setByte(output, 0, 7);
          }
        }
        """);
  }
}
