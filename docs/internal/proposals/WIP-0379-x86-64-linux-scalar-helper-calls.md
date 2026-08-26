# WIP-0379: x86-64 Linux scalar helper calls

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and runtime maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, AOT lowering, x86-64 calls, scalar helpers |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0378 |
| Supersedes | Single-function scalar AOT as the complete call boundary |
| Superseded by | WIP-0380 for arguments, WIP-0396 for function order |

## Summary

The x86-64 Linux scalar AOT leaf lowers a bounded graph of Wheeler helper calls. Up to seven signed, zero-argument helpers precede one entry function. `CALL_VALUE` transfers control through generated machine-code calls and returns the helper's signed value to a fresh caller local.

This is the first native call-stack slice. WIP-0380 extends it with six register parameters, WIP-0383 adds void helpers, WIP-0386 adds bounded byte borrows, and WIP-0395 carries one seventh parameter in an aligned stack slot. It is not a general Wheeler ABI. This WIP alone does not specify parameters, void calls, result slots, recursion, imported functions, dynamic targets, inverse calls, and effects remain outside the profile.

## Function graph

The accepted WBC remains subject to WIP-0378. Its function table now contains one through eight dense functions with the entry last. Every nonentry function has:

- Zero parameters.
- One through 32 signed or Boolean locals.
- One signed result.
- Two through 128 acyclic scalar instructions.
- One terminal `RETURN_VALUE`.
- No inverse, result slot, global store, or effect.

A call has canonical operands `CALL_VALUE target, 0, 0, destination`. The target must be a lower function ID, which makes the complete graph acyclic without a runtime depth counter. The destination is a fresh signed local. Entry retains the WIP-0378 status-store and halt rules.

The profile admits source such as:

```wheeler
module example.hello;

classical class Hello {
  state long status = 0;

  long code() {
    long left = 70;
    long right = 3;
    return left + right;
  }

  entry void main() {
    status = code();
  }
}
```

## Machine call boundary

`ScalarAotProgram` owns complete profile validation and independent constant evaluation. It rejects the complete artifact if any helper signature, instruction, branch, call edge, local flow, return, or status path falls outside the profile. It does not remove unsupported functions or rewrite calls.

`ScalarAotMachine` emits helper bodies before the entry body and places one checked relative call at each admitted edge. Every function owns a 16-byte-aligned stack frame. Helpers return their signed value in RAX and a trap flag in RDX. A caller checks RDX before committing the returned local. Arithmetic failure propagates through each active helper frame to entry, where status 126 remains the native execution trap. Entry alone owns the status global and process result.

The generated call convention is private to this closed image. It does not claim the platform C ABI, preserve registers for external code, expose symbols, or admit ambient linking.

## Failure boundary

Reject sparse or reordered function IDs, more than eight functions, a nonterminal entry, parameters, non-signed helper results, helper global stores, nonterminal returns, calls with arguments, calls without values, forward call edges, recursion, unsupported call opcodes, stale locals, and any existing WIP-0378 failure.

A failed helper graph produces no runtime output. There is no interpreter fallback and no projection to the entry function.

## Evidence

`LinuxX8664ScalarAotCompilerTest` lowers a three-function nested graph and the exact eight-function terminal graph. It checks independent status evaluation, distinct runtime identities, owned machine bytes, argument-helper rejection, and function-nine rejection. Existing tests retain literal, arithmetic, bitwise, comparison, branch, malformed-input, capsule, and ELF evidence after the backend split.

`ImageCommandTest` compiles a physical Wheeler module containing a signed helper, lowers its canonical WBC through `runtime-elf-x86-64-aot`, builds and verifies the complete capsule ELF, and launches it on x86-64 Linux.

An independent Alpine 3.22 kernel under x86-64 emulation launched the 6,008-byte eight-function image. Seven nested machine calls returned status 73 and the process wrote exact `Wheeler\n`.

The terminal fixture identities are:

| Product | Identity |
| --- | --- |
| WBC | `b44257e22ffde0ffd65e243b9c6d6e3b7c87644113bc2c3c8c35e1ce53aca50e` |
| runtime | `f799877a72ee6f0d235676de3878f471b6ae62a90ff9bf83b68c14e7f8f88d4a` |
| capsule | `6fa99c7bb69a4763f71eba2af47938d0441098003fcb3703e5046f2deb37a4e3` |
| native plan | `7b38b94cd540955ee4063456df433060b49dc5ddac426466494784c5d595652b` |
| unsigned PREV | `df01f2d6524bd92909b576cfa641bd1efb41f6870315de3d4ef86d0fd1b516c2` |

## Acceptance

- [x] Complete helper signatures and bodies reject before machine lowering.
- [x] At most eight dense functions form one prior-target acyclic graph.
- [x] Zero-argument signed helper results cross native call and return instructions.
- [x] Every helper owns and releases one aligned stack frame.
- [x] Arithmetic trap state propagates to entry without committing a call result.
- [x] Function nine, parameters, recursion, forward calls, and unsupported effects reject.
- [x] Physical source, WBC, runtime, capsule, ELF, and loader evidence agree.
- [x] No broader ABI, linker, or startup claim is made.

## Rejected alternatives

### Inline helpers before lowering

Rejected. Inlining would avoid the machine call boundary and compile a different artifact identity. This WIP preserves each admitted function and edge.

### Use the platform C ABI as an implicit contract

Rejected. The generated image has no external call authority. A private two-register result boundary is smaller and explicit.

### Permit recursion with the host stack as the limit

Rejected. Loader stack size is ambient policy. Recursive calls need an explicit depth or storage bound before admission.

### Ignore unsupported helpers that entry does not reach

Rejected. Complete-artifact validation precedes reachability. Dormant unsupported code cannot accompany a claimed native image.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0378](WIP-0378-x86-64-linux-scalar-aot.md)
- [WIP-0380](WIP-0380-x86-64-linux-scalar-call-arguments.md)
- [WIP-0386](WIP-0386-x86-64-linux-borrowed-byte-helpers.md)
- [WIP-0383](WIP-0383-x86-64-linux-void-helper-calls.md)
- [WIP-0396](WIP-0396-order-independent-scalar-aot-calls.md)
