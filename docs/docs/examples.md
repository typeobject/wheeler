# Executable examples

Every checked-in `.w` file must pass both the compiler and the Tree-sitter grammar. Classical examples run on the VM. Quantum and hybrid examples use asynchronous `QuantumTarget` jobs on the ideal state-vector target. Before any example runs, its bytecode must complete a canonical round trip.

Each example has a fixed bound. It shows behavior that works today and names any limit it reaches. Rows that name core, compiler, runtime, or package-codec modules link to the canonical `wheeler.core`, `wheeler.compiler`, `wheeler.runtime`, and `wheeler.packages` sources. The example package uses their locked archives and keeps no duplicate copies. `QFTProof.w` is also the workspace's selected test target, so `wheeler test .` follows the normal package build and execution path.


## Examples

### `Counter.w`

Source: [`Counter.w`](../../wheeler-examples/src/main/wheeler/classical/control/Counter.w).

Covers: Generated inverse calls, reverse-block order, kernel-checked generated-inverse theorem, and byte-identical compilation by the Wheeler-written bounded compiler.

Expected result: `count = 0`.

### `BinaryTree.w`

Source: [`BinaryTree.w`](../../wheeler-examples/src/main/wheeler/classical/data/BinaryTree.w).

Covers: Fixed-capacity reversible tree slots.

Expected result: `root = left = right = 0`.

### `BootstrapControl.w`

Source: [`BootstrapControl.w`](../../wheeler-examples/src/main/wheeler/classical/control/BootstrapControl.w).

Covers: Typed signed and Boolean locals, expressions, branch joins, and a bounded counted `for`.

Expected result: `sum = 10`, `branch = 1`.

### `MinimalCompiler.w`

Files: [`MinimalCompiler.w`](../../wheeler-compiler/src/main/wheeler/MinimalCompiler.w) + [`compiler/frontend/Parser.w`](../../wheeler-compiler/src/main/wheeler/compiler/frontend/Parser.w) + [`compiler/backend/StringTable.w`](../../wheeler-compiler/src/main/wheeler/compiler/backend/StringTable.w) + dedicated IR/token/scanner/code-generation/encoding modules.

Covers: Wheeler compilation of one bounded minimal source grammar to canonical `.wbc`.

Expected behavior:

- Input `classical class LongClass { state long value = 7; entry void main() { value += 5; } }` drives global and instruction IR, canonical lexical string ordering, function descriptors, and layout.
- The 504-byte result passes Wheeler's header/directory/payload/instruction-stream verifier, including global/local/type/call operand domains, matches stage 0, and executes with `value = 12`.
- `verification = 1`.
- The differential suite covers no-global classes with zero to five statements.
- Cases include signed and Boolean locals, literal or prior-local truth assertions, stateful updates, helper calls, reversible helpers, reverse blocks, and generated-inverse theorems.
- Fixtures use two to four strings and zero or one global.
- Bounded entry bodies derive up to twenty locals and 528 code bytes while `assert(global == constant)` lowers directly to local-free `EXPECT_EQ`.
- A named one- through five-statement helper plus static entry call emits two descriptors, `RETURN`, and `CALL`.
- One or two helper calls derive repeated `CALL` sites.
- A following entry statement derives its own locals, type window, descriptor length, and code after the call.
- The `rev` form maps checked `+=`/`-=` to opposite intrinsic bodies and `^=` to a self-inverse body, reverses multi-statement inverse order, emits entry `CALL`/`UNCALL`, then may assert the restored state.
- Plain assignment is rejected because it has no checked inverse.
- A checked statement may appear before and after a reversible block.
- The checked-in `Counter.w` compiles byte for byte through the direct VM and package-selected `wheeler run` paths. It runs two calls, two inverse calls, and both assertions.
- Compiler-local comment compaction leaves the shared teaching scanner's token stream intact.
- An optional theorem adds a canonically sorted proof name and 28-byte `GENERATED_INVERSE` section accepted by the proof kernel.
- Signed and Boolean literals, unary negation, literal truth assertions, and prior-local Boolean assertions work in no-global, stateful, and ordinary-helper bodies.
- They lower through `LOCAL_CONST`, `LOCAL_XOR`, `LOCAL_MOVE`, and `EXPECT_TRUE`. The compiler emits exact signed and Boolean local type windows from named token, punctuation, and statement identities.
- Signed decimal initializers and operands use canonical two's-complement form. An overlong negative magnitude fails before publication, with no substitute constant.
- `codeStart = 392`, `finalCursor = 504`.

