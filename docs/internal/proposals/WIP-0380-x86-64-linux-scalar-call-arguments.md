# WIP-0380: x86-64 Linux scalar call arguments

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and runtime maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, AOT lowering, x86-64 call ABI, scalar parameters |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0379 |
| Supersedes | Zero-argument-only scalar helper calls as the complete AOT call profile |
| Superseded by | WIP-0396 for function order, WIP-0399 for argument width |

## Summary

The x86-64 Linux scalar AOT call boundary carries up to six signed or Boolean arguments. Each `CALL_VALUE` binds one exact contiguous caller-local range to the target's declared parameter types. The callee copies those register arguments into its own stack frame before executing Wheeler instructions.

This WIP extends the private WIP-0379 call convention. WIP-0381 adds bounded loops without changing this register boundary. It does not establish an external ABI or admit owned values, loans, aggregates, result slots, variadic calls, void calls, recursion, imports, or effects.

## Accepted calls

A scalar helper declares zero through six parameters. Its parameter types are the first entries in the canonical local-type table. The existing 32-local and 128-instruction bounds include parameters and their use.

An admitted call has:

- A lower function ID.
- An argument count equal to the target parameter count.
- One contiguous in-range caller-local span.
- Exact signed or Boolean type agreement at every position.
- One fresh signed destination.

Scalar arguments remain available in the caller after a call. This matches canonical WBC scalar call semantics. Affine owner and loan transfer is not admitted by this profile.

The physical source boundary now covers:

```wheeler
module example.hello;

classical class Hello {
  state long status = 0;

  long code(long left, long right) {
    return left + right;
  }

  entry void main() {
    status = code(70, 3);
  }
}
```

## Register boundary

`ScalarAotMachine` uses RDI, RSI, RDX, RCX, R8, and R9 for arguments in source order. A helper copies every admitted argument to stack locals zero through `n - 1` before it may overwrite a register. RAX carries the signed result. RDX carries the helper trap flag only after the callee has retained its third parameter.

Every caller loads all argument registers from its own frame immediately before the relative call. It checks the returned trap flag before storing RAX. Nested callers propagate failure through their own epilogues. The entry frame converts the terminal failure to process status 126.

These register choices are image-private. No external symbol, stack argument, red zone, callee-save promise, unwind metadata, or dynamic linker contract enters the image.

## Failure boundary

Reject parameter seven, parameterized entry functions, count disagreement, out-of-range argument spans, type disagreement, non-signed destinations, forward or recursive targets, and every unsupported WIP-0379 call form. Reject before machine bytes or physical output are published.

The lowerer validates and evaluates the same arguments independently before emission. It does not pad missing arguments, truncate excess arguments, coerce Boolean and signed values, or select a different overload.

## Evidence

`LinuxX8664ScalarAotCompilerTest` constructs one six-parameter signed helper and one mixed Boolean and signed helper. Every argument contributes to the returned status 73. The test also requires parameter seven to reject and retains exact nested zero-argument, function-count, dormant-helper, forward-edge, arithmetic, branch, capsule, and ELF evidence.

`ImageCommandTest` compiles a physical two-parameter Wheeler helper, lowers the resulting canonical WBC, verifies the AOT plan and capsule, builds the ELF, and launches it on x86-64 Linux.

An independent Alpine 3.22 kernel under x86-64 emulation launched the 5,584-byte six-parameter image. All six register arguments contributed to exact process status 73, and the process wrote exact `Wheeler\n`.

The six-parameter fixture identities are:

| Product | Identity |
| --- | --- |
| WBC | `160f4d6b5857adad15ce8b26507f4e5987f82decd506598b39910f7a8ac9abdc` |
| runtime | `10b75c50d121b828012f7936c4f3ef716440c4e5b8ef0affe61bddba1540df0b` |
| capsule | `19c973cc9388635492229e44b5457f27a67e8b8728b5f437e0f30497273eaf4a` |
| native plan | `4583cf7b5a6ad42aa084ee57cb14456b0295677b4002f1db282e80f5c0b5b759` |
| unsigned PREV | `13709727fb26438876bbfe0c330ebdcd12c5332924d218726c502c4cfa0f797a` |

## Acceptance

- [x] Zero through six exact signed or Boolean parameters validate before lowering.
- [x] Caller-local spans and callee parameter types agree exactly.
- [x] Six register arguments survive callee frame construction.
- [x] Returned RAX and trap-state RDX remain separate.
- [x] Nested calls preserve frame and trap behavior.
- [x] Parameter seven and malformed call shapes reject intact.
- [x] Physical source and independent Linux loader evidence observe status 73.
- [x] No external or affine call ABI is claimed.

## Rejected alternatives

### Spill excess parameters to the host stack

Rejected. A stack-argument ABI needs explicit offsets, alignment, ownership, and unwind rules. Six registers form one closed slice.

### Coerce Boolean and signed parameters

Rejected. WBC local types are semantic input. A native backend may not invent source conversions.

### Reuse caller stack slots as the callee frame

Rejected. Frame aliasing would make call semantics depend on caller layout and obstruct nested calls.

### Treat RDX as a trap flag before saving parameter three

Rejected. The callee owns its incoming arguments first. Trap state becomes authoritative only after parameter retention.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0379](WIP-0379-x86-64-linux-scalar-helper-calls.md)
- [WIP-0381](WIP-0381-x86-64-linux-bounded-scalar-loops.md)
- [WIP-0395](WIP-0395-x86-64-linux-seventh-scalar-argument.md)
- [WIP-0396](WIP-0396-order-independent-scalar-aot-calls.md)
- [WIP-0399](WIP-0399-compiler-width-scalar-aot-arguments.md)
