package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import com.typeobject.wheeler.runtime.io.IoCompletion.CancellationRelation;
import com.typeobject.wheeler.runtime.io.IoCompletion.TerminalKind;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

/** Exercises bounded overlap and cancellation races on the portable threaded backend. */
final class ThreadedIoTest {
  private static final IoLimits LIMITS = new IoLimits(16, 16, 8, 8, 16, 64);

  @Test
  void twoWorkersMakeRequiredOverlappingProgress() throws Exception {
    CountDownLatch started = new CountDownLatch(2);
    CountDownLatch release = new CountDownLatch(1);
    try (ThreadedIo io = new ThreadedIo(2, 4);
        IoScope scope = io.scope(LIMITS)) {
      List<IoOperation<Integer>> operations = scope.submitBatch(List.of(
          blockingRequest("threaded:overlap-0", 0, started, release),
          blockingRequest("threaded:overlap-1", 1, started, release)));
      assertTrue(started.await(2, TimeUnit.SECONDS));
      release.countDown();
      assertEquals(0, operations.get(0).await().value());
      assertEquals(1, operations.get(1).await().value());
    }
  }

  @Test
  void admissionFailsBeforeConsumingTheNextRequest() throws Exception {
    CountDownLatch started = new CountDownLatch(1);
    CountDownLatch release = new CountDownLatch(1);
    ThreadedIo io = new ThreadedIo(1, 1);
    IoScope scope = io.scope(LIMITS);
    IoOperation<Integer> first = scope.submit(
        blockingRequest("threaded:capacity-0", 0, started, release));
    assertTrue(started.await(2, TimeUnit.SECONDS));
    IoRequest<Integer> next = IoRequest.prepare(
        "threaded:capacity-1", 1, () -> IoTaskResult.success(1, 1));
    assertThrows(IllegalStateException.class, () -> scope.submit(next));
    assertThrows(IllegalStateException.class, io::close);

    release.countDown();
    assertEquals(0, first.await().value());
    assertEquals(1, scope.await(next).value());
    scope.close();
    io.close();
  }

  @Test
  void queuedCancellationRunsNoProviderAction() throws Exception {
    CountDownLatch started = new CountDownLatch(1);
    CountDownLatch release = new CountDownLatch(1);
    AtomicInteger queuedEffects = new AtomicInteger();
    try (ThreadedIo io = new ThreadedIo(1, 2);
        IoScope scope = io.scope(LIMITS)) {
      IoOperation<Integer> running = scope.submit(
          blockingRequest("threaded:running", 0, started, release));
      assertTrue(started.await(2, TimeUnit.SECONDS));
      IoOperation<Integer> queued = scope.submit(IoRequest.prepare(
          "threaded:queued", 1,
          () -> IoTaskResult.success(queuedEffects.incrementAndGet(), 1)));
      assertTrue(queued.cancel());
      IoCompletion<Integer> canceled = queued.await();
      assertEquals(TerminalKind.CANCELED, canceled.terminalKind());
      assertEquals(CancellationRelation.CANCELED_BEFORE_EFFECT, canceled.cancellationRelation());
      assertEquals(0, queuedEffects.get());
      release.countDown();
      running.await();
    }
  }

  @Test
  void cancellationOfRunningWorkRecordsThatCompletionWon() throws Exception {
    CountDownLatch started = new CountDownLatch(1);
    CountDownLatch release = new CountDownLatch(1);
    try (ThreadedIo io = new ThreadedIo(1, 1);
        IoScope scope = io.scope(LIMITS)) {
      IoOperation<Integer> operation = scope.submit(
          blockingRequest("threaded:cancel-race", 7, started, release));
      assertTrue(started.await(2, TimeUnit.SECONDS));
      assertFalse(operation.cancel());
      release.countDown();
      IoCompletion<Integer> completion = operation.await();
      assertEquals(7, completion.value());
      assertEquals(
          CancellationRelation.COMPLETED_BEFORE_CANCELLATION,
          completion.cancellationRelation());
    }
  }

