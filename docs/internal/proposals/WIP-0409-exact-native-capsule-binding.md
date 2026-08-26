# WIP-0409: Exact native capsule binding

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT startup, capsules, capability binding |
| Depends on | WIP-0008, WIP-0026, WIP-0369, WIP-0370, WIP-0376, WIP-0408 |
| Supersedes | Framing-only startup for scalar AOT runtimes |
| Superseded by | None |

## Summary

Bind each x86-64 Linux scalar AOT runtime to one complete verified application capsule. Lowering consumes the root WBC and capsule together. It verifies every WBC, binds the exact root function, checks AOT mode and entry capabilities, then embeds one immutable copy of the canonical capsule in runtime text. Loaded code compares the mapped capsule with that copy before executing one WBC instruction.

The fixed WIP-0376 probe remains framing evidence. It cannot be supplied to the scalar AOT command and is not a release runtime.

## Lowering boundary

`LinuxX8664ScalarAotCompiler.lower` requires owned WBC bytes and an `ApplicationCapsule`. There is no unbound scalar-runtime overload.

Lowering performs these checks in order:

1. Parse canonical capsule framing.
2. Verify and canonically reconstruct every WBC entry.
3. Resolve the declared root WBC and exact qualified entry function.
4. Require AOT runtime mode.
5. Require the supplied WBC bytes to equal the root entry bytes.
6. Validate the closed scalar AOT program.
7. Match root capabilities to the entry shape.
8. Emit machine code and bind the complete canonical capsule bytes.

A parameterless entry requires no application capability. A one-parameter output entry requires exactly `io:stdout/1`. A two-parameter dynamic entry requires sorted `io:stdin/1` and `io:stdout/1`. Missing, extra, reordered, or changed grants reject before machine publication.

The command surface is:

```text
wheeler image runtime-elf-x86-64-aot <root.wbc> \
  --capsule <application.capsule> \
  -o <runtime.bin>
```

The old WBC-only command is removed. Image plans bind the resulting capsule-specific runtime identity.

## Loaded identity check

The entry shim retains locator magic, exact capsule offset, and framing-magic checks. A bound runtime then:

1. Compare the mapped little-endian capsule length with the verified canonical length.
2. Derive an immutable expected-capsule address relative to the instruction pointer.
3. Compare every capsule byte in increasing address order.
4. Branch to status 125 on the first difference.
5. Enter the scalar machine only after complete equality.

The expected copy occupies the read-execute runtime segment. The mapped capsule remains in its read-only segment. The comparison uses no path, image reopen, environment, cache, network, dynamic import, allocator, clock, or locale.

A runtime may bind at most `ElfImage.MAX_RUNTIME_BYTES - 65,536` capsule bytes. This leaves a fixed envelope for entry checks, scalar machine code, and application output under the 16 MiB ELF runtime limit. Larger capsules reject rather than falling back to framing-only startup.

Exact byte equality transfers build-time semantic verification to loaded startup. A changed WBC, receipt, root profile, capability grant, entry descriptor, padding byte, digest, or unrelated capsule entry changes the compared bytes and cannot reach application code. Repository signature trust remains outside this WIP.

## Failure boundary

Malformed framing, a noncanonical WBC, wrong root entry, wrong root WBC bytes, non-AOT mode, capability disagreement, oversized bound capsule, changed mapped length, or any mapped byte mismatch rejects. Lowering failure publishes no runtime. Loaded mismatch exits with status 125 and writes no standard output or standard error. Scalar execution traps retain status 126.

The runtime does not repair a capsule, select a similar entry, trust a matching filename, or hash only the root payload. An attacker that replaces both image code and capsule changes the image and plan identities and remains a repository-signature problem.

## Evidence

`LinuxX8664BoundCapsuleTest.bindsTheCompleteVerifiedCapsuleBeforeExecution` lowers one status-73 root, verifies its plan and ELF, and launches the accepted image once on x86-64 Linux. It then launches one content-damaged capsule and one length-damaged capsule. Each damaged image exits 125 before output. A different root WBC, changed capability grant, and embedded-VM mode reject during lowering.

All scalar AOT launch tests now use capsule-bound runtime text. `ImageCommandTest` supplies the physical capsule during AOT publication, builds the ELF from that exact runtime, verifies it independently, and launches the resulting physical image where supported.

| Product | Identity |
| --- | --- |
| WBC | `c8af845b4cc1722d55e807211f2320fbf83a66a5332537cc57d2171cbf1243f3` |
| capsule | `a0f55d2ba640f4038b4b4fb9bd9fb8517cfc4bd0e98c19782a977af1d57ebe0c` |
| bound runtime | `c550a0d2a1860a96f566263e67b567d2886e511c30190dd6c83faac0b4041e47` |
| native plan | `92df2ecf69b0b18bc7dd9abc2da9257e8ed899ef5b31ef8275936eec75d487a8` |
| unsigned PREV | `88ed49c3fb6b55424aae6acab92271d813f11ce6189b2cdcd066499e97486e34` |

## Acceptance

- [x] Scalar AOT lowering accepts no unbound runtime path.
- [x] Every WBC is verified before runtime publication.
- [x] Root WBC bytes and qualified entry are exact.
- [x] AOT mode and entry capabilities are exact.
- [x] The loaded runtime compares complete canonical capsule bytes.
- [x] Length and content damage fail before scalar execution and output.
- [x] Bound runtime, plan, ELF, and PREV identities include the capsule.
- [x] Physical command and direct API evidence use the same authority.
- [x] Native x86-64 Linux launch covers acceptance and both damage classes.

## Rejected alternatives

### Keep an unbound test overload

Rejected. A callable fallback would remain an executable product path.

### Check only capsule framing and root WBC

Rejected. Receipts, profiles, capabilities, and secondary WBC entries are startup authority too.

### Reopen the executable image

Rejected. Loader-mapped immutable bytes are the input. Paths are not identities.

### Embed only the expected capsule identity text

Rejected. Comparing digest text without an in-process digest implementation proves nothing about mapped bytes.

### Claim repository trust

Rejected. Exact loaded bytes establish plan-bound startup, not signer authorization.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0369](WIP-0369-canonical-application-capsules.md)
- [WIP-0370](WIP-0370-application-capsule-inspection.md)
- [WIP-0376](WIP-0376-x86-64-linux-native-entry-shim.md)
- [WIP-0408](WIP-0408-reversible-scalar-result-slot-aot.md)
