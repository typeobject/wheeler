# WIP-0383: x86-64 Linux void helper calls

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and runtime maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, AOT lowering, void helpers, assertion boundaries |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0382 |
| Supersedes | Signed-result-only helpers as the complete scalar AOT call profile |
| Superseded by | None |

## Summary

The x86-64 Linux scalar AOT leaf lowers parameterized void helpers. `CALL_VOID` passes zero through six exact signed or Boolean arguments to one prior helper. The helper terminates with `RETURN`, carries no result local back, and returns only execution-trap state.

WIP-0384 adds output ownership to entry without granting it to helpers. Void helpers provide a native assertion and validation boundary without granting global state or host effects. They do not admit output, storage mutation, ownership transfer, imported functions, result slots, inverse calls, or recursion.

## Accepted void helpers

A nonentry helper may declare no result type. Its body follows the same local, instruction, branch, loop, parameter, and assertion profile as signed-result helpers, except that its sole terminal instruction is `RETURN`.

An admitted `CALL_VOID target, argumentBase, argumentCount` requires:

- A lower function ID naming a void helper.
- An argument count equal to the helper parameter count.
- One exact contiguous and initialized caller-local span.
- Signed and Boolean type equality at every position.
- No destination operand.

`CALL_VALUE` may name only a signed-result helper. `CALL_VOID` may name only a void helper. The lowerer never discards a value result or fabricates one for void code.

The physical source boundary covers:

```wheeler
module example.hello;

classical class Hello {
  state long status = 0;

  void check(long value) {
    assert(value == 73);
  }

  entry void main() {
    long value = 73;
    check(value);
    status = value;
  }
}
```

## Machine boundary

A void helper owns the same aligned stack frame and register-argument prologue as a signed helper. Successful `RETURN` clears RAX and RDX, releases the frame, and returns. The caller checks RDX before continuing but does not store RAX. Failure sets the helper trap flag and propagates through nested callers to entry status 126.

Clearing RAX is deterministic hygiene, not a void-result ABI. No Wheeler instruction may consume it after `CALL_VOID`.

`ScalarAotProgram` independently evaluates every void body and call. A false assertion rejects before machine emission. Dormant void helpers remain subject to complete validation.

## Failure boundary

Reject `RETURN` in entry or a signed helper, `RETURN_VALUE` in a void helper, a nonterminal return, value calls to void targets, void calls to value targets, argument mismatch, forward or recursive targets, global state access from a helper, and all existing scalar-profile failures.

No runtime is published when a void helper fails build-time evaluation. Accepted machine code retains the helper assertion and trap propagation paths.

## Evidence

`LinuxX8664ScalarAotCompilerTest` lowers a one-parameter void helper that asserts exact value 73. The entry calls it, then stores status 73. A value of 72 fails independent evaluation before publication. Existing value-call, six-register argument, Boolean parameter, nested call, state, loop, arithmetic, capsule, and ELF evidence remains.

`ImageCommandTest` compiles physical source containing a two-argument signed helper, one-argument void assertion helper, status read, bounded loop, void call, and final status store. The complete command path lowers, builds, verifies, and launches one AOT ELF.

An independent Alpine 3.22 kernel under x86-64 emulation launched the 5,304-byte void-helper fixture. Native `CALL_VOID`, assertion, `RETURN`, and caller trap check completed with exact status 73 and `Wheeler\n`.

The fixture identities are:

| Product | Identity |
| --- | --- |
| WBC | `82467bc2267b6df2ccc5827b8f9ad112b56d189220c9f3d367a44ffec2e7076f` |
| runtime | `91ea23c9affaa9c15fbeb2fbf3df45c064f887f0e02027bdd8c2d273c7afc10c` |
| capsule | `bc819f9a2df5412dcfa8efccf3e29ea493c19ee54506de4bbc391536a8c6121b` |
| native plan | `8e09ee9f1a6dc94375ea280126b22d8f26c00fe9b28e0f65f7bb486f10664d11` |
| unsigned PREV | `5630b9dfa332bf972f9d775017254b72d457aa516b2da63faa525c5a9dc4afb4` |

## Acceptance

- [x] Void helpers terminate through one canonical `RETURN`.
- [x] `CALL_VOID` binds zero through six exact scalar arguments.
- [x] Value and void call targets cannot be interchanged.
- [x] Successful void return commits no caller local.
- [x] Helper execution traps propagate through RDX to entry status 126.
- [x] False helper assertions reject before publication.
- [x] Physical source and independent Linux loader evidence observe status 73.
- [x] No effectful or external void ABI is claimed.

## Rejected alternatives

### Lower void calls as value calls to an invented zero

Rejected. A fabricated result changes WBC call shape and caller local flow.

### Ignore the helper trap flag after void return

Rejected. Void means no value, not no failure.

### Let assertion helpers read the status global

Rejected. Helper global access remains an ambient dynamic-link problem. Pass the scalar explicitly.

### Remove known-successful void calls

Rejected. The native call, frame, assertion, return, and trap-check boundaries are the evidence.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0382](WIP-0382-x86-64-linux-scalar-state-checks.md)
- [WIP-0384](WIP-0384-x86-64-linux-constant-byte-output.md)
