---
title: "Murphy: the debugger that searches failing timelines"
sidebar_position: 2
---

# Murphy: the debugger that searches failing timelines

:::caution Future design, not current Wheeler

`Murphy.w` is a hypothetical fault-tolerant-era application. Its syntax is not accepted by the current compiler unless the same construct appears in the [language reference](../reference/language-profile.md). This is a bounded model-checking and proof-system target, not a claim that quantum hardware currently improves distributed debugging.

:::

`Murphy.w` receives a canonical distributed protocol artifact, finite initial state, safety invariants, and an explicit fault bound. It searches all admitted schedules of delivery, duplication, loss, crash, restart, partition, healing, timeout, and logical-time advance. It returns one of three honest results:

- a deterministically replayable, kernel-certified counterexample;
- a kernel-checked proof that no counterexample exists within the exact bound;
- `inconclusive`.

No production log, traffic archive, packet corpus, or learned model is an input. The schedule space is generated from the program and fault grammar.

The dataset is every bad thing that can happen, generated fresh by mathematics.

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

A successful counterexample might show that node 3 credits a transfer, crashes before its durable idempotency marker, reconstructs the transfer as prepared, and applies a duplicated commit after restart.

Search evidence alone cannot establish either result. A proposed schedule is decoded and replayed classically. “No useful sample was observed” is not a proof of safety. A universal bounded-safety claim requires a separate canonical certificate checked by Wheeler's trusted kernel.

## Speculative source sketch

The notation below assumes finite-domain types, bounded maps and queues, first-class protocol artifacts, explicit logged reversibility, coherent finite interpreters, proof-producing model checking, [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md) structured asynchronous effects, and proof-bearing replay packages. Its model scheduler is not a second host-I/O API.

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

The sketch intentionally distinguishes mechanisms that are often conflated:

- `logged rev` means the finite simulator carries explicit event witnesses. It does not claim that real crashes or packet loss run backward.
- `borrow` and `inout` express alias and mutation ownership; a protocol artifact cannot acquire host authority through interpretation.
- `record ... await` stores external evidence durably. Replay consumes that evidence; retry creates a new job identity.
- `experiment` returns samples and confidence metadata, never a theorem.
- `Proof<P>` exists only after bounded deterministic kernel checking.
- `NoCounterexampleAtLength` is required before search advances to a longer timeline. An empty quantum sample set proves nothing.
- the counterexample's minimality proof is relative to the exact event grammar, canonical encoding, protocol artifact, initial state, fault budget, and timeline-length metric.

The original moonshot needs several semantic corrections before it could become syntax. A locally minimized trace is not necessarily the globally shortest trace; shortestness requires checked absence at every smaller length. A replicated ledger must state whether money conservation applies independently to each replica or to one logical committed view; summing all replica copies is wrong. Delivery and timer witnesses must retain network cursors and emitted envelopes, not only recipient state. Fault counters must be derived from canonical events rather than trusted fields. Coherent classification requires a finite reversible interpreter for every map, queue, handler, and safety operation it invokes.

The current Wheeler profile has none of the package/import, protocol-artifact, structured-concurrency, generic finite-type, logged-transition, coherent-lambda, proposition, or capability-interface syntax shown here.

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

That is stronger than “CI failed once on a Tuesday; could not reproduce.”

## What quantum search changes

Conventional explicit-state and symbolic model checkers already explore bounded schedules. Murphy is not justified by renaming model checking. Its Wheeler-specific target is composition:

- explicit reversible witnesses avoid copying a complete cluster at every branch;
- one finite schedule classifier can execute classically and, when eligible, coherently;
- quantum search may reduce the candidate-discovery portion for sparse failures;
- deterministic replay normalizes the proposed timeline;
- proof-producing checking certifies failure or bounded absence;
- durable workflow state survives long searches and distinguishes replay from retry;
- the package system publishes the exact reproducer and certificates.

Quantum search does not remove state-space explosion, fault-tolerant overhead, oracle cleanup, certificate cost, or the need for better partial-order reduction and protocol-specific lemmas. A classical checker may remain faster for every practical bound.

## Boundaries

A bounded safety proof says nothing beyond its protocol artifact, compiler and semantics identities, initial state, node/message/timer limits, event grammar, fault budget, arithmetic model, and step bound. Liveness generally needs a fairness model and is not inferred from finite safety exploration. Real clocks, weak memory, cryptography, storage corruption, Byzantine behavior, and network semantics enter only when explicitly modeled.

The same machinery could investigate consensus, databases, distributed filesystems, cache coherence, spacecraft swarms, robot coordination, package registries, game servers, or Wheeler's own durable hybrid runtime. A particularly useful conformance target is:

> Under every bounded ordering of completion, cancellation, retry, replay, recovery, and duplicate delivery, one quantum observation is applied at most once.

The governing design work is [WIP-0015](../proposals/WIP-0015-certified-adversarial-schedule-exploration.md), with live external operations owned by [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md). `Murphy.w` remains documentation until every dependency is implemented and the ordinary CI gate can compile, parse, execute, replay, and verify it.
