# WIP-0381: x86-64 Linux bounded scalar loops

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and runtime maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, AOT lowering, x86-64 control flow, bounded loops |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0380 |
| Supersedes | Forward-only scalar AOT control flow as the complete branch profile |
| Superseded by | None |

## Summary

The x86-64 Linux scalar AOT leaf lowers canonical bounded loops. A backward branch is admitted only when its cycle crosses a `LOCAL_LOOP_CHECK` with one stable zero-initialized counter and one stable literal limit from 1 through 255.

This WIP also admits scalar local reassignment. Wheeler signed and Boolean locals are ordinary scalar registers, not affine owners. Constants, moves, arithmetic, comparisons, calls, and loop bodies may overwrite an initialized destination exactly as canonical WBC directs.

## Loop profile

Each admitted loop check names two distinct signed locals:

- A counter initialized exactly once to zero before the check.
- A limit initialized exactly once to a literal from 1 through 255 before the check.

No other instruction may write the limit. Only the initializer and `LOCAL_LOOP_CHECK` may write the counter. Every backward edge must cross at least one validated loop check. Self-branches and out-of-range targets reject.

The evaluator executes at most 65,536 instructions across one entry or helper invocation. This whole-invocation bound rejects reset cycles and excessive nested products even when individual loop checks are superficially valid. An admitted artifact must terminate without exhausting a declared loop limit.

The physical source boundary covers:

```wheeler
module example.hello;

classical class Hello {
  state long status = 0;

  entry void main() {
    long value = 70;
    while (value < 73) limit 3 {
      value += 1;
    }
    status = value;
  }
}
```

## Machine lowering

A backward WBC edge becomes one checked relative x86-64 branch. `LOCAL_LOOP_CHECK` loads the counter and limit from the active stack frame, rejects negative values and `counter >= limit`, increments the counter with overflow detection, and stores it back before the body continues. Failure reaches the function's existing trap epilogue and process status 126.

WIP-0382 names status 126 as the common execution trap and adds state reads and assertions. WIP-0387 adds one instruction budget across loops and the complete helper call tree. The native body does not trust the build-time result in place of loop checks. Build-time evaluation and generated machine control flow are separate evidence over the same WBC. No host timer, signal, thread, stack limit, or watchdog defines loop semantics.

## Failure boundary

Reject an absent loop check, unstable counter, nonzero counter initializer, unstable or nonliteral limit, limit zero, limit 256, self-edge, out-of-range edge, exhausted loop, arithmetic failure, or 65,537st evaluated instruction. Reject the complete artifact without unrolling, branch deletion, clamping, or interpreter fallback.

The 255-iteration limit is a profile bound, not a WBC format limit. A later backend may widen it only with exact terminal and next-value evidence.

## Evidence

`LinuxX8664ScalarAotCompilerTest` executes the canonical status-73 loop with limits 3 and 255. It requires distinct runtime identities, limit-two exhaustion, limit-256 rejection, and rejection of a backward cycle without `LOCAL_LOOP_CHECK`. Existing helper, six-argument, Boolean-argument, arithmetic, comparison, branch, capsule, and ELF evidence remains intact.

`ImageCommandTest` compiles one physical module whose two-argument helper initializes a mutable local and whose three-iteration loop computes status 73. The command lowers exact WBC, constructs and verifies the complete AOT ELF, and launches it on x86-64 Linux.

An independent Alpine 3.22 kernel under x86-64 emulation launched the 5,432-byte limit-255 fixture. The generated backward branch executed exactly 255 times, returned status 73, and wrote exact `Wheeler\n`.

The terminal-bound fixture identities are:

| Product | Identity |
| --- | --- |
| WBC | `cf956b8d807cd87a9594c4f5457c6454440f7d1742aa83c7937933842df536d7` |
| runtime | `8ee9a86b9fe2210e866e5dc282b6296f7733132ead5af926b1bbe9b359c0f6e1` |
| capsule | `b182dad66136ffc0dfaf811f18dc477f2ef57f1d5af5e2a506afc36ebabade9f` |
| native plan | `2506ad222dda46d1bdf85538df3d551c32b869449abdfe412581004373e32f11` |
| unsigned PREV | `62b8808943e3a02227212ae29206f1d0936db536caf4af704bac57ab2c8776ab` |

## Acceptance

- [x] Every backward edge crosses a validated loop check.
- [x] Counter zero and limits 1 through 255 are stable literal facts.
- [x] Scalar destination reassignment matches canonical VM semantics.
- [x] Native counter range, exhaustion, and increment checks trap through status 126.
- [x] Independent evaluation rejects exhaustion and excessive nested execution.
- [x] Limit 255 succeeds and limit 256 rejects.
- [x] Physical source and independent Linux loader evidence observe status 73.
- [x] No host watchdog or unbounded-loop claim is made.

## Rejected alternatives

### Unroll loops during lowering

Rejected. Unrolling changes machine size with the chosen path and avoids the required native backward-edge semantics.

### Trust only the build-time evaluation

Rejected. The generated image must retain the loop limit check rather than publish an unchecked cycle.

### Use a global native step counter alone

Rejected. Wheeler loop limits are local semantic state. The whole-invocation evaluator bound is a secondary admission limit, not a replacement.

### Treat scalar reassignment as an affine move

Rejected. Only owned and borrowed values transfer. Clearing a signed source changes canonical WBC behavior.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0380](WIP-0380-x86-64-linux-scalar-call-arguments.md)
- [WIP-0382](WIP-0382-x86-64-linux-scalar-state-checks.md)
- [WIP-0387](WIP-0387-x86-64-linux-scalar-execution-bound.md)
