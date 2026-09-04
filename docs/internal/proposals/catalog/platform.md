# Runtime, I/O, and native platforms

[Proposal guide](../index.mdx) · [Open work](../roadmap.md)

Quantum and hybrid execution, host effects, native images, and release authorization.

Each record appears in one catalog. Cross-cutting work links its other owners from the proposal itself. Implemented records describe the evidence and bounds at that milestone, not the current whole-system profile.

| WIP | Status | Decision |
| --- | --- | --- |
| [WIP-0003](../WIP-0003-quantum-target-and-qiskit-backend.md) | Implemented | Quantum target contract and OpenQASM interoperability |
| [WIP-0004](../WIP-0004-hybrid-jobs-history-and-replay.md) | Implemented | Hybrid jobs, history, and replay |
| [WIP-0008](../WIP-0008-java-free-runtime-and-native-bootstrap.md) | Draft | Java-free runtime and native bootstrap |
| [WIP-0025](../WIP-0025-native-ffi-and-system-integration.md) | Draft | Native ABI descriptors, FFI, and system capabilities |
| [WIP-0026](../WIP-0026-self-contained-native-executables.md) | Draft | Self-contained platform-native Wheeler executables |
| [WIP-0032](../WIP-0032-unified-io-fabric-and-durability-receipts.md) | Draft | Unified asynchronous I/O fabric, operation graphs, and durability receipts |
| [WIP-0128](../WIP-0128-native-rnic-registration-authority.md) | Implemented | Native RNIC registration authority |
| [WIP-0129](../WIP-0129-native-rnic-one-sided-write-completion.md) | Implemented | Native RNIC one-sided write completion |
| [WIP-0130](../WIP-0130-native-rnic-one-sided-read-completion.md) | Implemented | Native RNIC one-sided read completion |
| [WIP-0131](../WIP-0131-native-rnic-compare-and-swap-completion.md) | Implemented | Native RNIC compare-and-swap completion |
| [WIP-0132](../WIP-0132-native-rnic-operation-cancellation.md) | Implemented | Native RNIC operation cancellation |
| [WIP-0133](../WIP-0133-native-rnic-peer-and-persistence-evidence.md) | Implemented | Native RNIC peer and persistence evidence |
| [WIP-0368](../WIP-0368-platform-abi-and-native-image-identities.md) | Implemented | Platform ABI and native image identities |
| [WIP-0369](../WIP-0369-canonical-application-capsules.md) | Implemented | Canonical application capsules |
| [WIP-0370](../WIP-0370-application-capsule-inspection.md) | Implemented | Application capsule inspection |
| [WIP-0371](../WIP-0371-embedded-application-capsule-startup.md) | Implemented | Embedded application capsule startup |
| [WIP-0372](../WIP-0372-canonical-elf-capsule-images.md) | Implemented | Canonical ELF capsule images |
| [WIP-0373](../WIP-0373-physical-elf-image-command.md) | Implemented | Physical native image commands |
| [WIP-0374](../WIP-0374-canonical-mach-o-capsule-images.md) | Implemented | Canonical Mach-O capsule images |
| [WIP-0375](../WIP-0375-canonical-pe-capsule-images.md) | Implemented | Canonical PE capsule images |
| [WIP-0376](../WIP-0376-x86-64-linux-native-entry-shim.md) | Implemented | x86-64 Linux native entry shim |
| [WIP-0377](../WIP-0377-native-image-release-records.md) | Implemented | Native image release records |
| [WIP-0378](../WIP-0378-x86-64-linux-scalar-aot.md) | Implemented | x86-64 Linux scalar AOT |
| [WIP-0379](../WIP-0379-x86-64-linux-scalar-helper-calls.md) | Implemented | x86-64 Linux scalar helper calls |
| [WIP-0380](../WIP-0380-x86-64-linux-scalar-call-arguments.md) | Implemented | x86-64 Linux scalar call arguments |
| [WIP-0381](../WIP-0381-x86-64-linux-bounded-scalar-loops.md) | Implemented | x86-64 Linux bounded scalar loops |
| [WIP-0382](../WIP-0382-x86-64-linux-scalar-state-checks.md) | Implemented | x86-64 Linux scalar state checks |
| [WIP-0383](../WIP-0383-x86-64-linux-void-helper-calls.md) | Implemented | x86-64 Linux void helper calls |
| [WIP-0384](../WIP-0384-x86-64-linux-constant-byte-output.md) | Implemented | x86-64 Linux constant byte output |
| [WIP-0385](../WIP-0385-x86-64-linux-dynamic-byte-io.md) | Implemented | x86-64 Linux dynamic byte I/O |
| [WIP-0386](../WIP-0386-x86-64-linux-borrowed-byte-helpers.md) | Implemented | x86-64 Linux borrowed byte helpers |
| [WIP-0387](../WIP-0387-x86-64-linux-scalar-execution-bound.md) | Implemented | x86-64 Linux scalar execution bound |
| [WIP-0388](../WIP-0388-x86-64-linux-4096-iteration-byte-loops.md) | Implemented | x86-64 Linux 4,096-iteration byte loops |
| [WIP-0389](../WIP-0389-x86-64-linux-strict-utf8-input.md) | Implemented | x86-64 Linux strict UTF-8 input |
| [WIP-0390](../WIP-0390-x86-64-linux-shared-scalar-globals.md) | Implemented | x86-64 Linux shared scalar globals |
| [WIP-0395](../WIP-0395-x86-64-linux-seventh-scalar-argument.md) | Implemented | x86-64 Linux seventh scalar argument |
| [WIP-0396](../WIP-0396-order-independent-scalar-aot-calls.md) | Implemented | Order-independent scalar AOT calls |
| [WIP-0397](../WIP-0397-sixteen-function-scalar-aot-graph.md) | Implemented | Sixteen-function scalar AOT graph |
| [WIP-0398](../WIP-0398-compiler-width-scalar-aot-graph.md) | Implemented | Compiler-width scalar AOT graph |
| [WIP-0399](../WIP-0399-compiler-width-scalar-aot-arguments.md) | Implemented | Compiler-width scalar AOT arguments |
| [WIP-0400](../WIP-0400-compiler-frame-scalar-aot-bounds.md) | Implemented | Compiler-frame scalar AOT bounds |
| [WIP-0401](../WIP-0401-bounded-recursive-scalar-aot-calls.md) | Implemented | Bounded recursive scalar AOT calls |
| [WIP-0402](../WIP-0402-boolean-result-scalar-aot-helpers.md) | Implemented | Boolean-result scalar AOT helpers |
| [WIP-0403](../WIP-0403-scalar-global-instruction-aot.md) | Implemented | Scalar global instruction AOT |
| [WIP-0404](../WIP-0404-scalar-global-replacement-aot.md) | Implemented | Scalar global replacement AOT |
| [WIP-0405](../WIP-0405-directional-scalar-aot-calls.md) | Implemented | Directional scalar AOT calls |
| [WIP-0406](../WIP-0406-forward-control-marker-aot.md) | Implemented | Forward control marker AOT |
| [WIP-0407](../WIP-0407-helper-owned-process-status-aot.md) | Implemented | Helper-owned process status AOT |
| [WIP-0408](../WIP-0408-reversible-scalar-result-slot-aot.md) | Implemented | Reversible scalar result-slot AOT |
| [WIP-0409](../WIP-0409-exact-native-capsule-binding.md) | Implemented | Exact native capsule binding |
| [WIP-0410](../WIP-0410-cryptographic-elf-repository-authorization.md) | Implemented | Cryptographic ELF repository authorization |
