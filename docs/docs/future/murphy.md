---
title: "Murphy: the debugger that searches failing timelines"
sidebar_position: 2
---

# Murphy: the debugger that searches failing timelines

:::caution Future design, not current Wheeler

`Murphy.w` is a possible application for a future fault-tolerant system. The current compiler accepts only the syntax that also appears in the [language reference](../reference/language-profile.md). This page describes a bounded model-checking and proof target. It does not claim that today's quantum hardware improves distributed debugging.

:::

`Murphy.w` takes a canonical protocol artifact, a finite starting state, safety rules, and a clear fault bound. It searches every allowed schedule of delivery, duplication, loss, crash, restart, partition, healing, timeout, and logical-time advance. The run returns one of three results:

- a deterministically replayable, kernel-certified counterexample;
- a kernel-checked proof that no counterexample exists within the exact bound;
- `inconclusive`.

The search does not use production logs, traffic archives, packet corpora, or a learned model. It builds the schedule space from the program and the fault grammar.

The finite model defines every failure the search may explore.

## Concrete investigation

Consider five replicas of a payment ledger. For every running or recovered replica, Murphy checks:

```text
The sum of account balances remains 1,000,000.
One transfer identifier causes at most one externally visible debit/credit effect.
No account balance becomes negative.
```

The initial profile admits at most:

```text
64 timeline events
2 node crashes
2 restarts
2 dropped messages
2 duplicate messages
1 partition
8 timer firings
128 live messages
```

One counterexample might show node 3 crediting a transfer, then crashing before it writes a durable idempotency marker. After restart, the node rebuilds the transfer as prepared and applies a duplicated commit.

Search evidence alone cannot prove a failure or bounded safety. Wheeler decodes each proposed schedule and replays it with exact classical semantics. An empty sample set proves nothing. A bounded-safety claim needs a separate canonical certificate that the trusted kernel accepts.

## Speculative source sketch

The sketch assumes finite-domain types, bounded maps and queues, first-class protocol artifacts, logged reversibility, coherent finite interpreters, proof-producing model checking, [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md) asynchronous effects, and proof-bearing replay packages. The model scheduler does not define another host-I/O API.

