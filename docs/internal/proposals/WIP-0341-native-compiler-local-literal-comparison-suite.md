# WIP-0341: Native compiler local-literal comparison suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0340 |
| Supersedes | Product-only local-literal comparison evidence |
| Superseded by | WIP-0342 native compiler resolved assertion suite |

## Summary

Execute every public decoder in `ResolvedLocalLiteralComparisonSources.w` and every public classifier in `ResolvedLocalLiteralComparisons.w` through native compiler package cases.

Both targets retain complete physical `ResolvedStatements.w` input. The seven cases reach source local 255 in equality, less-than, and inequality columns.

## Graphs

```text
NativeCompilerResolvedLocalLiteralSourceTests
  -> ResolvedLocalLiteralComparisonSources
       -> ResolvedStatements

NativeCompilerResolvedLocalLiteralComparisonTests
  -> ResolvedLocalLiteralComparisons
       -> ResolvedStatements
```

No test owner copies a base, end, or source count.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one physical entry per graph. Each native artifact matches stage 0 byte for byte and executes successfully.

| Case | Artifact identity | Coverage identity |
| --- | --- | --- |
| `decodesEqualitySource` | `bd8e1a8463695f1675d1384a55b7cab89ca4bd952e13f3f622f87be59aba8221` | `6efe4f2257bd4b33f014a9cf6f6c6f8a94b1d56019b23c18558a30855eda4849` |
| `decodesLessThanSource` | `6128fc0bb9b0e643cb08900ed61e925e3c258800bbbd6d86befab25a28339751` | `e15e15598b5acbca8d49371cf514a31487e3d95bf0b6d337e31d5905ab835edc` |
| `decodesInequalitySource` | `a359fa8e941b6932281291184bc3c6820167fecf32caa2ddc1ca9dab623b4348` | `efc4d9c8bd690ddf989d8c0216a6ea41319e5bd989b1dbc808b51cddb5e93889` |
| `classifiesEquality` | `e9508f8e639425a49cef41f131aab27aba826aaab16835e1b7e876c3c861b1c8` | `d99bf6424b7cd1db9441af329ec639b4fe0bbcbbc89af26b65f7e532340b52a3` |
| `classifiesLessThan` | `9689cc8d83884c23d4455ac027e9d83224bf9b2362481ba6467890dcbb1ae1f9` | `b832e6feea4e470d0c8913d42479e36be389e8bb85e0bcf4ba3406b130b47d30` |
| `classifiesInequality` | `3fc9c371b9b0a3863b9bbae78084fda46d0c4b77ef99658504d9f5b2ca05591e` | `a8ba2808fcfde1dcefaf88e5915b871cd9faa3501ca26eca716638e928b9e3c3` |
| `classifiesComparison` | `c712fa9b363d301f5813f81091d49c5b472fd6b339bb1dba7948769dab2b66da` | `09f051f2b0e45aa250c31d44f672401fe7388d578c0894a60096194208033676` |

The source-decoder cases share source identity `2d2119f30b9711097654926daecee978da0f2c77543d5252746f125a37c03c59` and execution identity `1b11489ec900276aefeee045feca1c803d2dbff0683c13c3eec7582b2a4e57b5`. The classifier cases share source identity `2152f99f8cb2d768ceba1fe44eae3b1a27ad0b7baf3b3cced2b0ca8bb6a7649a` and execution identity `3630251dd008da8c37496d492895f24cdd3ff2707bcabffbd2ff73ef18971202`.

`wheeler test wheeler-compiler --format json` publishes one hundred selected, one hundred passed, and zero failed cases with report identity `838122e5406511fcd0cfcaf0e44f89a492dc581e1dadd1fdf5ca8e5bbbf9e45d`. The canonical workspace checks 137 targets.

## Acceptance

- [x] All seven public queries have independent native cases.
- [x] Complete physical opcode ownership remains input to both graphs.
- [x] Equality, less-than, and inequality terminal sources execute.
- [x] Both physical artifacts match stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] JSON, terminal, and JUnit adapters consume the same one hundred rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete package run finished in seven minutes and three seconds. Its host guard is eight minutes.

The compiler manifest contains 17,521 bytes. The compiler archive contains 3,070,989 bytes with SHA-256 `98fb97502fafbef9eee1a8d4bf5853b1b128ccbb69ff4c4cf5d09c8743266b0d`. Its root manifest identity is `8e66c79670385f5c9aafdecdf45d4eb3dd61c48647c371af0ba726f3cdf65ba1`.

## Rejected alternatives

### Use one representative column

Rejected. The columns are disjoint and the aggregate classifier has separate gap and inequality branches.

### Publish only the aggregate classifier

Rejected. The source decoder and narrow classifiers are public compiler authority.

### Keep the seven-minute host guard

Rejected. The complete suite consumed it without exhausting any native execution bound.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0340](WIP-0340-native-compiler-resolved-local-less-than-suite.md)
- [WIP-0342](WIP-0342-native-compiler-resolved-assertion-suite.md)
