# WIP-0217: Runtime test runner authority

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and conformance maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, runtime ownership, conformance boundaries |
| Depends on | WIP-0018, WIP-0202, WIP-0216 |
| Supersedes | Conformance-owned two-case scheduling and reduction |
| Superseded by | None |
| Follow-up | WIP-0218 counted descriptor scheduling |

## Summary

Move the complete WIP-0216 two-case runner from `wheeler.conformance` into the canonical runtime library.

`wheeler.runtime.testing.runners.two_case_test_runner` now owns descriptor validation, source and case identity derivation, shard selection, fresh artifact execution, report reduction, summary reduction, and atomic product composition. The conformance executable calls one runtime operation and publishes its returned length.

## Boundary

The canonical operation is:

```text
runTwoCaseTests(input, output) -> 39
```

`input` is the WIP-0216 bounded descriptor frame. `output` must hold the 32-byte report identity and seven-byte summary. The operation returns only after both reducers succeed and every owned allocation is dropped.

The conformance entry point contains no parser, identity code, scheduler, diagnostic policy, or reducer. Its sole publication action is `setOutputLength` after the runtime operation returns.

## Source layout

The runtime testing directory already carries ten public semantic modules. Runner composition therefore lives under `runtime/testing/runners`, keeping source concerns and the ten-file directory limit explicit.

`RuntimeLibrary.w` imports the runner module. Package closure checks therefore compile this authority as part of every runtime archive rather than only through the conformance fixture.

## Evidence

The existing independent descriptor-frame test now compiles the runtime runner and the thin conformance publisher as separate modules. Serial, sharded, verifier-failure, assertion-failure, interpreter-failure, empty-report, and malformed-input products remain byte-identical.

Package checks prove the runtime export closure owns every imported semantic operation. Source policy proves the split directory remains bounded.

The runtime archive contains 188,107 bytes with SHA-256 `2136cbebbfc9f043d059f82a0ac3481b6b2b362b376ff8dd42c68d9f35f27cba` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive shrinks to 131,110 bytes with SHA-256 `332db489cf2bdac3d887123cff545c7a93a6d387f12d699421d02f608049aa5f`. Its lock names the runtime archive exactly and retains root manifest identity `8e8fe8757e7729a9399b59b2d7ec53170b8828434e9e0268405a1652c3bf3048`.

## Acceptance

- [x] Runtime owns complete two-case scheduling and reduction.
- [x] Conformance publishes one returned runtime product.
- [x] Runtime package closure imports the runner authority.
- [x] No duplicate parser or scheduler remains in conformance.
- [x] Existing report and failure identities remain byte-identical.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Leave orchestration in conformance

Rejected. Executable fixtures must not become a second semantic runtime.

### Copy the implementation into runtime

Rejected. One implementation moved. The conformance copy was replaced, not retained.

### Publish output length inside the library

Rejected. Host output publication belongs to the executable boundary. The runtime operation writes an all-or-nothing product and returns its length.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0202](WIP-0202-runtime-artifact-execution-authority.md)
- [WIP-0216](WIP-0216-native-runner-descriptor-frames.md)
- [WIP-0218](WIP-0218-bounded-native-descriptor-runner.md)
