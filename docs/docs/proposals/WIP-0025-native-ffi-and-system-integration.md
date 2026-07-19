# WIP-0025: Native ABI descriptors, FFI, and system capabilities

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, compiler, verifier, runtime, native, package, and security maintainers |
| Created | 2026-07-19 |
| Updated | 2026-07-19 |
| Area | Native FFI, ABI, effects, memory, packages, runtime loading, system libraries |
| Depends on | WIP-0001, WIP-0004, WIP-0005, WIP-0008, WIP-0009, WIP-0012, WIP-0013, WIP-0022, WIP-0023 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler will expose native calls through canonical ABI descriptors and package-visible providers. The first profile is a deliberately small C ABI subset. A provider is either an exact bundled package artifact or a system capability granted by deployment policy and mapped by WIP-0024. Symbols are never found by searching the host.

Foreign calls are typed effectful operations and are forbidden in `rev`, `coherent rev`, `unitary`, proof evaluation, and reverse blocks. Every foreign call is initially an irreversible boundary. Raw pointers are not Wheeler values: memory crosses as exact scalars, immutable views, exclusive mutable borrows, opaque affine handles, or explicitly owned foreign buffers.

Calling convention, target ABI, symbols, layouts, ownership, errors, effects, blocking, threading, and callbacks are package identity. Generic `dlopen`, `dlsym`, C++ ABI binding, exceptions, varargs, callbacks, and ambient search are outside the first profile.

## Motivation

FFI is needed for operating systems, established C libraries, databases, graphics, devices, and native toolchains. Unrestricted FFI would also import ambient library/header search, implementation-defined layout, pointer aliasing, hidden threads, native exceptions, undeclared I/O, irreversible state, and installed-host variance. It therefore needs one language, verifier, runtime, package, reproducibility, and deployment contract.

## Goals

- Define canonical target ABI and interface descriptors.
- Support exact-width scalars, immutable/exclusive buffers, affine handles, and owned foreign buffers.
- Bind exact bundled providers or explicit mapped system capabilities with no ambient discovery.
- Make ownership, error, effect, blocking, thread, and reentrancy rules visible and verified.
- Keep native calls out of reversible, quantum, coherent, proof, and reverse contexts.
- Define static and exact dynamic binding, package link groups, reproducible providers, and sealed-image integration.
- Keep the loader and marshaller small, bounded, and auditable.

## Non-goals

- Bind arbitrary C++, headers at runtime, raw pointers, arithmetic, unions, bitfields, flexible arrays, implementation-defined `long`, varargs, callbacks, or native exceptions.
- Permit path-based loading or ambient includes.
- Claim destruction is an inverse or VM rewind restores foreign state.
- Let descriptors grant authority or use generic FFI as the quantum target API.

## Semantic model

```text
native_abi_descriptor {
    schema
    logical_interface_name
    target_abi
    provider_requirement
    symbols[]
    data_types[]
    ownership_rules[]
    error_rules[]
    effects[]
    threading_rules
    callback_policy
    compatibility_version
}
```

A target ABI fixes OS family, architecture, endianness, pointer width, calling convention, integer widths, alignment/layout, floating ABI, symbol versioning, and libc/runtime baseline. A target triple alone is not the contract.

A bundled provider records exact package instance, RREV, variant, build-input ID, PREV, target ABI, bytes, and exports. A system provider is a deployment capability. Portable artifacts carry the requirement; WIP-0024 maps it. Build-host libraries are irrelevant.

Logical capabilities look like `native:zlib/1`, not filenames. Native link groups identify process-global symbols, allocators, runtimes, or state; incompatible providers cannot coexist without verified isolation.

A foreign function records Wheeler name, native symbol, calling convention, parameter/result descriptors, effects, error rule, blocking, and thread rule.

Initial scalars are exact signed/unsigned 8/16/32/64-bit integers, declared Boolean encoding, and supported IEEE 32/64-bit floats. Target aliases resolve to an exact width before artifact construction.

