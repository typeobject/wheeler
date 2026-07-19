# WIP-0019: Integrated documentation publication

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler documentation, compiler, package, tools, website, and stage-0 Java maintainers |
| Created | 2026-07-18 |
| Updated | 2026-07-18 |
| Area | Wheeler API docs, Markdown manuals, Javadoc ingestion, fixed static rendering, links, search, publication |
| Depends on | WIP-0006, WIP-0007, WIP-0009, WIP-0011, WIP-0016, WIP-0018 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler builds one documentation graph from three named source types: authored Markdown manuals, attached Wheeler `//!` and `///` docs, and temporary Java API docs read through a pinned Javadoc doclet. A deterministic generator checks ownership, links, examples, proof references, package identities, and navigation. It then emits a renderer-neutral bundle.

The fixed `wheeler site` renderer verifies that bundle again and writes static HTML and CSS. It uses no configuration, plugins, scripts, package manager, or network access.

Each source type keeps its authority. Markdown owns narrative manuals. Wheeler declarations and verified IR descriptors own Wheeler API reference. Java source owns only stage-0 Java implementation reference. Generated pages may link these parts, but prose cannot turn a forward call into `rev`, a provider circuit into unitary evidence, or an absent method into a real declaration. Generated reference pages also cannot define a second meaning for `CALL_VALUE`.

Javadoc is an optional stage-0 adapter, not part of bootstrap authority. Wheeler owns graph construction, safe Markdown rendering, navigation, output identities, and publication rules. Java remains a replaceable seed until the generator is written in Wheeler.

## Motivation

The repository contains manuals, source-attached Wheeler docs, and a stage-0 Java implementation. Without one publication model, several problems will appear:

- hand-written reference pages will drift from declarations;
- Wheeler API pages and Javadoc will use different anchors;
- Java details will leak into language reference;
- copied examples will compile in one place and fail elsewhere;
- proof and quantum claims will lose the identities that bind them;
- site builds will fetch ambient renderer packages and depend on the runtime available in CI;
- migration to a Wheeler compiler will still leave docs tied to Java reflection.

A generic API generator does not own Wheeler's module graph, package model, theorem evidence, or bootstrap boundary. One system must own both the semantic graph and its fixed safe renderer.

## Use cases

1. A public Wheeler function has adjacent `///` documentation and a `Proof` facet. `wheeler docs` resolves the function and theorem identities, emits one API node, and links the manual's `wheeler:` reference to it. A stale theorem name fails before site publication.

2. A stage-0 Java class implements the canonical bytecode reader. A pinned doclet emits a Java API node under the stage-0 namespace. The generated page links to the bytecode manual but is visibly implementation API; deleting Java at native cutover removes the node without changing Wheeler symbol URLs.

3. A Markdown tutorial contains a fenced Wheeler example. WIP-0018 compiles and runs the declared test-selected runnable target. The documentation bundle records artifact and test-result identities. A prose edit does not rerun hardware jobs; a changed executable snippet does.

4. Two packages export declarations named `Result`. Cross-package links use exact package, version, module, and symbol identities. An unqualified ambiguous link fails instead of choosing whichever page was visited first.

5. Rendering fails after bundle generation but before publication; the immutable documentation bundle remains complete and content-addressed. Retrying rendering consumes the same verified bundle; it does not regenerate examples, Javadoc, proof checks, or package resolution.

6. A malicious dependency comment contains raw HTML and a script URL. The generator stores inert documented text under the WIP-0016 profile; the renderer escapes unsupported markup and never grants script execution.

## Goals

- Define one deterministic renderer-neutral documentation graph and bundle.
- Combine authored Markdown, Wheeler declaration docs, and stage-0 Javadoc without duplicate semantic authorities.
- Give every page, heading, declaration, theorem, package, example, and asset a stable identity.
- Validate links, navigation, documentation coverage, semantic facets, examples, and proof references before publication.
- Render safe static HTML/CSS from only a verified bundle under one fixed nonconfigurable profile.
- Generate deterministic search and symbol indexes.
- Support exact package/version documentation and cross-package links.
- Keep Java implementation APIs visibly separate from Wheeler language and library APIs.
- Permit renderer retry without rerunning semantic generation.
- Port the generator to Wheeler and delete Java-only extraction paths at native cutover.

## Non-goals

