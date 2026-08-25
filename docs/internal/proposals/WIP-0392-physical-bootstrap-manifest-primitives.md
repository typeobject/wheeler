# WIP-0392: Physical bootstrap manifest primitives

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Self-hosting, bootstrap manifests, physical source closure |
| Depends on | WIP-0007, WIP-0391 |
| Supersedes | Profile and assertion ownership in the mixed manifest-syntax module |
| Superseded by | None |

## Summary

Two canonical bootstrap manifest primitives have focused physical source owners. `ManifestProfile.w` classifies profile-name bytes. `ManifestAssertions.w` owns fail-closed metadata assertions. The Wheeler recovery compiler accepts each complete file and emits the same canonical library bytes as stage 0.

`ManifestSyntax.w` retains exact fragment consumption and quoted identity parsing. It no longer owns unrelated profile policy or assertion policy. Consumers import each required primitive explicitly.

## Profile ownership

`BootstrapManifestProfile.profileByte` answers whether a scalar belongs to the canonical profile-name alphabet under the caller's punctuation policy. It admits ASCII digits and letters. Hyphen, dot, and underscore return `allowPunctuation`. Other values return the caller's `valid` fallback after ordered range checks.

The function has no state, allocation, host effect, import, loop, or hidden configuration. Signed scalar input and both Boolean policy inputs remain explicit.

Three production consumers name this authority:

- `BootstrapModuleManifestParser` validates the compiler closure profile.
- `NativeBootstrapManifestIdentity` validates fixed-point evidence.
- `NativeCompilerOptionsIdentity` validates compiler options.

## Assertion ownership

`BootstrapManifestAssertions.requireMetadata` takes one Boolean condition. A false condition traps before publication. The old shared byte-view parameter was unused and is gone. Callers derive each condition from explicit retained transport bytes before invoking the guard.

Compiler closure planners, schedulers, symbol owners, archive readers, and conformance identity parsers import this owner directly. Files that also consume exact metadata fragments retain a separate `manifest_syntax` import. Files that only assert metadata no longer depend on the loop-bearing syntax owner.

Neither old owner re-exports or wraps the moved functions. Duplicate policy would turn one manifest contract into two opinions.

## Physical compilation

The profile owner is a dependency-free entryless library with one public three-parameter Boolean helper. Signed equality guards return the prior punctuation parameter through WIP-0391's typed Boolean-local result column. Ordered guards return literal verdicts. The final result returns the prior fallback parameter.

The assertion owner is a dependency-free entryless library with one public void helper. It accepts the canonical Boolean parameter type and emits the exact assertion instruction shape.

For each owner, the recovery compiler parses complete physical bytes and publishes one function plus the canonical `$library` halt entry. No declaration projection, copied constants, host-side source rewrite, or fixture-only body enters this evidence.

## Closure accounting

The physical compiler closure contains 379 modules and 1,883 imports. Its canonical manifest contains 177,378 bytes. Native validation halts after exactly 73,964,449 committed transitions.

The former 74,000,000 host guard rejected the enlarged complete closure before it halted. The evidence guard is now 75,000,000 transitions. This changes no Wheeler semantic limit. It leaves a bounded host cancellation margin above the exact retained result.

Wheeler-native SHA-256 consumes the current manifest in exactly 33,948,356 transitions and matches the independent host digest.

## Failure boundary

Reject:

- A malformed module or class declaration.
- A Boolean or unknown signed profile guard source.
- A signed value returned through a Boolean profile result arm.
- An assertion with a non-Boolean condition.
- A result name declared after its use.
- A duplicate or overlapping statement identity.
- Any source-local index outside the 256-slot recovery window.
- Any partial or noncanonical artifact.

Metadata fragment loops and quoted identity loops remain in `ManifestSyntax.w`. This WIP makes no claim that those bodies compile through the minimal recovery parser.

## Evidence

`NativeCompilerManifestProductExampleTest` reads both checked-in sources. Its focused tests compile each source through the physical Wheeler recovery compiler and through stage 0, compare complete artifacts, and require the qualified production function plus canonical `$library` entry.

Bootstrap feature, manifest, module, compiler-limit, compiler-options, toolchain, and artifact-set identity examples execute the explicit assertion dependency over accepted and rejected transports. Manifest and options examples also execute the profile dependency. `NativeBootstrapModulesIdentityExampleTest` validates the complete enlarged closure. `NativeSha256ExampleTest` hashes the exact enlarged manifest.

## Acceptance

- [x] Profile-byte policy has one physical source owner.
- [x] Metadata assertion policy has one physical source owner.
- [x] The unused assertion transport parameter is deleted.
- [x] Every production consumer imports the required owners explicitly.
- [x] The mixed manifest-syntax owner contains neither moved policy.
- [x] Both complete owners compile byte for byte through Wheeler and stage 0.
- [x] Qualified function and inert library entry identities remain exact.
- [x] Manifest parsing and options parsing preserve accepted behavior.
- [x] Complete closure and SHA-256 evidence are bounded and exact.

## Rejected alternatives

### Keep the functions in `ManifestSyntax.w`

Rejected. Two unrelated bounded loops prevent that mixed module from proving already-supported straight-line bodies.

### Copy the functions into test source

Rejected. A transcription proves the transcription. Physical evidence must consume checked-in production bytes.

### Re-export from the old owner

Rejected. Forwarding shims preserve obsolete ownership and add dependencies without semantics.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0391](WIP-0391-boolean-local-equality-guard-returns.md)
