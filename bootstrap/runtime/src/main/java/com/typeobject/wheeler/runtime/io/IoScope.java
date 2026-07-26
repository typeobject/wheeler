package com.typeobject.wheeler.runtime.io;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import com.typeobject.wheeler.runtime.io.IoCompletion.CancellationRelation;
import com.typeobject.wheeler.runtime.io.IoCompletion.TerminalKind;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.IdentityHashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/** Bounded structured owner for prepared, submitted, terminal, and reaped operations. */
public final class IoScope implements AutoCloseable {
  /** Selection result that leaves every nonselected operation owned by the caller. */
  public record Selected<T>(IoCompletion<T> completion, List<IoOperation<T>> remaining) {
    public Selected {
      Objects.requireNonNull(completion, "completion");
      remaining = List.copyOf(remaining);
    }
  }

  private static final String BACKEND = "deterministic-io-1";

  private final long scopeId;
  private final Delivery delivery;
  private final IoLimits limits;
  private final Map<Long, IoOperation<?>> active = new LinkedHashMap<>();
  private final Set<Long> delayed = new LinkedHashSet<>();
  private long nextOperation = 1;
  private long chargedWork;
  private int terminalCount;
  private boolean closed;

  IoScope(long scopeId, Delivery delivery, IoLimits limits) {
    this.scopeId = scopeId;
    this.delivery = Objects.requireNonNull(delivery, "delivery");
    this.limits = Objects.requireNonNull(limits, "limits");
  }

  /** Submits one prepared request and returns its must-reap operation. */
  public <T> IoOperation<T> submit(IoRequest<T> request) {
    requireOpen();
    Objects.requireNonNull(request, "request");
    reserve(1, request.work());
    request.consume();
    IoOperation<T> operation = publish(request);
    if (delivery == Delivery.INLINE) {
      execute(operation);
    }
    return operation;
  }

  /** Submits and consumes one request in direct await style. */
  public <T> IoCompletion<T> await(IoRequest<T> request) {
    return submit(request).await();
  }

  /** Submits one bounded independent batch without adding ordering edges. */
  public <T> List<IoOperation<T>> submitBatch(List<IoRequest<T>> requests) {
    requireOpen();
    Objects.requireNonNull(requests, "requests");
    if (requests.isEmpty() || requests.size() > limits.maxBatchSize()) {
      throw new IllegalArgumentException("batch size exceeds scope limits");
    }
    List<IoRequest<T>> checked = List.copyOf(requests);
    long work = validateDistinctRequests(checked);
    reserve(checked.size(), work);
    for (IoRequest<T> request : checked) {
      request.consume();
    }
    List<IoOperation<T>> operations = new ArrayList<>(checked.size());
    for (IoRequest<T> request : checked) {
      operations.add(publish(request));
    }
    if (delivery == Delivery.INLINE) {
      operations.forEach(this::execute);
    }
    return List.copyOf(operations);
  }

  /** Reaps the first canonical terminal operation without orphaning the remainder. */
  public <T> Selected<T> selectFirst(List<IoOperation<T>> operations) {
    requireOpen();
    Objects.requireNonNull(operations, "operations");
    if (operations.isEmpty() || operations.size() > limits.maxBatchSize()) {
      throw new IllegalArgumentException("selection size exceeds scope limits");
    }
    List<IoOperation<T>> checked = new ArrayList<>(List.copyOf(operations));
    Set<IoOperation<T>> identities = Collections.newSetFromMap(new IdentityHashMap<>());
    for (IoOperation<T> operation : checked) {
      validateOwned(operation);
      if (!identities.add(operation)) {
        throw new IllegalArgumentException("selection contains a duplicate operation");
      }
    }
    checked.sort(Comparator.comparingLong(IoOperation::id));
    IoOperation<T> selected = checked.stream()
        .filter(IoOperation::isTerminal)
        .findFirst()
        .orElseGet(() -> {
          IoOperation<T> first = checked.get(0);
          execute(first);
          return first;
        });
    IoCompletion<T> completion = reap(selected);
    checked.remove(selected);
    return new Selected<>(completion, checked);
  }

