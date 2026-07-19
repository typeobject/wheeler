# Contributing to Wheeler

Wheeler is pre-release, but changes are welcome when they preserve one semantic authority and arrive with executable evidence.

## Before sending a change

1. Read the relevant [Wheeler Improvement Proposal](docs/docs/proposals/README.md).
2. Keep reference documentation limited to implemented behavior.
3. Run the complete local gate:

```bash
export JAVA_HOME="$(brew --prefix openjdk)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
./bootstrap/gradlew -p bootstrap clean check treeSitterTest
rm -rf docs-site
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='site -o docs-site'
```

## Patch rules

- State observable semantics before choosing an API or opcode.
- Add positive, negative, boundary, and end-to-end tests.
- Keep authored code files below 1,000 lines.
- Keep every Java and Gradle-owned file below `bootstrap/`; canonical Wheeler package roots do not host Java helpers.
- Delete the replaced implementation in the same series; do not leave two authorities.
- Keep provider objects, credentials, and generated SDK types outside canonical bytecode.
- Update examples and current reference pages with behavior changes.
- Update an Implementing WIP's checklist in the patch that supplies the evidence.
- Use small commits whose message states the completed feature.

Compiler warnings are errors. Broken documentation links are errors. Tree-sitter conflicts and corpus failures are errors.

## Wheeler source layout

Physical directories group one concern and contain at most ten `.w` files; `sourceLayoutTest` enforces the limit. The compiler uses `backend`, `frontend`, `ir`, and `verification`; package code uses `archive`, `manifest`, `resolution`, and `workspace`; examples use classical control/data/ownership, host, native, quantum, and text groups. Logical `module` declarations remain the import authority, so moving a file does not buy a second namespace by accident.

Add a directory when a new concern appears instead of growing a miscellaneous drawer. A source tree should be navigable with `find`, not an expedition permit.

Generated Wheeler artifacts belong under `<repository>/build/<workspace-member>/` (or a standalone package's `build/`). Package-local `vendor/` trees are committed dependency inputs, not outputs: they carry the exact offline archive closure and `wheeler.package.lock`, and `clean` must not eat the ladder used for bootstrap.

## Review standard

Review starts from invariants, failure behavior, bounds, and migration deletion. There is no pre-release backward-compatibility burden: replaced experimental files and profiles are deleted, not preserved behind switches. A proposal is not Implemented until code, tests, examples, documentation, and required deletion agree.
