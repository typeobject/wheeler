# Semantic coverage

Wheeler's first semantic-coverage system watches successful VM transitions. It does not add counter instructions to `.wbc`, because those writes would change the program being measured.

## Transition observations

A `VirtualMachine` may receive a `TransitionObserver`. After each successful instruction, the VM emits an immutable observation with:

- a monotonic transition number;
- `forward` or language-`inverse` direction;
- function and instruction indexes;
- the canonical opcode;
- `taken` or `fallthrough` for `JUMP_IF_ZERO`, and `none` for other instructions.

Rewinding saved history emits a separate `rewind_forward` or `rewind_inverse` observation for the transition being undone. These observations do not erase the attempted execution. Failed validation and trapped instructions emit nothing because the machine made no transition.

The observer cannot access mutable machine state. It also cannot change bytecode, instruction limits, history records, effects, or snapshots.

The conformance suite runs the same proof-bearing reversible fixture with collection on and off; it compares both the terminal snapshots and the fully rewound snapshots, which must match.

## Stage-0 report

`SemanticCoverage` groups observations into points keyed by direction, function, instruction, and opcode. Counts use checked arithmetic.

The canonical JSON profile is `wheeler-transition-coverage-1`. Points are sorted without depending on map insertion order, and the report identity is a domain-separated SHA-256 hash of those bytes.

Fresh classical cases chosen by `wheeler test` collect this report. The test output prints its identity beside each case and includes it in the canonical package test report. Quantum cases do not include a classical transition identity.

The report has no percentage. This first slice knows which transitions ran, but it does not yet define a complete source or IR denominator.

Source points, compound conditions, match arms, traps, attempt lineage, sharded merging, quantum structure, proof duties, thresholds, adapters, and Wheeler-written reduction remain part of [WIP-0020](../proposals/WIP-0020-semantic-coverage-and-evidence-accounting.md). JaCoCo still measures only the Java seed implementation. It is not evidence about Wheeler semantics.