### `FixedArrays.w`

Files: [`FixedArrays.w`](../../wheeler-examples/src/main/wheeler/classical/data/FixedArrays.w) + [`collections/FixedLongs.w`](../../wheeler-core/src/main/wheeler/collections/FixedLongs.w).

Covers: Fixed immutable arrays, nonescaping borrowed slices, locked core reductions, checked indexing, and structural equality.

Expected result: `selected = 6`, `sum = 20`, `middleSum = 10`, `equal = 1`.

### `FrozenUtf8.w`

Files: [`FrozenUtf8.w`](../../wheeler-examples/src/main/wheeler/text/FrozenUtf8.w) + [`text/Utf8.w`](../../wheeler-core/src/main/wheeler/text/Utf8.w).

Covers: Strict byte-owner freezing plus locked core metrics/scalar inspection over nested nonescaping immutable UTF-8 parameter borrows.

Expected result: `byteLength = 6`, `scalarCount = 3`, `middleScalar = 8364`, `valid = 1`.

### `FiniteEnums.w`

Source: [`FiniteEnums.w`](../../wheeler-examples/src/main/wheeler/classical/data/FiniteEnums.w).

Covers: Compile-time scalar constants and a finite enum elaborated to a payload-free variant.

Expected behavior:

- Checked constant folding emits no extra global.
- Exhaustive enum matching selects `Right` and produces `selected = 7`.
- Complete rewind.

### `FunctionValues.w`

Source: [`FunctionValues.w`](../../wheeler-examples/src/main/wheeler/classical/control/FunctionValues.w).

Covers: Signed/Boolean values, typed calls, right-associative logical negation, a callee loop, and a named compile-time constant used by a kernel-checked straight-line step bound.

Expected result: `result = 10`.

### `HostBinaryInput.w`

Source: [`HostBinaryInput.w`](../../wheeler-examples/src/main/wheeler/host/HostBinaryInput.w).

Covers: Explicit immutable `byteview` host input, arbitrary octet reads, bounded byte output, defensive input copying, and exact rewind.

Expected behavior:

- Input `00 ff 7f 80` gives `byteLength = 4`, `middleByte = 255`, `checksum = 510`.
- Output `00 80`.
- UTF-8 binding and source mutation are rejected.

### `HostInput.w`

Source: [`HostInput.w`](../../wheeler-examples/src/main/wheeler/host/HostInput.w).

Covers: Explicit bounded UTF-8 input and byte-output borrows with no ambient file/network access.

Expected behavior:

- For UTF-8 `A¢` and capacity 2: globals `byteLength = 3`, `scalarCount = outputLength = 2`, `firstScalar = 65`.
- Output `A!`.

### `LoopControl.w`

Source: [`LoopControl.w`](../../wheeler-examples/src/main/wheeler/classical/control/LoopControl.w).

Covers: Early typed return plus bounded `break` and `continue` edges.

Expected result: `sum = 12`, `selected = 7`.

### `modules/ModuleMain.w`

Files: [`modules/ModuleMain.w`](../../wheeler-examples/src/main/wheeler/modules/ModuleMain.w) + [`Arithmetic.w`](../../wheeler-examples/src/main/wheeler/modules/Arithmetic.w) + [`Collections.w`](../../wheeler-examples/src/main/wheeler/modules/Collections.w) + [`Results.w`](../../wheeler-examples/src/main/wheeler/modules/Results.w).

Covers: Exact source set, sorted imports, qualified calls and value types, private helper, and direct public function/record/variant/scalar-array/slice APIs.

Expected result: `result = 18`, `decoded = 9`, `arrayValue = 5`, `sliceValue = 15`, `nominalArrayValue = 8`, `nominalSliceValue = 26`, `qualifiedVariant = 1`.

### `NativeArchive.w`

