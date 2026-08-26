# WIP-0310: Native multi-helper entry programs

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, self-hosting, and conformance maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler frontend, code generation |
| Depends on | WIP-0305 |
| Supersedes | One-helper native entry profile |
| Superseded by | WIP-0311 native compiler call-width suite |

## Summary

Compile an entry that calls one scalar helper whose body calls another scalar helper.

The old graph linker could assemble the source, but the native core admitted either one helper beside an entry or a multi-helper entryless library. A valid linked entry with two helpers reached `requireMinimalProgram` and trapped. That gap blocked physical compiler modules such as the assignment-call width decoders.

The core now parses one bounded helper table followed by an entry, resolves each entry call against that exact table, emits all helper bodies, emits the entry body, and gives the entry its canonical module-qualified name. Entry calls carry explicit statement and function columns. They no longer inherit function zero from the old one-helper shortcut.

## Design

`HelperCallSites.w` owns call-name and statement-row collection for helper and entry bodies. `ScalarHelperLibraries.w` consumes that authority instead of carrying a second collector. `ScalarHelperParsing.w` stops a helper table at either the class close or an entry declaration. It still rejects an arbitrary trailing member and a twenty-fourth helper.

`ScalarHelperPrograms.w` parses the entry body only after the complete helper table resolves. It builds one pseudo-body for call checking, resolves every call name and signature through `ScalarHelperCallResolution.w`, and publishes the resolved entry call columns in `MinimalProgram`.

`ProgramCodegen.w` emits the entry sequence after a multi-helper table when `program.library` is false. Entryless libraries still end at the canonical halt entry. `LibraryStrings.w` writes `$library` only for a library. An entry program receives `<module>::main` without losing imported helper owner qualification.

The one-helper entry parser remains authoritative for its reversible, proof, void-call, result-slot, and global-bearing forms. The table parser declines one-helper entries and does not silently widen that older contract.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles this graph through the Wheeler-native module compiler:

```text
example.entry -> example.widths -> example.arities
```

The entry calls helper one. Helper one calls helper zero. The native artifact is byte-identical to stage 0 and executes its assertion. Replacing the entry target with an absent name traps before output. Calling the transitive helper from the entry also traps because flattening does not grant root visibility.

The complete imported-helper differential still passes all one- through seven-owner and twenty-three-helper partitions. The checked-in compiler package still publishes nineteen passing native cases. The bounded physical compiler closure now contains 379 modules, 1,892 imports, and a 177,773-byte canonical module manifest. Native validation halts after exactly 74,172,747 transitions.

## Acceptance

- [x] Shared call-site collection replaces the helper-local copy.
- [x] Helper tables stop at a canonical entry declaration.
- [x] Entry calls resolve by exact name, arity, and primitive signature.
- [x] Entry call statements and function identities enter immutable IR.
- [x] Multi-helper code generation emits the entry after every helper body.
- [x] Multi-helper entry strings use the canonical qualified main name.
- [x] Entryless multi-helper libraries remain byte-identical.
- [x] One-helper entry handling retains its existing parser.
- [x] The compiled entry executes its nested call and assertion.
- [x] An absent entry call target traps before publication.
- [x] A transitive helper remains unavailable to the entry.
- [x] The complete physical product closure passes.
- [x] Compiler, runtime, package, conformance, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,036,033 bytes with SHA-256 `5662d0f45eca5ffc82f3bb5f8fc38e73bea6ae94b70756c66c9cda62c3d6dab0`. Its manifest identity remains `bbeb1cd8d20d8e5b95b1533d63ad2c952ce38ec1b2f6c1c33dfacebe5cdd1b06`.

## Rejected alternatives

### Treat the last helper as every entry call target

Rejected. Frame order is not semantic identity. Entry calls carry resolved function rows just as helper calls do.

### Inline the inner helper during graph linking

Rejected. Source linking does not own body optimization, call identity, or visibility erasure.

### Turn the entry into `$library`

Rejected. A test artifact must execute its selected case. A halt-only library entry would publish an artifact that proves nothing.

### Extend the one-helper parser with another staircase

Rejected. The complete helper-table parser already owns bounded table resolution. A second two-helper grammar would drift on the next module.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0285](WIP-0285-native-compiler-callable-suite.md)
- [WIP-0305](WIP-0305-native-compiler-call-arity-suite.md)
- [WIP-0311](WIP-0311-native-compiler-call-width-suite.md)