A buffer view is a nonescaping pointer/length pair for one call. Mutable views are exclusive. A callee cannot retain a view unless ownership transfers into a declared handle.

A foreign handle is affine opaque state with provider/type, nullability, creation/destruction, thread affinity, send/share policy, borrows, invalidation, error state, and checkpoint policy. It cannot be copied, compared by address, serialized, cloned, or rewound.

A foreign-owned buffer records exact element layout, length, destructor, mutability, reallocation policy, provider, and thread affinity. Numeric addresses remain unobservable.

Effects form a closed initial set covering foreign/Wheeler memory, allocation, process-global state, filesystem, network, clock, randomness, environment, thread creation, blocking, callback, and device/hardware. Effects describe behavior and never grant authority.

Error mappings include exact status conventions, null handle, sentinel, out-error buffer, and declared thread-local native error. Native exceptions/signals are not Wheeler errors.

Thread rules distinguish nonblocking, bounded blocking, blocking, thread creation, affinity, reentrancy, and process-global serialization.

## Ownership and boundaries

The language owns syntax, types, effects, and restricted contexts. The compiler resolves descriptors and generates stubs. The verifier checks descriptor references, register types, borrow windows, handle state, effects, capabilities, and forbidden contexts. The runtime binds providers, validates symbols/layout, marshals, calls, maps errors, and owns handle cleanup. Packages own provider identity, variants, and link groups. WIP-0023 owns reproducible native builds, WIP-0024 owns system mappings, and WIP-0026 owns final image policy. Host policy alone grants authority.

## Design

The first C subset supports fixed arity, exact scalars, immutable/exclusive buffers, opaque handles, owned buffers, fixed-layout structs after explicit checks, status-code errors, and static or exact dynamic providers. It excludes callbacks, varargs, exceptions, longjmp across frames, and pointer results except typed handles/buffers.

Conceptually:

```text
native interface Zlib from capability "native:zlib/1" {
    foreign int32 compress(byteview source, bytes destination)
        writes destination
        status zero;
}
```

Provider selection is package/deployment policy, never a source path.

Binding generation consumes exact headers, target ABI, definitions, include closure, frontend, declaration allowlist, ownership/effect annotations, and symbol metadata. Ambient include paths/defaults are forbidden. Fixed aggregates verify size, alignment, offsets, representations, ABI, and tool identity; unsupported layout fails.

A bundled dynamic provider loads only from one exact approved image/package path. Runtime verifies identity, descriptor, ABI, soname/install name, required symbols/versions, and transitive imports. It does not search working directory, home, `PATH`, loader environment, defaults, registry, or caches.

Static link plans identify every object/archive, order/group semantics, exports, linker/arguments, ABI, runtime libraries, and link groups. Static linkage does not confer reversibility.

System-provider resolution maps a logical capability through a pinned deployment profile. Runtime evidence may include exact provider manifest, ABI fingerprint, symbol version, or distro metadata. The installed build-host library remains irrelevant.

Buffer marshalling validates liveness/ownership/range, stabilizes storage, excludes competing access, executes, validates error/output rules, ends the borrow, and publishes permitted mutations. Failure may leave native output mutated according to its descriptor; Wheeler assumes no rollback.

Handle flow rejects copy, address equality, use after destroy, double destroy, wrong-thread movement, borrowed-as-owned return, live owned exit, unsupported persistence, and rewind across creation/destruction.

Foreign calls require explicit commit/effect boundaries and are rejected in inverse/quantum/proof contexts. A future reversible FFI would require a formal foreign state model and verified inverse pair; a destructor wearing a bow tie is not enough.

Invoking a compiler or linker during build is a process capability, not runtime FFI. Both share exact package/reproducibility rules but differ in lifetime and semantics.

ABI compatibility covers consumed symbols, convention, types/layouts, ownership, errors, thread rules, and effects. Version text alone is not ABI evidence.

