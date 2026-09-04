# WIP-0346: Native compiler resolved return-call suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0345 |
| Supersedes | Product-only resolved forwarding return-call evidence |
| Superseded by | None |
| Follow-up | WIP-0347 native compiler terminal return profile |

## Summary

Execute every public query in `ResolvedReturnCallKinds.w` through independent native compiler package cases.

The classifier and arity cases reach the seven-argument sentinel. Four source-decoder cases reach local 255 in every coordinate of the final four-argument packed opcode. `ResolvedStatements.w` remains complete physical input.

## Graph

```text
NativeCompilerResolvedReturnCallTests
  -> ResolvedReturnCallKinds
       -> ResolvedStatements
```

The test owner does not copy a base, range width, source count, or arity bound.

## Evidence

`NativeCompilerResolvedReturnEntryExampleTest` compiles one physical entry that invokes all six queries. The native artifact matches stage 0 byte for byte and executes successfully.

| Case | Artifact identity | Coverage identity |
| --- | --- | --- |
| `classifiesSevenArgumentReturnCall` | `faea7fdc36f464d7fc1a5d1289d35760a04af5f13de80d81428b3ddaaca83770` | `1fbeff7ab88b40b296cfb14c596738cb854b819954567b3c812438fdfee312bc` |
| `decodesSevenArgumentReturnCallArity` | `1394864849118962bddaf486b6a5da6dea3692f625cd3a8f3dc7d8af35628c18` | `32a35916988b5bae7505eac35a924139ef70071f7c94f1f447fc14ccadd3aa7c` |
| `decodesFinalFourArgumentFirstSource` | `804e3610c780f67d5ccc5e774587f5791fc32301862d668e20a7b38f1b5952e6` | `e764083206fbce74a66390d5e891846e9a00488433ebe74dd8889396ce525ced` |
| `decodesFinalFourArgumentSecondSource` | `899a06d227c2aadd6f7a48f9fd29a9dad2db2eccaa1414002a740e8bcc188c24` | `7fec7356c0b81a8129d1929902d65d10dde1f628a51d87764c4d185ee38bc4ac` |
| `decodesFinalFourArgumentThirdSource` | `4ae2ee21dc0ebabed558e062f3b5cfe518d975447451957077894fc656b22898` | `4e07b24c7dc0f04f9ad21b2fec17747201f22ea77b38524bb4c9c64a09136606` |
| `decodesFinalFourArgumentFourthSource` | `f7541d3bb819c9b421f2197fd99b320b33b61d18f4bd37696874e40dec6aba08` | `9382fb46f573180192d93d8a4b2649f47fa49eb02a175cbaae5ccf9806ac8e38` |

All cases share source identity `a96e29e0a447bbafd19dc972fc2e3c78018446e23bd37aea95567556f1ce0783` and execution identity `f08e201107ae215f775dd544fedd94d9c6d614dc56c19726d835b6e08c339bf9`.

`wheeler test wheeler-compiler --format json` publishes 125 selected, 125 passed, and zero failed cases with report identity `b6eb065c4ec87614db2cb80a155b17c0a3633b1de6a2dcd1f5c51bf8f41eeba4`. The canonical workspace checks 143 targets.

## Acceptance

- [x] All six public queries have independent native cases.
- [x] Complete physical opcode ownership remains input.
- [x] The seven-argument sentinel classifies and reports its arity.
- [x] Every final four-argument source coordinate decodes to 255.
- [x] The physical artifact matches stage 0 byte for byte.
- [x] Every selected case executes exactly once.
- [x] JSON, terminal, and JUnit adapters consume the same 125 rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete package run finished in ten minutes and twenty-three seconds. Its host guard is twelve minutes.

The compiler manifest contains 20,571 bytes. The compiler archive contains 3,080,183 bytes with SHA-256 `b63aaefd94925b7504c28657feda4074901fb72025ec2673327ffa24cb5cba97`. Its root manifest identity is `fa533aae15e09328772b210ddc86d60cbcf54e5d9146921e3035104ba721597f`.

## Rejected alternatives

### Check only arities one through four

Rejected. Zero and five through seven use scalar sentinels outside packed opcode ranges.

### Decode a low four-argument opcode

Rejected. The final packed opcode proves every coordinate and the upper range width.

### Recompute packed coordinates in test source

Rejected. The physical production module remains decoder authority.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0345](WIP-0345-native-24k-test-manifest-bound.md)
- [WIP-0347](WIP-0347-native-compiler-terminal-return-profile.md)