```java
package future.murphy.ledger;

import wheeler.concurrent.model.*;
import wheeler.distributed.*;
import wheeler.quantum.search.*;
import wheeler.proof.*;
import wheeler.package.*;

const long NODE_COUNT = 5;
const long ACCOUNT_COUNT = 8;
const long MAX_EVENTS = 64;
const long MAX_MESSAGES = 128;
const long MAX_TIMERS = 32;
const long SCHEDULE_BITS = 8192;
const long INITIAL_TOTAL_MONEY = 1_000_000;

type NodeId = Index<NODE_COUNT>;
type AccountId = Index<ACCOUNT_COUNT>;
type MessageId = Index<MAX_MESSAGES>;
type TimerId = Index<MAX_TIMERS>;
type Money = Int<65>;
type TransferId = BitVec<128>;
type NodeSet = BitSet<NODE_COUNT>;
type ScheduleEncoding = BitVec<SCHEDULE_BITS>;

variant TransferStatus {
  case Unknown();
  case Prepared(AccountId from, AccountId to, Money amount);
  case Applied();
  case Rejected();
}

record Account(Money balance) {}

record StableReplicaState(
  Array<Account, ACCOUNT_COUNT> accounts,
  BoundedMap<TransferId, TransferStatus, 256> transfers,
  BoundedMap<TransferId, UInt<2>, 256> visibleEffectCount,
  long persistedEpoch
) {}

record VolatileReplicaState(
  BoundedMap<TransferId, PendingTransfer, 256> pending,
  BoundedQueue<MessageId, MAX_MESSAGES> inbox,
  BoundedMap<TimerId, TimerState, MAX_TIMERS> timers
) {}

record Replica(
  boolean running,
  StableReplicaState stable,
  VolatileReplicaState volatileState
) {}

variant LedgerMessage {
  case BeginTransfer(
    TransferId transfer,
    AccountId from,
    AccountId to,
    Money amount
  );
  case Prepare(
    TransferId transfer,
    AccountId from,
    AccountId to,
    Money amount
  );
  case Prepared(TransferId transfer, NodeId participant);
  case Commit(TransferId transfer);
  case Abort(TransferId transfer);
  case Acknowledge(TransferId transfer);
}

record Envelope(
  MessageId id,
  NodeId sender,
  NodeId recipient,
  LedgerMessage payload
) {}

record NetworkState(
  BoundedMap<MessageId, Envelope, MAX_MESSAGES> pending,
  NodeSet partitionA,
  NodeSet partitionB,
  boolean partitioned
) {}

record TimerState(boolean armed, long logicalDeadline) {}
record PendingTransfer(AccountId from, AccountId to, Money amount) {}

record ClusterState(
  Array<Replica, NODE_COUNT> nodes,
  NetworkState network,
  long logicalTime,
  long nextMessageId
) {}

variant TimelineEvent {
  case Deliver(MessageId message);
  case Drop(MessageId message);
  case Duplicate(MessageId message);
  case Crash(NodeId node);
  case Restart(NodeId node);
  case Partition(NodeSet sideA, NodeSet sideB);
  case HealPartition();
  case FireTimer(NodeId node, TimerId timer);
  case AdvanceTime(long ticks);
}

record FaultBudget(
  long maximumCrashes,
  long maximumRestarts,
  long maximumDrops,
  long maximumDuplicates,
  long maximumPartitions,
  long maximumTimerFirings
) {}

record Timeline(
  UInt<7> length,
  Array<TimelineEvent, MAX_EVENTS> events,
  FaultBudget usedFaults
)
  invariant length <= MAX_EVENTS
  invariant canonicalUnusedEvents(events, length)
  invariant usedFaults == countFaults(events, length)
{}

record ProtocolArtifact(
  Hash256 artifactIdentity,
  Hash256 compilerIdentity,
  ProtocolSchema schema,
  VerifiedBytecode implementation
) {}

/*
* Modeled loss is explicit. A crash moves volatile state into its witness.
* A drop moves an envelope into its witness. Delivery records the previous
* recipient, emitted envelopes, and prior message-ID cursor. This is logged
* reversibility of the finite model, not reversal of a physical crash.
*/
variant EventWitness {
  case Clean();
  case Delivered(
    Envelope envelope,
    Replica previousRecipient,
    Array<Envelope, 8> emitted,
    long previousNextMessageId
  );
  case Dropped(Envelope envelope);
  case Duplicated(Envelope duplicate, long previousNextMessageId);
  case Crashed(NodeId node, VolatileReplicaState lostState);
  case Restarted(NodeId node, VolatileReplicaState previousState);
  case PartitionChanged(NetworkState previousNetwork);
  case TimerFired(
    NodeId node,
    TimerId timer,
    TimerState previousTimer,
    Replica previousNode,
    Array<Envelope, 8> emitted,
    long previousNextMessageId
  );
  case TimeAdvanced(long previousTime);
}

record TimelineWitness(Array<EventWitness, MAX_EVENTS> events) {
  static TimelineWitness clean() {
    return new TimelineWitness(
      Array.fill(MAX_EVENTS, new EventWitness.Clean())
    );
  }
}

logged rev void applyEvent(
  borrow ProtocolArtifact protocol,
  borrow TimelineEvent event,
  inout ClusterState cluster,
  inout EventWitness witness
)
  requires witness == EventWitness.Clean()
  ensures inverse(applyEvent)(
    protocol,
    event,
    cluster,
    witness
  ) restores old(cluster, witness)
{
  match (event) {
    case TimelineEvent.Deliver(MessageId id) {
      Envelope envelope = cluster.network.pending.remove(id);
      assert(cluster.nodes[envelope.recipient].running);
      assert(NetworkModel.canDeliver(
        cluster.network,
        envelope.sender,
        envelope.recipient
      ));

      Replica previous = cluster.nodes[envelope.recipient];
      long previousCursor = cluster.nextMessageId;
      Array<Envelope, 8> emitted =
        ProtocolMachine.dispatchBounded(
          protocol,
          envelope,
          cluster.nodes[envelope.recipient],
          cluster.logicalTime
        );
      NetworkModel.enqueueAll(
        emitted,
        cluster.network,
        cluster.nextMessageId
      );
      witness = new EventWitness.Delivered(
        envelope,
        previous,
        emitted,
        previousCursor
      );
    }

    case TimelineEvent.Drop(MessageId id) {
      witness = new EventWitness.Dropped(
        cluster.network.pending.remove(id)
      );
    }

    case TimelineEvent.Duplicate(MessageId id) {
      Envelope original = cluster.network.pending[id];
      long previousCursor = cluster.nextMessageId;
      Envelope duplicate = NetworkModel.duplicateWithNextId(
        original,
        cluster.nextMessageId
      );
      cluster.network.pending.insert(duplicate.id, duplicate);
      witness = new EventWitness.Duplicated(
        duplicate,
        previousCursor
      );
    }

    case TimelineEvent.Crash(NodeId node) {
      assert(cluster.nodes[node].running);
      VolatileReplicaState lost =
        move cluster.nodes[node].volatileState;
      cluster.nodes[node].volatileState =
        VolatileReplicaState.empty();
      cluster.nodes[node].running = false;
      witness = new EventWitness.Crashed(node, lost);
    }

    case TimelineEvent.Restart(NodeId node) {
      assert(!cluster.nodes[node].running);
      VolatileReplicaState prior =
        move cluster.nodes[node].volatileState;
      cluster.nodes[node].volatileState =
        ProtocolMachine.recoverVolatileState(
          protocol,
          cluster.nodes[node].stable
        );
      cluster.nodes[node].running = true;
      witness = new EventWitness.Restarted(node, prior);
    }

    case TimelineEvent.Partition(NodeSet a, NodeSet b) {
      assert(disjoint(a, b));
      NetworkState previous = cluster.network;
      cluster.network = NetworkModel.partition(previous, a, b);
      witness = new EventWitness.PartitionChanged(previous);
    }

    case TimelineEvent.HealPartition() {
      NetworkState previous = cluster.network;
      cluster.network = NetworkModel.heal(previous);
      witness = new EventWitness.PartitionChanged(previous);
    }

    case TimelineEvent.FireTimer(NodeId node, TimerId timer) {
      assert(cluster.nodes[node].running);
      assert(cluster.nodes[node].volatileState.timers[timer].armed);
      witness = ProtocolMachine.fireTimerWithWitness(
        protocol,
        node,
        timer,
        cluster
      );
    }

    case TimelineEvent.AdvanceTime(long ticks) {
      assert(ticks > 0);
      long previous = cluster.logicalTime;
      cluster.logicalTime += ticks;
      witness = new EventWitness.TimeAdvanced(previous);
    }
  }
}

logged rev void runTimeline(
  borrow ProtocolArtifact protocol,
  borrow Timeline timeline,
  inout ClusterState cluster,
  inout TimelineWitness witness
)
  requires witness == TimelineWitness.clean()
{
  for (long index = 0; index < timeline.length; index += 1)
    limit MAX_EVENTS
  {
    applyEvent(
      protocol,
      timeline.events[index],
      cluster,
      witness.events[index]
    );
  }
}

record SafetyResult(
  boolean moneyConservedAtEveryReplica,
  boolean effectsAppliedAtMostOnce,
  boolean balancesNonnegative,
  Option<TransferId> duplicateTransfer
) {
  boolean passed() {
    return moneyConservedAtEveryReplica
      && effectsAppliedAtMostOnce
      && balancesNonnegative;
  }
}

pure SafetyResult evaluateSafety(borrow ClusterState cluster) {
  return new SafetyResult(
    LedgerInspection.everyReplicaTotalEquals(
      cluster.nodes,
      INITIAL_TOTAL_MONEY
    ),
    LedgerInspection.everyVisibleEffectCountAtMostOne(
      cluster.nodes
    ),
    LedgerInspection.allBalancesNonnegative(cluster.nodes),
    LedgerInspection.findMultiplyAppliedTransfer(cluster.nodes)
  );
}

proposition IsCounterexample(
  ProtocolArtifact protocol,
  ClusterState initial,
  FaultBudget budget,
  Timeline timeline
) =
  canonical(timeline)
  && timeline.usedFaults <= budget
  && enabledThroughout(protocol, initial, timeline)
  && !evaluateSafety(
    execute(protocol, initial, timeline)
  ).passed();

proposition NoCounterexampleShorterThan(
  ProtocolArtifact protocol,
  ClusterState initial,
  FaultBudget budget,
  UInt<7> length
) =
  forall finite (Timeline timeline)
    where timeline.length < length
    && timeline.usedFaults <= budget
  {
    Not<IsCounterexample(protocol, initial, budget, timeline)>
  };

proposition NoCounterexampleWithinBounds(
  ProtocolArtifact protocol,
  ClusterState initial,
  FaultBudget budget
) =
  forall finite (Timeline timeline)
    where timeline.length <= MAX_EVENTS
    && timeline.usedFaults <= budget
  {
    Not<IsCounterexample(protocol, initial, budget, timeline)>
  };

/*
* Decode, execute, inspect, and reverse one schedule. The coherent oracle
* leaves only the phase mark; cluster state, event witnesses, enabledness
* trace, decoder scratch, and predicate workspace return clean.
*/
coherent rev void classifySchedule(
  borrow ProtocolArtifact protocol,
  borrow ClusterState initial,
  borrow FaultBudget budget,
  borrow ScheduleEncoding encoding,
  inout Bit violates,
  inout SearchWorkspace workspace
)
  requires violates == 0
  requires workspace.clean()
{
  Option<Timeline> timeline = Option.None();
  ScheduleDecoder.decodeCanonical(
    encoding,
    budget,
    timeline,
    workspace.decodeScratch
  );

  controlled (timeline.isSome()) {
    ClusterState cluster = initial;
    TimelineWitness witness = TimelineWitness.clean();
    EnabledTrace enabled = EnabledTrace.clean();

    SchedulerModel.recordEnabledness(
      protocol,
      timeline.value(),
      cluster,
      enabled
    );

    controlled (enabled.allEventsEnabled()) {
      runTimeline(protocol, timeline.value(), cluster, witness);
      violates ^= !evaluateSafety(cluster).passed();
      reverse runTimeline(
        protocol,
        timeline.value(),
        cluster,
        witness
      );
    }

    reverse SchedulerModel.recordEnabledness(
      protocol,
      timeline.value(),
      cluster,
      enabled
    );

    assert(cluster == initial);
    assert(witness == TimelineWitness.clean());
  }

  reverse ScheduleDecoder.decodeCanonical(
    encoding,
    budget,
    timeline,
    workspace.decodeScratch
  );

  assert(timeline == Option.None());
  assert(workspace.clean());
}

unitary void markFailingSchedule(
  borrow ProtocolArtifact protocol,
  borrow ClusterState initial,
  borrow FaultBudget budget,
  QView<SCHEDULE_BITS> candidate,
  QView<1> marker,
  QView<SEARCH_WORKSPACE_BITS> workspace
)
{
  coherent classifySchedule(
    protocol,
    initial,
    budget,
    candidate,
    marker,
    workspace
  );
  PhaseMark(marker[0]);
  reverse classifySchedule(
    protocol,
    initial,
    budget,
    candidate,
    marker,
    workspace
  );
  assert(clean(marker));
  assert(clean(workspace));
}

experiment FailureSearchEvidence searchLength(
  ProtocolArtifact protocol,
  ClusterState initial,
  FaultBudget budget,
  UInt<7> requestedLength
)
  requires target supports {
    FAULT_TOLERANT_LOGICAL_QUBITS;
    COHERENT_BYTECODE_INTERPRETER;
    AMPLITUDE_AMPLIFICATION;
    CHECKPOINTED_JOB_RECOVERY;
  }
  estimates failingSchedule
  confidence 0.999999999
  shots 16_384
{
  return QuantumSearch.sampleCanonicalSchedules(
    requestedLength,
    oracle = markFailingSchedule(
      protocol,
      initial,
      budget
    ),
    shots = 16_384
  );
}

record Counterexample(
  ProtocolArtifact protocol,
  ClusterState initial,
  FaultBudget budget,
  Timeline timeline,
  NormalizedTrace trace,
  SafetyResult finalSafety,
  Proof<IsCounterexample(
    protocol,
    initial,
    budget,
    timeline
  )> failureProof,
  Proof<NoCounterexampleShorterThan(
    protocol,
    initial,
    budget,
    timeline.length
  )> minimalityProof
) {}

variant InvestigationResult {
  case CounterexampleFound(Counterexample counterexample);
  case BoundedSafe(
    Proof<NoCounterexampleWithinBounds(
      ProtocolArtifact,
      ClusterState,
      FaultBudget
    )> proof
  );
  case Inconclusive(FailureSearchEvidence evidence, String explanation);
}

capability interface FailureSearchTarget {
  async FailureSearchEvidence run(
    Experiment<FailureSearchEvidence> experiment
  );
}

capability interface CertificateSearch {
  async Certificate propose(
    Proposition proposition,
    ProofBudget budget
  );
}

capability interface ReportOutput {
  async void publish(MurphyReport report);
}

hybrid class Murphy {
  durable state UInt<7> currentLength = 0;
  durable state InvestigationJournal journal =
    InvestigationJournal.empty();

  entry async InvestigationResult main(
    ProtocolArtifact protocol,
    ClusterState initial,
    FaultBudget budget,
    FailureSearchTarget target,
    CertificateSearch certificateSearch,
    ProofKernel kernel,
    ReportOutput output
  )
    effects {
      target.run;
      certificateSearch.propose;
      output.publish;
    }
  {
    assert(protocol.schema.nodeCount == NODE_COUNT);
    assert(evaluateSafety(initial).passed());

    FailureSearchEvidence lastEvidence =
      FailureSearchEvidence.empty();
    MinimalSchedulePrefix noShorter =
      MinimalSchedulePrefix.baseCase();

    for (UInt<7> length = 0; length <= MAX_EVENTS; length += 1)
      limit MAX_EVENTS + 1
    {
      currentLength = length;
      checkpoint("search-length-started");

      lastEvidence = record "failure-search"
        await target.run(
          searchLength(protocol, initial, budget, length)
        );

      Option<Timeline> candidate =
        CandidateSelector.firstConfirmed(
          lastEvidence.samples,
          lambda (ScheduleEncoding encoding) {
            return ClassicalReplay.decodeAndCheck(
              protocol,
              initial,
              budget,
              length,
              encoding
            );
          }
        );

      if (candidate.isSome()) {
        Timeline timeline = candidate.value();
        ReplayResult replay = ClassicalReplay.execute(
          protocol,
          initial,
          timeline,
          TraceMode.Normalized
        );
        assert(!replay.safety.passed());

        Proof<IsCounterexample(
          protocol,
          initial,
          budget,
          timeline
        )> failure = kernel.verify(
          IsCounterexample(protocol, initial, budget, timeline),
          await certificateSearch.propose(
            IsCounterexample(protocol, initial, budget, timeline),
            ProofBudget.largeButFinite()
          )
        ) else trap COUNTEREXAMPLE_PROOF_REJECTED;

        Counterexample counterexample = new Counterexample(
          protocol,
          initial,
          budget,
          timeline,
          replay.normalizedTrace,
          replay.safety,
          failure,
          noShorter.closeAt(length)
        );

        await output.publish(
          ReportBuilder.counterexample(counterexample)
        );
        commit("minimal-counterexample-published");
        return new InvestigationResult.CounterexampleFound(
          counterexample
        );
      }

      /* Sampling found nothing. Only a checked absence proof advances. */
      Proposition absentAtLength =
        NoCounterexampleAtLength(
          protocol,
          initial,
          budget,
          length
        );
      Option<Proof<typeof(absentAtLength)>> absent =
        kernel.tryVerify(
          absentAtLength,
          await certificateSearch.propose(
            absentAtLength,
            ProofBudget.largeButFinite()
          )
        );

      if (absent.isNone()) {
        return new InvestigationResult.Inconclusive(
          lastEvidence,
          "no candidate and no accepted absence certificate"
        );
      }

      noShorter = noShorter.extend(length, absent.value());
      commit("length-proven-safe");
    }

    Proof<NoCounterexampleWithinBounds(
      protocol,
      initial,
      budget
    )> safe = noShorter.closeBound(MAX_EVENTS);

    await output.publish(
      ReportBuilder.boundedSafety(protocol, initial, budget, safe)
    );
    commit("bounded-safety-proof-published");
    return new InvestigationResult.BoundedSafe(safe);
  }
}
```

