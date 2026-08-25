# WIP-0384: x86-64 Linux constant byte output

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and native maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, AOT lowering, byte output, Linux host services |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0383 |
| Supersedes | Fixed `Wheeler\n` as the only successful AOT output observation |
| Superseded by | None |

## Summary

The x86-64 Linux scalar AOT leaf publishes source-declared constant byte output. An entry may accept one `borrow mut bytes` output parameter, execute bounded `BYTES_SET` instructions, commit one `OUTPUT_LENGTH`, and return a scalar process status. The lowerer retains the exact resulting byte prefix in runtime text, and the Linux shim writes that prefix instead of its loader probe.

This is constant-output AOT. The complete output is independently evaluated before image construction. It admits no input-dependent bytes, output reads, dynamic allocation, helper access to the output owner, multiple output owners, partial host writes, standard error, files, or network effects.

## Accepted output profile

An output-bearing entry has exactly one parameter of type `borrow mut bytes`. Entry locals may contain that borrow and scalar signed or Boolean values. Helpers remain scalar-only and cannot receive, copy, read, or write the output owner.

The profile admits:

- `LOCAL_MOVE` between output-borrow locals.
- `BYTES_SET owner, index, value` with the exact output owner, index 0 through 4,095, and byte value 0 through 255.
- One `OUTPUT_LENGTH owner, length` selecting 1 through 4,096 bytes.
- Zero-filled bytes that were not explicitly written.

Output length 4,096 succeeds. Length 4,097 rejects. The output-bearing entry admits at most 64 locals because canonical source lowering retains one borrow plus scalar index and value temporaries for each write. Local 64 succeeds and local 65 rejects. Helpers and entries without output retain the 32-local profile.

The physical source boundary covers:

```wheeler
module example.hello;

classical class Hello {
  state long status = 0;

  entry void main(borrow mut bytes output) {
    setByte(output, 0, 78);
    setByte(output, 1, 10);
    setOutputLength(output, 2);
    status = 73;
  }
}
```

## Lowering and host write

`ScalarAotProgram` creates one zero-filled 4,096-byte output arena while evaluating the complete entry. It checks every borrow handle, index, byte value, and length commitment. The validated program and public lowering result each own the retained prefix. Caller mutation cannot alter either copy.

`BYTES_SET`, output-borrow moves, and `OUTPUT_LENGTH` need no executable instruction after complete partial evaluation because the profile has no runtime input or mutable external source. `ScalarAotMachine` emits no counterfeit pointer operation. `LinuxX8664EntryShim` embeds the retained prefix adjacent to runtime text, uses a compact length comparison through 127 bytes and a full 32-bit comparison above it, passes the exact address and length to one `write(1, ...)` system call, requires the complete length, and reaches status 125 on a short write.

The existing zero-parameter profile still writes fixed `Wheeler\n` as loader evidence. Output-bearing AOT replaces that probe with application bytes. The maintained 113-byte shim and its identity do not change.

The physical lowering command reports the application-output byte count with runtime, WBC, and process identities. It publishes only after complete WBC validation and output evaluation.

## Failure boundary

Reject missing or repeated output-length commitment, zero length, length 4,097, index 4,096, negative index, byte 256, nonbyte owner, helper output access, a second entry parameter, local 65, uninitialized scalar input, malformed output opcode, and every existing scalar-profile failure. Reject before runtime bytes or output files are published.

The backend does not infer output from source text or from the capsule resource table. Canonical WBC remains the sole semantic input.

## Evidence

`LinuxX8664ScalarAotCompilerTest` lowers exact `Native Wheeler\n`, checks owned returned output, changes one byte and requires a distinct runtime identity, admits 4,096 zero bytes, rejects lengths zero and 4,097, admits an output entry with 64 locals, and rejects local 65. Its complete ELF launch uses application output rather than the fixed probe.

`ImageCommandTest` compiles physical source containing status state, signed and void helpers, assertions, a bounded loop, seven `setByte` operations, and `setOutputLength`. The command reports seven application bytes, builds and verifies the capsule ELF, and expects exact `Native\n` on Linux.

An independent Alpine 3.22 kernel under x86-64 emulation launched the 6,400-byte output fixture. It wrote exact `Native Wheeler\n` and returned exact status 73. The same kernel launched the 9,264-byte terminal fixture, retained exactly 4,096 zero bytes through the wide write-count path, and returned status 73.

The fixture identities are:

| Product | Identity |
| --- | --- |
| WBC | `4067db8bc3183d6f6660b94d87f50d7783614b0a6fd1e3dfc1c4ec5c1802af6f` |
| runtime | `e32cc553571867b47af50dde8e17b540e5a30a5c70977ca730ac1883e233b6b0` |
| capsule | `07cc6a2e0963576d709935e728796c0a4a2cc3708b70876b79ff1d71d8d56ac4` |
| native plan | `985b8ea42b578a17e5ebbd2b4ac42f83915f2817bc7b49c99f2753cf242a40d0` |
| unsigned PREV | `ce0d59b98dc23ffe5031b3c6fc2fc6cdf3aeafbbdee2a4f12cd8ccd5edfb06c2` |

The 4,096-byte terminal identities are:

| Product | Identity |
| --- | --- |
| WBC | `c4f4f87b5bf96b35e3b1ab14ed41da2d6e973e76c6adffa8f132fae71ddf6c3b` |
| runtime | `a2bd9caea1da0f2658a806d5366719ef1f3a298423774667446a80d6269795ab` |
| capsule | `3a0c4863715d96bc5def78ea09a931833f6919af555e0682765e62a7dc6c3204` |
| native plan | `121d19c1577d049814adb6816384a1864f8c556a796d4407b3127bcfcb5a8c62` |
| unsigned PREV | `7ef0c126017379d890fc82901a4f1d9199d04658159eee024079b6c01c89a693` |

## Acceptance

- [x] One output parameter owns one bounded zero-filled byte arena.
- [x] Every byte write, index, value, and length validates independently.
- [x] Output length 4,096 succeeds and 4,097 rejects.
- [x] Output-entry local 64 succeeds and 65 rejects.
- [x] Returned output and runtime arrays are owned.
- [x] Native stdout contains application bytes rather than the fixed probe.
- [x] Short writes retain malformed-image status 125.
- [x] Physical source and independent Linux loader evidence agree.

## Rejected alternatives

### Parse output literals from source

Rejected. Source spelling is not the native backend input. Only canonical WBC writes establish output bytes.

### Materialize a fake native output pointer

Rejected. No runtime instruction needs a pointer after complete bounded partial evaluation. An invented address would add semantics rather than preserve them.

### Append application bytes after the fixed probe

Rejected. A successful process has one stdout byte sequence. The output-bearing entry replaces the probe.

### Widen output to the launch-I/O maximum immediately

Rejected. The maintained machine encoding and evidence boundary is 4,096 bytes. Larger output needs a wider retained arena and new terminal evidence.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0383](WIP-0383-x86-64-linux-void-helper-calls.md)
