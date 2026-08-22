# WIP-0233: Native local import resolution

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, compiler, and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, source plans, module graph |
| Depends on | WIP-0009, WIP-0018, WIP-0232 |
| Supersedes | Native source plans without import resolution |
| Superseded by | Native dependency imports and cycle validation |

## Summary

Validate canonical local imports against the complete native target-source module set.

After WIP-0232, every selected source has one unique module owner. `TestSourcePlan.w` now performs a second pass over the completely framed plan, parses leading import declarations, rejects self imports, and resolves each import to an exact selected module.

## Accepted import profile

After the module declaration and optional blank lines, a source may carry up to 64 canonical imports:

```text
module pkg.pass;
import pkg.fail;
```

Import names use the same bounded dotted-name grammar as module declarations. Each line requires exact `import`, one ASCII space, semicolon, and LF.

This WIP resolves package-local imports only. The accepted lock has no dependency entries. External module resolution must pair canonical dependency imports with validated lock and archive products rather than treating an absent local module as ambient.

## Validation order

The first source-plan pass validates all framing, paths, UTF-8, module declarations, and module uniqueness. Only after proving the exact plan end does the import pass begin. It may therefore rescan any selected payload without trusting an unchecked future length.

For each import the validator:

1. validates complete dotted-name bytes
2. rejects equality with the importing module
3. scans all selected module declarations for one exact owner
4. rejects when no owner exists

Module uniqueness from WIP-0232 makes resolution singular. The pass allocates no graph or name table.

## Bounds

The runner admits 64 sources and 64 leading imports per source in the accepted profile. Every name comparison stays under 255 bytes and every scan stays inside the 32,768-byte plan. This recovery algorithm favors exact rescans over mutable hash authority.

Cycle rejection and duplicate import-edge rejection remain separate graph products. This WIP establishes only syntax, no self edge, and one local target for each accepted import.

## Evidence

The normal three-module execution fixture remains import-free while preserving byte-identical artifact and report evidence.

A zero-case transport adds `import pkg.fail;` to `pkg.pass`. Native validation resolves the later source against the complete plan and publishes the canonical empty report. A second transport changes the import to absent `pkg.xail`. It rejects before hashing or publication.

Using a zero-case transport isolates package graph validation from artifact compilation. It does not claim native source-to-artifact compilation for the imported fixture.

The runtime archive contains 221,520 bytes with SHA-256 `81b4f9abb142120bd785d12389ea3eb30bc0f3cb3c49db0024f12f2a347bc7ba` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Import parsing starts only after complete plan validation.
- [x] Canonical local imports resolve to exact selected modules.
- [x] Self imports and unresolved imports reject.
- [x] Import and module names share one bounded grammar.
- [x] Validation allocates no graph or name table.
- [x] Resolved and unresolved zero-case fixtures publish the expected outcomes.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Resolve imports during the framing pass

Rejected. Future entry lengths are not yet authoritative.

### Ignore unresolved imports until compilation

Rejected. Package module-graph validity precedes compilation and artifact identity.

### Treat absent modules as external

Rejected. External resolution requires explicit locked package provenance.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0232](WIP-0232-native-source-module-uniqueness.md)