  /** Executes one terminal-dependency graph and returns completions by node identity. */
  public <T> List<IoCompletion<T>> awaitGraph(IoGraph<T> graph) {
    requireOpen();
    Objects.requireNonNull(graph, "graph");
    List<IoGraph.Node<T>> nodes = graph.nodes();
    if (nodes.size() > limits.maxGraphNodes() || graph.edgeCount() > limits.maxGraphEdges()) {
      throw new IllegalArgumentException("graph exceeds scope limits");
    }
    List<IoRequest<T>> requests = nodes.stream().map(IoGraph.Node::request).toList();
    long work = validateDistinctRequests(requests);
    reserve(nodes.size(), work);
    for (IoRequest<T> request : requests) {
      request.consume();
    }
    graph.markConsumed();

    List<IoOperation<T>> operations = requests.stream()
        .map(request -> publish(request, false))
        .toList();
    List<IoCompletion<T>> completions = new ArrayList<>(
        Collections.nCopies(nodes.size(), null));
    boolean[] activated = new boolean[nodes.size()];
    int completed = 0;
    while (completed < nodes.size()) {
      for (int node = 0; node < nodes.size(); node++) {
        if (!activated[node] && dependenciesComplete(nodes.get(node), completions)) {
          activate(operations.get(node));
          activated[node] = true;
        }
      }

      List<IoOperation<T>> ready = new ArrayList<>();
      for (int node = 0; node < nodes.size(); node++) {
        if (activated[node] && !operations.get(node).isReaped()) {
          ready.add(operations.get(node));
        }
      }
      if (ready.isEmpty()) {
        throw new IllegalStateException("graph made no completion progress");
      }
      Selected<T> selected = selectFirst(ready);
      int node = operationNode(operations, selected.completion().operationId());
      completions.set(node, selected.completion());
      completed++;
    }
    return List.copyOf(completions);
  }

  /** Returns the number of submitted operations not yet reaped. */
  public int activeOperationCount() {
    return active.size();
  }

  /** Requires all work terminal and reaped before closing this scope. */
  @Override
  public void close() {
    if (!active.isEmpty()) {
      throw new IllegalStateException("I/O scope has live or unreaped operations");
    }
    closed = true;
  }

  <T> boolean cancel(IoOperation<T> operation) {
    requireOpen();
    validateOwned(operation);
    if (!operation.isTerminal()) {
      delayed.remove(operation.id());
      operation.request().releaseResources();
      operation.complete(new IoCompletion<>(
          operation.id(),
          operation.requestIdentity(),
          TerminalKind.CANCELED,
          CancellationRelation.CANCELED_BEFORE_EFFECT,
          null,
          "canceled-before-effect",
          0,
          operation.request().work(),
          true,
          BACKEND));
      terminalCount++;
      requireCompletionCapacity();
      return true;
    }

    IoCompletion<T> completion = operation.completion();
    CancellationRelation relation = switch (completion.terminalKind()) {
      case SUCCESS -> CancellationRelation.COMPLETED_BEFORE_CANCELLATION;
      case FAILURE -> CancellationRelation.FAILED_BEFORE_CANCELLATION;
      case UNCERTAIN -> CancellationRelation.UNCERTAIN_AFTER_CANCELLATION;
      case CANCELED -> completion.cancellationRelation();
    };
    operation.replaceCompletion(completion.withCancellationRelation(relation));
    return false;
  }

  <T> IoCompletion<T> await(IoOperation<T> operation) {
    requireOpen();
    validateOwned(operation);
    if (!operation.isTerminal()) {
      execute(operation);
    }
    return reap(operation);
  }

  private <T> IoOperation<T> publish(IoRequest<T> request) {
    return publish(request, true);
  }

  private <T> IoOperation<T> publish(IoRequest<T> request, boolean ready) {
    long operationId = operationId();
    IoOperation<T> operation = new IoOperation<>(this, operationId, request);
    active.put(operationId, operation);
    chargedWork += request.work();
    if (delivery == Delivery.DELAYED && ready) {
      delayed.add(operationId);
    }
    return operation;
  }

  private <T> void activate(IoOperation<T> operation) {
    if (delivery == Delivery.INLINE) {
      execute(operation);
    } else if (!delayed.add(operation.id())) {
      throw new IllegalStateException("graph operation activated more than once");
    }
  }

  private <T> void execute(IoOperation<T> operation) {
    validateOwned(operation);
    if (operation.isTerminal()) {
      return;
    }
    if (delivery == Delivery.DELAYED && !delayed.remove(operation.id())) {
      throw new IllegalStateException("delayed operation is not queued: " + operation.id());
    }

    IoTaskResult<T> result;
    try {
      result = operation.request().execute();
    } catch (RuntimeException failure) {
      String type = failure.getClass().getSimpleName();
      result = IoTaskResult.failure("provider-exception:" + type, 0);
    }
    if (result.progress() > operation.request().work()) {
      result = IoTaskResult.failure("invalid-provider-progress", 0);
    }
    operation.request().releaseResources();
    operation.complete(toCompletion(operation, result));
    terminalCount++;
    requireCompletionCapacity();
  }

