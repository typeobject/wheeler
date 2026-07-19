# WIP-0017: Compile-time constants and finite enums

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler language, compiler, bytecode, quantum, proof, and tooling maintainers |
| Created | 2026-07-18 |
| Updated | 2026-07-18 |
| Area | Named values, finite types, constant evaluation, reversible and coherent semantics |
| Depends on | WIP-0001, WIP-0005, WIP-0006 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler supports immutable compile-time constants and finite enum types. Constants are typed names evaluated by the compiler. They allocate no globals, execute no initializer, and depend on no module load order. WIP-0029 reuses this exact bounded evaluator for const-generic lengths, widths, moduli, shapes, resource limits, and finite-basis cardinalities; it does not add arbitrary compile-time execution.

An enum is the nullary case of Wheeler's existing closed variant model, not a second object hierarchy. Enum members have semantic names but no implicit ordinal, integer conversion, singleton identity, or hidden wire value. Protocol encodings remain explicit ordinary Wheeler functions built from named constants, exhaustive enum matches, and checked decode results.

This separation matters. `Opcode.Halt` is a semantic member of a finite type. `OPCODE_HALT = 0x0001` is a bytecode-format constant. Equating the two by invisible ordinal works until a source reorder changes a protocol, a quantum basis, and everybody's afternoon.

WIP-0017 is a prerequisite for widening the Wheeler-written bootstrap compiler, verifier, and interpreter. Those modules should stop accumulating raw opcode, section, token, proof-rule, diagnostic, and package-record integers before they learn more of the machine.

## Motivation

The bounded self-hosting slices currently recognize protocol identities as raw `long` literals. That was tolerable while a module handled six cases. It does not scale to a readable verifier or interpreter: reviewers must remember which domain owns `513`, accidental cross-domain comparisons type-check, and duplicated tables drift.

Constants give limits and wire identities one source name. Enums give finite semantic domains exhaustive handling and nominal separation. Wheeler needs both, but they must not be collapsed:

- constants model values known during compilation;
- enums model closed choices;
- codecs model representations at trust boundaries;
- variants model closed choices with payloads;
- proofs establish properties of those models rather than being inferred from confident capitalization.

Haskell's algebraic-data-type lesson applies: a finite choice is a sum type, not a small integer in formal wear. Wheeler adds explicit reversible, coherent, artifact, and host-effect boundaries on top.

## Use cases

1. A verifier compares an encoded instruction with `OPCODE_HALT`, imported from one bytecode-format module, rather than `1`.
2. A decoder returns `OpcodeDecode.Value(Opcode.Halt)` or `OpcodeDecode.Unknown(raw)`. A match over `Opcode` is exhaustive.
3. A package codec uses `MAX_PLAN_NODES` as a compile-time bound. No state slot or initializer appears in `.wbc`.
4. A reversible transformation permutes all members of a finite enum. The compiler checks bijectivity and derives the inverse table.
5. A future coherent enum permutation acts on a power-of-two finite basis with no invalid bit patterns. Wire codes do not become amplitudes by proximity.
6. Two imports export `MAX_DEPTH`. Unqualified use fails as ambiguous; canonical module qualification resolves the owner.

## Goals

- Provide typed scalar `const` declarations and bounded deterministic evaluation.
- Provide `enum` as exact source sugar for a payload-free closed variant.
- Preserve one nominal sum-type, matching, visibility, and metadata model.
- Keep semantic enum membership separate from integer/wire encoding.
- Support exhaustive classical matches over enum members.
- Define reversible enum operations as checked finite permutations.
- Define a sound path for coherent enum operations without reserving bogus current syntax.
- Support public export, direct import, and canonical module qualification.
- Give compiler, Tree-sitter, formatter, documentation, and diagnostics stable nodes.
- Replace bootstrap number soup before expanding the native verifier/interpreter opcode surface.

## Non-goals