Files: [`NativeArchive.w`](../../wheeler-examples/src/main/wheeler/native/NativeArchive.w) + [`packages/archive/Archive.w`](../../wheeler-package/src/main/wheeler/packages/archive/Archive.w).

Covers: Wheeler-native bounded `.wpk` framing with Wheeler-computed outer and entry-data SHA-256, one frozen and parsed canonical-YAML manifest, one or two sorted checked ASCII paths with exact target-source closure, and exact consumption.

Expected behavior:

- An independently encoded `demo.archive` package with `src/Main.w` yields path/data lengths `10/4`, stage-0 decode acceptance, and exact rewind.
- Outer digest damage, re-signed data corruption, traversal, valid-but-wrong source paths, and a re-signed malformed YAML key trap.

### `NativeLock.w`

Files: [`NativeLock.w`](../../wheeler-examples/src/main/wheeler/native/NativeLock.w) + [`packages/resolution/Lock.w`](../../wheeler-package/src/main/wheeler/packages/resolution/Lock.w).

Covers: Wheeler-native bounded snapshot-bound `wheeler.package.lock.yaml` parsing into caller-owned package and edge tables, with lowercase digest/name/version checks, package/dependency ordering, known-target validation, and exact canonical-byte publication.

Expected behavior:

- Schema 3 with repository/snapshot-bound sorted packages and dependency `demo.app -> demo.base` yields package count 2 and edge count 1 with exact rewind.
- Empty and generated six-package locks pass the independent stage-0 parser, while a seventh package exceeds the fixture's declared capacity and traps before publication.
- Wrong schema, uppercase digest, duplicate or unsorted packages/dependencies, and unknown targets also trap.

### `NativePlan.w`

Files: [`NativePlan.w`](../../wheeler-examples/src/main/wheeler/native/NativePlan.w) + [`packages/resolution/Plan.w`](../../wheeler-package/src/main/wheeler/packages/resolution/Plan.w) + [`PlanIdentity.w`](../../wheeler-package/src/main/wheeler/packages/resolution/PlanIdentity.w).

Covers: Wheeler-native bounded binary build-plan framing, payload SHA-256, one-node field decoding, name/release/path checks, target kind, execution limits, and Wheeler-rederived node identity.

Expected behavior:

- A stage-0 one-node `demo.plan:main` plan yields kind 2, limits `1000/2000/3000/4000/5000`, exact field lengths and rewind.
- A second canonical fixture verifies one package input and one identical requested/granted capability.
- Payload/digest corruption and a re-signed invalid target kind or forged node identity trap.
- Larger input/capability lists and additional nodes remain.

### `NativeSha256.w`

Files: [`NativeSha256.w`](../../wheeler-examples/src/main/wheeler/native/NativeSha256.w) + [`crypto/Sha256.w`](../../wheeler-core/src/main/wheeler/crypto/Sha256.w).

Covers: Wheeler-written bounded SHA-256 over immutable binary input with caller-owned digest output and region scratch.

Expected behavior:

- Empty, `abc`, 55/56/64-byte padding boundaries, and 100 arbitrary binary bytes match the JDK SHA-256 oracle.
- Output is exactly 32 bytes and the empty-input run rewinds exactly.

### `NativeVerifier.w`

Files: [`NativeVerifier.w`](../../wheeler-examples/src/main/wheeler/native/NativeVerifier.w) + [`compiler/verification/Verifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/Verifier.w) + [`compiler/verification/FunctionVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/FunctionVerifier.w) + [`compiler/verification/InstructionVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/InstructionVerifier.w) + [`compiler/verification/ProofVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/ProofVerifier.w).

Covers: Package-selected Wheeler verification of framing/payloads plus split instruction, operand-type, local-window, and branch-target checks over exact immutable binary `.wbc` input.

Expected behavior:

- Canonical stage-0, Boolean-negation/XOR, and immutable `byteview`-entry artifacts yield `verification = 1`.
- Damaged magic and forged operand domains fail before interpretation.
- Direct verification rewinds exactly.

### `compiler/ir/Opcodes.w`