  @Test
  void cancellationRaceCanRemainExplicitlyUncertain() throws Exception {
    CountDownLatch started = new CountDownLatch(1);
    CountDownLatch release = new CountDownLatch(1);
    try (ThreadedIo io = new ThreadedIo(1, 1);
        IoScope scope = io.scope(LIMITS)) {
      IoOperation<Integer> operation = scope.submit(IoRequest.prepare(
          "threaded:uncertain-race", 4, () -> {
            started.countDown();
            await(release);
            return IoTaskResult.uncertain("reconcile:threaded-1", 2);
          }));
      assertTrue(started.await(2, TimeUnit.SECONDS));
      assertFalse(operation.cancel());
      release.countDown();
      IoCompletion<Integer> completion = operation.await();
      assertEquals(TerminalKind.UNCERTAIN, completion.terminalKind());
      assertEquals(
          CancellationRelation.UNCERTAIN_AFTER_CANCELLATION,
          completion.cancellationRelation());
      assertEquals("reconcile:threaded-1", completion.detail());
      assertEquals(2, completion.progress());
    }
  }

  @Test
  void graphAdmitsIndependentRootsBeforeTheirDependent() {
    CountDownLatch roots = new CountDownLatch(2);
    AtomicInteger completedRoots = new AtomicInteger();
    IoGraph<Integer> graph = new IoGraph<>(3, 2);
    int first = graph.add(rootRequest("threaded:graph-0", 0, roots, completedRoots));
    int second = graph.add(rootRequest("threaded:graph-1", 1, roots, completedRoots));
    graph.addAfter(
        IoRequest.prepare("threaded:graph-2", 1, () -> {
          int observed = completedRoots.get();
          return IoTaskResult.success(observed, 1);
        }),
        first,
        second);

    try (ThreadedIo io = new ThreadedIo(2, 3);
        IoScope scope = io.scope(LIMITS)) {
      List<IoCompletion<Integer>> completions = scope.awaitGraph(graph);
      assertEquals(0, completions.get(0).value());
      assertEquals(1, completions.get(1).value());
      assertEquals(2, completions.get(2).value());
    }
  }

  @Test
  void threadedAndInlineBackendsAgreeOnSemanticCompletion() {
    IoCompletion<Long> inline;
    IoCompletion<Long> threaded;
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      inline = scope.await(IoRequest.prepare(
          "threaded:differential", 3, () -> IoTaskResult.success(19L, 3)));
    }
    try (ThreadedIo io = new ThreadedIo(1, 1);
        IoScope scope = io.scope(LIMITS)) {
      threaded = scope.await(IoRequest.prepare(
          "threaded:differential", 3, () -> IoTaskResult.success(19L, 3)));
    }
    assertEquals(inline.operationId(), threaded.operationId());
    assertEquals(inline.requestIdentity(), threaded.requestIdentity());
    assertEquals(inline.terminalKind(), threaded.terminalKind());
    assertEquals(inline.cancellationRelation(), threaded.cancellationRelation());
    assertEquals(inline.value(), threaded.value());
    assertEquals(inline.progress(), threaded.progress());
    assertEquals(inline.declaredWork(), threaded.declaredWork());
    assertEquals(inline.resourcesReleased(), threaded.resourcesReleased());
  }

  private static IoRequest<Integer> blockingRequest(
      String identity,
      int value,
      CountDownLatch started,
      CountDownLatch release) {
    return IoRequest.prepare(identity, 1, () -> {
      started.countDown();
      await(release);
      return IoTaskResult.success(value, 1);
    });
  }

  private static IoRequest<Integer> rootRequest(
      String identity,
      int value,
      CountDownLatch roots,
      AtomicInteger completedRoots) {
    return IoRequest.prepare(identity, 1, () -> {
      roots.countDown();
      await(roots);
      completedRoots.incrementAndGet();
      return IoTaskResult.success(value, 1);
    });
  }

  private static void await(CountDownLatch latch) {
    try {
      if (!latch.await(2, TimeUnit.SECONDS)) {
        throw new IllegalStateException("test provider timed out");
      }
    } catch (InterruptedException interrupted) {
      Thread.currentThread().interrupt();
      throw new IllegalStateException("test provider interrupted", interrupted);
    }
  }
}