- Make prose, Javadoc, or a rendered page authoritative for language semantics, bytecode, proofs, or packages.
- Parse arbitrary Markdown, arbitrary HTML, arbitrary Javadoc tags, themes, or plugins.
- Execute documentation scripts, remote embeds, Mermaid servers, or network-fetched examples during a trusted build.
- Copy source documentation into hand-maintained API Markdown.
- Publish private declarations unless a package policy explicitly includes an internal site.
- Permit scripts, raw HTML, runtime themes, or host-dependent output in the trusted site.
- Require Java in the final self-hosted toolchain.
- Turn every code block into a test; examples opt into a declared language, target, and expectation profile.
- Treat a successful doctest or sampled quantum run as a theorem.

## Terms and semantic model

A **documentation source** is one bounded, strict-UTF-8 input with an exact content identity and source kind: `manual`, `wheeler-api`, `java-stage0-api`, `generated-reference`, or `asset`.

A **documentation node** is a canonical typed record representing a manual page, section, Wheeler declaration, Java declaration, theorem reference, executable example, package, version, or asset.

A **documentation edge** is a typed relation such as `contains`, `documents`, `links-to`, `implements-stage0`, `proved-by`, `example-of`, `supersedes`, or `version-of`.

A **documentation graph** is the closed canonical set of nodes and edges after package resolution, symbol resolution, link validation, example validation, and policy filtering.

A **documentation bundle** is an immutable content-addressed directory containing:

```text
manifest.json
nodes.json
edges.json
navigation.json
search.json
pages/*.md
assets/*
```

JSON objects use canonical key order, integers, strict UTF-8 strings, and no floating-point values. Paths are normalized logical paths. The bundle manifest binds every file digest, generator/compiler identity, package lock, documentation profile, example-result identity, and source identity.

A **rendering adapter** converts one valid bundle to presentation output. The website adapter is the fixed `wheeler.doc-site/1` safe static renderer. Terminal symbol help and offline package docs may use other explicitly identified adapters.

A **semantic build** produces and validates the graph and bundle. A **render build** consumes a bundle; render retry cannot mutate semantic results.

## Source ownership

### Markdown manuals

Authored Markdown owns explanations, tutorials, architecture, operational guides, and current reference prose. The accepted profile is the safe source-readable subset already selected by WIP-0016 plus headings, tables, admonitions, and explicit cross-reference syntax needed by manuals.

Manual pages carry stable front matter with page identity, title, navigation parent, and optional version policy. Filesystem order is not navigation order.

### Wheeler declaration documentation

WIP-0016 attachment is authoritative for Wheeler API summaries and facets. The compiler exports declaration identity, visibility, signature, source range, documentation payload, theorem references, and package/module identity. The generator never reparses Wheeler declarations with a website grammar.

Generated signature blocks come from compiler metadata. Documentation does not duplicate parameter and return types in an invented tag language.

### Stage-0 Java API documentation

A pinned standard-doclet integration emits a bounded neutral Java declaration model. It does not scrape generated Javadoc HTML. Accepted elements are package, type, constructor, method, field, signature, visibility, deprecation, source link, summary, selected block tags, and exact cross-references.

Java nodes live under an explicit `stage0-java` namespace and banner; they may link to Wheeler declarations through reviewed `implements-stage0` mappings. They cannot create Wheeler declarations, theorem claims, opcode semantics, or package exports.

When a Java subsystem is deleted, its nodes disappear. Stable Wheeler API and manual identities do not redirect through tombstoned Java pages.

### Generated reference

Bytecode tables, opcode lists, package schemas, diagnostics, and proof-rule catalogs are generated from their authoritative registries. Test summaries and WIP-0020 coverage pages are rendered from exact semantic reports and retain report/policy identities; the website never recomputes their outcomes. Hand-maintained copies are deleted after generator parity. Generated tables include source authority and generator identity. Their meaning doesn't depend on HTML presentation.

## Stable identities and links

Node identities are domain-separated and include source kind plus the smallest semantic owner:

- manuals: documentation package, version policy, and declared page ID;
- Wheeler declarations: package release, module, declaration kind, and canonical qualified symbol identity;
- Java declarations: stage-0 component, Java package, binary type name, and erased-plus-generic signature identity;
- theorems: proof subject and declaration identity;
- examples: owning node, declared example name, source/artifact identity, and expectation profile;
- assets: logical path and content digest.

Authored links use explicit schemes:

```text
wheeler:package/module#symbol
manual:page-id#section-id
proof:package/module#theorem
java-stage0:package.Type#member(signature)
asset:logical/path
```

Relative Markdown links are accepted only within one manual source root and normalize to declared page IDs. Ambiguous, private, missing, cyclic-include, wrong-version, and cross-package-unlocked references fail generation.

