# WIP-0164: Sparse compiled-function publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, linker, and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, compiled artifacts, functions, instructions, bounded publication |
| Depends on | WIP-0047, WIP-0048, WIP-0163 |
| Supersedes | Full-capacity compiled function and instruction copies |
| Superseded by | None |

## Summary

Publish decoded function and instruction products only through canonical artifact counts. `CompiledFunctionProducts.w` formerly copied all 640 function words and all 24,576 instruction words after decoding one artifact.

The decoder now publishes ten columns through `functionCount` and six columns through `instructionCount`.

## Function products

Each canonical function descriptor contributes:

- function ID
- flags
- forward code start
- forward code length
- inverse code start
- inverse code length
- parameter count
- local count
- local-type start
- local-type count

Descriptor IDs remain dense and source local. Irreversible functions retain signed minus-one inverse starts and zero inverse length.

## Instruction products

Each validated forward or inverse instruction contributes:

- local function owner
- direction
- artifact byte start
- opcode
- operand count
- encoded length

Instruction streams must cover each function code extent exactly. Opcode forms own operand counts and fixed instruction widths.

## Atomicity

Header, directory, function section, local types, code extents, function IDs, flags, parameter and local counts, every instruction form, and complete section coverage validate in private staging.

The decoder traps before publication on malformed canonical artifacts. Active rows replace caller contents only after complete decoding. Untouched rows retain prior contents.

## Bounds

No capacity changes:

- 64 functions per module
- ten function columns
- 4,096 instructions per module
- six instruction columns
- 64 canonical sections

Worst-case work remains identical. Small artifacts no longer publish maximum decoder capacity.

## Evidence

`NativeCompilerFunctionProductsExampleTest` checks canonical descriptors, forward and inverse instructions, local calls, relocation tables, malformed extents, duplicate IDs, unknown opcodes, and publication failure.

Imported structured artifact and physical closure tests consume the same products before retaining source-local prefixes and resolving relocations.

The compiler archive contains 3,008,788 bytes with SHA-256 `6e3ff9fedc32768f0f25d64f845965b9d4094f63326ff3eddaf77d3fe6b3b45f`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9`. Complete evidence passes in 15 minutes under the unchanged twenty-minute deadline.

## Acceptance

- [x] Ten function columns publish exactly `functionCount` rows.
- [x] Six instruction columns publish exactly `instructionCount` rows.
- [x] Forward and inverse instruction streams retain exact artifact coordinates.
- [x] Section and code extents validate before publication.
- [x] Untouched rows retain caller contents.
- [x] Focused compiled-function products pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The linked physical subset publishes twice with identical bytes.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Decode directly into linker rows

Rejected. Canonical artifact coordinates remain distinct from closure-wide function coordinates.

### Retain only forward instructions

Rejected. Reversible artifacts require exact inverse products and relocation coordinates.

### Clear inactive rows

Rejected. Function and instruction counts define the complete decoded product.

### Skip canonical section validation

Rejected. Sparse publication changes output work, not the artifact trust boundary.

## References

- [WIP-0047](WIP-0047-counted-native-callable-bytecode-products.md)
- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0163](WIP-0163-sparse-reversible-evidence-publication.md)
