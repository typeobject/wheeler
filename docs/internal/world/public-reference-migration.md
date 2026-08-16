# Public reference migration map

This map accounts for every second-level section in the ten public reference pages
that preceded the instrument appendices. The exact former bytes live under
`docs/internal/engineering-reference/`. Public destinations state accepted
contracts. Implementation catalogues, differential-fixture inventories, and
future migration notes remain in the snapshots.

The classifications mean:

- **public contract**: the accepted behavior remains in the named public route.
- **public summary and internal ledger**: the stable boundary remains public while
  module lists, fixture inventories, or adoption status stay in the snapshot.
- **internal history**: the section described process or planned work rather than
  callable public behavior.

## Bootstrap

| Former section | Destination | Classification |
| --- | --- | --- |
| Profile and module derivation | `public/reference/bootstrap.md` sections “Present stage-0 work” and “Deriving the profile and graph” | public contract |
| Evidence command | `public/reference/bootstrap.md` section “Evidence command” | public contract |
| Compiler input schemas | `public/reference/bootstrap.md` sections on profile, options, limits, and provenance | public contract |
| Canonical evidence schema | `public/reference/bootstrap.md` section “Canonical bootstrap manifest” | public contract |
| Publication and retention | `public/reference/bootstrap.md` section “Publication” | public contract |

The former page's complete physical-module catalogue remains internal. The public
appendix retains the current closure dimensions, transition count, executable
subset dimensions, and artifact identity.

## Bytecode

| Former section | Destination | Classification |
| --- | --- | --- |
| Header | `public/reference/bytecode.md` section “Header and directory” | public contract |
| Implemented sections | `public/reference/bytecode.md` section “Sections in format 1.0” | public contract |
| Type and aggregate descriptors | sections “Type identities” and “Aggregate descriptors” | public contract |
| Classical instruction records | sections “Classical instruction records” through “Storage and text” | public contract |
| Proof certificates | section “Proof certificates” | public contract |
| Quantum and workflow records | section “Quantum and workflow records” | public contract |
| Verification | section “Verification before identity” | public contract |
| Compatibility | section “Compatibility” | public contract |

The former Wheeler-native compiler module inventory and differential fixture list
remain in `bytecode.md.snapshot`. The public page keeps the accepted wire form,
IDs, verification duties, and compatibility rule.

## Semantic coverage

| Former section | Destination | Classification |
| --- | --- | --- |
| Transition observations | `public/reference/coverage.md` section “Transition observations” | public contract |
| Stage-0 report | section “Canonical transition report” | public contract |
| Wheeler reduction | section “Wheeler reduction” | public contract |
| Native bootstrap collection | section “Wheeler reduction” | public summary and internal ledger |
| Presentation adapters | section “Presentation forms” | public contract |
| Exclusions and thresholds | section “Policies and thresholds” | public contract |
| Source and generated-body relations | sections “Relations to source” and “Adjacent paths” | public contract |
| Proof stages | section “Proof stages” | public contract |

## Yard procedures

| Former section | Destination | Classification |
| --- | --- | --- |
| Local gate | `public/reference/development.md` section “Local acceptance” | public contract |
| Documentation style | section “Prose kept fit for service” | public contract |
| Documentation check | section “Wheeler source comments” | public contract |
| Documentation bundle | sections “Manual bundle” and “Static site” | public contract |
| Instruction registry | section “Instruction registry” | public contract |
| Source formatting | section “Source formatting” | public contract |
| Design workflow | section “Design and maintenance” | public contract |
| Maintenance rules | section “Design and maintenance” | public contract |
| Module dependency direction | section “Module direction” | public contract |

Detailed CI sharding rationale and long module-location history remain in
`development.md.snapshot`.

## Hybrid runs

| Former section | Destination | Classification |
| --- | --- | --- |
| Lifecycle | `public/reference/hybrid-runs.md` section “Lifecycle” | public contract |
| Events | section “Events” | public contract |
| Result application | section “Applying an observation” | public contract |
| Persistence and recovery | section “Snapshots and recovery” | public contract |
| Replay and retry | section “Replay and retry” | public contract |
| Transactions | section “Transactions” | public contract |
| Limits and failures | section “Limits and failures” | public contract |
| Terminology | section “Terms kept apart” | public contract |

## I/O

| Former section | Destination | Classification |
| --- | --- | --- |
| Executable stage-0 slice | `public/reference/io-lifecycle.md` sections “One lifecycle” through “Portable backends” | public summary and internal ledger |
| Lifecycle | sections “One lifecycle” and “Portable backends” | public contract |
| Cancellation and uncertainty | sections “Cancellation and uncertainty” and “Effect boundaries and compensation” | public contract |
| Wheeler-native portable API and lifecycle kernel | section “Native lifecycle kernel” | public contract |
| Positional memory-file oracle | sections “Positional files” through “Placement across tiers” | public contract |
| Batches, selection, and graphs | section with the same name | public contract |
| Receipt schema and monotonicity gate | section “Receipt chain” | public contract |
| Deliberate nonclaims | section “Present physical boundary” | public contract |

The full class inventory, fixture paths, and adapter adoption notes remain in
`io-lifecycle.md.snapshot`.

## Wheeler language

