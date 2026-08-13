package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.IoCompletion.CancellationRelation;
import java.util.concurrent.CountDownLatch;
import org.junit.jupiter.api.Test;

/** Deadline conformance: expiry requests cancellation and preserves effect uncertainty. */
final class IoDeadlineTest {
  @Test
  void expiryBeforeEffectCancelsWithoutRunningTheProvider() {
    int[] calls = {0};
    try (IoScope scope = new DeterministicIo(DeterministicIo.Delivery.DELAYED).scope(
        new IoLimits(1, 1, 1, 1, 1, 1))) {
      IoOperation<Integer> operation = scope.submit(IoRequest.prepare(
          "deadline:before-effect", 1, () -> {
            calls[0]++;
            return IoProviderResult.success(7, 1);
          }));
      IoDeadline<Integer> deadline = new IoDeadline<>(operation, 4);

      assertFalse(deadline.expireAt(3));
      assertTrue(deadline.expireAt(4));
      IoCompletion<Integer> completion = operation.await();

      assertEquals(0, calls[0]);
      assertEquals(CancellationRelation.CANCELED_BEFORE_EFFECT, completion.cancellationRelation());
      assertTrue(deadline.expired());
    }
  }

  @Test
  void expiryDuringEffectDoesNotClaimTheEffectWasAbsent() throws Exception {
    CountDownLatch started = new CountDownLatch(1);
    CountDownLatch release = new CountDownLatch(1);
    try (ThreadedIo backend = new ThreadedIo(1, 1);
         IoScope scope = backend.scope(new IoLimits(1, 1, 1, 1, 1, 1))) {
      IoOperation<Integer> operation = scope.submit(IoRequest.prepare(
          "deadline:running", 1, () -> {
            started.countDown();
            try {
              release.await();
            } catch (InterruptedException interrupted) {
              Thread.currentThread().interrupt();
              return IoProviderResult.uncertain("reconcile:deadline-interrupted", 0);
            }
            return IoProviderResult.uncertain("reconcile:deadline-running", 1);
          }));
      assertTrue(started.await(1, java.util.concurrent.TimeUnit.SECONDS));
      IoDeadline<Integer> deadline = new IoDeadline<>(operation, 1);

      assertTrue(deadline.expireAt(1));
      release.countDown();
      IoCompletion<Integer> completion = operation.await();

      assertEquals(CancellationRelation.UNCERTAIN_AFTER_CANCELLATION,
          completion.cancellationRelation());
      assertEquals(1, completion.progress());
    }
  }
}