## Syntax review

The sketch keeps several mechanisms separate:

- `logged rev` means the finite simulator carries explicit event witnesses. It does not claim that real crashes or packet loss run backward.
- `borrow` and `inout` express alias and mutation ownership; a protocol artifact cannot acquire host authority through interpretation.
- `record ... await` stores external evidence durably. Replay consumes that evidence; retry creates a new job identity.
- `experiment` returns samples and confidence metadata, never a theorem.
- `Proof<P>` exists only after bounded deterministic kernel checking.
- `NoCounterexampleAtLength` is required before search advances to a longer timeline. An empty quantum sample set proves nothing.
- the counterexample's minimality proof is relative to the exact event grammar, canonical encoding, protocol artifact, initial state, fault budget, and timeline-length metric.

Several semantic rules must be settled before this can become real syntax. A locally minimized trace may still be longer than another trace, so global shortestness needs an absence proof for every smaller length. A replicated ledger must say whether conservation applies to each replica or to one committed logical view. Adding every replica balance together would be wrong. Delivery and timer witnesses must keep recipient state, network cursors, and emitted envelopes. Fault counts must come from canonical events instead of trusted fields. Coherent execution also needs a finite reversible interpreter for every map, queue, handler, and safety operation it calls.

The current Wheeler profile does not support the package, import, protocol artifact, structured concurrency, generic finite type, logged transition, coherent lambda, proposition, or capability interface syntax used here.

