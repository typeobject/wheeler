# Semantic coverage

Wheeler's first semantic-coverage system watches successful VM transitions. It does not add counter instructions to `.wbc`, because those writes would change the program being measured.

## Transition observations

A `VirtualMachine` may receive a `TransitionObserver`. After each successful instruction, the VM emits an immutable observation with:

- a monotonic transition number.
- `forward` or language-`inverse` direction.
- function and instruction indexes.
- the canonical opcode.
- `taken` or `fallthrough` for `JUMP_IF_ZERO`, and `none` for other instructions.

Rewinding saved history emits a separate `rewind_forward` or `rewind_inverse` observation for the transition being undone. These observations do not erase the attempted execution. Failed validation and trapped instructions emit nothing because the machine made no transition.

The observer cannot access mutable machine state. It also cannot change bytecode, instruction limits, history records, effects, or snapshots.

The conformance suite runs the same proof-bearing reversible fixture with collection on and off. It compares both the terminal snapshots and the fully rewound snapshots, which must match.

## Stage-0 report

`SemanticCoverage` groups observations into points keyed by direction, function, instruction, and opcode. Counts use checked arithmetic.

The canonical JSON profile is `wheeler-transition-coverage-1`. Points are sorted without depending on map insertion order, and the report identity is a domain-separated SHA-256 hash of those bytes.

Fresh classical cases chosen by `wheeler test` collect this report. The test output prints its identity beside each case and includes it in the canonical package test report. Quantum cases do not include a classical transition identity.

The report has no percentage. This first slice knows which transitions ran, but it does not yet define a complete source or IR denominator.

## Wheeler reduction

`wheeler.runtime.coverage_reducer` consumes at most 64 bounded canonical point fragments. Each input row separates its sort key from the rendered prefix and suffix. The library reducer validates every extent, insertion-sorts rows without a host collection, combines duplicate keys with exact counts, renders decimal counts, and returns the length only after the complete profile-1 report exists. `wheeler.conformance.runtime.native_coverage_reducer` is the executable boundary that publishes that exact returned extent. The runtime package therefore carries no hidden entry method.

The differential fixture collects two forward-and-rewind executions, reverses arrival order, and compares every Wheeler-produced report byte with `SemanticCoverage.canonicalReport()`. This proves reducer parity for the accepted row format. It does not prove source-native collection: the Java seed still turns VM observations into bounded input fragments.

## Presentation adapters

`SemanticCoverageRenderer` emits terminal, JSON, LCOV, Cobertura XML, and static website views from the immutable point table. Every view carries the semantic report identity and discloses the same unsupported dimensions: source lines, source branches, proof obligations, quantum state, and empirical targets.

LCOV and Cobertura receive explicit synthetic `wheeler-bytecode/function-N` coordinates. They never label instruction rows as source lines. The website prints the unsupported list in visible text and metadata. Adapter generation leaves canonical report bytes and identity unchanged.

## Exclusions and thresholds

`SemanticCoveragePolicy` gives direction and opcode exclusions an explicit sorted identity. It also binds bounded minimum observed-point and minimum per-point hit requirements. Evaluation emits the policy, base coverage, included and excluded counts, thresholds, selected points, and pass result in canonical JSON with its own identity.

Changing one exclusion or threshold changes both policy and evaluation identities. Caller set order does not. Evaluation never edits the underlying transition report. This profile has no hidden percentage denominator and cannot promote an excluded source, proof, quantum, or empirical dimension into coverage evidence.

## Source and generated-body relations

`SemanticCoverageMap` validates source-to-runtime relations against one exact canonical artifact. Each row binds a normalized source range, forward, inverse, or rewind direction, function, contiguous instruction window, authored or generated-inverse origin, and a digest of the exact opcode window.

Map construction rejects dangling or unknown coordinates, duplicate and overlapping bytecode windows, generated-inverse claims over forward code, malformed source ranges, and forged opcode digests. Joining one transition report rejects missing relations and observed opcode or branch shapes that disagree with the artifact. The resulting `wheeler-source-transition-coverage-1` report names source path, line, column, bytecode coordinates, direction, origin, branch result, and hit count. Map, artifact, transition, and adjacent-path identities remain separate.

`SemanticCoverage` also reduces consecutive successful transitions into `wheeler-transition-path-coverage-1`. An edge retains workflow epoch, hierarchical task identity, direction, both bytecode endpoints, the originating branch result, and a checked count. Forward and inverse edges require increasing task-local sequence. Rewind edges require decreasing sequence. A new run, task, workflow epoch, or direction cannot inherit the prior tail. The source join resolves both endpoints before publishing an edge.

Adjacent-edge coverage reports observed path outcomes without inventing a complete path denominator. It does not claim MC/DC, loop-path exhaustion, or feasibility of an unobserved path.

## Proof stages

`ProofObserver` records lookup, obligation construction, rule execution, acceptance, and rejection as distinct ordered stages. `ProofCoverage` keys points by proof rule, subject, and stage under `wheeler-proof-coverage-1`. A rejected certificate records rule execution and rejection, never acceptance. An accepted certificate records acceptance, never rejection.

Proof-stage observation does not change kernel decisions or inhabit a theorem. Its report and identity remain separate from VM transition coverage, certificate identity, and proof validity.

Compound conditions, match-arm denominators, trapped attempts, attempt lineage, quantum structure, and Wheeler-native observation collection remain part of WIP-0020. JaCoCo still measures only the Java seed implementation. It is not evidence about Wheeler semantics.
