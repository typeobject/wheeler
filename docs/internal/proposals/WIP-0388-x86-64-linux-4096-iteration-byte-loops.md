# WIP-0388: x86-64 Linux 4,096-iteration byte loops

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and native runtime maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, AOT lowering, bounded loops, byte I/O |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0381, WIP-0385, WIP-0387 |
| Supersedes | The 255-iteration scalar AOT loop profile |
| Superseded by | WIP-0389 for strict UTF-8 input traversal |

## Summary

Scalar AOT admits stable literal loop limits from 1 through 4,096. The terminal limit matches the native input and output arena capacity, so one bounded helper can inspect or copy every admitted application byte.

The loop form, ownership rules, and checked `LOCAL_LOOP_CHECK` instruction remain unchanged. This WIP widens one exhausted backend profile. It does not admit data-dependent limits, unchecked backward branches, general cyclic control flow, or a larger byte transport.

## Loop contract

A loop retains:

- One signed counter initialized exactly once to zero.
- One signed limit initialized exactly once to a canonical literal from 1 through 4,096.
- One `LOCAL_LOOP_CHECK counter, limit` crossed by every admitted backward edge.
- A runtime comparison that rejects a negative counter, negative limit, limit above 4,096, or counter at or above the limit before increment.
- One checked increment that traps signed overflow.

The profile validator requires limit ownership before machine generation. The generated machine check independently enforces the same 4,096 terminal value. Literal 4,097 rejects during lowering and cannot rely on execution fuel to repair an invalid loop.

WIP-0387 remains an independent aggregate bound. Every selected loop instruction consumes the shared 65,536-instruction budget. A syntactically valid 4,096-iteration loop can still trap if its selected body and call tree exhaust that budget.

## Byte-copy boundary

A physical source helper may now cover one complete native byte transport:

```wheeler
void copy(
  borrow byteview input,
  borrow mut bytes output
) {
  long length = bufferLength(input);
  long index = 0;
  while (index < length) limit 4096 {
    setByte(output, index, input[index]);
    index += 1;
  }
}
```

The entry reads the input length, commits the same output length, and passes canonical reborrows to `copy`. Input and output indexing retain their separate active bounds. The loop limit authorizes iterations. It does not authorize byte access by itself.

Schema-1 dynamic output still requires a positive committed length. Empty-input application policy remains separate from the loop profile.

## Failure boundary

Reject limit zero, limit 4,097, a nonliteral limit, multiple counter initializers, multiple limit initializers, a nonzero initial counter, a counter write outside `LOCAL_LOOP_CHECK`, a limit write after initialization, a backward edge without the check, and all prior byte-handle or execution-fuel failures.

A 4,097-byte stdin transport still rejects during complete input admission before Wheeler execution. The loop and transport bounds agree without sharing authority.

## Evidence

`LinuxX8664ScalarAotCompilerTest.lowersBoundedScalarLoops` executes the status loop at limits 3 and 4,096. The terminal fixture requires 4,096 selected increments to reach status 73. The test also rejects limit exhaustion at two iterations, literal 4,097, and an unchecked backward branch.

`ImageCommandTest.lowersBuildsAndLaunchesOnePhysicalScalarAotImage` compiles a source-level 4,096-limit copy helper. The physical command lowers retained `BUFFER_BORROW`, input length, indexed input, indexed output, loop check, backward branch, output commitment, status state, scalar helpers, assertions, and a separate scalar loop before complete capsule and ELF verification.

An independent Alpine 3.22 x86-64 guest launched a 6,088-byte physical echo image with exactly 4,096 input bytes containing sixteen repetitions of byte values 0 through 255. It returned status 73, produced exactly 4,096 bytes, and `cmp` found no difference.

| Product | Identity |
| --- | --- |
| WBC | `731cbedb516dd82dd9bf920a9dccdc65dd6d516cbf261596a74db05df62ec0d3` |
| runtime | `82daeb7eb67f6ba500025e7a0200010297c4dc3127676293e81c21bc0614ce67` |
| capsule | `4cfc2936e8437c95306fef2e374143e91d838fe0d12f88f31ffb2d46f0c55a83` |
| native plan | `77a628e96c00436d9fc3df74791505ffa139dffa17e892768421355132e93dfc` |
| unsigned PREV | `af62f2fb0aca9ede31909fb1878213caa349fc02218b895bf6471f40cee730b2` |

## Acceptance

- [x] Literal loop limits 1 through 4,096 validate.
- [x] Literal loop limit 4,097 rejects before machine generation.
- [x] Generated loop checks independently reject limits above 4,096.
- [x] The complete loop still consumes shared execution fuel.
- [x] Physical source copies every byte of a terminal-size transport.
- [x] Independent Linux evidence proves exact terminal output.

## Rejected alternatives

### Derive the loop limit from input length

Rejected for this profile. A stable literal retains a static upper bound while the loop condition selects the shorter runtime path.

### Remove the per-loop limit after adding execution fuel

Rejected. Fuel bounds aggregate work. The loop check binds counter ownership and one cycle's local invariant.

### Keep the 255 limit and split input in host code

Rejected. Host chunking would become application semantics and borrowed output identity would cross executions.

### Increase byte arenas with the loop limit

Rejected. Loop and transport capacities remain separate authorities and must exhaust independently.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0381](WIP-0381-x86-64-linux-bounded-scalar-loops.md)
- [WIP-0385](WIP-0385-x86-64-linux-dynamic-byte-io.md)
- [WIP-0387](WIP-0387-x86-64-linux-scalar-execution-bound.md)
- [WIP-0389](WIP-0389-x86-64-linux-strict-utf8-input.md)
