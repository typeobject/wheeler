# WIP-0257: Native parameter-row compilation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, native testing, source compilation |
| Depends on | WIP-0249, WIP-0255, WIP-0256 |
| Supersedes | Transported artifacts for bounded scalar parameter rows |
| Superseded by | None |
| Follow-up | Native test metadata compilation |

## Summary

Compile native-discovered `long` and `boolean` parameter rows without transported artifacts.

For each selected zero-artifact row, the runtime lowers the source declaration into one direct entry. The lowered entry declares the exact native-discovered parameter value before the original body:

```wheeler
entry void main() {long input = -1;
  // original body
}
```

Boolean rows use exact `false` or `true` text. The physical compiler, verifier, interpreter, coverage reducer, and report reducer then own the same one-attempt path as parameterless native cases.

## Exact lowering

`TestSourceLowering.w::parameterizedEntrySourceLength` scans the validated root and locates the exact declaration-name token already bound to the descriptor. It finds the body through the first canonical opening-brace token after the declaration header.

The generated prefix contains:

- `entry void main() {`
- exact `long ` or `boolean ` type text
- the original parameter-name token bytes
- ` = `
- canonical signed decimal or Boolean value text
- `;`

Lowering removes the original parameter list, `cases(...)`, tags, limits, and opening brace. It retains every original body byte after that brace. Peer test declarations are blanked through balanced body braces at their original width.

Signed decimal emission keeps all values in the nonpositive domain while extracting digits. This admits `Long.MIN_VALUE` without negation overflow. Positive values are converted once to their exact negative magnitude, and digits are written from right to left.

## Bounds

The lowered root remains within the physical compiler's 4,096-byte per-source ceiling. Oversize lowering rejects before private plan construction.

A parameter prefix can grow the validated 32,768-byte source plan. The private lowered-plan ceiling is 33,048 bytes. The lowering region reserves exactly 37,144 bytes for one maximum lowered plan and one maximum compiler source.

The fixed graph remains one root plus at most seven imports. Every selected row gets fresh lowering and artifact recovery storage after shard assignment.

## Artifact modes

All descriptors in one transport remain either nonempty transported artifacts or zero-length native source products. Parameterless and parameterized native cases may coexist because discovery publishes case kind and value by canonical descriptor ordinal.

Transported rows retain WIP-0252 synthetic-entry authorization. Native rows bypass that check because the trusted native compiler emits their direct entry from the validated source and discovered value.

## Evidence

`compilesCanonicalLongAndBooleanRowsNatively` supplies canonical zero-artifact descriptors for `false`, `true`, `-1`, `0`, and `2`.

The runtime discovers all five values, derives exact lowered source lengths, emits Boolean or signed local declarations, blanks the peer test, compiles each selected row, verifies each committed artifact once, executes each once with fresh storage, and publishes five selected and five passed cases.

The physical artifacts execute `LOCAL_CONST` and `LOCAL_MOVE` transitions for each injected row before the original assertion body. No Java artifact enters the transport.

Transported row discovery, function authorization, and swapped-row rejection remain green beside native compilation.

The runtime archive contains 297,457 bytes with SHA-256 `68868aa16ce0d76746e9fa5fcf6acaf278da1adfcf3168bcd4cab3ae4e943afa` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,094 bytes with SHA-256 `b866164f0216db3c6b2e0662e0c36510863a4324a0481b4a4831b3890c0d5a3b` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Native `long` rows lower to exact signed decimal declarations.
- [x] Native Boolean rows lower to exact `false` or `true` declarations.
- [x] Original parameter-name token bytes are retained.
- [x] Original body bytes remain exact after the opening brace.
- [x] Cases, tags, limits, and parameter syntax do not reach the fixed compiler.
- [x] Parameterless and parameterized native cases may coexist.
- [x] Lowered source and private plan bounds are explicit.
- [x] Shard assignment precedes each row compiler attempt.
- [x] Five mixed scalar rows compile, verify, execute, and pass.
- [x] Java supplies no consumed row artifact.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Compile one synthetic wrapper supplied by Java

Rejected. Java cannot provide source or artifact semantics to native source mode.

### Preserve `cases(...)` for the fixed compiler

Rejected. The fixed physical frontend has no test metadata grammar.

### Convert signed values through absolute magnitude

Rejected. `Long.MIN_VALUE` has no positive signed magnitude.

### Compile every row before sharding

Rejected. Discovery is complete before scheduling, but compiler attempts belong only to selected cases.

## References

- [WIP-0249](WIP-0249-native-parameter-row-discovery.md)
- [WIP-0255](WIP-0255-native-counted-test-compilation.md)
- [WIP-0256](WIP-0256-native-test-lowering-authority.md)