Files: [`compiler/ir/Opcodes.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/Opcodes.w) + [`compiler/ir/TypeCodes.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/TypeCodes.w) + [`compiler/ir/ProofRules.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/ProofRules.w).

Covers: Public compile-time opcode/type/proof identities, interpreter bounds, and shared bounded opcode-family predicates.

Expected behavior:

- `Verifier.w` and `Interpreter.w` import one authority.
- Constants add no VM globals or initializer, and the consumers dispatch without raw opcode/type literals.

### `NativeVm.w`

Files: [`NativeVm.w`](../../wheeler-examples/src/main/wheeler/native/NativeVm.w) + [`runtime/Interpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/Interpreter.w) + [`runtime/AggregateInterpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/AggregateInterpreter.w) + [`compiler/verification/AggregateVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/AggregateVerifier.w) + [`runtime/StorageInterpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/StorageInterpreter.w) + [`compiler/verification/StorageVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/StorageVerifier.w) + [`runtime/Utf8Interpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/Utf8Interpreter.w) + [`runtime/MapInterpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/MapInterpreter.w).

Covers: Wheeler-written bounded interpreter for the self-hosted compiler artifact profile after Wheeler-native structural verification.

Expected behavior:

- A checked local/global update agrees with the stage-0 VM at `value = 12` and rewinds exactly.
- The Wheeler-written compiler emits the checked-in proof-bearing `Counter.w` artifact byte-for-byte with stage 0, then the Wheeler-written interpreter executes `CALL`/`UNCALL` back to `count = 0`.
- Control-flow tests cover signed and Boolean branches, a bounded loop, two-argument value calls, argument-bearing void calls, and the four-function `FunctionValues.w` graph.
- Stress fixtures use a thirty-five-local frame and an eighty-expectation code window. They also cover six-level `RecursiveValue.w` recursion and the early-return, `break`, and `continue` paths in `LoopControl.w`.
- Aggregate tests cover nested `Records.w` values, payload-free `FiniteEnums.w`, payload-carrying `Variants.w`, fixed arrays, and slices.
- Storage and text tests cover owned regions, word and byte buffers, nested mutable borrows, valid and malformed UTF-8, and the full `FrozenUtf8.w` path with nested read-only borrows.
- Ownership tests cover returned and transferred owners in `OwnedReturns.w`, plus a signed map with a nested mutable borrow.
- Every case agrees with stage 0 across all declared globals, up to eight, and rewinds exactly.
- Forged record-field, variant-tag, array-index-local, slice-index-local, word/byte-index-local UTF-8-index-local and map-key-local operands, a forged static-step bound, a structurally valid wrong generated inverse, and damaged artifacts and forged branch/call targets trap before interpretation.

### `NativeWorkspace.w`

Files: [`NativeWorkspace.w`](../../wheeler-examples/src/main/wheeler/native/NativeWorkspace.w) + [`packages/workspace/Workspace.w`](../../wheeler-package/src/main/wheeler/packages/workspace/Workspace.w).

Covers: Wheeler-native bounded `wheeler.workspace.yaml` parsing into caller-owned member tables, with schema/key checks, checked names and paths, ordering, uniqueness, nonnesting, and exact canonical-byte publication.

Expected behavior:

- Workspace `demo-workspace` with five sorted package members is parsed and accepted by the independent stage-0 YAML parser with exact rewind.
- A sixteen-member generated workspace proves that collection parsing uses table bounds. A seventeenth member exceeds the fixture's declared capacity and traps before publication.
- Wrong schema/key, malformed names, duplicates, unsorted members, shared/nested paths, and traversal also trap.

### `NativeManifest.w`

Files: [`NativeManifest.w`](../../wheeler-examples/src/main/wheeler/native/NativeManifest.w) + [`packages/manifest/Manifest.w`](../../wheeler-package/src/main/wheeler/packages/manifest/Manifest.w) + [`ManifestTokens.w`](../../wheeler-package/src/main/wheeler/packages/manifest/ManifestTokens.w).

Covers: Wheeler-native bounded token parsing of canonical `wheeler.package.yaml` into caller-owned target/source/dependency/capability row tables, with closed schema/kinds, names, paths, releases, constraints, booleans, ordering, source closure, and exact canonical-byte publication.

Expected behavior:

