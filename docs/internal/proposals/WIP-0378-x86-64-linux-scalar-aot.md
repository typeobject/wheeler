# WIP-0378: x86-64 Linux scalar AOT

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and native maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, AOT lowering, x86-64 Linux, process status |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0368, WIP-0372, WIP-0376 |
| Supersedes | Fixed-status native entry probes as AOT evidence |
| Superseded by | None |

## Summary

The first native backend leaf lowers verified canonical Wheeler bytecode into x86-64 Linux runtime text. One closed straight-line scalar profile computes a source-declared status global and returns that value as process status after mapped capsule entry.

This is AOT evidence, not the classical bootstrap backend. It does not lower branches, calls, history, inverse execution, ownership, aggregates, storage, effects, quantum regions, workflows, proofs, or general entry signatures. It does not perform complete in-process capsule or WBC verification. WIP-0008 retains those boundaries.

## Accepted WBC profile

`LinuxX8664ScalarAotCompiler` accepts one canonical WBC artifact only after `BytecodeReader` verification and byte-for-byte `BytecodeWriter` reconstruction. The decoded program must contain:

- Classical program kind.
- No record, variant, array, slice, proof, quantum, workflow, or extension section.
- One signed global named `status`, initially zero.
- One entry function and no helper.
- Zero parameters, one through 32 signed locals, no result, no result slot, and no inverse.
- Three through 128 forward instructions.
- Fresh-destination `LOCAL_CONST`, `LOCAL_MOVE`, `LOCAL_ADD`, `LOCAL_SUB`, `LOCAL_MUL`, `LOCAL_DIV`, `LOCAL_MOD`, `LOCAL_AND`, and `LOCAL_XOR` instructions.
- One terminal `LOCAL_STORE_GLOBAL 0, result`, then `HALT`.
- Computed process status from 0 through 124.

Status 125 remains the native malformed-image result. Larger and negative source values reject during lowering rather than wrapping through the host exit convention.

The profile admits ordinary source such as:

```wheeler
module example.hello;

classical class Hello {
  state long status = 0;

  entry void main() {
    long left = 70;
    long right = 3;
    long result = left + right;
    status = result;
  }
}
```

## Lowering

The lowerer retains the exact portable-artifact SHA-256, validates single-assignment local flow, and evaluates checked constants to establish the expected status. It emits x86-64 stack locals, moves, signed checked addition, subtraction, multiplication, division, remainder, and bitwise operations. Runtime range and overflow guards lead to process status 126. The WIP-0376 entry assembler wraps that owned position-independent code. No source text, host path, assembler, linker, dynamic import, relocation, clock, environment, locale, or random state enters output.

Every accepted artifact maps deterministically to one runtime. Changing the source status changes both WBC and runtime identities. Returned runtime arrays are owned.

The physical command is:

```text
wheeler image runtime-elf-x86-64-aot <root.wbc> -o <runtime.bin>
```

It reads one bounded physical WBC, verifies and lowers it, atomically publishes exact runtime bytes, and reports byte count, runtime identity, WBC identity, and process status. It does not build or execute an image.

WIP-0372 now admits `aot` mode for ELF when plan, capsule root, portable artifact, ABI, and runtime identity agree. Mach-O and PE remain outside this AOT slice.

## Native observation

The generated runtime follows the same mapped-entry boundary as WIP-0376. It validates locator magic, exact capsule offset, and capsule framing magic. It then completes the fixed eight-byte standard-output probe and exits with the Wheeler-declared scalar.

The source-declared computed status is the sole native semantic observation in this profile. Fixed probe output establishes the host write leaf but does not derive application output from WBC.

## Failure boundary

Reject malformed or noncanonical WBC, unsupported program kind, any extra semantic section, extension, global, function, unsupported local or instruction, parameter, result, inverse, or entry effect, a renamed or nonzero-initialized status global, unassigned reads, destination reuse, checked arithmetic failure, and final status outside 0 through 124.

Image construction separately rejects mode, plan, ABI, capsule, root WBC, runtime, target, locator, permission, or canonical-byte disagreement before publication. Loaded entry retains WIP-0376 framing-failure status 125.

The backend does not project a larger program down to this profile. Unsupported input rejects intact.

## Evidence

`LinuxX8664ScalarAotCompilerTest` constructs canonical literal WBC at statuses 17 and 42 and an arithmetic status-73 WBC. It executes addition, subtraction, multiplication, division, remainder, AND, and XOR products that each compute 42. It requires stable lowering, owned bytes, exact portable identity, distinct WBC and runtime identities, canonical AOT ELF construction, and rejection of status 125, renamed state, unsupported instructions, overflow, division by zero, and damaged artifacts.

On x86-64 Linux the test launches one status-73 AOT image containing every admitted arithmetic and bitwise opcode. It requires exact `Wheeler\n` output, process status 73, and empty standard error. `ImageCommandTest` independently compiles the source form, publishes runtime text through the physical AOT command, builds and verifies its complete AOT capsule image, and repeats native launch on Linux.

An independent Alpine 3.22 kernel under x86-64 emulation launched the 5,728-byte all-operations image and observed `Wheeler\n` followed by status 73.

The status-73 fixture identities are:

| Product | Identity |
| --- | --- |
| WBC | `4cafb3e54d2df73acb40ab43167a4c3aac4f443ee89f9dad50d16956fc84d4b9` |
| runtime | `43c8d4b7aafef0570d3946e22fc266f3b2a05394e708b1a8950a58720c19be9b` |
| capsule | `5415a99509fbbd128df1e73da4edaee2c600df2dd56372e7cf16ddc8d3fb411d` |
| native plan | `e57825e776b9b4598ac3135ed7f6630b04e9c6170da26bf5a574a8552ebeeccc` |
| unsigned PREV | `b2111e116204152bf8de5f54b8ed362b5fa695728a9a3478071d72db5dba2f30` |

## Acceptance

- [x] Canonical WBC verification and reconstruction precede lowering.
- [x] One closed straight-line signed status computation reaches x86-64 machine code.
- [x] Checked arithmetic and bitwise operations preserve accepted scalar results.
- [x] Status changes alter portable and runtime identities deterministically.
- [x] Unsupported programs reject without projection or fallback.
- [x] Physical lowering and image publication are bounded and atomic.
- [x] ELF plan and capsule identities bind AOT mode and exact WBC.
- [x] Linux loader evidence observes the source-declared process status.
- [x] The implementation makes no broader backend or startup claim.

## Rejected alternatives

### Read status from source text

Rejected. Native lowering consumes verified canonical WBC. Source spelling cannot become a second semantic input.

### Accept any final computation in a larger program

Rejected. Ignoring unsupported instructions or dataflow would compile a different program. The complete closed profile must match.

### Wrap arbitrary signed values to eight-bit exit status

Rejected. Host truncation would hide semantic distinctions. The first profile admits only unambiguous nonfailure values.

### Call the fixed WIP-0376 status AOT

Rejected. Loader entry proves native mechanics, not bytecode lowering. This WIP requires at least two WBC values to produce distinct native observations.

### Claim build-time WBC verification as complete startup

Rejected. The loaded runtime still checks framing rather than complete capsule and WBC identities. Full in-process startup remains required before release use.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0368](WIP-0368-platform-abi-and-native-image-identities.md)
- [WIP-0372](WIP-0372-canonical-elf-capsule-images.md)
- [WIP-0376](WIP-0376-x86-64-linux-native-entry-shim.md)
