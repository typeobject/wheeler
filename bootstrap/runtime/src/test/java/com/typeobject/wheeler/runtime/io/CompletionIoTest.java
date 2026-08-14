package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import com.typeobject.wheeler.runtime.io.IoCompletion.CancellationRelation;
import com.typeobject.wheeler.runtime.io.IoCompletion.TerminalKind;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

/** Exercises one-queue and many-queue completion delivery through the common lifecycle. */
final class CompletionIoTest {
  private static final IoLimits LIMITS = new IoLimits(16, 16, 8, 8, 16, 64);

  @Test
  void requestConstructionAndSubmissionRunNoProviderActionBeforeAwait() {
    AtomicInteger effects = new AtomicInteger();
    IoRequest<Integer> request = IoRequest.prepare(
        "completion:pure", 1,
        () -> IoProviderResult.success(effects.incrementAndGet(), 1));
    try (IoScope scope = new CompletionIo(1, 16).scope(LIMITS)) {
      IoOperation<Integer> operation = scope.submit(request);
      assertEquals(0, effects.get());
      IoCompletion<Integer> completion = operation.await();
      assertEquals(1, effects.get());
      assertEquals(TerminalKind.SUCCESS, completion.terminalKind());
      assertEquals(CancellationRelation.NOT_REQUESTED, completion.cancellationRelation());
      assertEquals("bounded-completion-io-1", completion.backend());
    }
  }

  @Test
  void queuedCancellationRunsNoProviderActionAndStillRequiresReaping() {
    AtomicInteger effects = new AtomicInteger();
    IoScope scope = new CompletionIo(4, 4).scope(LIMITS);
    IoOperation<Integer> operation = scope.submit(IoRequest.prepare(
        "completion:cancel", 1,
        () -> IoProviderResult.success(effects.incrementAndGet(), 1)));
    assertTrue(operation.cancel());
    assertEquals(0, effects.get());
    assertThrows(IllegalStateException.class, scope::close);
    IoCompletion<Integer> completion = operation.await();
    assertEquals(TerminalKind.CANCELED, completion.terminalKind());
    assertEquals(CancellationRelation.CANCELED_BEFORE_EFFECT, completion.cancellationRelation());
    assertTrue(completion.resourcesReleased());
    scope.close();
  }

  @Test
  void oneAndManyQueueProfilesPreserveCanonicalBatchReduction() {
    for (CompletionIo io : List.of(new CompletionIo(1, 16), new CompletionIo(4, 4))) {
      List<Integer> execution = new ArrayList<>();
      try (IoScope scope = io.scope(LIMITS)) {
        List<IoOperation<Integer>> operations = scope.submitBatch(List.of(
            request("completion:batch-0", 0, execution),
            request("completion:batch-1", 1, execution),
            request("completion:batch-2", 2, execution)));
        assertTrue(execution.isEmpty());
        IoScope.Selected<Integer> selected = scope.selectFirst(operations);
        assertEquals(0, selected.completion().value());
        assertEquals(1, selected.remaining().get(0).await().value());
        assertEquals(2, selected.remaining().get(1).await().value());
        assertEquals(List.of(0, 1, 2), execution);
      }
    }
  }

  @Test
  void graphDependentsEnterAQueueOnlyAfterNamedPredecessorsComplete() {
    List<Integer> execution = new ArrayList<>();
    IoGraph<Integer> graph = new IoGraph<>(3, 2);
    int first = graph.add(request("completion:graph-0", 0, execution));
    int second = graph.add(request("completion:graph-1", 1, execution));
    graph.addAfter(request("completion:graph-2", 2, execution), first, second);
    try (IoScope scope = new CompletionIo(4, 4).scope(LIMITS)) {
      List<IoCompletion<Integer>> completions = scope.awaitGraph(graph);
      assertEquals(List.of(0, 1, 2), execution);
      assertEquals(List.of(0, 1, 2), completions.stream().map(IoCompletion::value).toList());
    }
  }

  @Test
  void completionAndInlineProfilesAgreeOnEveryPortableCompletionFact() {
    IoCompletion<Long> inline;
    IoCompletion<Long> completion;
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      inline = scope.await(IoRequest.prepare(
          "completion:differential", 3, () -> IoProviderResult.success(19L, 3)));
    }
    try (IoScope scope = new CompletionIo(2, 8).scope(LIMITS)) {
      completion = scope.await(IoRequest.prepare(
          "completion:differential", 3, () -> IoProviderResult.success(19L, 3)));
    }
    assertEquals(inline.operationId(), completion.operationId());
    assertEquals(inline.requestIdentity(), completion.requestIdentity());
    assertEquals(inline.terminalKind(), completion.terminalKind());
    assertEquals(inline.cancellationRelation(), completion.cancellationRelation());
    assertEquals(inline.value(), completion.value());
    assertEquals(inline.progress(), completion.progress());
    assertEquals(inline.declaredWork(), completion.declaredWork());
    assertEquals(inline.resourcesReleased(), completion.resourcesReleased());
  }

  @Test
  void queueTopologyAndScopeAdmissionFailBeforeRequestConsumption() {
    assertThrows(IllegalArgumentException.class, () -> new CompletionIo(0, 1));
    assertThrows(IllegalArgumentException.class, () -> new CompletionIo(1, 0));
    CompletionIo io = new CompletionIo(1, 1);
    IoRequest<Integer> request = IoRequest.prepare(
        "completion:capacity", 1, () -> IoProviderResult.success(7, 1));
    assertThrows(IllegalArgumentException.class, () -> io.scope(LIMITS));
    IoLimits one = new IoLimits(1, 1, 1, 1, 1, 1);
    try (IoScope scope = io.scope(one)) {
      assertFalse(request.isConsumed());
      assertEquals(7, scope.await(request).value());
    }
  }

  private static IoRequest<Integer> request(
      String identity, int value, List<Integer> execution) {
    return IoRequest.prepare(identity, 1, () -> {
      execution.add(value);
      return IoProviderResult.success(value, 1);
    });
  }
}