## Example report

```text
MURPHY INVESTIGATION 8F41…A92C

Protocol:
  com.example.replicated-ledger@7.4.1

Bounds:
  nodes:                5
  events:              64
  crashes:              2
  message duplicates:  2
  partitions:           1
  timer firings:        8

RESULT: VERIFIED MINIMAL COUNTEREXAMPLE

Timeline length: 7 events

  0. DELIVER BeginTransfer(T-91, Alice, Bob, 40) -> node 0
  1. DELIVER Prepare(T-91) -> node 3
  2. PARTITION {0,1,2} FROM {3,4}
  3. DELIVER Commit(T-91) -> node 3
       credit becomes visible before durable Applied(T-91)
  4. CRASH node 3
  5. RESTART node 3
       recovery reconstructs T-91 as Prepared
  6. DUPLICATE AND DELIVER Commit(T-91) -> node 3
       Bob is credited a second time

Invariant failure at node 3:
  expected replica total: 1,000,000
  observed replica total: 1,000,040
  visible effect count for T-91: 2

Certificates:
  counterexample-8f41a92c.wcert
  no-shorter-timeline-8f41a92c.wcert

Replay package:
  counterexample-8f41a92c.wpk
```

This report gives an exact reproducer and checked evidence, not a one-time CI failure.