- The canonical `demo.native` fixture yields header lengths `11/10/11`, two targets, two sources, two dependencies, and two capabilities with exact rewind.
- Empty trailing sections and a generated eight-target manifest pass the independent stage-0 parser, while a ninth target exhausts the fixture table.
- Wrong schema/kind, test-selected library, malformed name/path, unsorted source selectors, or selectors that omit the root trap before publication.

### `LongMap.w`

Files: [`LongMap.w`](../../wheeler-examples/src/main/wheeler/classical/data/LongMap.w) + [`collections/LongMap.w`](../../wheeler-core/src/main/wheeler/collections/LongMap.w).

Covers: Region-owned signed map using the locked core package's deterministic insert/lookup and membership API, nested exclusive mutable parameter borrows, and drop.

Expected result: `selected = 17`, `zeroKey = 5`, `present = missing = 1`.

### `OwnedReturns.w`

Source: [`OwnedReturns.w`](../../wheeler-examples/src/main/wheeler/classical/ownership/OwnedReturns.w).

Covers: Caller-region factories returning unique word, byte, immutable UTF-8, and signed-map owners through typed calls, followed by final-caller use and one consuming sink over all five owner kinds, stage-0/Wheeler interpreter parity, and exact rewind.

Expected result: `wordValue = 17`, `byteValue = 65`, `scalarCount = 2`, `mapValue = 23`.

### `Records.w`

Source: [`Records.w`](../../wheeler-examples/src/main/wheeler/classical/data/Records.w).

Covers: Nested immutable records, typed record calls, fields, and structural equality.

Expected result: `width = 5`, `equal = 1`.

### `RecursiveValue.w`

Source: [`RecursiveValue.w`](../../wheeler-examples/src/main/wheeler/classical/control/RecursiveValue.w).

Covers: Recursive signed value call under frame and step ceilings.

Expected result: `result = 6`.

### `RegionStorage.w`

Source: [`RegionStorage.w`](../../wheeler-examples/src/main/wheeler/classical/ownership/RegionStorage.w).

Covers: Consumed region-factory results, nested exclusive word/byte loans, one shared byte loan followed by resumed mutation, strict UTF-8 scanning, affine ownership, and explicit drop.

Expected result: `first = 7`, `byteValue = 65`, `byteLength = 6`, `validUtf8 = 1`, `utf8Scalars = decodedScalars = 3`, `scalarSum = 8591`, `scratchValue = 19`.

### `Utf8Lexer.w`

Files: [`Utf8Lexer.w`](../../wheeler-examples/src/main/wheeler/text/Utf8Lexer.w) + [`lexer/Parser.w`](../../wheeler-examples/src/main/wheeler/lexer/Parser.w) + [`lexer/Scanner.w`](../../wheeler-compiler/src/main/wheeler/lexer/Scanner.w).

Covers: An explicit host UTF-8 source scanned and parsed by dependency-first modules. The scanner creates region-owned identifier, number, punctuation, escaped ASCII literal, and line or block comment tokens. It supports digits after the first identifier character, bounded signed-decimal parsing, and stable diagnostic codes with byte offset, line, and column. A typed-local-declaration parser consumes those tokens.

Expected behavior:

- Input `long x2=123;/*c*/` gives `tokenCount = 6`, `numberStart = 8`, `commentStart = 12`, `numericValue = 123`, `lexicalCode = 0`, `outputLength = 3`, `finalCursor = 17`.
- Malformed comment, literal, and token-capacity cases report codes 1, 2, and 3 with one-based source coordinates.
- Output `123`.

### `Variants.w`

Source: [`Variants.w`](../../wheeler-examples/src/main/wheeler/classical/data/Variants.w).

Covers: Closed tagged variants, typed construction, structural equality, and exhaustive payload selection.

Expected result: `selected = 9`, `equal = 1`.

### `WorkQueue.w`

Files: [`WorkQueue.w`](../../wheeler-examples/src/main/wheeler/classical/data/WorkQueue.w) + [`collections/LongQueue.w`](../../wheeler-core/src/main/wheeler/collections/LongQueue.w).

Covers: Bounded FIFO over an exclusive word-buffer borrow with immutable cursor and explicit `Full`/`Empty` results.

