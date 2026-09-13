# WIP-0521: Source-bounded block comments

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, scanner bounds |
| Depends on | WIP-0006, WIP-0049 |
| Supersedes | None |
| Superseded by | None |

## Defect

The scanner admits an input window of 262,144 bytes. Its block-comment walk uses
an unrelated loop limit of 256. A comment with 256 body characters traps before
examining its closing delimiter. An unterminated comment of the same size traps
instead of returning the scanner's existing diagnostic. This also prevents a
32,768-byte compiler source from using its full window for a block comment.

## Repair

Use the existing `MAX_SCANNER_INPUT_BYTES` bound in `blockCommentEnd`. The opener
consumes two bytes. Every subsequent iteration consumes at least one UTF-8 byte
or returns at the first closing delimiter. The number of iterations is therefore
no greater than the admitted byte window. No scanner input, token, VM, history,
or source-product limit increases.

Keep byte coordinates, strict UTF-8 access, first-delimiter behavior, and the
existing unterminated-comment diagnostic. Do not introduce nesting or a second
comment parser. The scanner may leave partial token staging on an error, as
before. Higher-level source compilers must keep that staging private.

The repair adds no buffers, regions, or records. Direct fixtures reserve
`(4*3 + 5)*8 = 136` bytes in four word buffers: three token columns and a
five-column result report. Tests inspect actual charges, complete columns,
inactive tails, and borrowed input before cleanup.

## Evidence

The old implementation fails the explicit 256-character body case with a loop
trap. Three native methods cover both sides of that boundary, multibyte bodies,
CRLF byte origins, first-delimiter behavior, and unterminated comments. Success,
diagnostic publication, and cleanup replay to complete machine snapshots.

Two history-free cases use the full declared 262,144-byte scanner window, one
terminated and one unterminated. The test derives that capacity from the scanner's
declared input bound, not from the defective loop instruction. WIP-0520 also
compiles a complete 32,768-byte class-only source containing a long block comment.
These are API capacity checks, not native-command step-budget evidence.

The combined WIP-0520 verification passes original physical archive intake,
independent archives and graphs, the unchanged selected linked reference, four
regenerated locks, 181 workspace targets, and six-root syntax checks. The scanner
helper's compiled frame remains 44 locals. The source-product consumer halts
within its command bound. That does not certify command timing for the separate
262,144-byte scanner capacity probes.

## Acceptance

- [x] The walk derives from the existing source-window bound.
- [x] Complete token columns and diagnostics agree across the old boundary.
- [x] UTF-8 byte coordinates, tails, input preservation, and replay agree.
- [x] Full-window success and unterminated-comment diagnostics run history-free.
- [x] Affected physical identities, packages, and documentation agree.
- [ ] The exact verified feature tree is committed, pushed, and checked remotely.
