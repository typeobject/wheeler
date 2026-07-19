# Disposable Java bootstrap

Everything Java or Gradle-owned in this repository lives below this directory. The directories one level above are Wheeler packages, language tooling, documentation, provider adapters, and repository metadata; none should acquire a stray `src/main/java` because a host helper wanted a shorter commute.

The modules here are temporary stage-0 infrastructure:

- `core` is the independent Java oracle for canonical bytecode and VM behavior;
- `stage0` is the bounded Java source compiler seed;
- `runtime`, `package`, and `tools` are host-side migration adapters;
- `examples` is the JUnit conformance harness, not an implementation package.

The canonical Wheeler compiler lives in [`../wheeler-compiler`](../wheeler-compiler). Stage 0 compiles that exact package into stage 1. Stage 1 compiles the same package and options into stage 2. Complete stage-1 and stage-2 artifacts must match byte for byte before the result can become a recovery-seed candidate.

## Running the bootstrap gate

From the repository root:

```bash
./bootstrap/gradlew -p bootstrap clean check treeSitterTest
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='check .'
```

No root-level Gradle wrapper or build file is retained. That is deliberate: the repository is a Wheeler project with one quarantined host seed, not a Java multiproject wearing Wheeler source as a resource directory.

## Trust boundary

A fixed point proves reproducibility, not innocence. A malicious seed can reproduce its payload while smiling politely; Thompson documented that trick before many projects documented their build flags. Recovery-seed promotion therefore also requires:

- reviewed, content-addressed Java stage-0 source and Wheeler compiler source;
- strict independent `.wbc` verification of every emitted stage;
- no network, credentials, clock, randomness, environment lookup, reflection, dynamic loading, or ambient source discovery in compiler semantics;
- deterministic source, symbol, diagnostic, section, and padding order;
- differential artifacts and diagnostics over the checked conformance corpus;
- builds under pinned, independently obtained JDK distributions;
- diverse double-compilation evidence before a recovery-seed update;
- a manifest binding seed, sources, options, limits, verifier, and complete outputs.

The diverse path must not execute the candidate seed before comparing its result. It may use an independently built prior Wheeler recovery compiler, another reviewed stage-0 implementation, or a separately sourced host toolchain capable of reproducing this seed. Agreement narrows the trust argument; it does not repeal the need to trust hardware, reviewers, and at least one derivation path.

`wheeler bootstrap-manifest` is the final stage-0 evidence gate. It compares canonical stage 1, stage 2, diverse output, and diagnostic bytes; verifies the source package, schema-3 snapshot-bound lock, and closed acceptance artifact set; then atomically writes `wheeler.bootstrap.yaml`. It never executes the candidate and it rejects identical ordinary/diverse compiler or toolchain identities. The full option list and schema are in [`../docs/docs/reference/bootstrap.md`](../docs/docs/reference/bootstrap.md). There is intentionally no checked-in bootstrap manifest until the repository can supply real fixed-point and diverse evidence. Empty ceremony is still empty, even in canonical YAML.

## Scope and deletion

Stage 0 grows only when canonical Wheeler compiler source cannot yet be compiled or independently checked without that slice. New package, test, documentation, coverage, optimizer, provider, or editor behavior belongs in Wheeler unless it is strictly required to cross the bootstrap boundary. Each promoted Wheeler authority deletes its Java counterpart.

Once the Wheeler compiler builds a fixed point, passes differential diagnostics and examples, and has an independently reproduced recovery seed, ordinary builds stop depending on this directory. WIP-0007 owns that cutover; WIP-0008 removes the remaining host runtime. A bootstrap ladder is useful. Carrying it around forever is performance art.