## What quantum search changes

Existing explicit-state and symbolic model checkers already explore bounded schedules. Murphy's Wheeler-specific goal is to combine several parts in one system:

- explicit reversible witnesses avoid copying a complete cluster at every branch;
- one finite schedule classifier can execute classically and, when eligible, coherently;
- quantum search may reduce the candidate-discovery portion for sparse failures;
- deterministic replay normalizes the proposed timeline;
- proof-producing checking certifies failure or bounded absence;
- durable workflow state survives long searches and distinguishes replay from retry;
- the package system publishes the exact reproducer and certificates.

Quantum search does not remove state-space growth, fault-tolerant overhead, oracle cleanup, certificate cost, or the need for partial-order reduction and protocol-specific lemmas. A classical checker may still be faster at every practical bound.

## Boundaries

A bounded safety proof applies only to its exact protocol artifact, compiler and semantics identities, starting state, node, message, and timer limits, event grammar, fault budget, arithmetic model, and step bound. Liveness usually needs a fairness model, so finite safety exploration cannot establish it by itself. Real clocks, weak memory, cryptography, storage corruption, Byzantine behavior, and network rules count only when the model includes them.

The same machinery could study consensus, databases, distributed file systems, cache coherence, spacecraft swarms, robot coordination, package registries, game servers, or Wheeler's own durable hybrid runtime. One useful conformance target is:

> Under every bounded ordering of completion, cancellation, retry, replay, recovery, and duplicate delivery, one quantum observation is applied at most once.

[WIP-0015](../proposals/WIP-0015-certified-adversarial-schedule-exploration.md) owns the exploration design, while [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md) owns live external operations. `Murphy.w` remains a document until the normal CI gate can compile, parse, run, replay, and verify the full application.
