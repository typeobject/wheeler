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

Wheeler builds one documentation graph from three explicit source classes: authored Markdown manuals, attached Wheeler `//!`/`///` documentation, and eventual stage-0 Java API documentation obtained through a pinned Javadoc doclet. A deterministic generator validates ownership, links, examples, proof references, package identities, and navigation before emitting a renderer-neutral documentation bundle. The fixed `wheeler site` renderer verifies that bundle again and emits inert static HTML and CSS without configuration, plugins, scripts, a package manager, or network access.

Markdown owns narrative manuals. Wheeler declarations own Wheeler API documentation. Java source owns only stage-0 Java implementation API documentation. Generated pages may combine links and navigation across those classes, but they do not blur authority: a Javadoc sentence cannot define Wheeler semantics, and a Markdown page cannot make an absent method callable.

Javadoc is an optional stage-0 extraction adapter, not a bootstrap authority. Graph construction, safe Markdown rendering, navigation, output identities, and publication policy belong to Wheeler's documentation system. Java remains a replaceable seed until the generator is Wheeler-written. The website may eventually have a search box. It may not have three contradictory copies of `CALL_VALUE` wearing different CSS.

## Motivation

The repository has authored manuals, source-attached Wheeler documentation, and a stage-0 Java implementation. Without one publication model, the likely result is familiar:

- hand-written reference pages drift from declarations;
- generated Wheeler API pages use one anchor scheme while Javadoc uses another;
- Java implementation details leak into language documentation;
- copied examples compile in one location and rot in two others;
- proof and quantum claims lose the identities that bound them;
- website builds fetch ambient renderer packages and depend on whichever runtime wandered into CI;
- migration to a Wheeler-written compiler leaves the documentation tool chained to Java reflection.

A generic API generator does not own Wheeler's documentation graph, package model, theorem evidence, or self-hosting boundary. The graph and a fixed safe renderer need one authority rather than a shell pipeline with opinions.

## Use cases

1. A public Wheeler function has adjacent `///` documentation and a `Proof` facet. `wheeler docs` resolves the function and theorem identities, emits one API node, and links the manual's `wheeler:` reference to it. A stale theorem name fails before site publication.

2. A stage-0 Java class implements the canonical bytecode reader. A pinned doclet emits a Java API node under the stage-0 namespace. The generated page links to the bytecode manual but is visibly implementation API; deleting Java at native cutover removes the node without changing Wheeler symbol URLs.

3. A Markdown tutorial contains a fenced Wheeler example. WIP-0018 compiles and runs the declared test-selected runnable target. The documentation bundle records artifact and test-result identities. A prose edit does not rerun hardware jobs; a changed executable snippet does.

4. Two packages export declarations named `Result`. Cross-package links use exact package, version, module, and symbol identities. An unqualified ambiguous link fails rather than choosing whichever page was visited first.

5. Rendering fails after bundle generation but before publication. The immutable documentation bundle remains complete and content-addressed. Retrying rendering consumes the same verified bundle; it does not regenerate examples, Javadoc, proof checks, or package resolution.

6. A malicious dependency comment contains raw HTML and a script URL. The generator stores inert documented text under the WIP-0016 profile. The renderer escapes unsupported markup and grants no script execution merely because the comment was enthusiastic.

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

A **semantic build** produces and validates the graph and bundle. A **render build** consumes a bundle. Render retry cannot mutate semantic results.

## Source ownership

### Markdown manuals

Authored Markdown owns explanations, tutorials, architecture, operational guides, and current reference prose. The accepted profile is the safe source-readable subset already selected by WIP-0016 plus headings, tables, admonitions, and explicit cross-reference syntax needed by manuals.

Manual pages carry stable front matter with page identity, title, navigation parent, and optional version policy. Filesystem order is not navigation order.

### Wheeler declaration documentation

WIP-0016 attachment is authoritative for Wheeler API summaries and facets. The compiler exports declaration identity, visibility, signature, source range, documentation payload, theorem references, and package/module identity. The generator never reparses Wheeler declarations with a website grammar.

Generated signature blocks come from compiler metadata. Documentation does not duplicate parameter and return types in an invented tag language.

### Stage-0 Java API documentation

A pinned standard-doclet integration emits a bounded neutral Java declaration model. It does not scrape generated Javadoc HTML. Accepted elements are package, type, constructor, method, field, signature, visibility, deprecation, source link, summary, selected block tags, and exact cross-references.

Java nodes live under an explicit `stage0-java` namespace and banner. They may link to Wheeler declarations through reviewed `implements-stage0` mappings. They cannot create Wheeler declarations, theorem claims, opcode semantics, or package exports.

When a Java subsystem is deleted, its nodes disappear. Stable Wheeler API and manual identities do not redirect through tombstoned Java pages.

### Generated reference

Bytecode tables, opcode lists, package schemas, diagnostics, and proof-rule catalogs are generated from their authoritative registries. Test summaries and WIP-0020 coverage pages are rendered from exact semantic reports and retain report/policy identities; the website never recomputes their outcomes. Hand-maintained copies are deleted after generator parity. Generated tables include source authority and generator identity; HTML upholstery remains optional.

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

Heading anchors derive from declared or canonical heading identity, not renderer slug folklore. Changing punctuation cannot silently retarget external links.

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

## Navigation, versions, and search

Navigation is a canonical tree over node IDs. Each visible node has at most one navigation parent but may have many graph links. Duplicate positions or cycles reject.

Package documentation is versioned by exact package release and lock identity. The site may expose aliases such as `latest`, but aliases resolve in a separately signed publication manifest and never enter stored links or proof claims.