- Mutable static fields, Java class initialization, static blocks, reflection, or process-wide registries.
- Implicit enum ordinals, `.ordinal()`, auto-numbering, integer casts, or persisted declaration positions.
- A parallel enum runtime beside tagged variants.
- Bit-flag enums. Bit masks remain named `const long` values or a later checked flag-set type.
- Arbitrary compile-time execution, macros, user-defined constant functions, file reads, environment access, network access, clocks, randomness, or provider SDKs.
- Declaring that every enum is automatically reversible, coherent, measurable, or safe to decode.
- Dynamic target-resident quantum control in this WIP.
- Keeping raw-literal compatibility aliases after bootstrap migration.

## Source syntax

### Constants

A constant is a member declaration with an explicit type and initializer:

```java
public const long MAX_FRAME_DEPTH = 8;
private const boolean VERIFY_OPERANDS = true;
public const long OPCODE_CALL = 0x0200;
```

`const` is not `state`. It creates no global slot, cannot be assigned, cannot be borrowed, and has no address or object identity. The first profile permits `long` and `boolean`; later immutable values require an explicit extension because “known at compile time” is not a storage model.

Public constants should use `UPPER_SNAKE_CASE`. Naming is a tooling convention, not an alternate resolver.

### Enums

An enum declares one or more payload-free cases:

```java
public enum Opcode {
  case Halt;
  case Return;
  case Call;
  case Uncall;
}
```

This elaborates exactly to the existing sum-type shape:

```java
public variant Opcode {
  case Halt();
  case Return();
  case Call();
  case Uncall();
}
```

The two spellings cannot declare distinguishable runtime types. The compiler, bytecode verifier, VM, match checker, debugger, documentation generator, and proof kernel share one case/type authority. An enum cannot later grow payload on one case; changing it to `variant` is an explicit source migration.

Cases use ordinary nominal values:

```java
Opcode operation = new Opcode.Call();

match (operation) {
  case Opcode.Halt() { }
  case Opcode.Return() { }
  case Opcode.Call() { }
  case Opcode.Uncall() { }
}
```

The first canonical value and match spelling is exact variant parity: `new Opcode.Call()` constructs a value and `case Opcode.Call()` selects it. `enum` removes payload punctuation from declarations, not from the value model. A later terse value spelling would require a separate syntax decision and must elaborate to the same case; the bootstrap does not need another parser path merely to save five characters.

### Protocol encodings

Enum declarations carry no wire values. A codec states the mapping in ordinary checked Wheeler:

```java
public const long OPCODE_HALT = 0x0001;
public const long OPCODE_RETURN = 0x0002;

public long encodeOpcode(Opcode opcode) {
  match (opcode) {
    case Opcode.Halt() { return OPCODE_HALT; }
    case Opcode.Return() { return OPCODE_RETURN; }
  }
}

public OpcodeDecode decodeOpcode(long raw) {
  if (raw == OPCODE_HALT) {
    return new OpcodeDecode.Value(new Opcode.Halt());
  }

  if (raw == OPCODE_RETURN) {
    return new OpcodeDecode.Value(new Opcode.Return());
  }

  return new OpcodeDecode.Unknown(raw);
}
```

`OpcodeDecode` is an ordinary explicit variant. There is no unchecked `Opcode(raw)` constructor. The type checker can recognize total enum encoders and duplicate constant values for diagnostics and future proof generation, but the source mapping remains inspectable code rather than a hidden derived instance.

A future declaration-level codec shorthand may elaborate to this pattern only after its generated API, diagnostics, proofs, and deletion behavior are specified. WIP-0017 does not need one to remove number soup.

### Qualification

Within the declaring module, constants and enums use local names. Direct imports expose public declarations unqualified only when exactly one candidate exists. Canonical qualification uses Wheeler's existing module separator:

```java
long call = examples.bytecode.opcodes::OPCODE_CALL;
examples.bytecode.opcodes::Opcode opcode =
  new examples.bytecode.opcodes::Opcode.Call();
```

Private names do not enter imports. Transitive imports do not re-export names absent an explicit future re-export rule.

## Constant expression model

A **constant expression** is side-effect-free syntax over:

