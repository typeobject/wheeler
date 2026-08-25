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

The first native backend leaf lowers verified canonical Wheeler bytecode into x86-64 Linux runtime text. One closed scalar profile writes a source-declared status global and returns that value as process status after mapped capsule entry.

This is AOT evidence, not the classical bootstrap backend. It does not lower arithmetic, branches, calls, history, inverse execution, ownership, aggregates, storage, effects, quantum regions, workflows, proofs, or general entry signatures. It does not perform complete in-process capsule or WBC verification. WIP-0008 retains those boundaries.

## Accepted WBC profile

`LinuxX8664ScalarAotCompiler` accepts one canonical WBC artifact only after `BytecodeReader` verification and byte-for-byte `BytecodeWriter` reconstruction. The decoded program must contain:

- Classical program kind.
- No record, variant, array, slice, proof, quantum, workflow, or extension section.
- One signed global named `status`, initially zero.
- One entry function and no helper.
- Zero parameters, one signed local, no result, no result slot, and no inverse.
- Exact forward code `LOCAL_CONST 0, N`, `LOCAL_STORE_GLOBAL 0, 0`, `HALT`.
- Process status `N` from 0 through 124.

Status 125 remains the native malformed-image result. Larger and negative source values reject during lowering rather than wrapping through the host exit convention.

The profile admits ordinary source such as:

```wheeler
module example.hello;

classical class Hello {
  state long status = 0;

  entry void main() {
    status = 73;
  }
}
```

## Lowering

The lowerer retains the exact portable-artifact SHA-256, extracts the verified literal, and asks the WIP-0376 instruction assembler for owned position-independent runtime text carrying that status. No source text, host path, assembler, linker, dynamic import, relocation, clock, environment, locale, or random state enters output.

Every accepted artifact maps deterministically to one runtime. Changing the source status changes both WBC and runtime identities. Returned runtime arrays are owned.

The physical command is:

```text
wheeler image runtime-elf-x86-64-aot <root.wbc> -o <runtime.bin>
```

It reads one bounded physical WBC, verifies and lowers it, atomically publishes exact runtime bytes, and reports byte count, runtime identity, WBC identity, and process status. It does not build or execute an image.

WIP-0372 now admits `aot` mode for ELF when plan, capsule root, portable artifact, ABI, and runtime identity agree. Mach-O and PE remain outside this AOT slice.

## Native observation

The generated runtime follows the same mapped-entry boundary as WIP-0376. It validates locator magic, exact capsule offset, and capsule framing magic. It then completes the fixed eight-byte standard-output probe and exits with the Wheeler-declared scalar.

The source-declared status is the sole native semantic observation in this profile. Fixed probe output establishes the host write leaf but does not derive application output from WBC.

## Failure boundary

Reject malformed or noncanonical WBC, unsupported program kind, any extra semantic section, extension, global, function, local, instruction, parameter, result, inverse, or entry effect, a renamed or nonzero-initialized status global, and status outside 0 through 124.

Image construction separately rejects mode, plan, ABI, capsule, root WBC, runtime, target, locator, permission, or canonical-byte disagreement before publication. Loaded entry retains WIP-0376 framing-failure status 125.

The backend does not project a larger program down to this profile. Unsupported input rejects intact.

## Evidence

`LinuxX8664ScalarAotCompilerTest` constructs canonical WBC at statuses 17, 42, and 73. It requires stable lowering, owned bytes, exact portable identity, distinct WBC and runtime identities, canonical AOT ELF construction, and rejection of status 125, renamed state, extra instructions, and damaged artifacts.

On x86-64 Linux the test launches the status-73 AOT image through the kernel and requires exact `Wheeler\n` output, process status 73, and empty standard error. `ImageCommandTest` independently compiles the source form, publishes runtime text through the physical AOT command, builds and verifies its complete AOT capsule image, and repeats native launch on Linux.

An independent Alpine 3.22 kernel under x86-64 emulation launched the 5,104-byte image and observed `Wheeler\n` followed by status 73.

The status-73 fixture identities are:

| Product | Identity |
| --- | --- |
| WBC | `c8af845b4cc1722d55e807211f2320fbf83a66a5332537cc57d2171cbf1243f3` |
| runtime | `d2e3874039662e3668852d5255b0f5bcf89ba215962f49110e0e336e4691a9f5` |
| capsule | `a0f55d2ba640f4038b4b4fb9bd9fb8517cfc4bd0e98c19782a977af1d57ebe0c` |
| native plan | `200a42afcd771abaee0973c73dac85d7f9d3f98c2f64dec0389ae6cb09c02dd6` |
| unsigned PREV | `e8b3ae8b764b3035f4d51655eae29872af6b60d3edc3c387e1c7fc35000518a9` |

## Acceptance

- [x] Canonical WBC verification and reconstruction precede lowering.
- [x] One closed source-declared signed status reaches x86-64 machine code.
- [x] Status changes alter portable and runtime identities deterministically.
- [x] Unsupported programs reject without projection or fallback.
- [x] Physical lowering and image publication are bounded and atomic.
- [x] ELF plan and capsule identities bind AOT mode and exact WBC.
- [x] Linux loader evidence observes the source-declared process status.
- [x] The implementation makes no broader backend or startup claim.

## Rejected alternatives

### Read status from source text

Rejected. Native lowering consumes verified canonical WBC. Source spelling cannot become a second semantic input.

### Accept any final constant in a larger program

Rejected. Ignoring unsupported instructions would compile a different program. The complete closed profile must match.

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
