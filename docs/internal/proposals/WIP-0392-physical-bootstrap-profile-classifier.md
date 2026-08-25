# WIP-0392: Physical bootstrap profile classifier

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Self-hosting, bootstrap manifests, physical source closure |
| Depends on | WIP-0007, WIP-0391 |
| Supersedes | Profile-byte ownership in the mixed manifest-syntax module |
| Superseded by | None |

## Summary

The canonical bootstrap profile-byte classifier has one physical source owner at `compiler/closure/syntax/ManifestProfile.w`. The Wheeler recovery compiler accepts that complete file and emits the same canonical library bytes as stage 0.

`ManifestSyntax.w` retains metadata assertions, exact fragment consumption, and quoted identity parsing. It no longer owns unrelated profile policy. Consumers import the profile owner explicitly.

## Ownership

`BootstrapManifestProfile.profileByte` answers one question: whether a scalar belongs to the canonical profile-name alphabet under the caller's punctuation policy. It admits ASCII digits and letters. Hyphen, dot, and underscore return `allowPunctuation`. Other values return the caller's `valid` fallback after the ordered range checks.

The function has no state, allocation, host effect, import, loop, or hidden configuration. Signed scalar input and both Boolean policy inputs remain explicit.

Three production consumers name the new authority:

- `BootstrapModuleManifestParser` validates the compiler closure profile.
- `NativeBootstrapManifestIdentity` validates fixed-point evidence.
- `NativeCompilerOptionsIdentity` validates compiler options.

The old module does not re-export or wrap the function. Duplicate policy would turn one alphabet into two opinions.

## Physical compilation

The owner is a dependency-free entryless library with one public three-parameter Boolean helper. Signed equality guards return the prior punctuation parameter through WIP-0391's typed Boolean-local result column. Ordered guards return literal verdicts. The final result returns the prior fallback parameter.

The recovery compiler parses the complete physical bytes, resolves both typed result sources, emits one function plus the canonical `$library` halt entry, and publishes only after byte-for-byte comparison with stage 0.

No declaration projection, copied constants, host-side source rewrite, or fixture-only function body enters this evidence.

## Closure accounting

The physical compiler closure now contains 378 modules and 1,882 imports. Its canonical manifest contains 177,065 bytes. Native validation halts after exactly 74,049,522 committed transitions.

The former 74,000,000 host guard rejected the enlarged complete closure before it halted. The evidence guard is now 75,000,000 transitions. This changes no Wheeler semantic limit. It only leaves a bounded host cancellation margin above the exact retained result.

Wheeler-native SHA-256 consumes the new manifest in 33,887,070 transitions and matches the independent host digest.

## Failure boundary

Reject:

- A malformed module or class declaration.
- A Boolean or unknown signed guard source.
- A signed value returned through a Boolean result arm.
- A result name declared after its use.
- A duplicate or overlapping statement identity.
- Any source-local index outside the 256-slot recovery window.
- Any partial or noncanonical artifact.

Metadata fragment loops and quoted identity loops remain in `ManifestSyntax.w`. This WIP makes no claim that those bodies compile through the minimal recovery parser.

## Evidence

`NativeCompilerManifestProductExampleTest.compilesPhysicalManifestProfileByteForByte` reads the checked-in source, compiles it through the physical Wheeler recovery compiler, compiles the same bytes through stage 0, and compares complete artifacts. It also requires the qualified `profileByte` function and canonical `$library` entry.

`NativeBootstrapManifestIdentityExampleTest` and `NativeCompilerOptionsIdentityExampleTest` execute the explicit new dependency over accepted and rejected transports. `NativeBootstrapModulesIdentityExampleTest` validates the complete enlarged closure. `NativeSha256ExampleTest` hashes the exact enlarged manifest.

## Acceptance

- [x] Profile-byte policy has one physical source owner.
- [x] Every production consumer imports that owner explicitly.
- [x] The mixed manifest-syntax owner no longer contains profile policy.
- [x] The complete owner compiles byte for byte through Wheeler and stage 0.
- [x] Qualified function and inert library entry identities remain exact.
- [x] Manifest parsing and options parsing preserve accepted behavior.
- [x] Complete closure and SHA-256 evidence are bounded and exact.

## Rejected alternatives

### Keep the function in `ManifestSyntax.w`

Rejected. Two unrelated bounded loops prevent that mixed module from proving the already-supported classifier body.

### Copy the function into a test source

Rejected. A transcription proves the transcription. Physical evidence must consume the checked-in production bytes.

### Re-export the function from the old owner

Rejected. A forwarding shim preserves obsolete ownership and adds another dependency without adding semantics.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0391](WIP-0391-boolean-local-equality-guard-returns.md)
