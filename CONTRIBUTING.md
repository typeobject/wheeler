# Contributing to Wheeler

Wheeler is pre-release, but changes are welcome when they preserve one semantic authority and arrive with executable evidence.

## Before sending a change

1. Read the relevant [Wheeler Improvement Proposal](docs/internal/proposals/index.mdx).
2. Keep reference documentation limited to implemented behavior.
3. Match verification to the change. For proposal organization or prose, run the
   [short documentation gate](docs/internal/proposals/index.mdx#checks). Run the
   complete local gate for an implementation series before final review:

```bash
export JAVA_HOME="$(brew --prefix openjdk)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
./bootstrap/gradlew -p bootstrap clean check treeSitterTest
rm -rf docs-site
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='site -o docs-site'
```

Run the bounded closure evidence task when a patch changes the physical compiler catalog, retained products, relocation, or final linking:

```bash
./bootstrap/gradlew -p bootstrap :examples:closureEvidenceTest
```

The ordinary gate gives each JUnit method two minutes. Hosted CI also caps each deterministic example shard at fifteen minutes. The explicit closure task allows forty-five minutes per method and fifty minutes for the task. `bootstrap/examples/build.gradle` owns those deadlines. Do not run closure evidence for documentation-only changes.

## Patch rules

- State observable semantics before choosing an API or opcode.
- Add positive, negative, boundary, and end-to-end tests.
- Keep authored code files below 1,000 lines.
- Keep every Java and Gradle-owned file below `bootstrap/`. Canonical Wheeler package roots do not host Java helpers.
- Delete the replaced implementation in the same series. Do not leave two authorities.
- Keep provider objects, credentials, and generated SDK types outside canonical bytecode.
- Update examples and current reference pages with behavior changes.
- Update an Implementing WIP's checklist in the patch that supplies the evidence.
- Use the [proposal workflow](docs/internal/proposals/workflow.md). Keep routine refactors in the owning checklist rather than allocating a WIP per helper. Keep detailed milestone evidence out of umbrella checklists.
- Use small commits whose message states the completed feature.
- Run `wheeler format --check .`. Canonical `/* parameter= */ value` comments label adjacent ambiguous literals without pretending comments are named-argument syntax.
- After changing a workspace package, rebuild its `.wpk`, replace that archive identity in every exact dependent lock, and run one locked dependent command before pushing.
- Add mechanical checks only when they are deterministic, high-signal, and fatal without a suppression ledger.

Compiler warnings are errors. Broken documentation links are errors. Tree-sitter conflicts and corpus failures are errors.

## Documentation voice

Write in active voice. Name the actor first. Address readers as `you` when you give instructions. Use short words and direct sentences. Vary sentence length so the page does not sound like a register dump.

Cut filler, clichés, marketing claims, repeated conclusions, and fake enthusiasm. State the problem. State the rule. Show the evidence. Keep jokes dry and brief.

Do not use prose semicolons, en dashes, or em dashes. Use Markdown punctuation where the format needs it, including list markers, links, and emphasis. Keep code punctuation inside code spans and fences. `DocumentationStyleTest` enforces the mechanical rules and catches a narrow set of passive constructions and filler phrases. Reviewers still own judgment. A regex cannot edit prose, and anyone claiming otherwise is selling a regex.

## Wheeler source layout

Physical directories group one concern and contain at most ten `.w` files. `sourceLayoutTest` enforces the limit. The compiler uses `backend`, `frontend`, `ir`, and `verification`. Package code uses `archive`, `manifest`, `resolution`, and `workspace`. Examples use classical control/data/ownership, host, native, quantum, and text groups. Logical `module` declarations remain the import authority, so moving a file does not buy a second namespace by accident.

Add a directory when a new concern appears instead of growing a miscellaneous drawer. A source tree should be navigable with `find`, not an expedition permit.

Generated Wheeler artifacts belong under `<repository>/build/<workspace-member>/` (or a standalone package's `build/`) and that root is ignored. Package-local `vendor/` trees are generated offline inputs and are ignored too. Do not commit a small archive warehouse once the exact lock and workspace sources can reproduce it. `clean` removes `build/`, not source, locks, or an explicitly materialized vendor closure.

## Review standard

Review starts from invariants, failure behavior, bounds, and migration deletion. There is no pre-release backward-compatibility burden: replaced experimental files and profiles are deleted, not preserved behind switches. A proposal is not Implemented until code, tests, examples, documentation, and required deletion agree.
