# Wheeler examples

People learning or evaluating Wheeler can read every program in this package.
It covers classical control, affine ownership, aggregate data, modules, host input, text, and
quantum structure. Each program is a bounded `deployable` target in
[`wheeler.package.yaml`](wheeler.package.yaml).

Compiler bootstrap probes, package identity codecs, and runtime parity machines live in
[`wheeler-conformance`](../wheeler-conformance/README.md). They are important, executable, and
poor introductions. A manifest validator with seventeen rejection cases is not a hello-world
program merely because it once occupied the examples directory.

Run the package gates from the repository root:

```bash
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='check wheeler-examples'
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='test wheeler-examples'
```

Every source must compile, parse with Tree-sitter, and format canonically. `QFTProof.w` is the
selected package test target. Bounds are part of each example rather than ambient promises from
a machine with more memory.
