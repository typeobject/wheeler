# WIP-0335: Native compiler resolved local-operation suites

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0334 |
| Supersedes | Product-only resolved copy and signed-operation evidence |
| Superseded by | WIP-0336 native compiler resolved local-loop form suite |

## Summary

Execute all public queries in `ResolvedLocalCopyKinds.w` and `ResolvedLongOperations.w` through eight independent native compiler package cases.

The copy suite covers signed assertions, signed copies, Boolean copies, and Boolean negation. The signed-operation suite covers literal-right and local-pair membership and source decoding through their terminal AND columns.

## Graphs

Two canonical graphs retain the shared opcode owner without manufacturing a redundant root edge:

```text
NativeCompilerResolvedLocalCopyTests
  -> ResolvedLocalCopyKinds
       -> ResolvedStatements

NativeCompilerResolvedLongOperationTests
  -> ResolvedLongOperations
       -> ResolvedStatements
```

Complete graph validation rejects a combined root importing both classifiers. The package keeps two physical targets rather than weakening rooted-edge or owner checks for a fixture.

## Differential evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry for each graph. Each entry calls all four public functions in its physical owner, matches stage 0 byte for byte, and executes successfully.

The copy target has source identity `16652872b17e905ed8e0c4404474e6aa6e0e345fe4c17026b167a83c8020767c` and execution identity `9d8e924d0d35c2783ba3096c51c2ab5d0106b7e669f4ded10aa3d4fcfc6d62c4`.

| Copy query | Artifact identity | Coverage identity |
| --- | --- | --- |
| Signed assertion | `e0c537311f986243a672c8afcd78762268582995e8043084fec1cdaec68bf1a0` | `d99bf6424b7cd1db9441af329ec639b4fe0bbcbbc89af26b65f7e532340b52a3` |
| Signed copy | `2e71123d8f274baf0091f861e03572dbce6ae057ab6b3c7fc2782360f2e35bda` | `a8ba2808fcfde1dcefaf88e5915b871cd9faa3501ca26eca716638e928b9e3c3` |
| Boolean copy | `c5910e4b74cbce6bfcee36a012115ef895d97881838b314936ff2e072848de9c` | `b832e6feea4e470d0c8913d42479e36be389e8bb85e0bcf4ba3406b130b47d30` |
| Boolean negation | `a0f53cdcecf882d6754112f15df19ae83d693a208ba360c1911c3f42df7ae03e` | `fedbd4aabaaf4becb6decfff0e39ebf9fbe792084036a4797dbaaef94baa5318` |

The signed-operation target has source identity `83ead504f6ef448bed43e7dc2d76255e8f317726cb9082b90d8040ebba387276` and execution identity `98c36dbc3c57e77985e00d41d2969b32eaec03d26e73c112bce9299227de3718`.

| Signed-operation query | Artifact identity | Coverage identity |
| --- | --- | --- |
| Binary membership | `8b9cc87d375e093d65d98a5bbe6bbb7120ca0b2a560461e74e62363d87aedaaf` | `8ea4b4e78518a36155932e2ad2561f4708ca07ada807872dd8075ed2da3a4d56` |
| Binary source | `75e97954a6b39909342449c1d6591f5653cd00f7c0c4288283dcdc680d064e01` | `3d5ac867ac817bd25df7798c27f3d01f7b30dd7b59cb263f21e417252445a990` |
| Pair membership | `212e6a353419ea62f9e4b95f028134ef9098cb96b541432b5174389ecea61e87` | `c7d7e09850da3c39fc16b1d16d3f726eafebcf53761172055a4019e913e70cd6` |
| Pair source | `14768382ce512859da61ecc37e508e7628397b2bc247fbc7f1db1e3e418ae914` | `d3307d978c28f03db4b63baea8c3722ba569e5697db9c0c76fe634083f0b2248` |

`wheeler test wheeler-compiler --format json` publishes eighty-five selected, eighty-five passed, and zero failed cases with report identity `2858c1527dbf30b1aa2bbb118285563152b206b4b0e8599ad3ce909c374b8fad`. The canonical workspace checks 131 targets.

## Acceptance

- [x] All eight public queries have independent native cases.
- [x] Every membership case reaches its final admitted opcode.
- [x] Both decoders reach the terminal AND column.
- [x] Two complete physical artifacts match stage 0 byte for byte.
- [x] Each combined artifact executes exactly once.
- [x] Eight selected cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same eighty-five rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete run finished in five minutes and fifty-six seconds. Its host guard is seven minutes. Native step and history bounds remain unchanged.

The compiler manifest contains 14,411 bytes. The compiler archive contains 3,063,336 bytes with SHA-256 `d6cd292ca28689dc4aec817f24cf6985ed155e6f7ffaa38ecc1610aafbb52a72`. Its root manifest identity is `1919ce37250d3d2e09ea0e75bc880a37e459eba0fb20cb87f11f6f89995de82d`.

## Rejected alternatives

### Force both owners through one root

Rejected. The graph validator rejects the redundant shared dependency shape before compilation. Tests do not authorize graph normalization.

### Check only the first arithmetic family

Rejected. Multiplication, division, remainder, and AND occupy later disjoint columns.

### Retain one package case per owner

Rejected. Independent public queries require independent artifact and coverage identities.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0334](WIP-0334-native-compiler-resolved-local-assignment-suite.md)
- [WIP-0336](WIP-0336-native-compiler-resolved-local-loop-form-suite.md)
