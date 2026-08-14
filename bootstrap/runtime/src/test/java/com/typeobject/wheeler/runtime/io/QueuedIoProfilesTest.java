package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.IoCompletion.CancellationRelation;
import com.typeobject.wheeler.runtime.io.IoCompletion.TerminalKind;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

/** Exercises readiness and polling delivery against the common bounded lifecycle. */
final class QueuedIoProfilesTest {
  private static final IoLimits LIMITS = new IoLimits(8, 8, 8, 8, 8, 64);

  @Test
  void readinessRunsNoProviderActionUntilTheLevelSignalIsAsserted() {
    AtomicBoolean ready = new AtomicBoolean();
    AtomicInteger effects = new AtomicInteger();
    IoRequest<Integer> request = IoRequest.prepareWhen(
        "readiness:level",
        1,
        ready::get,
        () -> IoProviderResult.success(effects.incrementAndGet(), 1),
        () -> {});
    try (IoScope scope = new ReadinessIo(1, 8).scope(LIMITS)) {
      IoOperation<Integer> operation = scope.submit(request);
      assertEquals(0, effects.get());
      assertThrows(IllegalStateException.class, operation::await);
      assertFalse(operation.isTerminal());
      ready.set(true);
      IoCompletion<Integer> completion = operation.await();
      assertEquals(1, completion.value());
      assertEquals("bounded-readiness-io-1", completion.backend());
    }
  }

  @Test
  void readinessSelectionConsumesTheFirstCanonicalReadyOperationOnly() {
    AtomicBoolean firstReady = new AtomicBoolean();
    AtomicBoolean secondReady = new AtomicBoolean(true);
    try (IoScope scope = new ReadinessIo(2, 4).scope(LIMITS)) {
      List<IoOperation<Integer>> operations = scope.submitBatch(List.of(
          readyRequest("readiness:first", 1, firstReady),
          readyRequest("readiness:second", 2, secondReady)));
      IoScope.Selected<Integer> selected = scope.selectFirst(operations);
      assertEquals(2, selected.completion().value());
      assertEquals(1, selected.remaining().size());
      firstReady.set(true);
      assertEquals(1, selected.remaining().getFirst().await().value());
    }
  }

  @Test
  void readinessCancellationNeedsNoSignalAndRunsNoProviderAction() {
    AtomicBoolean ready = new AtomicBoolean();
    AtomicInteger effects = new AtomicInteger();
    try (IoScope scope = new ReadinessIo(1, 8).scope(LIMITS)) {
      IoOperation<Integer> operation = scope.submit(IoRequest.prepareWhen(
          "readiness:cancel",
          1,
          ready::get,
          () -> IoProviderResult.success(effects.incrementAndGet(), 1),
          () -> {}));
      assertTrue(operation.cancel());
      IoCompletion<Integer> completion = operation.await();
      assertEquals(TerminalKind.CANCELED, completion.terminalKind());
      assertEquals(CancellationRelation.CANCELED_BEFORE_EFFECT, completion.cancellationRelation());
      assertEquals(0, effects.get());
    }
  }

  @Test
  void pollingRequiresExplicitProgressBeforeDirectAwait() {
    AtomicInteger effects = new AtomicInteger();
    try (IoScope scope = new PollingIo(1, 8).scope(LIMITS)) {
      IoOperation<Integer> operation = scope.submit(IoRequest.prepare(
          "polling:explicit", 1,
          () -> IoProviderResult.success(effects.incrementAndGet(), 1)));
      assertThrows(IllegalStateException.class, operation::await);
      assertEquals(0, effects.get());
      assertTrue(scope.pollOne());
      assertEquals(1, effects.get());
      assertFalse(scope.pollOne());
      IoCompletion<Integer> completion = operation.await();
      assertEquals(1, completion.value());
      assertEquals("bounded-polling-io-1", completion.backend());
    }
  }

  @Test
  void pollingUsesCanonicalOperationOrderAcrossManyLanes() {
    try (IoScope scope = new PollingIo(4, 2).scope(LIMITS)) {
      List<IoOperation<Integer>> operations = scope.submitBatch(List.of(
          request("polling:0", 0),
          request("polling:1", 1),
          request("polling:2", 2)));
      assertTrue(scope.pollOne());
      assertTrue(operations.get(0).isTerminal());
      assertFalse(operations.get(1).isTerminal());
      assertTrue(scope.pollOne());
      assertTrue(operations.get(1).isTerminal());
      assertTrue(scope.pollOne());
      assertTrue(operations.get(2).isTerminal());
      assertFalse(scope.pollOne());
      for (int index = 0; index < operations.size(); index++) {
        assertEquals(index, operations.get(index).await().value());
      }
    }
  }

  @Test
  void interruptProfileUsesTheSameTerminalContract() {
    IoCompletion<Integer> completion;
    try (InterruptIo io = new InterruptIo(1, 1);
        IoScope scope = io.scope(LIMITS)) {
      completion = scope.await(request("interrupt:differential", 9));
    }
    assertEquals(TerminalKind.SUCCESS, completion.terminalKind());
    assertEquals(CancellationRelation.NOT_REQUESTED, completion.cancellationRelation());
    assertEquals(9, completion.value());
    assertEquals(1, completion.progress());
    assertTrue(completion.resourcesReleased());
    assertEquals("bounded-interrupt-io-1", completion.backend());
  }

  @Test
  void readinessAndPollingProfilesMatchPortableTerminalFacts() {
    IoCompletion<Integer> readiness;
    AtomicBoolean ready = new AtomicBoolean(true);
    try (IoScope scope = new ReadinessIo(1, 8).scope(LIMITS)) {
      readiness = scope.await(readyRequest("queued:differential", 7, ready));
    }
    IoCompletion<Integer> polling;
    try (IoScope scope = new PollingIo(1, 8).scope(LIMITS)) {
      IoOperation<Integer> operation = scope.submit(request("queued:differential", 7));
      scope.pollOne();
      polling = operation.await();
    }
    assertEquals(readiness.operationId(), polling.operationId());
    assertEquals(readiness.requestIdentity(), polling.requestIdentity());
    assertEquals(readiness.terminalKind(), polling.terminalKind());
    assertEquals(readiness.cancellationRelation(), polling.cancellationRelation());
    assertEquals(readiness.value(), polling.value());
    assertEquals(readiness.progress(), polling.progress());
    assertEquals(readiness.declaredWork(), polling.declaredWork());
    assertEquals(readiness.resourcesReleased(), polling.resourcesReleased());
  }

  private static IoRequest<Integer> readyRequest(
      String identity, int value, AtomicBoolean ready) {
    return IoRequest.prepareWhen(
        identity,
        1,
        ready::get,
        () -> IoProviderResult.success(value, 1),
        () -> {});
  }

  private static IoRequest<Integer> request(String identity, int value) {
    return IoRequest.prepare(identity, 1, () -> IoProviderResult.success(value, 1));
  }
}
