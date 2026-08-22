# WIP-0195: Native test-case identity

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, case identity, Java-free execution |
| Depends on | WIP-0018, WIP-0194 |
| Supersedes | None |
| Superseded by | WIP-0197 runtime library ownership |

## Summary

Derive profile-2 test-case identities inside Wheeler.

`TestCaseIdentity.w` reproduces stage 0's `wheeler.test-case/1` SHA-256 transcript from the package manifest identity, complete selected case name, and source identity. `NativeTestCaseIdentity.w` publishes its raw 32-byte digest through the conformance boundary.

WIP-0194 can consume the lowercase hexadecimal form of that digest for deterministic shard assignment. Discovery, compilation, execution, and report reduction remain separate WIP-0018 work.

## Input

The executable accepts one bounded frame:

| Offset | Width | Product |
| ---: | ---: | --- |
| 0 | 64 | lowercase hexadecimal manifest identity |
| 64 | 64 | lowercase hexadecimal source identity |
| 128 | 2 | little-endian case-name byte length |
| 130 | 1..255 | complete case-name bytes |

The physical input length must equal 130 plus the declared name length. Identity fields accept exactly lowercase hexadecimal. The case name is retained as raw bytes because the compiler and package graph already own its source spelling.

## Transcript

Each field uses an eight-byte big-endian length followed by its bytes. Field order is fixed:

1. `wheeler.test-case/1`
2. manifest identity text
3. complete case name
4. source identity text

The transcript contains 179 plus the case-name byte length bytes. SHA-256 hashes only that active prefix of a fixed 434-byte private buffer.

## Bounds

Case names contain at most 255 bytes. Private storage owns 1,522 bytes in four allocations: the maximum transcript, eight hash words, sixty-four schedule words, and sixty-four constant words.

Hash work spans at most seven 64-byte blocks. Existing SHA-256 bounds remain unchanged.

## Failure behavior

Malformed identity text, an empty or oversized case name, a truncated frame, trailing input, the wrong output capacity, or exhausted private storage traps before output length changes.

The transcript and hash state remain invocation-owned. No partial digest becomes authoritative.

## Package boundary

`wheeler.runtime` owns derivation under WIP-0197. `wheeler.conformance` exports the `nativetestcaseidentity` deployable boundary. Neither operation reads a source tree, lock, environment, locale, clock, random source, or network state.

## Evidence

`NativeTestCaseIdentityExampleTest` computes the stage-0 transcript independently with `MessageDigest` and compares all 32 bytes.

Fixtures cover a bare target, a qualified parameterized case name, and the maximum 255-byte case name. Uppercase identity text, an empty case name, and trailing bytes trap before publication.

The conformance archive contains 124,908 bytes with SHA-256 `f14cdd82914f76d040a45f52fd508affc9852b7be8777f00b19cbdc3c0dea9f4`. Its schema-3 lock binds root manifest identity `707f401d5b28dac9abd371b8cc60547ec7f86429de7fa25f40df633bde5967fc`.

## Acceptance

- [x] Wheeler reproduces the profile-2 stage-0 case digest byte for byte.
- [x] Every transcript length uses canonical eight-byte big-endian encoding.
- [x] The complete manifest, name, and source fields participate.
- [x] Maximum-length names hash without widening the profile.
- [x] Malformed frames publish no digest.
- [x] Focused differential evidence passes.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Hash decoded identity octets

Rejected. Stage 0 binds the lowercase hexadecimal field text.

### Let the host construct the transcript

Rejected. Framing is part of the semantic identity.

### Publish hexadecimal output

Rejected. The raw digest is the smallest native product. Presentation belongs at the caller boundary.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0194](WIP-0194-native-test-shard-assignment.md)
- [WIP-0197](WIP-0197-runtime-test-selection-authority.md)
- [Package testing reference](../../public/reference/packages.md#tests)
