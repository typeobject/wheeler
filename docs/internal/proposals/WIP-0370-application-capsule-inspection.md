# WIP-0370: Application capsule inspection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, bytecode, package, native, and tooling maintainers |
| Created | 2026-08-24 |
| Updated | 2026-08-24 |
| Area | Native bootstrap, capsule inspection, bytecode verification, root binding |
| Depends on | WIP-0008, WIP-0026, WIP-0369 |
| Supersedes | Ad hoc capsule dumps and partial WBC checks |
| Superseded by | None |

## Summary

Add one nonexecuting runtime verifier and one command boundary for schema-1 application capsules.

`wheeler image inspect` validates complete capsule framing and emits deterministic JSON for the root, semantic profiles, required capabilities, package receipts, and entries. `wheeler image verify` performs the same transport check, then parses, verifies, and canonically re-encodes every WBC before binding the declared root function to the startup WBC.

Inspection reports authenticated framing. Verification adds executable bytecode structure and root binding. Neither command executes entry code, loads a native provider, resolves a package, follows an adjacent path, extracts data, or grants a capability.

## Runtime authority

`ApplicationCapsuleVerifier` belongs to the runtime, not the command. It consumes either exact capsule bytes or an already framed `ApplicationCapsule`. For every WBC entry it:

1. invokes the canonical bytecode reader and verifier.
2. re-encodes the resulting program with the canonical writer.
3. requires byte-for-byte equality with the embedded entry.
4. retains the program under its exact capsule logical name.

The verifier then selects the WBC named by the root descriptor. That program's bytecode entry function must have the root descriptor's exact qualified name. A missing program, different entry, malformed secondary WBC, noncanonical WBC, unsupported required section, failed bytecode proof, bad instruction, or type error rejects the complete capsule result.

The returned program map follows canonical capsule entry order and is immutable. The result carries the already verified capsule and exact root program. Only the verifier can construct that result. Callers receive no fallback program and cannot substitute a program by package, module, or function name.

The runtime verifier does not interpret resource, proof, provider, provenance, or package-receipt payloads. Their format authorities remain separate. Native startup must compose those checks before execution.

## Command boundary

```text
wheeler image inspect <application.capsule>
wheeler image verify <application.capsule>
```

The command accepts one physical nonsymlink file. It opens with no-follow semantics, admits at most the WIP-0369 33,554,432-byte bound, reads the initially observed byte count through one channel, and checks for shrink or growth before parsing. A path replacement cannot redirect the open channel. A directory, link, oversized file, short read, or growing file rejects.

`inspect` emits one deterministic JSON object. The object includes capsule identity and bytes, every root profile identity, runtime mode, capabilities, complete receipt evidence, and each entry's kind, name, content identity, bytes, alignment, and flags. JSON quoting handles controls and Unicode without changing capsule bytes. Presentation bytes do not enter capsule identity.

`verify` emits one line only after every WBC and the root bind. The line contains capsule identity, entry count, and verified WBC count. Failure publishes no success line.

The command reads no package cache, repository, lock beside the capsule, current project, executable path, environment value, locale, clock, network endpoint, random source, or configuration file.

## Failure boundary

Inspection rejects every WIP-0369 framing failure before rendering. It cannot turn a damaged entry into plausible metadata because entry hashes and canonical reconstruction precede output.

Verification rejects all inspection failures plus malformed or noncanonical WBC, unsupported bytecode profiles, invalid executable semantics, and root-function disagreement. A well-framed capsule with malformed WBC may be inspected for audit, but it cannot be reported as verified. This distinction is deliberate and visible in the command name.

No current result claims that native segment permissions are safe, a platform ABI matches the host, a provider import closure is complete, a package receipt is authorized, proof payloads are valid, or an entry can execute with its requested capabilities. Those checks remain required for native startup.

## Evidence

`ApplicationCapsuleVerifierTest` constructs canonical WBC directly through the bytecode writer. It verifies two WBC entries, preserves canonical map order, binds the root, and proves the returned map immutable. A malformed secondary WBC and a different qualified root reject.

`ImageCommandTest` builds a physical capsule around stage-0 output. Repeated inspection produces identical JSON containing root, receipt, and resource identities. Verification checks the WBC and emits the exact success line. Separate cases reject a wrong root, malformed WBC, damaged capsule content, a directory, and invalid command shape. Inspection of the malformed-WBC fixture succeeds only after its capsule framing and content digest verify.

Focused runtime and command suites complete in seconds. They perform no execution and no external I/O beyond bounded temporary physical files.

## Acceptance

- [x] One runtime authority verifies every WBC and the exact root binding.
- [x] Canonical WBC re-encoding must equal embedded bytes.
- [x] Verified programs retain canonical names and immutable order.
- [x] Inspection renders complete root, receipt, and entry metadata deterministically.
- [x] Verification publishes only after complete framing, WBC, and root checks.
- [x] Physical input is bounded, nonsymlink, no-follow, and checked for change.
- [x] Inspecting malformed WBC does not claim bytecode verification.
- [x] Neither path executes, resolves, loads, extracts, or grants authority.

## Rejected alternatives

### Verify only the startup WBC

Rejected. Secondary executable entries remain runtime-loadable or inspectable members of the closed image. One malformed member invalidates the claimed capsule verification.

### Let inspection silently verify what it recognizes

Rejected. Partial semantic checks produce an ambiguous green result. Inspection authenticates framing. Verification authenticates every current WBC and root.

### Put WBC verification in the command

Rejected. Native startup needs the same authority without terminal or filesystem policy. The runtime owns verification and the command only publishes its result.

### Decode directly from a path throughout verification

Rejected. Reopening permits replacement and path-dependent results. The command reads one bounded physical file once, then all authorities consume retained bytes.

### Execute the entry as a verification side effect

Rejected. Verification must remain safe for audit tooling and hostile capsules. Execution requires platform, provider, capability, proof, and startup policy that this WIP does not supply.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0369](WIP-0369-canonical-application-capsules.md)
- [WIP-0371](WIP-0371-embedded-application-capsule-startup.md)