Bundled provider reproducibility includes exact sources, tools, sysroot, standard libraries, ABI, ordering, normalization, feature policy, build-input identity, and PREV. Divergence is quarantined.

A WIP-0026 sealed executable may statically include providers. A system-baseline image embeds logical requirements. The first profile does not unpack embedded shared objects to temporary files.

## Reversibility, concurrency, quantum, and proofs

Foreign calls are irreversible. VM history does not restore foreign memory, kernel state, files, networks, devices, globals, or threads. Handle allocation/destruction and foreign allocation are commit boundaries.

Thread/reentrancy rules are explicit and the runtime serializes nonreentrant/process-global providers. Native clock/random/thread/I/O can make execution nondeterministic and must be declared.

Foreign calls are forbidden in unitary, coherent, and proof execution. Native numerical output is not proof evidence. Quantum SDKs remain behind structured target adapters rather than generic source FFI.

## Bytecode and persistence

Bytecode gains versioned foreign descriptors and call references. A call identifies descriptor/function, exact register types, ownership transitions, effects, capability, and source location. Snapshots do not serialize live native handles initially. Portable WBC may carry system capability requirements; target images bind providers.

## Safety and failures

Limits cover descriptors, symbols, types, nesting, buffers, handles, concurrent calls, duration, memory, stubs, providers, and diagnostics. Reject unsupported ABI, symbol/layout mismatch, undeclared dependencies, ambient paths, invalid pointer/length, mutable aliasing, lifetime errors, callback/varargs, exception crossing, restricted-context calls, missing capability, link conflicts, unmapped provider, PREV mismatch, and exhaustion.

## Migration and deletion

1. Define ABI/interface schemas and scalar/buffer/handle model.
2. Add source, bytecode, and verifier support.
3. Generate stubs for C fixtures.
4. Add exact static then dynamic providers.
5. Add handle/error/thread semantics and package link groups.
6. Integrate reproducibility, system mappings, and sealed images.
7. Consider isolation and callbacks only in successor proposals.
8. Delete JNI/JNA/raw loaders and ambient header/library paths.

## Progress

- [ ] ABI subset and provider metadata accepted.
- [ ] Restricted contexts and ownership verified.
- [ ] Exact bundled providers and link groups reproduce.
- [ ] System mappings and sealed images integrate.
- [ ] Ambient discovery is absent and deleted.

## Testing and acceptance

- [ ] Scalars and layouts match C fixtures; unsupported layouts fail.
- [ ] Buffer mutability, aliases, and pointer/length checks hold.
- [ ] Pointers are not observable and handles cannot copy, leak, or double-destroy.
- [ ] Status mappings and native crash boundaries are exact.
- [ ] Restricted contexts reject calls and rewind claims no rollback.
- [ ] Providers load only by exact identity/path and undeclared imports fail.
- [ ] Cross compilation, link conflicts, PREV reproduction, and system mappings are deterministic.
- [ ] Final WIP-0024/WIP-0026 closure equals declarations.
- [ ] Stage 0 and Wheeler agree.

## Alternatives

Raw loading/function pointers, libffi as language contract, ambient headers, C++ first, cleanup-as-inverse, native-memory rewind, soname-only identity, universal bundling, and universal singleton policy each erase required type, provenance, or effect boundaries. They are rejected.

## Open questions

- Which C ABIs and targets form the first conformance set? — **Owner:** native maintainers — **Decide by:** implementation
- Direct stubs, generated shim, or libffi underneath? — **Owner:** runtime maintainers — **Decide by:** runtime work
- Are structs in the first slice? — **Owner:** ABI maintainers — **Decide by:** parser acceptance
- Which crash isolation and callback subset require successors? — **Owner:** security/runtime maintainers — **Decide by:** public packages
- What evidence proves a system provider? — **Owner:** distribution/security maintainers — **Decide by:** WIP-0024 integration

## References

- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0022](WIP-0022-package-instances-and-resolution.md)
- [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md)
- [WIP-0024](WIP-0024-system-package-exports.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
