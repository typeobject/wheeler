# WIP-0376: x86-64 Linux native entry shim

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and platform maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, Linux entry, ELF locator, host services |
| Depends on | WIP-0008, WIP-0026, WIP-0368, WIP-0372, WIP-0373 |
| Supersedes | None |
| Superseded by | None |

## Summary

The first maintained native runtime text enters through the x86-64 Linux loader. It finds the WIP-0372 locator relative to its instruction pointer, checks the locator and mapped capsule framing magics, writes one fixed probe through standard output, and exits through the Linux process service.

This is the platform entry and locator slice. It is not the embedded VM. It does not verify capsule digests, decode WBC, bind capabilities, allocate runtime state, or call the root. WIP-0371 remains the format-neutral startup authority. WIP-0384 lets a completely verified constant-output AOT entry replace the probe with application bytes. WIP-0385 lets an input-dependent AOT body own bounded standard-input and standard-output calls. That partial evaluation does not satisfy embedded startup.

## Contract

`LinuxX8664EntryShim.runtimeText()` returns one owned 113-byte position-independent text image. The text has no relocation, symbol, dynamic import, writable data, stack input, argument input, environment input, path lookup, clock, random source, or network access.

Entry assumes the loader mapped a canonical WIP-0372 ELF image. The shim computes the locator address from the fixed ELF runtime and locator file offsets. It then:

1. Check the eight-byte `WHLLOC01` locator magic.
2. Read the capsule file offset from the fixed locator field and require its exact page-aligned value.
3. Derive the image base without consulting a process path.
4. Check the mapped eight-byte `WHLCAP` schema-1 framing magic.
5. Issue one bounded `write(1, "Wheeler\n", 8)` system call.
6. Require the complete eight-byte write.
7. Issue `exit(42)`.

A bad locator, bad capsule framing value, or short write reaches `exit(125)`. Framing failure occurs before output. Linux system calls are the first two host-shim leaves for WIP-0368 `stdout-write` and `process-exit`. Their raw register ABI remains private to this target shim.

The physical command publishes those exact bytes atomically as nonexecutable runtime input:

```text
wheeler image runtime-elf-x86-64 -o <runtime.bin>
```

It accepts no input file, configuration, or target inference. Existing links and nonregular output leaves reject under the shared physical publication boundary.

The runtime digest is:

```text
220690e44353796c912558f5fddd1680e4828244b899083392b1a0406d0aa954
```

The canonical fixture ELF has unsigned PREV:

```text
34c250443a86328faebda523d466779c64ce1d259d21160b4fc217e9718b0a8c
```

The Java stage-0 assembler writes explicit x86-64 instructions and patches only checked relative displacements. It consumes the canonical ELF and capsule magic authorities instead of copying their values. No external assembler or linker participates in runtime construction.

## Ownership

`ElfImage` publishes the stable locator and runtime file coordinates needed by mapped entry code. `ApplicationCapsule` publishes an owned copy of its framing magic. Neither exposes mutable canonical state.

`LinuxX8664EntryShim` owns target instruction construction and host-call mapping. `ElfImage` still owns headers, segments, permissions, locator framing, plan bindings, canonical rebuilding, and unsigned PREV. `ApplicationCapsuleVerifier` and `ApplicationCapsuleLauncher` still own executable capsule semantics.

A process exit proves loader entry and host-shim control transfer. It does not prove WBC semantics. Documentation and progress records must retain that distinction.

## Failure boundary

The text rejects bad mapped locator or capsule framing before the successful probe. It has no recovery path and publishes no artifact. A short standard-output write is failure even when the kernel wrote a prefix.

This slice deliberately relies on the canonical image precondition for segment ranges, locator bounds, plan identity, capsule identity, and read-only permissions. Complete in-process range and identity validation belongs in the next startup slice. The probe cannot become a release runtime.

## Evidence

`LinuxX8664EntryShimTest` checks byte identity, returned ownership, exact size, canonical ELF construction, runtime entry offset, and read-only capsule placement. `ImageCommandTest` publishes and replaces one physical runtime leaf, checks exact bytes and identity, builds and verifies a capsule image from that leaf, and launches the complete command-produced ELF on x86-64 Linux. It retains atomic-output rejection behavior. On an x86-64 Linux host it launches the complete ELF through the kernel, requires exact `Wheeler\n` output and status 42, separately damages locator magic, capsule offset, and capsule magic, relaunches each image, and requires no output and status 125. Other hosts skip only the OS-launch case.

Independent assembly and disassembly reproduce all 113 bytes. The complete runtime contains no relocation or imported symbol.

## Acceptance

- [x] Runtime text is deterministic, owned, position independent, and import free.
- [x] Entry locates the mapped capsule without a path, environment, cache, or adjacent file.
- [x] Locator and capsule framing failures precede successful output.
- [x] Standard-output completion and process exit use bounded fixed target calls.
- [x] Physical command publication is atomic and returns the generated identity.
- [x] Canonical ELF construction and verification retain the exact runtime bytes.
- [x] Native x86-64 Linux launch evidence covers success and damaged framing.
- [x] The implementation makes no WBC execution or complete startup claim.

## Rejected alternatives

### Reopen the executable

Rejected. Process paths, `/proc`, current directories, replacement races, and adjacent files are outside the startup authority.

### Call libc

Rejected. The first entry leaf needs only two fixed Linux services. A dynamic loader and C runtime would add undeclared imports without adding Wheeler semantics.

### Claim the probe as an embedded VM

Rejected. Two magic checks do not authenticate identities or bytecode. The probe exists to establish loader and platform mechanics before the semantic runtime replaces it.

### Check only successful launch

Rejected. A fixed exit stub can launch while ignoring the capsule. Damaged mapped framing must take a distinct no-output failure path.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0368](WIP-0368-platform-abi-and-native-image-identities.md)
- [WIP-0371](WIP-0371-embedded-application-capsule-startup.md)
- [WIP-0372](WIP-0372-canonical-elf-capsule-images.md)
- [WIP-0373](WIP-0373-physical-elf-image-command.md)
- [WIP-0384](WIP-0384-x86-64-linux-constant-byte-output.md)
- [WIP-0385](WIP-0385-x86-64-linux-dynamic-byte-io.md)
