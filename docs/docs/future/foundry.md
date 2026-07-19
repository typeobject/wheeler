---
title: "Foundry: a program that invents an algorithm"
sidebar_position: 1
---

# Foundry: a program that invents an algorithm

:::caution Future design, not current Wheeler

`Foundry.w` is a hypothetical fault-tolerant-era application. None of the syntax on this page is accepted by the current compiler unless it also appears in the [language reference](../reference/language-profile.md). This page is a design target, not a checked-in `.w` fixture, hardware promise, benchmark result, or release schedule.

:::

`Foundry.w` receives a finite mathematical specification, a candidate grammar, and explicit resource bounds. It searches for an implementation, checks every input in the declared finite domain, emits kernel-checkable correctness and minimality certificates, and publishes the result as an ordinary Wheeler package.

The concrete challenge is deliberately small to state and brutal to execute:

> Find the smallest reversible sorting network for eight 4-bit integers.

No corpus is supplied. `Array<BitInt<4>, 8>` defines all `2^32` inputs. The candidate grammar defines the programs. The selected comparator-count, gate, memory, proof, and time ceilings define the theorem's boundary.

The only training data is mathematics and regret.

## Required result

A conforming Foundry run would:

1. enumerate or coherently encode only canonical candidate networks;
2. check a candidate against every value of the finite input type;
3. uncompute each temporary candidate execution;
4. use quantum amplitude amplification only to propose promising candidates;
5. verify the selected candidate again with deterministic exact semantics;
6. check a formal correctness certificate in Wheeler's trusted kernel;
7. check nonexistence certificates for every smaller candidate length;
8. emit source, canonical `.wbc`, certificates, provenance, and a package manifest;
9. publish through an explicit output capability.

Quantum evidence is not proof. Sampling may choose what to check next; it cannot authorize a theorem, establish absence, or publish an artifact.

## Speculative source sketch

The notation below is intentionally ahead of the language. It assumes finite-domain generics, affine borrows, first-class propositions and proofs, bounded synthesis, proof-producing model checking, coherent candidate interpreters, durable asynchronous workflows, and proof-bearing packages.