Search indexes canonical normalized titles, qualified symbols, summaries, headings, tags, and package versions. Tokenization is specified, locale-independent, and bounded. Search ranking is presentation policy; the indexed node set and terms are semantic bundle data.

Private/internal nodes are removed before search generation. A search index is not an access-control system.

## Fixed Wheeler website renderer

`wheeler site -o <directory>` discovers the repository's canonical manual and Wheeler source roots. It accepts no theme, plugin, source-root, script, or network configuration. It builds profile-2 graph data in private staging, verifies exact paths and every digest at the rendering boundary, and then renders the fixed safe Markdown subset.

The renderer escapes unsupported markup, emits no JavaScript, installs a restrictive content-security policy, rewrites verified manual links to static routes, maps repository source links to exact repository paths, generates navigation from the closed page set, and emits one fixed stylesheet. It bounds input/output counts and bytes and publishes only with one atomic directory move.

`publication-manifest.json` binds the semantic bundle identity, renderer class identity, site profile, and digest of every emitted file. Existing destinations, malformed bundles, raw special files, unclosed fences/admonitions, and output overflow fail before publication. A renderer needing new semantic source fields changes the bundle or site profile; it does not acquire a configuration file in the night.

## Javadoc adapter

Javadoc runs with a pinned JDK and a Wheeler-owned doclet. The doclet emits the neutral model directly, sorted by canonical Java identity. Locale, source file order, default stylesheet, current module path, and external-link fetching cannot affect model bytes.

Unsupported tags produce diagnostics. `@param`, `@return`, and `@throws` remain valid Java implementation documentation but do not migrate into Wheeler `///` syntax automatically. Automatic prose translation is how one obtains two stale comments for the price of one.

The standard Javadoc HTML generator may be published as a convenience link during stage 0, but it is not ingested back into the graph and is not part of the canonical bundle.

## Reversibility and history

Documentation generation is a pure bounded transformation until bundle or site publication. It does not mutate Wheeler machine state and has no language inverse.

Example execution follows WIP-0018 semantics. Language inverse, VM rewind, target replay, and retry remain separate in example results.

Bundle and site publication are irreversible host effects. Files are staged under invocation-owned paths, verified against the manifest, and atomically published only after complete success. A failed semantic or render build leaves the prior publication untouched.

## Concurrency and determinism

Parsing, extraction, example execution, and rendering may run concurrently only when canonical reduction produces the same graph and diagnostics as serial source-ID order.

Diagnostics sort by source identity, source range, and code. Nodes and edges sort by canonical identity. Worker completion order, filesystem enumeration, locale, CPU count, and cache hit order are unobservable.

Caches are keyed by complete source, tool, policy, and example identities. Cache corruption fails digest verification and triggers recomputation; stale data is never “close enough for docs.”

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

The compiler and WIP-0016 own Wheeler declaration/document attachment. The Markdown parser owns the accepted manual syntax. The Javadoc doclet owns Java-source extraction. The documentation generator owns graph validation, identities, links, navigation, examples, and bundle publication.

WIP-0018 owns executable examples. The proof kernel owns proof validity. The package system owns exact source/package sets and locks. The fixed Wheeler renderer owns website bytes only. Hosting owns deployment and aliases, not documentation semantics.

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

- [x] The stage-0 concrete-syntax boundary exports parser-owned module identity, file summary, selected public/semantic declaration kind, name, source position, modifiers, summary, and ordered facets. Bundle generators no longer need to rediscover Wheeler declarations with a website parser; that road ends in anchors made of cheese.
- [x] `wheeler docs` walks explicit physical manual and Wheeler roots with strict UTF-8 and bounded counts, validates Wheeler documentation, emits canonically ordered manual/heading/API nodes, validates explicit `manual:`/`wheeler:` links and root-contained relative Markdown page/heading links into sorted `links-to` edges, builds navigation and search indexes, copies inert manual pages, binds every emitted file digest in `manifest.json`, and atomically publishes a renderer-neutral profile-2 bundle. Canonical heading identities have deterministic duplicate suffixes, fenced pseudo-headings remain code, and escaping/noncanonical/missing targets fail closed. The full repository currently yields 1,357 nodes without asking the renderer what a declaration is.
- [ ] Documentation graph, identity, link, and bundle contracts are accepted.
- [ ] One manual page, Wheeler API declaration, Java stage-0 declaration, and executable example produce one validated bundle.
- [x] The zero-configuration `wheeler site` command builds canonical roots, re-verifies the complete semantic bundle, safely renders headings, prose, links, code, lists, tables, quotes, and admonitions, emits no scripts, binds bundle/renderer/output identities in `publication-manifest.json`, and atomically publishes static HTML/CSS. The renderer package graph, duplicated deployment-test workflow, and generic website configuration are deleted.
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

Rejected. Themes, plugins, package locks, and runtime-side Markdown interpretation recreate authorities already removed by the semantic bundle. The fixed renderer is intentionally boring. Boring publication code gets to sleep at night.

## Open questions

- Which safe Markdown extensions beyond the WIP-0016 profile enter the first manual bundle? — **Owner:** documentation and security maintainers — **Decide by:** before parser acceptance
- Should source packages ship bundle fragments or only raw docs plus compiler metadata? — **Owner:** package and documentation maintainers — **Decide by:** before package publication integration
- Which Java generic-signature identity remains stable across supported stage-0 JDKs? — **Owner:** Java and tools maintainers — **Decide by:** before doclet acceptance
- Which additional inert Markdown constructs justify a versioned site-profile change? — **Owner:** website and security maintainers — **Decide by:** before accepting such syntax

## References

- [WIP-0006](WIP-0006-concrete-syntax-tooling-and-teaching.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0016](WIP-0016-nonconfigurable-source-formatter.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [Development guide](../reference/development.md)
