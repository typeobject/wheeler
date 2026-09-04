# WIP-0382: x86-64 Linux scalar state checks

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and runtime maintainers |
| Created | 2026-08-25 |
| Updated | 2026-09-04 |
| Area | Native bootstrap, AOT lowering, scalar state, assertions, execution traps |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0381 |
| Supersedes | Write-only status state and arithmetic-only trap naming |
| Superseded by | None |
| Follow-up | WIP-0390 for shared helper-visible scalar globals |

## Summary

The x86-64 Linux scalar AOT leaf reads its bounded status state, enforces canonical Boolean assertions, lowers 32-bit rotate-right, and accepts semantic no-ops. Process status 126 is the common execution trap for arithmetic overflow, invalid loop state, propagated helper failure, assertion failure, and final status range failure.

WIP-0383 uses this assertion boundary in parameterized void helpers. This WIP does not add general globals, history, rollback, reversible effects, external input, or assertion diagnostics. The sole state cell remains signed `status`, initialized to zero and owned by entry.

## Accepted instructions

Entry may execute `LOCAL_LOAD_GLOBAL destination, 0`. The destination must be signed. It receives the most recently stored status value, or zero before the first store. Helpers may neither read nor write global state.

Any admitted function may execute:

- `EXPECT_TRUE condition` over an initialized Boolean local.
- `LOCAL_ROTR32 destination, value, amount` with a signed amount from 0 through 31.
- `NOP` with no operands or machine effect.

Rotate-right consumes the low 32 bits of the signed source and returns the zero-extended unsigned 32-bit result in a signed local. This matches canonical VM semantics. Scalar sources remain available after these operations.

The physical source boundary covers status reads and assertions:

```wheeler
module example.hello;

classical class Hello {
  state long status = 0;

  entry void main() {
    status = 70;
    long value = status;
    value += 3;
    assert(value == 73);
    status = value;
  }
}
```

## Machine lowering

The entry stack frame owns one dedicated status slot. Global stores write that slot and global loads copy it into a scalar local. `EXPECT_TRUE` tests the full Boolean word and branches to the active function trap epilogue on zero. `LOCAL_ROTR32` uses the checked RCX amount and x86-64 `ror eax, cl`. Writing EAX supplies the required zero extension. `NOP` emits no byte.

`ScalarAotProgram` independently evaluates status transitions, assertions, and rotations before emission. Assertion failure or an amount outside 0 through 31 rejects the artifact. The emitted runtime retains the assertion branch for accepted input instead of deleting a known-true check.

The former arithmetic-trap identifier is removed. `EXECUTION_TRAP_STATUS` names the complete status-126 boundary. There is no compatibility alias.

## Failure boundary

Reject global loads in helpers, unknown global indices, non-signed load destinations, false assertions, non-Boolean conditions, rotate amounts below zero or above 31, malformed NOP operands, and every existing scalar-profile failure. Reject before runtime publication.

The fixed output probe still reports only loader and host-write evidence. An execution trap changes process status, not standard output framing.

## Evidence

`LinuxX8664ScalarAotCompilerTest` stores rotate result 42, reads it back through the status slot, asserts exact equality, adds 31, executes NOP, stores 73, and halts. It separately rejects expected value 41 and rotate amount 32. The arithmetic table also derives 42 from `rotateRight32(0x540, 5)`.

`ImageCommandTest` compiles physical source that stores and reloads status 70, passes the value through a two-argument helper and bounded loop, asserts 73, and publishes that result. Complete WBC, runtime, capsule, plan, ELF verification, and Linux launch remain one physical path.

An independent Alpine 3.22 kernel under x86-64 emulation launched the 5,376-byte state-check image. Native rotate, store, load, assertion, NOP, and final store produced exact status 73 and `Wheeler\n`.

The fixture identities are:

| Product | Identity |
| --- | --- |
| WBC | `eb27d2669f322a47f95c9fe51a30d0194be337cee6969046ecef0574b3331793` |
| runtime | `976a2ac250749dbe87eb103fbd9e1ad3bde423c0051a5f0c93f4c6599c1e131b` |
| capsule | `4b89342c19002cbecd44410596145fa8b0351927a377c2ca564f658e29bce7ac` |
| native plan | `f0142231f6f23ef40b48d506fcf1e716ec20077af51bbee875db5f6f3ada6bd8` |
| unsigned PREV | `bbfbd15c39c17850a1e2ff28e08c94c51094809e0302a68cffcd6bbe2397c6d6` |

## Acceptance

- [x] Entry status loads observe the last native status store.
- [x] Helpers remain unable to access global state.
- [x] Native assertions retain one checked failure branch.
- [x] Rotate-right matches low-32-bit and zero-extension semantics.
- [x] Rotate amount 31 succeeds and 32 rejects.
- [x] NOP has no semantic or machine effect.
- [x] Status 126 has one execution-trap authority and no legacy alias.
- [x] Physical source and independent Linux loader evidence observe status 73.

## Rejected alternatives

### Fold known assertions away

Rejected. Retaining the native check proves the instruction boundary and keeps accepted machine behavior aligned with WBC.

### Let helpers address the entry frame

Rejected. Hidden dynamic links would create an ambient global ABI. Helper state access needs an explicit design.

### Use signed 64-bit rotate semantics

Rejected. `LOCAL_ROTR32` is explicitly a low-32-bit operation with zero extension.

### Keep arithmetic trap as an alias

Rejected. Assertions and loop checks made that name false. One execution-trap identifier is sufficient.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0381](WIP-0381-x86-64-linux-bounded-scalar-loops.md)
- [WIP-0403](WIP-0403-scalar-global-instruction-aot.md)
- [WIP-0390](WIP-0390-x86-64-linux-shared-scalar-globals.md)
- [WIP-0383](WIP-0383-x86-64-linux-void-helper-calls.md)