```java
package future.foundry.sort8;

import wheeler.core.*;
import wheeler.quantum.search.*;
import wheeler.synthesis.*;
import wheeler.proof.*;
import wheeler.package.*;


type Nibble = BitInt<4>;
type SortInput = Array<Nibble, 8>;

const long MAX_COMPARATORS = 32;
const long CANDIDATE_BITS = 320;

record Comparator(Index<8> left, Index<8> right)
  invariant left < right
{}

record Network(
  UInt<6> length,
  Array<Comparator, MAX_COMPARATORS> steps
)
  invariant length <= MAX_COMPARATORS
  invariant canonicalUnusedSlots(steps, length)
{}

record SortTrace(BitVec<MAX_COMPARATORS> swapped) {
  static SortTrace clean() {
    return new SortTrace(0);
  }
}


/*
* Forward records the comparison before swapping. Reverse first uses that
* bit to restore the pair, then recomputes the original predicate and clears
* the bit. The inverse must not guess which equal-looking output was input.
*/
coherent rev void compareExchange(
  borrow Comparator comparator,
  inout SortInput values,
  inout Bit traceBit
)
  requires traceBit == 0
  ensures traceBit ==
    old(values[comparator.left] > values[comparator.right])
  resources {
    ancillas <= 12;
    t_gates <= 240;
  }
{
  boolean shouldSwap =
    values[comparator.left] > values[comparator.right];

  traceBit ^= shouldSwap;

  controlled (traceBit) {
    Swap(values[comparator.left], values[comparator.right]);
  }
}

coherent rev void executeNetwork(
  borrow Network network,
  inout SortInput values,
  inout SortTrace trace
)
  requires trace == SortTrace.clean()
{
  for (long i = 0; i < network.length; i += 1)
    limit MAX_COMPARATORS
  {
    compareExchange(
      network.steps[i],
      values,
      trace.swapped[i]
    );
  }
}

specification ReversibleSort8 {
  input SortInput original;
  output SortInput sortedValues;
  output SortTrace inverseWitness;

  ensures nondecreasing(sortedValues);
  ensures multiset(sortedValues) == multiset(original);
  ensures reverse discoveredSort8(
    sortedValues,
    inverseWitness
  ) == (original, SortTrace.clean());

  resources {
    comparator_count minimize;
    temporary_bits <= MAX_COMPARATORS;
    hidden_history == 0_bytes;
  }
}

pure boolean acceptsInput(
  borrow Network network,
  borrow SortInput input
)
{
  SortInput working = input;
  SortTrace trace = SortTrace.clean();

  executeNetwork(network, working, trace);

  boolean accepted =
    nondecreasing(working)
    && multiset(working) == multiset(input);

  reverse executeNetwork(network, working, trace);

  assert(working == input);
  assert(trace == SortTrace.clean());
  return accepted;
}

proposition CorrectNetwork(Network network) =
  forall finite (SortInput input) {
    acceptsInput(network, input)
  };

proposition SmallerCorrectNetworkExists(Network network) =
  exists finite (Network other) {
    other.length < network.length
    && CorrectNetwork(other)
  };


/* Decode one coherent candidate and uncompute all decoding workspace. */
coherent rev void decodeCandidate(
  borrow BitVec<CANDIDATE_BITS> encoding,
  inout Option<Network> network,
  inout DecodeScratch scratch
)
  requires network == Option.None()
  requires scratch.clean()
{
  CandidateCodec.decodeCanonical(encoding, network, scratch);
}

unitary void markCorrectCandidate(
  UInt<6> requestedLength,
  QView<CANDIDATE_BITS> candidate,
  QView<1> accepted,
  QView<MODEL_CHECK_SCRATCH> workspace
)
{
  Option<Network> network = Option.None();
  DecodeScratch scratch = DecodeScratch.clean();

  coherent decodeCandidate(candidate, network, scratch);

  controlled (
    network.isSome()
    && network.value().length == requestedLength
  ) {
    QuantumModelCheck.forallFinite<SortInput>(
      workspace,
      lambda coherent (SortInput input) {
        return acceptsInput(network.value(), input);
      }
    ).xorInto(accepted);
  }

  reverse decodeCandidate(candidate, network, scratch);

  assert(network == Option.None());
  assert(scratch.clean());
}

experiment CandidateEvidence searchLength(UInt<6> requestedLength)
  requires target supports {
    FAULT_TOLERANT_LOGICAL_QUBITS;
    COHERENT_CLASSICAL_INTERPRETER;
    EXACT_FINITE_MODEL_CHECKING;
    AMPLITUDE_AMPLIFICATION;
    CHECKPOINTED_JOB_RECOVERY;
  }
  estimates satisfyingCandidate
  confidence 0.999999999
  shots 8192
{
  qreg<CANDIDATE_BITS> candidate;
  qreg<1> accepted;
  qreg<MODEL_CHECK_SCRATCH> workspace;

  prepare(candidate, 0);
  prepare(accepted, 0);
  prepare(workspace, 0);
  UniformSuperposition(candidate);

  QuantumSearch.amplify(
    candidate,
    accepted,
    workspace,
    oracle = markCorrectCandidate(
      requestedLength,
      candidate,
      accepted,
      workspace
    )
  );

  Distribution<BitVec<CANDIDATE_BITS>> samples =
    sample(candidate, 8192);

  assert(clean(accepted));
  assert(clean(workspace));

  return CandidateEvidence.record(
    requestedLength,
    samples,
    semanticRegionIdentity(),
    targetDescriptorIdentity(),
    jobLineage(),
    confidenceReport()
  );
}

capability interface SynthesisTarget {
  async CandidateEvidence run(
    Experiment<CandidateEvidence> experiment
  );
}

capability interface ProofSearch {
  async Certificate propose(
    Proposition proposition,
    ProofBudget budget
  );
}

capability interface ArtifactOutput {
  async void publishPackage(PackageArchive package);
}

hybrid class AlgorithmFoundry {
  durable state UInt<6> currentLength = 0;
  durable state Array<SearchRecord, MAX_COMPARATORS + 1>
    searchHistory;

  entry async void main(
    SynthesisTarget target,
    ProofSearch proofSearch,
    ProofKernel kernel,
    ArtifactOutput output
  )
    effects {
      target.run;
      proofSearch.propose;
      output.publishPackage;
    }
  {
    Option<Network> discovered = Option.None();
    Option<CandidateEvidence> winningEvidence = Option.None();
    MinimalityPrefix noShorter = MinimalityPrefix.baseCase();

    for (UInt<6> length = 0;
      length <= MAX_COMPARATORS;
      length += 1)
      limit MAX_COMPARATORS + 1
    {
      currentLength = length;
      checkpoint("starting-candidate-length");

      CandidateEvidence evidence =
        record "candidate-search"
        await target.run(searchLength(length));

      Option<Network> proposed =
        CandidateSelector.bestCanonical(evidence.samples);

      if (proposed.isSome()
        && ClassicalModelCheck.forallFinite<SortInput>(
          lambda (SortInput input) {
            return acceptsInput(proposed.value(), input);
          }
        ).passed())
      {
        discovered = proposed;
        winningEvidence = new Option.Some(evidence);
        checkpoint("correct-candidate-found");
        break;
      }

      Proposition absentAtLength =
        forall finite (Network network)
          where network.length == length
        {
          Not<CorrectNetwork(network)>
        };

      Certificate proposal = await proofSearch.propose(
        absentAtLength,
        ProofBudget.largeButFinite()
      );

      noShorter = noShorter.extend(
        length,
        kernel.verify(absentAtLength, proposal)
          else trap PROOF_SEARCH_FAILED
      );

      commit("length-proven-impossible");
    }

    Network winner = discovered.value()
      else trap NO_NETWORK_WITHIN_BOUND;

    Proof<CorrectNetwork(winner)> correct = kernel.verify(
      CorrectNetwork(winner),
      await proofSearch.propose(
        CorrectNetwork(winner),
        ProofBudget.largeButFinite()
      )
    ) else trap WINNER_NOT_PROVABLE;

    Proof<Not<SmallerCorrectNetworkExists(winner)>> minimal =
      noShorter.closeAt(winner.length);

    SourceFile source = SourceGenerator.emitSortingNetwork(
      packageName = "generated.optimal_sort8",
      declarationName = "discoveredSort8",
      network = winner
    );

    PackageArchive package = PackageBuilder.create(
      manifest = PackageManifest.generated(
        "generated.optimal_sort8",
        "1.0.0"
      ),
      sources = [source],
      certificates = [
        kernel.encode(correct),
        kernel.encode(minimal)
      ],
      provenance = SynthesisProvenance.record(
        specification = ReversibleSort8.identity(),
        candidateGrammar = ComparatorNetworkGrammar.identity(),
        searchHistory = searchHistory,
        targetEvidence = winningEvidence.value().identity(),
        compiler = currentCompilerIdentity()
      )
    );

    await output.publishPackage(package);
    commit("generated-algorithm-published");
  }
}
```