- signed `long` and Boolean literals;
- same-module or imported public constants;
- parentheses;
- checked unary negation;
- checked `+`, `-`, `*`, `/`, and `%`;
- bitwise `^` and `&`;
- `==` and `<`, yielding Boolean;
- a small closed set of specified pure integer intrinsics, beginning with `rotateRight32` only when a checked-in declaration needs it.

Constant expressions cannot read state, locals, parameters, host input, aggregate stores, regions, buffers, package discovery, clocks, randomness, function bodies, quantum state, measurement results, or provider state.

The compiler builds one dependency graph for constants in the closed source set. Resolution and evaluation use canonical qualified-name order, not map iteration or parser arrival order. Forward references are valid. Cycles report a bounded complete cycle and produce no artifact.

Evaluation uses Wheeler runtime arithmetic rules: signed overflow traps; division and remainder by zero fail; `Long.MIN_VALUE / -1` fails; rotation ranges are checked. A `long` result remains signed 64-bit. There is no host-language narrowing, unlimited intermediate integer, or “close enough” literal.

## Semantic model

A constant declaration disappears after type checking and substitution. Debug metadata may retain its source name for diagnostics, but execution cannot observe whether a literal came from a constant.

An enum is a finite nominal type with cardinality equal to its case count. Case names, owning type identity, and membership are semantic. Declaration order is documentation order only. Canonical metadata orders cases by their stable qualified case names so source reordering alone does not alter execution artifacts.

Renaming, adding, or removing a case changes the enum type identity. A protocol codec may preserve old wire values deliberately, but no compiler-assigned ordinal survives the type change because none exists.

Enum equality is permitted only within one enum type. Cross-enum equality and enum/integer operations fail statically. Pattern matching is exhaustive using the same rules as variants. Empty enums are rejected; bottom types deserve their own design rather than an accidental empty brace.

## Compiler and artifact boundaries

The source parser owns declarations and exact spans. The resolver owns visibility, qualification, ambiguity, dependency graphs, and duplicate names. The type checker owns expression types, enum nominality, match exhaustiveness, and constant-use legality. The constant evaluator owns bounded checked evaluation.

Lowering receives resolved values. Scalar constants become literal operands or IR constants at use sites. They do not add globals, functions, sections, or startup code.

Enums reuse payload-free variant metadata and values. The canonical writer may use a compact immediate representation for payload-free cases, but that is an encoding optimization under the variant type identity. It cannot create different source behavior or a second decoder. Canonical `.wbc` remains format `1.0`.

Artifact decoders reject unknown enum/variant type IDs, unknown case IDs, payload on enum cases, duplicate metadata, noncanonical case ordering, and type-incompatible locals. Source-order positions are not persisted wire values.

## Reversibility

Finite type does not mean reversible operation. A function from `Opcode` to `boolean` loses information; a function mapping every opcode to `Halt` is not rescued by a small domain.

A reversible enum transformation must be a permutation of the complete case set. For a finite pattern-defined function, the compiler can construct its table and require:

- every input case is covered exactly once;
- every output case appears exactly once;
- no branch performs irreversible effects;
- the generated inverse table maps each output back to its unique input.

For example, swapping two states and leaving all others fixed is reversible:

```java
rev Opcode swapCallDirection(Opcode opcode) {
  match (opcode) {
    case Opcode.Call() { return new Opcode.Uncall(); }
    case Opcode.Uncall() { return new Opcode.Call(); }
    case Opcode.Halt() { return new Opcode.Halt(); }
    case Opcode.Return() { return new Opcode.Return(); }
  }
}
```

The current source profile does not yet accept this parameter/result form for `rev`; the example states the required semantics, not implemented syntax. Until typed reversible calls exist, enum values follow ordinary immutable local and variant rules.

Destructive enum assignment is logged or ordinary according to its context. Reversible mutation uses a checked permutation, swap, or retained prior value. VM rewind restores the exact nominal value from ordinary frame history. Language inversion and rewind remain different mechanisms.

Encoding an enum to a `long` is injective only if the explicit codec values are distinct. Decoding is partial over all `long` values. Ordinary package/bytecode decoders should remain ordinary checked functions; labeling partial input validation `rev` would not improve its inverse.

