# WIP-0083: Zero-allocation unobserved transitions

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler VM and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Virtual machine, native closure execution, evidence deadlines |
| Depends on | WIP-0044 |
| Supersedes | Observation allocation for `TransitionObserver.NONE` |
| Superseded by | None |

## Summary

Skip transition observation construction when a virtual machine uses the canonical `TransitionObserver.NONE` singleton. Execution, validation, scheduler state, sequence numbers, rewind records, commits, effects, and traps remain unchanged.

The physical native compiler closure executes 72,194,806 transitions without an observer. Removing two temporary records per transition restores deadline margin while preserving the complete evidence transaction.

## Problem

`VirtualMachine.step(false)` correctly avoided `StepRecord` construction, but every successful transition still called:

```java
observer.observe(TransitionObserver.execution(...));
```

`TransitionObserver.execution` allocated one `Observation` and one `EventId`. The canonical no-op observer discarded both immediately. The closure therefore allocated more than 144 million immutable records to observe nothing.

The cost was not semantic. It pushed the complete physical product method from 18 minutes and 36 seconds to 19 minutes and 41 seconds as direct adoption grew. The method retained only 19 seconds under its fixed twenty-minute deadline.

## Rule

`VirtualMachine` compares the configured observer with `TransitionObserver.NONE` before constructing an execution or rewind observation. A caller that supplies any other observer receives the exact same immutable event stream as before, even if that observer chooses to discard events.

The singleton identity check matters. The VM does not infer behavior from an observer class, lambda body, result, or side effect. It recognizes only the public canonical no-op value.

## Semantics

The fast path changes no machine state. The VM still:

1. selects the canonical runnable task
2. fetches and validates the instruction
3. executes the transition
4. increments the global sequence
5. maintains or clears rewind history
6. updates task status
7. emits an observation when a real observer exists

Rewind uses the same guard after restoring exact state. A real observer still receives `REWIND_FORWARD` or `REWIND_INVERSE` with the retained event identity.

The fast path does not skip bytecode verification, dynamic preflight, proof observation, coverage observation, scheduler work, ownership checks, or effect-boundary checks.

## Evidence

Every core VM test passes, including task identity, execution observation, rewind observation, history, ownership, aggregate, call, commit, trap, and effect-boundary tests.

The focused `NamedComparisonKinds.w` product run fell from 7 minutes and 19 seconds to 6 minutes and 35 seconds on the same local builder. That comparison includes no source or artifact change between runs.

The complete physical closure then passed in 18 minutes and 47 seconds after adding the larger 4,040-byte comparison classifier product. It kept the fixed twenty-minute JUnit deadline and the fixed twenty-five-minute Gradle task deadline.

## Acceptance

- [x] `TransitionObserver.NONE` constructs no execution observation.
- [x] `TransitionObserver.NONE` constructs no rewind observation.
- [x] Every noncanonical observer receives the existing event stream.
- [x] Transition sequence, scheduling, validation, mutation, history, and traps remain unchanged.
- [x] Core VM tests pass.
- [x] Focused native product evidence preserves exact artifact bytes.
- [x] The complete native physical closure passes under its unchanged deadline.
- [x] Source, documentation, line, and style policy pass.

## Rejected alternatives

### Raise the closure deadline

Rejected. The allocations represented avoidable work, not additional evidence.

### Suppress all observation during `stepWithoutRewindHistory`

Rejected. Coverage and proof tools may observe a forward run without retaining rewind history.

### Detect no-op observer implementations

Rejected. Function behavior is not a stable identity or capability.

### Batch observations

Rejected. Observers consume one immutable, sequence-addressed transition at a time. Batching would change the API and failure boundary.

## References

- [WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md)
