# Development guide

## Local gate

Use JDK 26 and the checked-in Gradle wrapper:

```bash
export JAVA_HOME="$(brew --prefix openjdk)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
./gradlew clean check
```

Java compilation enables all lint warnings and treats warnings as errors. `check` runs JUnit and generates JaCoCo reports for modules with tests.

## Design workflow

Cross-cutting semantic changes begin as a [Wheeler Improvement Proposal](../proposals/README.md). Reference pages describe implemented behavior only. A WIP becomes Implemented after its acceptance tests, documentation, migration, and required deletion are complete.

## Maintenance rules

- Keep source files focused and below 1,000 lines.
- Delete replaced implementations; do not maintain parallel authorities.
- Add negative tests for every parser, verifier, capability, and lifecycle boundary.
- Prefer pure transition functions and immutable artifact models.
- Keep provider objects and credentials outside canonical bytecode and persisted language values.
- Commit and push each independently verified major feature.

## Module dependency direction

```text
wheeler-core <- wheeler-compiler
wheeler-core <- wheeler-runtime
wheeler-core + compiler + runtime <- wheeler-tools
wheeler-core + compiler + runtime <- wheeler-examples tests
```

Core has no runtime dependencies. Source parsing does not depend on a provider. Quantum adapters will implement runtime contracts rather than entering language semantics.