## Coherent and quantum semantics

A finite enum is a useful candidate for a quantum basis, but no wire encoding defines that basis. Wheeler derives coherent basis identity from canonical enum case identity, never from protocol integers.

The first coherent enum profile permits only cardinalities that are exact powers of two. An enum with `2^n` cases maps to `n` qubits in canonical qualified-case-name order. This avoids unused computational-basis states. Non-power-of-two enums remain valid classical types but cannot cross a coherent boundary until a later proposal defines subspace validity, leakage behavior, and uncomputation obligations.

A coherent enum transformation must be a permutation of all cases and therefore induces a unitary permutation matrix. The compiler may synthesize a circuit and inverse from a checked finite permutation. The artifact records enum type identity, canonical case-to-basis mapping, and permutation identity. A target cannot reorder cases according to a vendor enum or calibration table.

Classical matching on a coherent enum would observe the basis and is forbidden inside a coherent region. Coherent control uses permutation/control lowering without measurement. Measurement consumes the coherent value under WIP-0002 rules and returns an ordinary classical enum result. It is not an assignment that can be uncalled.

Wire encoding functions are classical. `OPCODE_CALL = 0x0200` does not place `Call` at basis state 512, allocate 10 qubits, or make a bytecode decoder unitary. This distinction is the main reason enums are not backed integers.

Dynamic target-resident control, reset, and correction remain WIP-0010/WIP-0002 work. WIP-0017 reserves no syntax for them.

## Proof implications

Enums provide finite domains for future quantified propositions. The proof kernel can derive cardinality and case identity from canonical type metadata and can check a claimed permutation by exhaustive finite enumeration.

Useful future certificate rules include:

- enum match exhaustiveness;
- finite permutation bijectivity;
- generated inverse equality;
- codec injectivity over enum inputs;
- decoder/encoder round-trip for declared cases.

Search is not proof. The kernel checks each finite table, type identity, case set, and output uniqueness. A theorem over an enum does not quantify over its codec's unknown raw integers unless the proposition says so.

Constants used in proof bounds are resolved to typed values before certificate construction. Changing a public constant changes the proposition/artifact identity when the value is semantically embedded.

## Ownership and module boundaries

Constants and enum values are immutable and freely copyable unless contained in an affine owner. They own no regions or buffers and require no drop.

Public constant and enum declarations participate in direct module export. Import ambiguity fails closed. The package manifest still defines the closed source set and source order; constants cannot be overridden by package features, environment variables, command-line `-D` flags, editor settings, or target selection.

The bootstrap should introduce domain modules rather than one junk drawer:

```text
compiler/ir/Opcodes.w
compiler/SectionKinds.w
compiler/ir/TypeCodes.w
compiler/ir/ProofRules.w
packages/RecordKinds.w
lexer/TokenKinds.w
```

Each module owns related constants/enums/codecs. A thousand-line `Constants.w` is number soup with an index.

## Diagnostics

The first stable family is:

```text
WCON001 duplicate constant name
WCON002 constant dependency cycle
WCON003 nonconstant initializer
WCON004 constant arithmetic trap
WCON005 inaccessible or ambiguous constant
WCON006 invalid constant type
WENU001 enum requires at least one case
WENU002 duplicate enum case
WENU003 enum/variant name collision
WENU004 enum/integer operation requires an explicit codec
WENU005 nonexhaustive enum match
WENU006 coherent enum cardinality is not a power of two
WENU007 reversible enum mapping is not a permutation
```

Diagnostics include primary spans and canonical related declarations. Runtime unknown wire values are explicit codec results or traps chosen by source, not compiler diagnostics.

## Determinism, safety, and limits

Compilers bound constants per module/source set, enum cases, expression nodes, dependency edges, evaluation depth, diagnostics, metadata bytes, and finite permutation checks. All allocation and size arithmetic is checked.

Constant evaluation terminates because it executes no loops, recursion, allocation, user functions, or effects. Dependency cycles fail before evaluation. Enum matching is finite. Coherent synthesis is bounded by case count, qubit count, circuit operations, and target-independent compiler limits.