Expected result: `first = 4`, `second = 9`, `finalHead = 2`, `finalTail = 4`, `emptyObserved = fullObserved = 1`.

### `CoherentOracle.w`

Source: [`CoherentOracle.w`](../../wheeler-examples/src/main/wheeler/quantum/CoherentOracle.w).

Covers: One XOR function over classical and coherent data.

Expected result: `bit = 0`, `measured = 1`.

### `QFT.w`

Source: [`QFT.w`](../../wheeler-examples/src/main/wheeler/quantum/QFT.w).

Covers: Quantum Fourier transform whose qreg size is a compile-time constant, with a generated adjoint and kernel-checked adjoint certificate.

Expected result: `measured = 5`.

### `QFTProof.w`

Source: [`QFTProof.w`](../../wheeler-examples/src/main/wheeler/quantum/QFTProof.w).

Covers: Executable two-qubit inverse law.

Expected result: `measured = 2`.

### `QuantumOptimizer.w`

Source: [`QuantumOptimizer.w`](../../wheeler-examples/src/main/wheeler/quantum/QuantumOptimizer.w).

Covers: Two target observations, reversible acceptance update, commit, and target-free replay.

Expected result: `sample = 1`, `bestCost = 1`, `accepted = 1`.

### `QuantumNeuralNetwork.w`

Source: [`QuantumNeuralNetwork.w`](../../wheeler-examples/src/main/wheeler/quantum/QuantumNeuralNetwork.w).

Covers: One-bit coherent activation layer.

Expected result: `activation = 1`, `measured = 0`.

### `QuantumCompiler.w`

Source: [`QuantumCompiler.w`](../../wheeler-examples/src/main/wheeler/quantum/QuantumCompiler.w).

Covers: Kernel-checked adjacent-inverse normalization plus basis-state execution.

Expected result: `sourceResult = normalizedResult = 1`.

### `SurfaceCode.w`

Source: [`SurfaceCode.w`](../../wheeler-examples/src/main/wheeler/quantum/SurfaceCode.w).

Covers: Static correction kernel and generated adjoint.

Expected result: `measured = 0`.

## Scope boundaries

No checked-in example uses the planned WIP-0032 unified I/O API. `HostInput.w`, `HostBinaryInput.w`, and the current asynchronous quantum jobs cover the smaller host boundaries that exist today. They do not implement `IoScope`, operation graphs, or durability receipts. The planned conformance fixture remains in [WIP-0010](proposals/WIP-0010-executable-application-portfolio.md) and the [future I/O page](future/io-fabric.md) until a full vertical slice can compile, parse, format, and run.

`BinaryTree.w` uses three fixed state slots. Generic nodes, allocation, ownership, and unbounded traversal are outside its scope. Those features belong to the self-hosting language work.

`QFTProof.w` is an executable conformance law. The trusted proof kernel does not accept it as a theorem. It checks that the generated adjoint restores one basis state on the semantic simulator.

`QuantumOptimizer.w` uses deterministic basis candidates so CI can check exact observations. Its event-log test records both jobs, then reproduces the classical result through replay without another target call. Parameter binding, sampled objective estimates, and convergence loops remain separate work.

`QuantumNeuralNetwork.w` shows that one coherent reversible function can act as a classical activation and a quantum permutation. Training arrays, gradients, and floating-point optimizers are not part of this example.

`QuantumCompiler.w` checks one small compiler law in two ways. Its exact cancellation rewrite carries a kernel certificate, and execution checks the basis behavior. This fixture is separate from the larger self-hosted compiler effort.

`SurfaceCode.w` is static. A full syndrome loop needs measurement, reset, bounded decoding, conditional correction, and a target that supports dynamic resident control. Wheeler must reject that workflow on a static target; it cannot hide the cost of host round trips.

## Running the suite

The canonical [`wheeler.package.yaml`](../../wheeler-examples/wheeler.package.yaml) declares every example as a package target. Use the same commands to check them all:

```bash
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='check .'
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='test .'
```

See the [development guide](reference/development.md) for the full gate. The normal `check` and `treeSitterTest` tasks cover every example. None is excluded as future syntax.
