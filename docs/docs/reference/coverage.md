# Semantic coverage

Wheeler's first semantic-coverage slice observes successful VM transitions without inserting counter instructions into `.wbc`. Instrumenting a reversible machine with surprise writes would be an unusually energetic way to measure the wrong program.

## Transition observations

A `VirtualMachine` may receive a `TransitionObserver`. After each successful instruction it emits an immutable observation containing:

- the monotonic transition sequence;
- `forward` or language-`inverse` direction;
- function and instruction indexes;
- the canonical opcode;
- `taken` or `fallthrough` for `JUMP_IF_ZERO`, and `none` for nondecisions.

Rewinding retained history emits a separate `rewind_forward` or `rewind_inverse` observation for the transition being undone. Rewind observations do not erase attempted execution. Failed validation and trapped instructions emit nothing because no machine transition occurred.

The observer receives no mutable machine state and cannot change bytecode, instruction bounds, history records, effects, or snapshots. The conformance suite runs the same proof-bearing reversible fixture with collection enabled and disabled, compares terminal and fully rewound snapshots, and requires equality.

## Stage-0 report

`SemanticCoverage` reduces observations into points keyed by direction, function, instruction, and opcode. Counts use checked arithmetic. Its canonical JSON profile is `wheeler-transition-coverage-1`; points are sorted independently of observation-map insertion order, and the report identity is domain-separated SHA-256 over those bytes.

Fresh classical cases selected by `wheeler test` collect this report, print its identity beside the case, and bind the identity into the canonical package test report. Quantum cases omit the classical transition identity. The report deliberately contains no percentage. This slice knows which transitions ran, but it does not yet own a complete source/IR denominator. Dividing a trustworthy numerator by a number found behind the sofa remains unsupported.

Source points, compound conditions, match arms, traps, test-attempt lineage, sharded merge, quantum structure, proof obligations, thresholds, adapters, and Wheeler-written reduction remain [WIP-0020](../proposals/WIP-0020-semantic-coverage-and-evidence-accounting.md) work. JaCoCo continues to measure Java seed implementation code only; it is not Wheeler semantic evidence.