  private <T> IoCompletion<T> toCompletion(
      IoOperation<T> operation, IoTaskResult<T> result) {
    return switch (result.kind()) {
      case SUCCESS -> new IoCompletion<>(
          operation.id(), operation.requestIdentity(), TerminalKind.SUCCESS,
          CancellationRelation.NOT_REQUESTED, result.value(), null, result.progress(),
          operation.request().work(), true, BACKEND);
      case FAILURE -> new IoCompletion<>(
          operation.id(), operation.requestIdentity(), TerminalKind.FAILURE,
          CancellationRelation.NOT_REQUESTED, null, result.detail(), result.progress(),
          operation.request().work(), true, BACKEND);
      case CANCELED_AFTER_PARTIAL_EFFECT -> new IoCompletion<>(
          operation.id(), operation.requestIdentity(), TerminalKind.CANCELED,
          CancellationRelation.CANCELED_AFTER_PARTIAL_EFFECT, null, result.detail(),
          result.progress(), operation.request().work(), true, BACKEND);
      case UNCERTAIN -> new IoCompletion<>(
          operation.id(), operation.requestIdentity(), TerminalKind.UNCERTAIN,
          CancellationRelation.UNCERTAIN_WITHOUT_CANCELLATION, null, result.detail(),
          result.progress(), operation.request().work(), true, BACKEND);
    };
  }

  private <T> IoCompletion<T> reap(IoOperation<T> operation) {
    validateOwned(operation);
    operation.markReaped();
    active.remove(operation.id());
    terminalCount--;
    return operation.completion();
  }

  private void reserve(int operations, long work) {
    if (operations < 1 || active.size() + operations > limits.maxOperations()) {
      throw new IllegalStateException("operation capacity exceeded");
    }
    if (nextOperation + operations - 1 > limits.maxOperations()) {
      throw new IllegalStateException("total operation capacity exceeded");
    }
    long nextWork = Math.addExact(chargedWork, work);
    if (nextWork > limits.maxWork()) {
      throw new IllegalStateException("scope work capacity exceeded");
    }
  }

  private <T> long validateDistinctRequests(List<IoRequest<T>> requests) {
    Set<IoRequest<T>> identities = Collections.newSetFromMap(new IdentityHashMap<>());
    long work = 0;
    for (IoRequest<T> request : requests) {
      Objects.requireNonNull(request, "request");
      if (!identities.add(request)) {
        throw new IllegalArgumentException("request collection contains an alias");
      }
      if (request.isConsumed()) {
        throw new IllegalStateException("request collection contains consumed work");
      }
      work = Math.addExact(work, request.work());
    }
    return work;
  }

  private static <T> boolean dependenciesComplete(
      IoGraph.Node<T> node, List<IoCompletion<T>> completions) {
    for (int predecessor : node.predecessors()) {
      if (completions.get(predecessor) == null) {
        return false;
      }
    }
    return true;
  }

  private static <T> int operationNode(
      List<IoOperation<T>> operations, long operationId) {
    for (int node = 0; node < operations.size(); node++) {
      IoOperation<T> operation = operations.get(node);
      if (operation != null && operation.id() == operationId) {
        return node;
      }
    }
    throw new IllegalStateException("selected operation is absent from graph");
  }

  private void validateOwned(IoOperation<?> operation) {
    Objects.requireNonNull(operation, "operation");
    if (!operation.ownedBy(this) || active.get(operation.id()) != operation) {
      throw new IllegalStateException("operation is not live in this scope");
    }
  }

  private long operationId() {
    if (nextOperation > limits.maxOperations()) {
      throw new IllegalStateException("scope operation identity capacity exceeded");
    }
    long base = Math.multiplyExact(scopeId, limits.maxOperations() + 1L);
    return Math.addExact(base, nextOperation++);
  }

  private void requireCompletionCapacity() {
    if (terminalCount > limits.maxCompletions()) {
      throw new IllegalStateException("completion capacity exceeded");
    }
  }

  private void requireOpen() {
    if (closed) {
      throw new IllegalStateException("I/O scope is closed");
    }
  }
}
