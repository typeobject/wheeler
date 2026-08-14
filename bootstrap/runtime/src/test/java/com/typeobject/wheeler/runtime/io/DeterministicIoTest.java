package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import com.typeobject.wheeler.runtime.io.IoCompletion.CancellationRelation;
import com.typeobject.wheeler.runtime.io.IoCompletion.TerminalKind;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

/** Exercises the stage-0 oracle for WIP-0032's bounded lifecycle laws. */
final class DeterministicIoTest {
  private static final IoLimits LIMITS = new IoLimits(32, 32, 16, 16, 32, 128);

  @Test
  void requestConstructionIsPureAndAwaitConsumesExactlyOnce() {
    AtomicInteger effects = new AtomicInteger();
    IoRequest<Integer> request = IoRequest.prepare(
        "test:pure-request", 3,
        () -> IoProviderResult.success(effects.incrementAndGet(), 3));
    assertEquals(0, effects.get());

    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      IoCompletion<Integer> completion = scope.await(request);
      assertEquals(1, effects.get());
      assertEquals(TerminalKind.SUCCESS, completion.terminalKind());
      assertEquals(CancellationRelation.NOT_REQUESTED, completion.cancellationRelation());
      assertEquals(1, completion.successfulValue().orElseThrow());
      assertEquals(0, scope.activeOperationCount());
      assertThrows(IllegalStateException.class, () -> scope.await(request));
    }
  }

  @Test
  void delayedCancellationCompletesBeforeEffectAndStillRequiresReaping() {
    AtomicInteger effects = new AtomicInteger();
    IoRequest<Integer> request = IoRequest.prepare(
        "test:cancel-before", 1,
        () -> IoProviderResult.success(effects.incrementAndGet(), 1));
    IoScope scope = new DeterministicIo(Delivery.DELAYED).scope(LIMITS);
    IoOperation<Integer> operation = scope.submit(request);
    assertThrows(IllegalStateException.class, scope::close);
    assertTrue(operation.cancel());
    assertEquals(0, effects.get());
    assertThrows(IllegalStateException.class, scope::close);

    IoCompletion<Integer> completion = operation.await();
    assertEquals(TerminalKind.CANCELED, completion.terminalKind());
    assertEquals(
        CancellationRelation.CANCELED_BEFORE_EFFECT,
        completion.cancellationRelation());
    assertEquals(0, completion.progress());
    assertTrue(completion.resourcesReleased());
    assertThrows(IllegalStateException.class, operation::await);
    scope.close();
  }

  @Test
  void cancellationAfterInlineCompletionRecordsThatCompletionWon() {
    IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS);
    IoOperation<Long> operation = scope.submit(IoRequest.prepare(
        "test:completion-won", 2, () -> IoProviderResult.success(7L, 2)));
    assertFalse(operation.cancel());
    IoCompletion<Long> completion = operation.await();
    assertEquals(
        CancellationRelation.COMPLETED_BEFORE_CANCELLATION,
        completion.cancellationRelation());
    assertEquals(7L, completion.value());
    scope.close();
  }

  @Test
  void providerResultMappingPreservesEveryNonsuccessKindWithoutInvokingMapper() {
    AtomicInteger mappings = new AtomicInteger();
    for (IoProviderResult<Integer> result : List.of(
        IoProviderResult.<Integer>failure("failed", 0),
        IoProviderResult.<Integer>canceledBeforeEffect("before"),
        IoProviderResult.<Integer>canceledAfterPartial("partial", 1),
        IoProviderResult.<Integer>uncertain("reconcile:item", 2))) {
      IoProviderResult<Long> mapped = result.mapSuccess(value -> {
        mappings.incrementAndGet();
        return value.longValue();
      });
      assertEquals(result.kind(), mapped.kind());
      assertEquals(result.detail(), mapped.detail());
      assertEquals(result.progress(), mapped.progress());
    }
    assertEquals(0, mappings.get());
    assertEquals(6L, IoProviderResult.success(3, 1)
        .mapSuccess(value -> value * 2L).value());
  }

  @Test
  void partialFailureAndUncertaintyRemainDistinct() {
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      IoCompletion<Long> partial = scope.await(IoRequest.prepare(
          "test:partial", 8,
          () -> IoProviderResult.canceledAfterPartial("four-bytes-visible", 4)));
      assertEquals(TerminalKind.CANCELED, partial.terminalKind());
      assertEquals(
          CancellationRelation.CANCELED_AFTER_PARTIAL_EFFECT,
          partial.cancellationRelation());
      assertEquals(4, partial.progress());

      IoCompletion<Long> uncertain = scope.await(IoRequest.prepare(
          "test:uncertain", 8,
          () -> IoProviderResult.uncertain("reconcile:request-44", 3)));
      assertEquals(TerminalKind.UNCERTAIN, uncertain.terminalKind());
      assertEquals(
          CancellationRelation.UNCERTAIN_WITHOUT_CANCELLATION,
          uncertain.cancellationRelation());
      assertEquals("reconcile:request-44", uncertain.detail());

      IoCompletion<Long> failure = scope.await(IoRequest.prepare(
          "test:failure", 8,
          () -> IoProviderResult.failure("provider-rejected", 0)));
      assertEquals(TerminalKind.FAILURE, failure.terminalKind());
      assertEquals(0, failure.progress());
    }
  }

  @Test
  void independentBatchSelectionNeverOrphansTheRemainder() {
    List<Integer> execution = new ArrayList<>();
    List<IoRequest<Integer>> requests = List.of(
        request("test:batch-0", 0, execution),
        request("test:batch-1", 1, execution),
        request("test:batch-2", 2, execution));
    try (IoScope scope = new DeterministicIo(Delivery.DELAYED).scope(LIMITS)) {
      List<IoOperation<Integer>> operations = scope.submitBatch(requests);
      assertTrue(execution.isEmpty());
      IoScope.Selected<Integer> selected = scope.selectFirst(operations);
      assertEquals(0, selected.completion().value());
      assertEquals(List.of(0), execution);
      assertEquals(2, selected.remaining().size());
      assertEquals(1, selected.remaining().get(0).await().value());
      assertEquals(2, selected.remaining().get(1).await().value());
      assertEquals(List.of(0, 1, 2), execution);
    }
  }

  @Test
  void graphPublishesDependentsOnlyAfterEveryNamedPredecessor() {
    List<Integer> execution = new ArrayList<>();
    IoGraph<Integer> graph = new IoGraph<>(16, 32);
    int first = graph.add(request("test:graph-0", 0, execution));
    int second = graph.add(request("test:graph-1", 1, execution));
    graph.addAfter(request("test:graph-2", 2, execution), first, second);

    try (IoScope scope = new DeterministicIo(Delivery.DELAYED).scope(LIMITS)) {
      List<IoCompletion<Integer>> completions = scope.awaitGraph(graph);
      assertEquals(List.of(0, 1, 2), execution);
      assertEquals(List.of(0, 1, 2), completions.stream().map(IoCompletion::value).toList());
      assertEquals(0, scope.activeOperationCount());
    }
    assertEquals(3, graph.nodeCount());
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      assertThrows(IllegalStateException.class, () -> scope.awaitGraph(graph));
    }
  }

  @Test
  void preflightLimitFailureConsumesNeitherBatchRequest() {
    IoLimits one = new IoLimits(1, 1, 2, 2, 2, 8);
    IoRequest<Integer> first = IoRequest.prepare(
        "test:limit-0", 1, () -> IoProviderResult.success(0, 1));
    IoRequest<Integer> second = IoRequest.prepare(
        "test:limit-1", 1, () -> IoProviderResult.success(1, 1));
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(one)) {
      assertThrows(
          IllegalStateException.class,
          () -> scope.submitBatch(List.of(first, second)));
      assertEquals(0, scope.await(first).value());
    }
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(one)) {
      assertEquals(1, scope.await(second).value());
    }
  }

  @Test
  void positionalReadsHoldAndReturnTheirDestinationOwner() {
    MemoryAddressableFile file = new MemoryAddressableFile(
        "memory:file-1",
        MemoryAddressableFile.Rights.READ_ONLY,
        "abcdef".getBytes(StandardCharsets.UTF_8));
    OwnedIoBuffer destination = OwnedIoBuffer.allocate(4);
    IoRequest<MemoryAddressableFile.ReadCompleted> request = file.readAt(1, destination, 0, 4);
    assertThrows(IllegalStateException.class, destination::snapshot);

    try (IoScope scope = new DeterministicIo(Delivery.DELAYED).scope(LIMITS)) {
      IoOperation<MemoryAddressableFile.ReadCompleted> operation = scope.submit(request);
      assertThrows(IllegalStateException.class, destination::snapshot);
      MemoryAddressableFile.ReadCompleted completed = operation.await().value();
      assertEquals(destination, completed.buffer());
      assertEquals(4, completed.bytesRead());
      assertArrayEquals("bcde".getBytes(StandardCharsets.UTF_8), destination.snapshot());
    }
  }

  @Test
  void positionalWritesRemainCompletionNotDurability() {
    MemoryAddressableFile file = new MemoryAddressableFile(
        "memory:file-2",
        MemoryAddressableFile.Rights.READ_WRITE,
        "abcdef".getBytes(StandardCharsets.UTF_8));
    OwnedIoBuffer source = OwnedIoBuffer.copyOf("XY".getBytes(StandardCharsets.UTF_8));
    IoRequest<MemoryAddressableFile.WriteCompleted> write = file.writeAt(2, source, 0, 2);
    assertThrows(IllegalStateException.class, source::snapshot);

    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      IoCompletion<MemoryAddressableFile.WriteCompleted> completion = scope.await(write);
      assertEquals(TerminalKind.SUCCESS, completion.terminalKind());
      assertEquals(2, completion.progress());
      assertEquals(source, completion.value().buffer());
      assertArrayEquals("XY".getBytes(StandardCharsets.UTF_8), source.snapshot());

      OwnedIoBuffer destination = OwnedIoBuffer.allocate(6);
      scope.await(file.readAt(0, destination, 0, 6));
      assertArrayEquals("abXYef".getBytes(StandardCharsets.UTF_8), destination.snapshot());
    }
  }

  @Test
  void cancellationBeforePositionalEffectReleasesTheBufferAndPreservesBytes() {
    MemoryAddressableFile file = new MemoryAddressableFile(
        "memory:file-3",
        MemoryAddressableFile.Rights.READ_WRITE,
        "stable".getBytes(StandardCharsets.UTF_8));
    OwnedIoBuffer source = OwnedIoBuffer.copyOf("BROKEN".getBytes(StandardCharsets.UTF_8));
    try (IoScope scope = new DeterministicIo(Delivery.DELAYED).scope(LIMITS)) {
      IoOperation<MemoryAddressableFile.WriteCompleted> write = scope.submit(
          file.writeAt(0, source, 0, 6));
      assertTrue(write.cancel());
      write.await();
      assertArrayEquals("BROKEN".getBytes(StandardCharsets.UTF_8), source.snapshot());

      OwnedIoBuffer destination = OwnedIoBuffer.allocate(6);
      scope.await(file.readAt(0, destination, 0, 6));
      assertArrayEquals("stable".getBytes(StandardCharsets.UTF_8), destination.snapshot());
    }
  }

  @Test
  void invalidPositionalRangesFailBeforeCapturingBuffers() {
    MemoryAddressableFile file = new MemoryAddressableFile(
        "memory:file-4",
        MemoryAddressableFile.Rights.READ_ONLY,
        new byte[4]);
    OwnedIoBuffer buffer = OwnedIoBuffer.allocate(2);
    assertThrows(IllegalArgumentException.class, () -> file.readAt(-1, buffer, 0, 1));
    assertThrows(IllegalArgumentException.class, () -> file.readAt(0, buffer, 1, 2));
    buffer.put(0, (byte) 7);
    assertEquals(7, buffer.get(0));
    assertThrows(IllegalStateException.class, () -> file.writeAt(0, buffer, 0, 1));
    assertEquals(7, buffer.get(0));
  }

  @Test
  void consumedBatchMemberDoesNotPublishItsNeighbors() {
    IoRequest<Integer> available = IoRequest.prepare(
        "test:batch-available", 1, () -> IoProviderResult.success(1, 1));
    IoRequest<Integer> consumed = IoRequest.prepare(
        "test:batch-consumed", 1, () -> IoProviderResult.success(2, 1));
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      assertEquals(2, scope.await(consumed).value());
    }
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      assertThrows(
          IllegalStateException.class,
          () -> scope.submitBatch(List.of(available, consumed)));
      assertEquals(1, scope.await(available).value());
    }
  }

  @Test
  void malformedProviderProgressBecomesAKnownFailure() {
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      IoCompletion<Integer> completion = scope.await(IoRequest.prepare(
          "test:bad-progress", 1, () -> IoProviderResult.success(4, 2)));
      assertEquals(TerminalKind.FAILURE, completion.terminalKind());
      assertEquals("invalid-provider-progress", completion.detail());
      assertEquals(0, completion.progress());
    }
  }

  @Test
  void graphConstructionHonorsItsOwnExplicitBounds() {
    IoGraph<Integer> graph = new IoGraph<>(2, 1);
    int first = graph.add(IoRequest.prepare(
        "test:bounded-0", 1, () -> IoProviderResult.success(0, 1)));
    graph.addAfter(IoRequest.prepare(
        "test:bounded-1", 1, () -> IoProviderResult.success(1, 1)), first);
    assertThrows(
        IllegalStateException.class,
        () -> graph.add(IoRequest.prepare(
            "test:bounded-2", 1, () -> IoProviderResult.success(2, 1))));
  }

  @Test
  void inlineAndDelayedDeliveryHaveEqualSemanticCompletions() {
    IoCompletion<Long> inline;
    IoCompletion<Long> delayed;
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      inline = scope.await(IoRequest.prepare(
          "test:delivery", 5, () -> IoProviderResult.success(23L, 5)));
    }
    try (IoScope scope = new DeterministicIo(Delivery.DELAYED).scope(LIMITS)) {
      delayed = scope.await(IoRequest.prepare(
          "test:delivery", 5, () -> IoProviderResult.success(23L, 5)));
    }
    assertEquals(inline, delayed);
  }

  private static IoRequest<Integer> request(
      String identity, int value, List<Integer> execution) {
    return IoRequest.prepare(identity, 1, () -> {
      execution.add(value);
      return IoProviderResult.success(value, 1);
    });
  }
}
