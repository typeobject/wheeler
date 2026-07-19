# Wheeler compiler

This directory is the canonical Wheeler-written compiler package. Its sources under `src/main/wheeler` define the compiler, scanner, verifier, codecs, and driver slices promoted out of examples. `wheeler.package`, the exact lock, and committed vendor archive set are the package boundary.

Java stage-0 code does not live here. The temporary seed is isolated in [`../bootstrap/stage0`](../bootstrap/stage0), which compiles this package into a stage-1 `.wbc` compiler. Stage 1 must compile these same sources into a byte-identical stage 2, and the resulting seed update must also satisfy the diverse-bootstrap and provenance rules in WIP-0007. Fixed points catch drift; they do not exorcise a malicious ancestor by repetition.

Examples consume this package through exact locks. They do not carry compiler implementation copies. New compiler features land here in Wheeler after the bootstrap profile can express and test them; Java additions require a concrete stage-crossing reason and an accompanying deletion condition.
