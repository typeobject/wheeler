---
title: Evidence and Coverage
description: Transition observations, source relations, path reports, proof stages, and the limits of each account.
---

# Evidence and Coverage

A machine account should show what it observed without placing unobserved roads
under the same seal. Wheeler's first semantic coverage system watches successful
VM transitions and leaves the measured artifact unchanged.

## Transition observations

A `TransitionObserver` receives an immutable event after each successful
instruction. The event carries transition number, forward or language-inverse
direction, function and instruction index, canonical opcode, and branch result.

Rewind emits separate `rewind_forward` or `rewind_inverse` observations for the
transition being restored. Failed validation and trapped instructions produce no
transition event because the machine did not change state.

The observer has no mutable machine access and cannot alter artifact bytes,
limits, history, effects, or snapshots.

## Canonical transition report

`SemanticCoverage` groups observations by direction, function, instruction, and
opcode. Counts use checked arithmetic. Canonical profile
`wheeler-transition-coverage-1` sorts rows independently of map insertion order
and receives a domain-separated SHA-256 identity.

Fresh classical cases selected by `wheeler test` carry this identity in their
package report. Quantum cases omit the classical transition field.

The report publishes no percentage. It knows which transitions occurred and has
no complete source or IR denominator.

## Wheeler reduction

`wheeler.runtime.coverage_reducer` accepts at most 64 canonical point fragments,
validates every range, sorts rows, combines duplicate keys with checked counts,
and returns a length only after constructing the complete report.

The native bootstrap collector admits a linear trace made from `LOCAL_CONST`,
`EXPECT_TRUE`, and `HALT`. Any other opcode fails before publication. Calls,
branches, inverses, rewind, and multiple functions await richer native interpreter
events.

## Presentation forms

`SemanticCoverageRenderer` emits terminal, JSON, LCOV, Cobertura XML, and static
site forms from one immutable point table. Every form carries the semantic report
identity and declares the same unsupported dimensions: source lines, source
branches, proof obligations, quantum state, and empirical targets.

LCOV and Cobertura use explicit synthetic coordinates such as
`wheeler-bytecode/function-N`. They never call an instruction row a source line.
Presentation bytes do not alter the semantic identity.

## Policies and thresholds

`SemanticCoveragePolicy` binds sorted direction and opcode exclusions, a minimum
observed-point count, and a minimum hit count for each selected point. Evaluation
produces its own canonical identity while preserving the underlying report.

A changed exclusion or threshold changes policy and evaluation identity. The
policy cannot invent a percentage denominator or promote excluded source, proof,
quantum, or physical dimensions into coverage evidence.

## Relations to source

`SemanticCoverageMap` binds one canonical artifact to normalized source ranges and
contiguous runtime windows. Each relation names forward, inverse, or rewind
direction, authored or generated origin, and a digest of the exact opcode window.

Construction rejects dangling coordinates, overlap, duplicate windows,
generated-inverse labels over forward work, malformed source ranges, and forged
opcode digests.

Joining a transition report yields profile
`wheeler-source-transition-coverage-1`, which keeps source path, line, column,
bytecode coordinates, direction, origin, branch result, and hit count. Artifact,
map, transition, and source-report identities remain separate.

## Adjacent paths

Profile `wheeler-transition-path-coverage-1` reduces consecutive successful
transitions into edges. An edge retains workflow epoch, task identity, direction,
both bytecode endpoints, originating branch result, and count.

Forward and inverse edges require increasing task-local sequence. Rewind edges
require decreasing sequence. A run, task, epoch, or direction boundary cannot
inherit the previous tail.

Observed adjacent edges establish no complete path denominator, MC/DC result,
loop-path exhaustion, or feasibility statement about an absent edge.

## Proof stages

`ProofObserver` distinguishes lookup, obligation construction, rule execution,
acceptance, and rejection. `ProofCoverage` keys rows by rule, subject, and stage
under `wheeler-proof-coverage-1`.

A rejected certificate records execution and rejection without acceptance. An
accepted certificate records acceptance without rejection. Proof-stage coverage
never changes a kernel decision or inhabits a theorem.

Proof coverage, transition coverage, certificate identity, and proof validity
remain different evidence.

## The present horizon

Compound-condition denominators, match-arm denominators, trapped attempts, attempt
lineage, quantum structure, and general Wheeler-native observation collection are
outside the current profiles. Host-language coverage measures the seed machinery
only and says nothing about Wheeler semantic coverage.

The [proof certificate section](bytecode.md#proof-certificates) gives the finite
kernel rules. The [program ledger](../examples.md) names the maintained executable
cases.