Determinism fixes qualified-name resolution, graph traversal, cycle reporting, arithmetic, canonical enum case order, metadata IDs, diagnostics, and artifact padding. Independent constants may evaluate concurrently only if output and diagnostics equal canonical serial evaluation byte-for-byte.

Naming a protocol integer does not validate it. Decoders still check framing, value membership, operands, authority, and digests in that order. `OPCODE_HALT` makes a comparison readable; it does not make an attacker polite.

## Formatter, Tree-sitter, and documentation

WIP-0016 formats one constant per line. Enum cases remain one per line even when compact form fits because case additions deserve local diffs. The formatter never sorts cases or rewrites codecs.

Mandatory file/function documentation applies normally. Public constants and enum declarations require adjacent documentation before WIP-0016 acceptance; case-level prose is encouraged for protocol domains but not initially mandatory.

Tree-sitter exposes named `constant_declaration`, `constant_expression`, `enum_declaration`, and `enum_case` nodes. Because enum elaborates to a nullary variant, semantic tools may expose a shared sum-type interface while retaining exact source node kind for formatting/refactoring.

Compiler and Tree-sitter corpora cover compact, multiline, commented, malformed, imported, qualified, reversible, and coherent-rejection forms.

## Migration and deletion

1. Add `const`/`enum` tokens, model records, parser productions, Tree-sitter nodes, and diagnostics.
2. Implement typed scalar constant resolution, dependency evaluation, substitution, and module visibility.
3. Elaborate enums to payload-free variants and share existing match/type/metadata paths.
4. Add enum-specific exhaustive diagnostics and canonical no-payload metadata checks.
5. Implement finite permutation analysis before typed `rev` enum functions are accepted.
6. Implement power-of-two coherent basis identity and permutation lowering before coherent enum source is checked in.
7. Create focused Wheeler identity modules for opcodes, sections, types, proofs, tokens, diagnostics, and package records.
8. Replace raw bootstrap protocol literals in domain-sized commits, with stage-0/Wheeler differential artifacts after each move.
9. Add repository checks for unexplained protocol literals in migrated modules while allowing arithmetic, offsets, and malformed golden fixtures.
10. Delete duplicate Java/Wheeler tables, aliases, migration shims, and raw-literal branches when each authority moves.

Promotion follows WIP-0007: the identity modules incubate with executable compiler slices, then move with the compiler into its production package. They are not copied into a proper directory and left behind “for examples.”

## Progress

- [x] Typed scalar `const long`/`const boolean` syntax and model exist; uses substitute ordinary local constants and create no globals or initializer.
- [x] Constant evaluation is checked, bounded, deterministic, declaration-order-independent, and cycle-safe. Scalar arithmetic, Boolean expressions, forward same-module declarations, direct imported public declarations, canonical qualification, and `rotateRight32` execute; cycles report their canonical path before artifact emission.
- [x] Direct public import and canonical `module::NAME` qualification are enforced; private and ambiguous use fails closed.
- [x] `enum` elaborates to the payload-free variant authority, and canonical case-name sorting makes source reordering artifact-stable.
- [x] Exhaustive classical enum construction, matching, and no-payload artifact execution use the variant path.
- [x] The Wheeler-written verifier validates finite-variant metadata and typed construction/tag/payload operands; the Wheeler-written interpreter differentially executes `FiniteEnums.w` and payload-carrying `Variants.w`, structurally interns values, and rejects a forged tag before execution.
- [ ] Reversible finite permutation checking exists.
- [ ] Power-of-two coherent enum basis/permutation semantics exist.
- [x] Tree-sitter nodes, highlighting, corpus fixtures, and the fixed formatter contract cover both declarations.
- [x] `compiler/ir/Opcodes.w`, `compiler/ir/TypeCodes.w`, and `compiler/ir/ProofRules.w` own the bounded Wheeler verifier/interpreter opcode/type/proof identities, interpreter limits, and membership predicates; those consumers contain no raw opcode/type dispatch literals.
- [ ] Duplicate stage-0 tables and migration shims are deleted at compiler promotion/cutover.

