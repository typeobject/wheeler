# WIP-0371: Embedded application capsule startup

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, bytecode, native, package, and security maintainers |
| Created | 2026-08-24 |
| Updated | 2026-08-24 |
| Area | Native bootstrap, embedded VM, capsule startup, capabilities, host I/O |
| Depends on | WIP-0008, WIP-0026, WIP-0368, WIP-0369, WIP-0370 |
| Supersedes | Unbound launcher-to-WBC execution |
| Superseded by | None |

## Summary

Add the embedded-VM startup authority that consumes loader-mapped capsule bytes, exact launch policy, and explicit host I/O.

`ApplicationCapsuleLauncher` checks the complete capsule identity, every semantic profile identity, runtime mode, capability grant, payload classes, all WBC, exact root function, program kind, and entry I/O shape before one execution. It accepts bytes rather than a path and returns a result bound to the capsule, package instance, target, and qualified entry.

This WIP implements format-neutral startup after a native adapter has located read-only capsule bytes. It does not implement ELF, Mach-O, or PE location, page-permission checks, a host ABI shim, provider loading, external proof payloads, signing, or native process exit.

## Launch context

A launch context carries:

- expected capsule identity.
- runtime, bytecode, proof, target, platform-ABI, and execution-limit identities.
- the complete sorted capability grant.
- no input, strict-UTF-8 input, or binary byte-view input mode.
- one owned input byte string when the mode requires it.
- absent output or one bounded mutable output capacity.

All identities are lowercase SHA-256. Capabilities are sorted, distinct canonical names and admit at most 32 entries. Input and output each admit at most 16,777,216 bytes. The context owns an input copy and returns copies from its accessor.

The native image plan and runtime startup code construct this context from already verified image, platform, and launch-policy records. Startup never derives it from environment variables, command-line spelling, current directory, executable path, package cache, locale, clock, random state, or network lookup.

## Admission order

Startup performs these checks in order:

1. Parse and verify complete WIP-0369 capsule framing.
2. Match the external capsule identity and all six root profile identities.
3. Require embedded-VM mode and exact equality between requested and granted capabilities.
4. Reject native-provider and external-proof entries until their independent verifiers exist.
5. Invoke WIP-0370 verification for every WBC and the exact qualified root.
6. Require a classical root program.
7. Derive host effects from the verified entry signature and match them to capabilities and launch I/O.
8. Construct one fresh runtime and execute the root once.
9. Publish one capsule-bound execution result after normal halt.

A failure at any earlier step creates no runtime and executes no instruction. A trap creates no successful `CapsuleExecution`.

## Entry effects

The first startup profile admits four entry shapes:

| Parameters | Required capabilities | Launch I/O |
| --- | --- | --- |
| none | none | no input or output |
| `borrow utf8` | `io:stdin/1` | strict UTF-8 input |
| `borrow byteview` | `io:stdin/1` | binary input |
| `borrow mut bytes` | `io:stdout/1` | bounded output |

One input parameter may precede one output parameter. That duplex shape requires both capabilities in canonical order. Startup initializes no other entry parameter.

The signature determines UTF-8 versus binary input. A launch-mode claim cannot reinterpret bytes. Output exists only when the entry ends in one mutable byte loan and the context supplies capacity. Extra capabilities reject rather than remaining dormant. Missing capabilities reject before runtime construction.

Standard error, process arguments, resource handles, files, directories, deadlines, targets, environment, providers, and process exit remain outside this first entry binder. Adding one requires an explicit typed entry form and profile update.

## Payload policy

WBC proof certificates remain inside the canonical bytecode verifier's authority. Separate capsule `PROOF` entries reject because no proof-payload descriptor binds them to a checker. `NATIVE_PROVIDER` entries reject because no provider closure and platform import verifier exists. Resources and provenance remain immutable inert payloads. The first launcher does not turn their names into capabilities.

AOT capsules reject. A later AOT launcher must retain exact WBC verification and demonstrate semantic equivalence before selecting native code.

## Result

Successful startup returns:

```text
capsule identity
root package instance
selected target
qualified entry function
runtime execution result
```

The runtime result owns globals, measurements, target jobs, transition count, and output bytes. Only the launcher can construct the capsule-bound wrapper. Callers cannot manufacture a successful launch record through the public API.

## Failure boundary

Reject malformed framing, changed capsule identity, profile disagreement, AOT mode, capability disagreement, malformed or noncanonical WBC, root mismatch, nonclassical programs, unsupported payload kinds, unsupported parameters, input-mode disagreement, absent or extra input, absent or extra output, and I/O beyond the fixed bound.

Exact profile identity matching is not semantic profile decoding. The native adapter must first verify the records that produced those identities. This launcher proves that mapped bytes and runtime policy refer to the same records and that the admitted entry consumes only the first supported effects.

## Evidence

`ApplicationCapsuleLauncherTest` executes one no-authority state update and observes exactly two transitions. Independent cases execute strict-UTF-8 input, binary input, output, and duplex input/output entry shapes. They check returned output ownership and capsule, package, target, and function binding.

Negative cases change capsule identity, runtime profile, capability grant, and input mode. AOT mode, an unverified provider payload, and capability drift from a no-argument entry reject before execution.

`ApplicationCapsuleExampleTest` now compiles a physical Wheeler module, builds and verifies its capsule, binds the capsule identity into a native image plan, launches the no-authority root from retained bytes, and checks normal halt. It reads no adjacent Wheeler artifact.

## Acceptance

- [x] Startup consumes retained capsule bytes and explicit policy, never a path.
- [x] Capsule and all semantic profile identities match before WBC work.
- [x] Capability requests and grants are exact.
- [x] Every WBC and the exact qualified root verify before runtime construction.
- [x] Only embedded classical execution is admitted.
- [x] No-input, UTF-8, binary, output, and duplex entry shapes are exact.
- [x] Unverified proof and provider payloads reject.
- [x] One successful launch executes one fresh root and returns capsule-bound evidence.

## Rejected alternatives

### Let the VM infer grants from supplied buffers

Rejected. A byte array is data, not authority. The capsule request, host grant, entry signature, and supplied object must all agree.

### Permit capability supersets

Rejected. Dormant ambient authority complicates audit and future binder changes. The launcher receives only the exact grant visible to this entry.

### Start before checking secondary WBC

Rejected. The capsule is one closed executable object. WIP-0370 verifies every WBC before the first instruction.

### Ignore unknown payload kinds

Rejected. A provider or proof entry claims semantics outside framing. Startup fails until the matching verifier is composed.

### Reopen the executable or capsule by path

Rejected. Native adapters hand startup the already located mapped range. Path lookup permits replacement and imports ambient namespace state.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0368](WIP-0368-platform-abi-and-native-image-identities.md)
- [WIP-0369](WIP-0369-canonical-application-capsules.md)
- [WIP-0370](WIP-0370-application-capsule-inspection.md)