Heading anchors derive from declared or canonical heading identity. Renderer-specific slug rules don't define them. Changing punctuation cannot silently retarget external links.

## Examples and doctests

Executable fenced blocks declare:

- language (`wheeler`, `openqasm3`, shell transcript, or inert text);
- exact package target or self-contained profile;
- input and output fixtures;
- expected compile, verification, execution, trap, proof, or sampled result;
- semantic limits;
- whether execution is exact, replayed, sampled, or presentation-only.

Wheeler examples execute through WIP-0018 in fresh cases. A block may reference a checked-in example instead of copying it. Copied blocks have independent content identities and are tested independently; duplication is therefore possible but painful on purpose.

Hardware examples default to recorded evidence and replay. Regeneration is an explicit workflow with a new evidence identity. Exact simulator examples may execute during the semantic build.

A passing example proves only its declared expectation. The site labels sampled evidence, bounded proof, speculative design, and implemented behavior separately.

## I/O documentation ownership

WIP-0032 is the sole source of the portable I/O lifecycle and method registry. Standard-library, target, package, native, and example pages link to that contract and add only their domain facts. Copied future, stream, callback, cancellation, or durability APIs fail review because they create a second contract.

Until its executable slice lands, every WIP-0032 page and fenced example is labeled Draft or speculative; current reference pages describe only implemented host loans and target jobs, then identify their migration boundary. Durability prose names exact evidence; atomic replacement, close, rename, staging, direct completion, transport completion, and replication acknowledgement never receive a promotion from the copy editor.

## Navigation, versions, and search

Navigation is a canonical tree over node IDs. Each visible node has at most one navigation parent but may have many graph links. Duplicate positions or cycles reject.

Package documentation is versioned by exact package release and lock identity. The site may expose aliases such as `latest`, but aliases resolve in a separately signed publication manifest and never enter stored links or proof claims.

Search indexes canonical normalized titles, qualified symbols, summaries, headings, tags, and package versions. Tokenization is specified, locale-independent, and bounded. Search ranking is presentation policy; the indexed node set and terms are semantic bundle data.

Private/internal nodes are removed before search generation. A search index isn't an access-control system.

## Fixed Wheeler website renderer

`wheeler site -o <directory>` discovers the repository's canonical manual and Wheeler source roots. It accepts no theme, plugin, source-root, script, or network configuration. It builds profile-2 graph data in private staging, verifies exact paths and every digest at the rendering boundary, and then renders the fixed safe Markdown subset.

The renderer consumes the accepted scalar MDX-style front matter as metadata and never renders the delimiters or fields as page prose. Front-matter title must agree with the page heading; sidebar positions are bounded. Executable MDX/JSX remains unsupported inert text and is escaped instead of evaluated.

The renderer escapes unsupported markup and emits no JavaScript. It installs a restrictive content-security policy, rewrites verified manual links to static routes, and maps source links to exact repository paths. One sidebar follows the fixed Manual, Reference, Proposals, Future order. Introduction and overview pages lead their sections. WIPs sort by identity, and the authoring template stays linkable but does not appear in navigation. The site uses one fixed stylesheet and a standard `sitemap.xml`. That sitemap includes a deterministic digest over sorted page paths and bytes, so content changes update it without a clock or Git timestamp. Output size is bounded, and publication uses one atomic directory move.

`publication-manifest.json` binds the semantic bundle identity, renderer class identity, site profile, and digest of every emitted file. Existing destinations, malformed bundles, raw special files, unclosed fences/admonitions, and output overflow fail before publication. A renderer needing new semantic source fields changes the bundle or site profile; it does not acquire a configuration file in the night.

## Javadoc adapter

Javadoc runs with a pinned JDK and a Wheeler-owned doclet. The doclet emits the neutral model directly, sorted by canonical Java identity. Locale, source file order, default stylesheet, current module path, and external-link fetching cannot affect model bytes.

Unsupported tags produce diagnostics. `@param`, `@return`, and `@throws` remain valid Java implementation documentation but do not migrate into Wheeler `///` syntax automatically. Automatic prose translation would create a second comment that can drift from the original.

The standard Javadoc HTML generator may be published as a convenience link during stage 0, but it is not ingested back into the graph and is not part of the canonical bundle.

## Reversibility and history

Documentation generation is a pure bounded transformation until bundle or site publication. It doesn't mutate Wheeler machine state and has no language inverse.

Example execution follows WIP-0018 semantics. Language inverse, VM rewind, target replay, and retry remain separate in example results.

Bundle and site publication are irreversible host effects. Files are staged under invocation-owned paths, verified against the manifest, and atomically published only after complete success. A failed semantic or render build leaves the prior publication untouched.