## Syntax review

The sketch uses separate notation for separate claims:

- `rev` states a language-level inverse law; it is not debugger rewind.
- `borrow` cannot escape, while `inout` transfers exclusive mutable access.
- `old(...)` is proof-state syntax, not a hidden runtime copy.
- `forall finite` and `exists finite` quantify over canonical inhabitants of a bounded type.
- `resources` is part of the checked claim and certificate identity.
- `experiment` produces empirical evidence with target and job identity.
- `Proof<P>` is accepted only after deterministic kernel checking.
- `record ... await` creates durable evidence; `commit` advances the recovery horizon.
- capability parameters authorize effects. Imports do not grant authority.

Several details must be fixed before any of this becomes language syntax. Finite-type enumeration order needs a canonical encoding. Candidate decoding must map one semantic network to one bitstring. Reverse lowering for `compareExchange` must prove that the saved bit is cleared after restoring the original pair. Quantum oracle cleanup must cover candidate decoding, model-check workspace, phase flags, and failure paths. Proof budgets and target limits need integer units and canonical identities. Dependent values such as `network.length` cannot leak unchecked host arithmetic into types.

The generated declaration should live in Wheeler's eventual module model; the current one-class source profile does not permit top-level functions, packages, or imports.

## What gets published

The result is not a weights file. It is a normal content-addressed Wheeler package containing:

- readable generated Wheeler source;
- canonical `.wbc` built by an identified compiler;
- a correctness certificate tied to the exact function body and finite semantics profile;
- a minimality certificate tied to the exact candidate grammar and resource bound;
- search and model-check provenance;
- explicit assumptions and target evidence;
- no credential, provider object, ambient cache path, or unbounded solver transcript.

A generated function might look like this:

```java
package generated.optimal_sort8;

public rev void discoveredSort8(
  inout Array<BitInt<4>, 8> values,
  inout SortTrace trace
)
  requires trace == SortTrace.clean()
  ensures nondecreasing(values)
  ensures inverse(discoveredSort8) restores old(values, trace)
  certified by {
    "correctness.wcert";
    "minimality.wcert";
  }
{
  compareExchange(new Comparator(0, 1), values, trace.swapped[0]);
  compareExchange(new Comparator(2, 3), values, trace.swapped[1]);
  compareExchange(new Comparator(4, 5), values, trace.swapped[2]);

  // The remaining certified network has not been discovered here.
}
```

## Scale and limits

The bounded claim avoids undecidability; it does not make the search cheap. The input domain alone has `2^32` arrays. There are 28 ordered index pairs for each comparator slot before scheduling symmetries. Candidate count grows exponentially with network length. Amplitude amplification can reduce an unstructured candidate-search factor quadratically; it does not remove exact model checking, certificate construction, fault-tolerant overhead, or minimality proof cost.

A credible execution therefore needs advances in fault-tolerant logical qubits, reversible finite-domain interpreters, proof-producing SAT/SMT or specialized sorting-network reasoning, large bounded proof search, durable multi-week jobs, and independent certificate checking. Better mathematics may matter more than better hardware.

Minimality is relative to `ComparatorNetworkGrammar`, its canonical encoding, `MAX_COMPARATORS`, the arithmetic profile, and the stated resource metric. Foundry does not prove that no shorter algorithm exists in every computational model, including one invented by a sufficiently argumentative alien.

## Generalization

Changing the bounded specification could target a reversible compression transform, arithmetic oracle, quantum error-correction decoder, semantics-preserving compiler rewrite, finite cryptographic permutation, bounded distributed protocol, state-preparation circuit, or strategy for a finite game. Every case must retain the same separation between search, execution, empirical evidence, exact checking, proof, and publication.

The governing design work is [WIP-0014](../proposals/WIP-0014-bounded-certified-program-synthesis.md). The application remains documentation until every dependency is implemented as an executable vertical slice.