| Former section | Destination | Classification |
| --- | --- | --- |
| Classes and state | `public/reference/language-profile.md` section “Domains and state” | public contract |
| Methods | section “Methods and their promises” | public contract |
| Classical statements | section “Classical work” | public contract |
| Local expressions and bounded control | section “Expressions and control” | public contract |
| Compile-time constants and finite enums | section “Constants and finite cases” | public contract |
| Value records | section “Immutable values” | public contract |
| Tagged variants | section “Immutable values” | public contract |
| Explicit presence slots | section “Immutable values” | public contract |
| Fixed arrays | section “Immutable values” | public contract |
| Bounded owned regions | sections “Owned storage and loans” and “Text and binary data” | public contract |
| Generated inverse and adjoint theorems | section “Proof declarations” | public contract |
| Quantum statements | section “Quantum regions” | public contract |
| Coherent lifting | section “Coherent lifting” | public contract |
| Distinct meanings of reverse | section “Five roads called reverse” | public contract |
| Classical source modules | section “Modules” | public contract |
| Explicit host input and output | section with the same name | public contract |
| Parser and editor tooling | section “Source limits and tooling” | public contract |
| Bootstrap direction | `public/reference/bootstrap.md` | public contract |
| Proof direction | sections “Proof declarations” and “Source limits and tooling” | public summary and internal ledger |
| Standard library direction | former snapshot only | internal history |
| Generic and ownership direction | section “Source limits and tooling” | public summary and internal ledger |
| Learning Wheeler | links at the close of the public language appendix | public contract |

The native recovery compiler's module-by-module adoption catalogue remains in
`language-profile.md.snapshot`. The public appendix retains source spelling,
semantics, limits, accepted gates, ownership rules, and explicitly absent language
features.

## Packages

| Former section | Destination | Classification |
| --- | --- | --- |
| Workspace manifest | `public/reference/packages.md` section “Workspaces” | public contract |
| Package manifest | section “Package manifests” | public contract |
| Resolution and lockfiles | section “Resolution and locks” | public contract |
| Build plan | section “Build plans” | public contract |
| Canonicalization | section “Canonical YAML” and path rules throughout | public contract |
| Package archive | section “Package archives” | public contract |
| Stage-0 command | sections “Commands” through “Tests” | public contract |
| Future hardening boundaries | section “Present boundary” | public summary and internal ledger |
| Vendored inputs | section “Vendored and locked work” | public contract |
| Locked dependency compilation | section “Vendored and locked work” | public contract |
| Local registry transport | section “Repository authority” | public contract |
| Security boundary | section “Present boundary” | public contract |
| Wheeler-native manifest slice | `packages.md.snapshot` | internal implementation ledger |
| Wheeler-native repository snapshot slice | `packages.md.snapshot` | internal implementation ledger |
| Wheeler-native lock slice | `packages.md.snapshot` | internal implementation ledger |
| Wheeler-native workspace slice | `packages.md.snapshot` | internal implementation ledger |
| Wheeler-native plan slice | `packages.md.snapshot` | internal implementation ledger |
| Wheeler-native archive slice | `packages.md.snapshot` | internal implementation ledger |
| Implementation direction | `packages.md.snapshot` | internal history |

Public package contracts retain canonical schemas, limits, commands, authority,
offline behavior, and deliberate nonclaims. Native fixture table sizes and cutover
status remain internal.

## Quantum targets

| Former section | Destination | Classification |
| --- | --- | --- |
| Submission contract | `public/reference/quantum-targets.md` section “Descriptor and submission” | public contract |
| Ideal state-vector target | sections “Ideal state-vector target” and “Target-resident dynamic work” | public contract |
| Batches and sampled expectations | sections “Batches and parameter bindings” and “Maintained planning protocols” | public contract |
| Provider-neutral quantum ISA | section “Provider-neutral quantum instructions” | public contract |
| OpenQASM 3 | section “OpenQASM 3” | public contract |
| OpenQASM target SPI | section “OpenQASM 3” | public contract |
| Live hardware tests | section “Live hardware authority” | public contract |
| Physical limits | section “Physical limits” | public contract |

## Virtual machine

| Former section | Destination | Classification |
| --- | --- | --- |
| State | `public/reference/virtual-machine.md` section “Machine state” | public contract |
| Wheeler-written bounded interpreter | section “Interpreter recovery slice” | public summary and internal ledger |
| Forward and reverse laws | section “One transition” | public contract |
| Function inverse versus rewind | sections “Inverse execution” and “Retained-history rewind” | public contract |
| Commit horizons | section “Commit horizons” | public contract |
| Traps and limits | sections “Tasks and workflow epoch” and “Traps” | public contract |

The detailed differential fixture portfolio remains in
`virtual-machine.md.snapshot`. Public limits, state components, transition laws,
observer behavior, and failure atomicity remain in the instrument appendix.

## Audit result

All 101 former second-level sections have a destination above. Every wire format,
accepted source form, public command, semantic distinction, runtime lifecycle,
exact limit needed to use the accepted profile, and explicit physical nonclaim
remains public. Detailed class lists, module inventories, fixture catalogues,
proposal references, and native cutover progress remain available in the immutable
internal snapshots.