## Concurrency and determinism

Parsing, extraction, example execution, and rendering may run concurrently only when canonical reduction produces the same graph and diagnostics as serial source-ID order.

Diagnostics sort by source identity, source range, and code. Nodes and edges sort by canonical identity. Worker completion order, filesystem enumeration, locale, CPU count, and cache hit order are unobservable.

Caches are keyed by complete source, tool, policy, and example identities. Cache corruption fails digest verification and triggers recomputation. Stale data is rejected.

## Quantum and proof implications

Documentation comments and pages are not evidence. `Proof` facets and `proof:` links resolve exact checked theorem identities. The generator may invoke the proof kernel to validate a referenced certificate but cannot prove a stronger prose sentence.

Quantum pages record whether claims derive from exact simulation, sampled evidence, hardware descriptors, bounded resource estimates, or checked proofs. Target credentials and provider objects never enter the graph or bundle.

Amplitude tables and circuit diagrams are derived presentation assets bound to exact circuit and generator identities. A diagram is not a circuit artifact, much as a photograph of a checksum is not a checksum.

## Bytecode, persistence, and compatibility

Documentation payload does not affect semantic `.wbc` identity unless a package explicitly ships documentation metadata as a separate content-addressed package input. Production code generation ignores prose.

Compiler-exported symbol/signature metadata and source maps use canonical format-1 sections or separate generator inputs accepted under WIP-0001; this WIP introduces no bytecode format 2.

Bundle profiles use explicit required features. Readers reject unknown required node, edge, markup, or identity semantics. Renderers may ignore unknown optional presentation hints but must preserve bundle validation.

Documentation bundles may be included in `.wpk` releases as ordinary content-addressed files. They do not alter package dependency resolution or grant capabilities.

## Safety, limits, and failures

The semantic build bounds source files, bytes, nodes, edges, links, nesting, includes, generated pages, examples, diagnostics, assets, search terms, Javadoc declarations, output bytes, and total work.

Strict UTF-8, normalized paths, physical nonsymlink source roots, exact package locks, and no network access are required. Duplicate IDs, path traversal, case-fold collisions under the publication profile, malformed markup, raw executable HTML, missing links, invalid proof references, failed examples, stale evidence, and exhausted limits fail before publication.

Dependency documentation is inert untrusted input. Rendering escapes it and applies a restrictive content-security policy. Source links expose repository-relative logical paths, never developer home directories.

## Ownership and boundaries

The compiler and WIP-0016 own Wheeler declaration/document attachment. The Markdown parser owns the accepted manual syntax. The Javadoc doclet owns Java-source extraction. The documentation generator owns graph validation, identities, links, navigation, examples, and bundle publication. Its current Java implementation is quarantined under `bootstrap/`; the canonical destination is a Wheeler tool package that reproduces the bundle byte-for-byte before the Java generator is deleted.

WIP-0018 owns executable examples. The proof kernel owns proof validity. The package system owns exact source/package sets and locks. The fixed Wheeler renderer owns website bytes only; hosting owns deployment and aliases, not documentation semantics.

## Migration and deletion

1. Define documentation nodes, edges, IDs, diagnostics, bundle encoding, and safe Markdown profile.
2. Export Wheeler declaration docs and symbol identities from the WIP-0016 concrete syntax/compiler boundary.
3. Implement manual parsing, link validation, navigation, search, and deterministic bundle emission.
4. Implement the pinned Javadoc doclet and explicit stage-0 namespace.
5. Route executable examples through WIP-0018 and proof references through WIP-0011.
6. Render the verified bundle through the fixed no-script Wheeler site profile and delete the generic renderer stack.
7. Generate bytecode, package, diagnostic, and proof-rule reference tables; delete hand-copied tables.
8. Publish versioned package documentation and offline bundles.
9. Port graph construction and bundle emission to Wheeler and compare bundle bytes with stage 0.
10. Delete Java extraction when each Java subsystem is removed; keep no copied API Markdown, duplicate navigation, renderer package lock, or obsolete build script.

## Progress

