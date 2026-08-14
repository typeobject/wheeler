package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.jupiter.api.Test;

/** Compares portable terminal rows across every stage-0 delivery profile. */
final class IoLifecycleEncodingTest {
  private static final IoLimits LIMITS = new IoLimits(8, 8, 8, 8, 8, 64);

  @Test
  void everyDeliveryProfileProducesTheSameCanonicalTerminalRows() throws Exception {
    List<List<long[]>> profiles = List.of(
        runDeterministic(Delivery.INLINE),
        runDeterministic(Delivery.DELAYED),
        runCompletion(1, 8),
        runCompletion(4, 2),
        runReadiness(),
        runPolling(),
        runThreaded(),
        runInterrupt());
    List<long[]> expected = List.of(
        new long[] {1, 0, 1, 1, 1},
        new long[] {2, 0, 0, 1, 1},
        new long[] {3, 2, 1, 2, 1},
        new long[] {4, 5, 1, 2, 1});
    for (List<long[]> profile : profiles) {
      assertEquals(expected.size(), profile.size());
      for (int row = 0; row < expected.size(); row++) {
        assertArrayEquals(expected.get(row), profile.get(row));
      }
    }
  }

  @Test
  void queuedProfilesAgreeOnCancellationBeforeEffectEncoding() {
    List<long[]> rows = new ArrayList<>();
    try (IoScope scope = new DeterministicIo(Delivery.DELAYED).scope(LIMITS)) {
      rows.add(cancelQueued(scope));
    }
    try (IoScope scope = new CompletionIo(1, 8).scope(LIMITS)) {
      rows.add(cancelQueued(scope));
    }
    AtomicBoolean ready = new AtomicBoolean();
    try (IoScope scope = new ReadinessIo(1, 8).scope(LIMITS)) {
      IoOperation<Integer> operation = scope.submit(IoRequest.prepareWhen(
          "encoding:canceled",
          1,
          ready::get,
          () -> IoProviderResult.success(1, 1),
          () -> {}));
      assertTrue(operation.cancel());
      rows.add(IoLifecycleEncoding.terminalRow(operation.await()));
    }
    try (IoScope scope = new PollingIo(1, 8).scope(LIMITS)) {
      rows.add(cancelQueued(scope));
    }
    for (long[] row : rows) {
      assertArrayEquals(new long[] {3, 1, 0, 1, 1}, row);
    }
  }

  private static List<long[]> runDeterministic(Delivery delivery) {
    try (IoScope scope = new DeterministicIo(delivery).scope(LIMITS)) {
      return runAwaiting(scope);
    }
  }

  private static List<long[]> runCompletion(int queues, int depth) {
    try (IoScope scope = new CompletionIo(queues, depth).scope(LIMITS)) {
      return runAwaiting(scope);
    }
  }

  private static List<long[]> runReadiness() {
    AtomicBoolean ready = new AtomicBoolean(true);
    try (IoScope scope = new ReadinessIo(1, 8).scope(LIMITS)) {
      List<long[]> rows = new ArrayList<>();
      for (IoRequest<Integer> request : requests()) {
        IoRequest<Integer> gated = IoRequest.prepareWhen(
            request.identity(), request.work(), ready::get, request::execute, () -> {});
        rows.add(IoLifecycleEncoding.terminalRow(scope.await(gated)));
      }
      return List.copyOf(rows);
    }
  }

  private static List<long[]> runPolling() {
    try (IoScope scope = new PollingIo(1, 8).scope(LIMITS)) {
      List<long[]> rows = new ArrayList<>();
      for (IoRequest<Integer> request : requests()) {
        IoOperation<Integer> operation = scope.submit(request);
        assertTrue(scope.pollOne());
        rows.add(IoLifecycleEncoding.terminalRow(operation.await()));
      }
      return List.copyOf(rows);
    }
  }

  private static List<long[]> runThreaded() throws Exception {
    try (ThreadedIo io = new ThreadedIo(1, 1);
        IoScope scope = io.scope(LIMITS)) {
      return runAwaiting(scope);
    }
  }

  private static List<long[]> runInterrupt() throws Exception {
    try (InterruptIo io = new InterruptIo(1, 1);
        IoScope scope = io.scope(LIMITS)) {
      return runAwaiting(scope);
    }
  }

  private static List<long[]> runAwaiting(IoScope scope) {
    List<long[]> rows = new ArrayList<>();
    for (IoRequest<Integer> request : requests()) {
      rows.add(IoLifecycleEncoding.terminalRow(scope.await(request)));
    }
    return List.copyOf(rows);
  }

  private static long[] cancelQueued(IoScope scope) {
    IoOperation<Integer> operation = scope.submit(IoRequest.prepare(
        "encoding:canceled", 1, () -> IoProviderResult.success(1, 1)));
    assertTrue(operation.cancel());
    return IoLifecycleEncoding.terminalRow(operation.await());
  }

  private static List<IoRequest<Integer>> requests() {
    return List.of(
        IoRequest.prepare(
            "encoding:success", 1, () -> IoProviderResult.success(1, 1)),
        IoRequest.prepare(
            "encoding:failure", 1, () -> IoProviderResult.failure("known-failure", 0)),
        IoRequest.prepare(
            "encoding:partial", 2,
            () -> IoProviderResult.canceledAfterPartial("known-partial", 1)),
        IoRequest.prepare(
            "encoding:uncertain", 2,
            () -> IoProviderResult.uncertain("reconcile:encoding", 1)));
  }
}
