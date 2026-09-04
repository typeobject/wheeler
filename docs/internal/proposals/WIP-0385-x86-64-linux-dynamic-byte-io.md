# WIP-0385: x86-64 Linux dynamic byte I/O

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and native maintainers |
| Created | 2026-08-25 |
| Updated | 2026-09-04 |
| Area | Native bootstrap, AOT lowering, standard input, dynamic byte output |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0384 |
| Supersedes | Constant-only application output as the complete AOT I/O profile |
| Superseded by | None |
| Follow-up | WIP-0386 for helper byte access |

## Summary

The x86-64 Linux scalar AOT leaf reads bounded standard input and computes standard output and process status at runtime. An entry with exact parameters `borrow byteview input, borrow mut bytes output` may execute `BUFFER_LENGTH`, `BYTES_GET`, `BYTES_SET`, `OUTPUT_LENGTH`, scalar operations, helpers, assertions, and bounded loops over retained native buffers.

This is the first input-dependent native Wheeler observation. Runtime output and status are no longer known during lowering. The compiler reports that fact instead of publishing a guessed value. The profile remains a bounded AOT slice, not complete capsule startup or a general owned-storage backend.

## Entry and transport

A dynamic-I/O entry has exactly two parameters in this order:

1. One immutable `byteview` input.
2. One mutable `bytes` output borrow.

The runtime admits complete input from zero through 4,096 bytes. It repeats `read(0, ...)` until EOF, so pipe chunking does not alter semantics. Once the retained input reaches 4,096 bytes, it performs one one-byte probe. EOF admits the terminal size. Any additional byte rejects before Wheeler instructions execute.

The runtime allocates separate 4,096-byte input and output arenas in the entry stack frame. It zeroes the complete output arena before execution. The 64-local output-entry bound is independent of those byte arenas.

The admitted dynamic instructions are:

- `BUFFER_LENGTH destination, input` returning the retained input length.
- `BYTES_GET destination, input, index` with a runtime-checked index.
- `BYTES_SET output, index, value` with runtime-checked index and byte value.
- `OUTPUT_LENGTH output, length` with a runtime-checked length from 1 through 4,096.

This WIP keeps input and output handles in the entry. Scalar values derived from input may cross existing signed or Boolean helper calls. WIP-0386 adds canonical borrowed byte helpers. WIP-0389 adds typed strict UTF-8 input.

The source boundary covers:

```wheeler
module example.echo;

classical class Echo {
  state long status = 0;

  entry void main(
    borrow byteview input,
    borrow mut bytes output
  ) {
    long first = input[0];
    setByte(output, 0, first);
    setOutputLength(output, 1);
    status = first;
  }
}
```

## Native execution

`ScalarAotMachine` retains input length and output length in dedicated frame slots. Indexed loads and stores use checked stack-relative x86-64 addressing. Negative indices, index equal to the active bound, byte value 256, missing output length, input read failure, output write failure, assertion failure, arithmetic failure, and invalid final status reach execution status 126.

The entry validates final status 0 through 124 before calling `write(1, ...)`. It requires the complete selected output length. A failed execution publishes no application bytes. The framing checks still run first and retain malformed-image status 125.

`LinuxX8664EntryShim` omits its fixed or retained-output write for this profile. The generated application body owns both standard-input and standard-output system calls. Runtime text remains import-free, relocation-free, and independent of libc.

`LinuxX8664ScalarAotCompiler.LoweredRuntime` exposes `usesDynamicApplicationIo()`. It reports no static process status and no retained constant output. Calling either static-result accessor rejects. The physical command reports `input-dependent status` and `dynamic stdin/stdout`.

## Failure boundary

Reject a reversed parameter order, one dynamic parameter without output, a third parameter, input or output handles in helpers, unsupported owner operations, input byte 4,097, output byte 4,097, index outside the retained length, byte outside 0 through 255, output length outside 1 through 4,096, incomplete writes, and all prior scalar-profile failures.

The runtime waits for EOF to establish complete input. An interactive producer that does not close standard input has not supplied a complete transport.

## Evidence

`LinuxX8664ScalarAotCompilerTest` lowers a canonical echo artifact whose output byte and process status both derive from input byte zero. It requires dynamic-result API state, complete ELF reconstruction, and on x86-64 Linux writes `Z`, closes stdin, observes exact `Z`, and receives status 90.

`ImageCommandTest` compiles a physical module with dynamic input and output, status state, signed and void helpers, assertions, a bounded loop, indexed input, seven output writes, and one output-length commitment. The command reports dynamic I/O, builds and verifies the complete capsule ELF, writes input `N`, and expects `Native\n` with status 73.

An independent Alpine 3.22 kernel under x86-64 emulation launched the 5,272-byte dynamic image and observed:

- Input `Z`, output `Z`, status 90.
- Empty input, empty output, status 126.
- Exactly 4,096 `A` bytes, output `A`, status 65.
- Exactly 4,097 `A` bytes, empty output, status 126.

The fixture identities are:

| Product | Identity |
| --- | --- |
| WBC | `b16859d4187c989ede32d3e3603a1481ff4162cb2cbbb6550041f0bb3dd402be` |
| runtime | `77877d949a96f21a7ea1091054d0392e0ef892b282eea00ff1e39c2d5665c59d` |
| capsule | `171267b1aed8331bb1f8595dd31bc4047c2c289908cfaa754ead3a3e6c050dba` |
| native plan | `b67a9c96f58fe3cb27d27725b78b4c8b1660dfc8684d0e5ded0e5ff10832513a` |
| unsigned PREV | `3cf28f680660d38822d50150cae3e87c934de51658c1a7e4a54ab40937592f8a` |

## Acceptance

- [x] Native input reads repeat until EOF and retain at most 4,096 bytes.
- [x] Input byte 4,096 succeeds and byte 4,097 rejects before execution.
- [x] Dynamic input length and indexed bytes reach scalar machine code.
- [x] Dynamic output writes and selected length reach one checked host write.
- [x] Final status validates before output publication.
- [x] Empty and excess input trap with empty output.
- [x] Physical source and independent Linux loader evidence agree.
- [x] The implementation makes no complete startup or owned-storage claim.

## Rejected alternatives

### Read standard input once

Rejected. Pipe chunking would become semantic input and could truncate a valid transport.

### Treat the 4,096th byte as implicit EOF

Rejected. A complete bounded transport must distinguish exact capacity from excess input.

### Publish a build-time status for dynamic input

Rejected. The result does not exist until native execution. A guessed status would corrupt plan and release evidence.

### Write output before final status validation

Rejected. A trapping execution must not publish application bytes.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0384](WIP-0384-x86-64-linux-constant-byte-output.md)
- [WIP-0386](WIP-0386-x86-64-linux-borrowed-byte-helpers.md)
- [WIP-0389](WIP-0389-x86-64-linux-strict-utf8-input.md)