- [x] The stage-0 concrete-syntax boundary exports parser-owned module identity, file summary, selected public/semantic declaration kind, name, source position, modifiers, summary, and ordered facets. Bundle generators no longer need a separate website parser to rediscover Wheeler declarations or invent a second anchor scheme.
- [x] `wheeler docs` walks explicit physical manual and Wheeler roots with strict UTF-8 and bounded counts. It validates Wheeler documentation and emits canonically ordered manual, heading, and API nodes. Explicit `manual:` and `wheeler:` links, plus root-contained relative page and heading links, become sorted `links-to` edges. The command builds navigation and search indexes, copies inert manual pages, binds every output digest in `manifest.json`, and publishes a renderer-neutral profile-2 bundle atomically.
- [ ] Documentation graph, identity, link, and bundle contracts are accepted.
- [ ] One manual page, Wheeler API declaration, Java stage-0 declaration, and executable example produce one validated bundle.
- [x] The zero-configuration `wheeler site` command builds canonical roots and rechecks the full semantic bundle.
  - It reads bounded MDX-style front matter without rendering it.
  - The renderer handles headings, prose, links, code, lists, tables, quotes, and admonitions safely.
  - It emits one Manual, Reference, Proposals, Future sidebar, hides the proposal template, and includes no scripts or header slogan.
  - `sitemap.xml` contains every HTML route plus a digest of exact page content.
  - `publication-manifest.json` binds the bundle, renderer, and every output file before atomic publication.
  - The current local build emits 47 linked HTML pages.
  - The old renderer package graph, duplicate deployment-test workflow, and generic website configuration are deleted.
  - Hosted run `29670968033` built and deployed the navigation and front-matter slice at commit `2dea61e`.
  - Hosted evidence remains tied to that commit and does not inherit later renderer identities.
- [ ] Cross-package/version links, search, proof references, and malformed-input diagnostics pass.
- [ ] A Wheeler-written generator emits the stage-0 bundle byte-for-byte.
- [ ] Duplicate hand-authored/generated authorities are deleted.

## Testing and acceptance

- [ ] Bundle generation is byte-identical under source enumeration, locale, worker count, and cache-order variation.
- [ ] Every node and edge has one valid canonical identity and owner.
- [ ] Ambiguous, missing, private, stale-version, malformed, and cyclic links fail with exact diagnostics.
- [ ] Wheeler docs preserve WIP-0016 payload and attachment exactly.
- [ ] Javadoc extraction is independent of generated HTML, locale, and source order.
- [ ] Java pages cannot define or shadow Wheeler symbols or semantic reference nodes.
- [ ] Executable examples compile/run/replay through WIP-0018 and retain exact result identities.
- [ ] Proof and quantum labels distinguish checked proof, exact simulation, sampled evidence, and speculation.
- [x] The fixed static renderer consumes only local verified inputs and grants documentation payload no script execution.
- [x] `sitemap.xml` contains every generated HTML route and changes when a route or page body changes, without nondeterministic timestamps.
- [ ] Render retry consumes the same bundle without rerunning semantic generation.
- [ ] Failed generation or rendering leaves the previous publication intact.
- [ ] Search and navigation contain every public selected node exactly once and no private nodes.
- [ ] Current website and development documentation describe the implemented generator and publication path.

## Alternatives

### Keep hand-written Markdown and add links to ordinary Javadoc

Rejected. It preserves two navigation and link authorities, does not publish Wheeler declarations, and lets generated Java URLs leak into stable language documentation.

### Generate Markdown directly from every source and let a renderer discover it

Rejected. Filesystem discovery is not a documentation graph. It cannot validate cross-package identities, theorem links, duplicate nodes, version policy, or semantic examples before rendering.

### Use Javadoc as the Wheeler documentation syntax

Rejected. Wheeler is Java-shaped, not Java-owned. Javadoc tags duplicate signatures and have no native vocabulary for inverse, coherent action, adjoints, bounds, or proof identities.

### Make executable component markup the canonical source format

Rejected. It mixes prose with executable components and renderer behavior. The trusted source profile remains inert.

### Keep a configurable generic website renderer

Rejected. Themes, plugins, package locks, and runtime-side Markdown interpretation recreate authorities already removed by the semantic bundle. The fixed renderer stays small and predictable.

## Open questions

- Which safe Markdown extensions beyond the WIP-0016 profile enter the first manual bundle (owner: documentation and security maintainers; decision point: before parser acceptance)?
- Should source packages ship bundle fragments or only raw docs plus compiler metadata (owner: package and documentation maintainers; decision point: before package publication integration)?
- Which Java generic-signature identity remains stable across supported stage-0 JDKs (owner: Java and tools maintainers; decision point: before doclet acceptance)?
- Which additional inert Markdown constructs justify a versioned site-profile change (owner: website and security maintainers; decision point: before accepting such syntax)?

## References

- [WIP-0006](WIP-0006-concrete-syntax-tooling-and-teaching.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0016](WIP-0016-nonconfigurable-source-formatter.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [Development guide](../reference/development.md)