## Testing and acceptance

- [ ] Literal, Boolean, forward-reference, imported, and qualified constants evaluate exactly.
- [ ] Overflow, division by zero, invalid rotate, cycles, ambiguity, privacy violations, and duplicate names produce stable diagnostics and no artifact.
- [ ] Constant use emits no global, initializer function, hidden history, or runtime lookup.
- [ ] Reordering independent constant declarations leaves semantic `.wbc` byte-identical.
- [ ] Enum and equivalent nullary-variant fixtures share one semantic type path and runtime behavior.
- [ ] Reordering enum source cases leaves canonical case IDs and semantic `.wbc` byte-identical.
- [ ] Enum/integer and cross-enum operations fail statically absent explicit codec code.
- [ ] Enum matches execute every case and reject an omitted case after type growth.
- [ ] Reversible mappings accept every finite permutation and reject duplicate/missing outputs.
- [ ] Coherent power-of-two enum permutations agree with an independent state-vector oracle and generated adjoints restore amplitudes exactly within tolerance.
- [ ] Non-power-of-two coherent use fails before circuit emission.
- [ ] Measurement tests distinguish coherent enum state from classical enum result and reject attempted uncall of measurement.
- [ ] Canonical payload-free metadata round-trips and rejects forged type/case/payload references.
- [ ] Compiler and Tree-sitter parse every checked-in `.w` source after migration.
- [ ] Stage-0 and Wheeler compilers agree on constant-substituted artifacts and diagnostics.
- [ ] Wheeler verifier/interpreter contain no unexplained raw protocol identities outside focused authority modules and malformed byte fixtures.
- [ ] Every authored file remains below 1,000 lines; identity modules stay split by protocol domain.

## Alternatives

### Keep raw integers with comments

Rejected. Comments drift and cannot prevent cross-domain mistakes. `513 // UNCALL` is a confession, not an abstraction.

### Use backed integer enums

Rejected. Backing conflates semantic membership, protocol representation, and quantum basis position. It invites implicit casts, persisted ordinals, and unsafe decoding. Wheeler keeps enum, codec, and coherent basis as separate checked boundaries.

### Use only constants

Insufficient. Constants name values but do not provide a finite nominal type, exhaustiveness, permutation analysis, or coherent finite-domain semantics.

### Use only payload-free variants with no `enum` spelling

Semantically sufficient and a viable implementation baseline. The `enum` spelling documents intent, permits enum-specific diagnostics, and avoids empty `()` noise while elaborating to exactly the same variant authority. If parser/tooling cost outweighs that value, WIP acceptance may choose canonical nullary `variant` syntax and reserve no `enum` keyword; it may not create two sum-type systems.

### Give cases declaration-order ordinals

Rejected. Reordering source must not rewrite protocols or quantum basis identity. Canonical case names own semantic ordering; explicit codec constants own wire values.

### Generate codecs invisibly

Rejected for the initial design. Generated encode/decode APIs obscure partiality and trust boundaries. Ordinary exhaustive Wheeler functions are testable and proof-friendly. Later codec sugar must elaborate to visible specified semantics.

### Evaluate arbitrary pure Wheeler functions at compile time

Deferred. It requires termination, effect, cache-identity, and resource models far beyond named constants. The first evaluator remains deliberately dull.

### Store constants as immutable globals

Rejected. That adds state, startup order, bytecode, and history for values already known to the compiler. The VM need not attend every naming ceremony.

### Permit coherent encoding for any enum cardinality

Deferred. Non-power-of-two domains leave invalid computational-basis states and require a subspace/leakage contract. Refusing them initially is less clever and more correct.

## Open questions

- What certificate rule should connect an explicit codec's exhaustive encoder and partial decoder to a checked round-trip theorem? — **Owner:** proof maintainers — **Decide by:** before codec proof claims

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0006](WIP-0006-concrete-syntax-tooling-and-teaching.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0016](WIP-0016-nonconfigurable-source-formatter.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [Bytecode reference](../reference/bytecode.md)
- [Language profile](../reference/language-profile.md)
