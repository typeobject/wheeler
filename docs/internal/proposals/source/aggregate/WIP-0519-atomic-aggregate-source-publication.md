# WIP-0519: Atomic aggregate source publication

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, aggregate products, publication |
| Depends on | WIP-0050, WIP-0051 |
| Supersedes | None |
| Superseded by | None |

## Failure

The aggregate adapter stages most outputs but passes the caller's carrier rows
to `writeLocalNominalCarriers`. A later imported nominal kind mismatch rejects
the module after those rows have changed. The old negative fixture checks only
the artifact and report marker, so it misses the carrier leak.

The adapter also constructs `AggregateCompiledCallableBody` after copying its
outputs. Allocation failure there can expose products without their report.
WIP-0516 must not carry either defect into counted primitive compilation. This
prerequisite repairs the existing publication boundary without claiming that
the minimal compiler, nominal composition, or runner handoff has been replaced.

## Contract

1. Validate the carrier output backing and source window before private storage
   allocation. Validate every other output backing before publication.
2. Give nested carrier rewriting a private four-column window. No nested producer
   may mutate an external output while later compilation can still reject.
3. Finish primitive validation, placeholder projection, and instruction composition
   before constructing the complete aggregate report.
4. Construct that report before copying any caller-visible row, byte, or identity.
   Copy only the active cells of each column. Preserve all inactive tails.
5. On rejection, preserve every caller buffer, input, report marker, and global.
   Private staging may change. Do not require cleanup after a trapping instruction.
6. Keep source, scanner, callable, parameter, artifact, and VM limits unchanged.
   Calculate the workspace from its actual columns and simultaneous lifetimes.

This is transport of producer-validated products, not a second bytecode verifier.
Primitive bytes and supplemental rows still do not constitute a nominal artifact.
The source-claim, global-coordinate, imported-target, and final-code verification
joins remain in WIP-0516 and WIP-0054.

## Storage

The adapter owns these word windows:

| Group | Cells | Buffers |
| --- | ---: | ---: |
| Statements, values, structures, local counts, statement locals | `4096*6 + 1024*7 + 1024 + 64 + 4096*2 = 41024` | 5 |
| Local projections and carriers | `512*8 + 512*4 = 6144` | 2 |
| Destinations, owners, arguments, placements, function/direction joins | `256*2 + 1024 + 256*3 + 256*2 = 2816` | 6 |
| Constructors, owners, projections, slices, resolved operands | `256*3 + 256*2 + 256*4 + 256 + 256*6 = 4096` | 6 |
| Primitive, projected, and composed functions/instructions, placements, selectors | `3*(64*10 + 4096*6) + 256*3 + 4096 = 80512` | 8 |
| Imported nominal and carrier projections | `16384*3 + 16384*4 = 114688` | 2 |
| Total | `249280` | 29 |

Seven source buffers can coexist: the original and six private projections.
Their worst-case storage is `7*32768 = 229376` bytes. The exact source adds one
lifetime identity after earlier source buffers have been dropped. Freezing the
original source preserves its buffer identity.

Primitive code, supplemental code, and SHA output need
`32768 + 12288 + 32 = 45088` bytes in three buffers. The reservation is therefore
`249280*8 + 229376 + 45088 = 2268704` bytes. Lifetime identities total
`29 + 3 + 7 + 1 = 40`. At most 39 of this arena's buffers coexist. Nested phases
own separate arenas. These counts exclude parser and result records.

Buffer bounds do not establish native frame fit. The aggregate function keeps
55 parameters, but its stage-0 frame grows from 1,199 to 1,247 locals. Both exceed
the native source-product frame bound of 256. No frame limit changes here.
WIP-0516 must extract coherent phases before this physical body can compile
through the counted native path.

The old reservation was 2,275,488 bytes with 39 identities. Private carrier rows
add 16,384 live bytes and one identity, but calculating the actual simultaneous
source lifetimes removes the old unexplained byte allowance. No limit increases.

## Evidence

The original kind-mismatch input exposes the defect before the repair: caller
buffer 9, the 2,048-cell carrier table, changes on rejection. The replacement
fixture checks all prepared caller buffers rather than assuming they contain
zeros. It fills every publication cell and byte with sentinel 211.

Direct checks cover both wrong carrier backing sizes, late imported nominal
rejection, all seventeen word windows, both code windows, the digest, and the
complete report. The success fixture stops immediately before report allocation
and requires every caller buffer to remain unchanged. It then compares complete
published windows against the private validated products, including inactive
tails. Canonical primitive re-encoding and an independent SHA calculation agree.
This establishes publication transport, not new primitive compiler semantics.

Publication, caller cleanup, and the late rejection each retain real rewind and
replay. Cleanup excludes every initially borrowed region. Storage and identity
checks inspect the actual arena and its allocations before drops erase contents.
The physical adapter measures 28,642 bytes and 3,590 raw tokens under the unchanged
32,768-byte and 4,096-token bounds. Both source orchestrators now have direct
native token-arena guards.

The final focused selection passes fifteen examples, 32 source checks, and twelve
documentation checks. Four separate guard and identity methods pass. Original
physical archive intake passes in five minutes and fifty seconds, with 483 modules,
2,442 constants, and 1,901 callables. All 485 physical source hashes remain unchanged
after that run. The independently reconstructed 603,784-byte selected linked
reference remains byte-identical, so its unchanged long body comparison was not
rerun for this publication repair.

Independent compiler archives and graphs agree. The graph takes 80,693,864 native
transitions, and SHA takes 43,194,286. Four regenerated locks and the 181-target
workspace check and build pass. A locked consumer independently matches its whole
6,022,072-byte driver and emits a canonical 688-byte primitive artifact. It reaches
publication at transition 1,391,647 and halts at 1,391,775 under the unchanged
four-million-step command bound. Its caller cleanup rewinds and replays 128
transitions. This consumer still contains the minimal compiler. It does not
establish counted primitive compilation or a nominal executable artifact.

Commit `14c4ad3f949d70da291e9d12c55268e011e2fe4e` matches the verified feature
tree and remote master. Bootstrap run
[34729870051](https://github.com/typeobject/wheeler/actions/runs/34729870051)
passes all 52 jobs, including output comparison. README, site, and CodeQL also
pass. This acceptance covers the publication repair, not later compiler changes.

## Acceptance

- [x] Late nominal rejection preserves every caller buffer and marker.
- [x] Carrier rows stay private until composition and report construction finish.
- [x] Complete rows, bytes, identities, report fields, and inactive tails agree.
- [x] Success, rejection, and cleanup have actual rewind and replay evidence.
- [x] Calculated storage, buffer lifetimes, source bytes, and tokens fit.
- [x] Affected identities, packages, locks, examples, and documentation agree.
- [x] The exact verified feature tree is committed, pushed, and checked remotely.
