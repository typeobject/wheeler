# WIP-0018: Integrated deterministic testing

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, compiler, runtime, package, proof, quantum, and tools maintainers |
| Created | 2026-07-18 |
| Updated | 2026-07-18 |
| Area | Test declarations, deterministic runners, fixtures, reports, replay, quantum and reversible assertions |
| Depends on | WIP-0001, WIP-0002, WIP-0004, WIP-0005, WIP-0007, WIP-0009, WIP-0011, WIP-0013 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler will provide one integrated test framework. It keeps the useful parts of JUnit 5, such as declared cases, fixtures, parameterized inputs, tags, assertions, discovery, and reports. It does not import Java reflection, exceptions, threads, or class loaders.

Tests are Wheeler declarations compiled into canonical `.wbc`. Exact package targets select them, and each case runs in a fresh bounded VM. Tests observe the same typed IR as production code. The framework does not inject semantic counters or create a separate test dialect.

Discovery, case identity, parameter order, scheduling, shrinking, diagnostics, and report reduction are deterministic. Reversible, coherent, unitary, measurement, hybrid, workflow, proof, and malformed-artifact tests use different assertion contracts. A test that passes after VM rewind does not prove that a language-level inverse exists.

This WIP defines a Wheeler testing model. It does not rename JUnit classes and treat that as integration. Java and JUnit remain a stage-0 conformance harness until Wheeler can run the same semantic suites itself.

## Motivation

The repository currently uses JUnit to test the stage-0 compiler, VM, runtime, packages, and examples. That is reasonable while Java is the seed. It is not a self-hosted test contract. Bootstrap cannot finish while Java reflection discovers Wheeler tests and Java exceptions define failure.

Wheeler also has testing needs that a normal unit framework cannot infer:

- A reversible operation may need forward-state, inverse-state, and exact-history checks.
- VM rewind and language inversion are separate events.
- A coherent operation must return the expected bit, preserve amplitudes, and clean its workspace.
- Hardware results provide bounded evidence, not a theorem.
- Replay must not submit jobs again.
- Proof tests must separate kernel acceptance, rejection, and theorem meaning.
- Package tests must use exact locked source and capabilities.
- Parallel or distributed runs must reduce to one canonical report.

Helper libraries would create several discovery systems, timeout rules, and report formats. Wheeler needs one model before bootstrap work depends on it.

## Use cases

1. A package declares a classical unit case and three parameter rows. The runner derives four stable case identities, creates a fresh machine for each, executes them in canonical row order, and emits the same report regardless of host locale or worker count.

2. A reversible case snapshots state, executes `rev` code forward, invokes the language inverse, and proves exact restoration. A second assertion rewinds VM history. The report records both operations separately; substituting rewind for inverse fails the case.

3. A coherent case executes on an exact simulator, compares amplitudes with a declared tolerance profile, checks generated adjoint restoration, and verifies every ancillary qubit is clean. A sampled hardware case may check a statistical acceptance rule but cannot satisfy an exact-state or proof assertion.

4. A hybrid test records target evidence, crashes after evidence publication, and resumes. Replay consumes the recorded evidence without another submission. Retry creates a new job identity and therefore a new test attempt.

5. A package test requests a temporary filesystem capability. The runner provides an invocation-owned bounded virtual root and publishes files only after success. A test requesting ambient home-directory or network access without a declared capability fails before execution.

6. Two workers finish cases in the opposite order. The reducer sorts by stable case identity, detects duplicate attempts, and emits byte-identical semantic results. Wall-clock completion order is presentation trivia.

## Goals

- Define first-class, statically discoverable Wheeler test declarations.
- Provide bounded assertions for values, traps, artifacts, history, inverses, quantum state, workflows, packages, and proof certificates.
- Provide fresh-case isolation, explicit lifecycle fixtures, deterministic parameterization, tags, and bounded property cases.
- Make step, memory, history, shot, job, output, and fixture limits explicit.
- Separate exact assertions, sampled acceptance, target evidence, and formal proof.
- Make discovery and report order independent of reflection, filesystems, worker schedules, and locale.
- Support deterministic sharding and canonical result merging.
- Emit a semantic test report with adapters for terminal text, JSON, and JUnit XML.
- Run compiler and runtime bootstrap suites under Wheeler before deleting their JUnit authorities.

## Non-goals

- Reproduce the JUnit 5 API, extension registry, annotations, class loading, or exception hierarchy.
- Treat test order as an application synchronization mechanism.
- Permit unbounded generators, wall-clock sleeps, ambient randomness, or ambient network access.
- Treat a passing sampled quantum test as proof of a unitary, advantage, or hardware fidelity.
- Treat line coverage or assertion count as correctness.
- Mock private implementation by rewriting bytecode or monkey-patching global names.
- Add a second package resolver, scheduler, proof kernel, quantum target API, or formatter.
- Store credentials, provider objects, host paths, or temporary directories in semantic test artifacts.
- Require production artifacts to carry test bodies.

## Terms and semantic model

A **test declaration** is a named source declaration admitted only in a deployable or tool target carrying the manifest's `test` selector. It has a body, tags, limits, fixture requirements, and zero or more parameter sources.

A **test descriptor** is canonical verified metadata containing the declaration identity, executable function identity, parameter schema, tags, limits, and required capabilities.

A **case** is one descriptor plus one canonical parameter value. A nonparameterized declaration has exactly one case.

A **case identity** is domain-separated from package, compiler, artifact, descriptor, and canonical parameter identities. Display names are not identities.

An **attempt** is one execution of one case under one exact runner, target, fixture, and policy identity. Retry creates a new attempt; replay does not.

A **fixture** is invocation-owned state supplied through an explicit typed capability. Fixtures are not hidden statics and do not survive unless a declared durable store owns them.

A **test event** is an append-only runner observation such as start, assertion, trap, target evidence, retry, replay, fixture publication, pass, fail, skip, or cancel.

A **semantic test result** is one of:

```text
Pass(assertions, bounds, evidence_ids)
Fail(primary_diagnostic, assertions, bounds, evidence_ids)
Skip(reason_code)
Cancel(reason_code, durable_checkpoint?)
Inconclusive(reason_code, evidence_ids)
```

`Inconclusive` is required when bounded evidence cannot justify pass or fail. It does not count as a pass.

A **test run** is the canonical map from selected case identity to one accepted terminal attempt plus ordered runner metadata. Every selected case appears exactly once.

## Source declarations and discovery

The accepted first declaration is explicit instead of annotation-reflective:

```java
test void addition() {
  assert(add(2, 3) == 5);
}

test void signedIdentity(long value) cases(-1, 0, 1) {
  assert(value == value);
}
```

The accepted forms are parameterless classical `test void name()` and one-parameter `long` or `boolean` tests with 1 to 1,024 unique inline scalar `cases(...)`. Each row compiles only when selected as a case, is omitted from ordinary artifacts, and cannot borrow entry effects. Multi-parameter products, named sources, and descriptor grammar remain subject to WIP-0005 review.

Discovery reads only the exact source set of a test-selected runnable package target. It does not scan classpaths, process resources, current directories, or loaded modules. Descriptors are sorted by canonical qualified declaration identity. Parameter cases are sorted by canonical encoded value unless the source declares an already canonical finite sequence.

Duplicate qualified names, duplicate case identities, unstable encodings, unsupported parameter types, and cases exceeding declared limits fail compilation or discovery before execution.

A test declaration cannot be called from a production target; shared setup and assertion helpers live in ordinary test-source modules. Production builds omit test descriptors and bodies by source-set construction instead of bytecode stripping.

## Assertions

Direct assertions use the single `assert(condition);` form defined by WIP-0021 and lower to runner-recognized outcomes. The framework does not duplicate Boolean truth as `assertTrue`, `assertEquals`, or matcher syntax. Reversible, rewind, quantum, workflow, and proof operations produce distinct typed evidence over which a case may assert; they do not collapse into aliases. Assertions do not throw Java exceptions or mutate hidden test globals.

The first profile includes:

- exact signed, Boolean, finite-enum, record, variant, array, slice, UTF-8, and digest equality;
- exact artifact bytes, canonical decode/re-encode, and expected verification rejection;
- expected trap code and source/bytecode location;
- state snapshot equality and selected-state predicates;
- expected forward instruction and retained-history ceilings;
- language inverse restoration;
- VM rewind restoration;
- generated adjoint restoration under an exact simulator;
- clean ancillary quantum resources;
- bounded sampled predicates with an explicit shot count and acceptance rule;
- event-log, replay, retry, commit, and recovery expectations;
- proof-kernel acceptance or rejection of an exact certificate and proposition.

Assertion messages are bounded inert UTF-8 values. Rendering may show structural diffs. Semantic failure still stores bounded typed expected and actual values plus stable diagnostic codes. A renderer cannot reinterpret `NaN`, truncate a digest, or treat two different variants as equal.

## Lifecycle and isolation

Each case starts from a fresh verified program baseline, empty retained history, fresh fixture capabilities, and a runner-owned event buffer. No case observes another case's globals, heap, output, target handle, temporary root, random stream, or history.

The initial lifecycle is:

```text
suite fixture acquire
    case fixture acquire
        case body
    case fixture release
suite fixture release
```

Suite fixtures are allowed only when their state is immutable or accessed through an explicitly deterministic serialized capability. Mutable shared suite state is not an ordering back door.

Fixture release runs after pass or ordinary fail. A VM trap rolls back only according to VM semantics; the runner then releases host fixtures. Process death relies on durable fixture ownership and recovery records. Cleanup failure is a separate diagnostic and cannot erase the primary failure.

## Parameterized and property cases

Parameter sources are finite, typed, bounded, and canonical. Sources may be literal tables, finite enum products, fixed ranges, package resources with locked identities, or deterministic generators with explicit seed and count.

A property attempt records generator identity, seed, ordinal, generated value identity, and bounds. Shrinking is deterministic breadth-first over a declared finite shrink relation. The first failing value in canonical shrink order is the semantic counterexample. Timeout or exhausted shrink bounds retains the original failure and marks minimization incomplete.

Random seeds never default from wall time. An omitted seed is a compile or command diagnostic, not an invitation for the runner to feel lucky.

## Tags, selection, and sharding

Tags are canonical package-scoped names. Selection uses explicit command arguments or package test-target policy. Unknown tags fail; they do not select an empty suite successfully.

Shard assignment is:

```text
shard(case_identity, shard_count) -> [0, shard_count)
```

using one specified digest domain. Worker count and completion order cannot alter assignment or result order. A merge rejects duplicate terminal attempts unless a retry policy identifies one accepted attempt and records the rejected duplicates.

Disabled tests require a checked-in reason code and optional issue reference. Runtime conditionals use assumptions and produce `Skip`; they cannot silently avoid assertions.

## Reversibility and history

Test execution is an external observation and is not logically reversible. Runner events are append-only attempt history.

Within a case:

- a language inverse executes inverse instructions and is counted as program execution;
- VM rewind consumes retained undo records and is counted as rewind;
- uncomputation is checked against clean-resource obligations;
- replay reduces recorded events and does not execute the original effects;
- retry creates new effects and a new attempt identity.

Assertions may checkpoint and rewind machine state. Rewinding does not delete runner events; the report records both the forward and rewind observations. Coverage integrates through WIP-0020 and likewise separates attempted execution from final net state.

History exhaustion traps before the next mutation and fails the case with the exact bound. The runner may not raise the artifact's semantic limits after verification.

## Concurrency and determinism

Cases are isolated and may execute concurrently. Within one case, scheduling follows the verified program and WIP-0004/WIP-0015 event rules.

The semantic report is sorted by case identity, then attempt identity, then event sequence. Durations, CPU use, worker names, and wall timestamps are optional presentation fields outside semantic comparison.

A fail-fast command may stop scheduling new cases, but unscheduled selected cases appear as `Cancel(fail_fast)`. Running cases reach a declared cancellation boundary. The semantic report records every case as selected.

Resource locks are explicit fixture capabilities sorted by canonical identity. Cyclic or dynamically discovered lock sets fail before any case executes. Tests cannot use their usual database order as synchronization.

## Quantum and proof implications

Exact quantum assertions execute only on a deterministic exact simulator profile and compare canonical state representations under a declared tolerance and global-phase rule. Generated adjoint tests execute the actual lowered adjoint and require clean ancillas.

Sampled assertions record target identity, circuit identity, shots, seed when supported, counts, confidence rule, and acceptance threshold. Hardware evidence may be replayed but never promoted to an exact assertion or theorem.

Measurement is irreversible and cannot be uncalled. A test expecting measurement replay consumes recorded measurement evidence.

Proof assertions invoke the trusted kernel on an exact proposition and certificate. Kernel acceptance proves only that proposition under the named kernel profile. Any test that expects acceptance of a forged certificate must always fail immediately. Finding a theorem by name does not verify its proposition or certificate.

## Bytecode, reports, and compatibility

Canonical `.wbc` format 1.0 gains an optional test-descriptor section only after WIP-0001 verification rules are accepted. The section references ordinary verified functions and canonical parameter metadata. Unknown required descriptor kinds reject. No second bytecode format is introduced.

Test-report semantics are represented by a canonical Wheeler value schema with domain-separated identities. Terminal text, JSON, JUnit XML, and CI service messages are derived adapters. Adapter bytes are not proof evidence and don't define result ordering.

Reports include package, lock, compiler, artifact, runner, target, fixture-policy, and test-selection identities; reports containing secrets, absolute host paths, or ambient environment snapshots reject publication.

Format evolution uses optional fields and explicit required-feature identities inside the report schema. Readers fail closed on unknown required semantics. Reports used as release evidence do not allow best-effort decoding.

## Safety, limits, and failures

Every run declares maxima for selected cases, parameter rows, generator attempts, shrink nodes, steps, call depth, machine history, fixture bytes/objects, output bytes, diagnostics, report bytes, quantum jobs, shots, replay events, and wall-policy cancellation.

Semantic timeouts are step, event, shot, or job-state bounds. A host wall timeout may cancel an attempt but cannot be reported as a deterministic program timeout.

Malformed descriptors, duplicate identities, unsupported assertions, invalid fixture capabilities, leaked owned values, dirty ancillas, stale target evidence, invalid proof certificates, report overflow, and cleanup failure produce stable diagnostics.

The runner publishes a report only after canonical reduction succeeds. Partial worker files remain untrusted recovery inputs and are never mistaken for a complete run.

## I/O conformance testing

WIP-0032 supplies a deterministic backend that schedules inline or delayed completions in bounded chosen orders and injects partial progress, cancellation races, exhausted credits, uncertain outcomes, fallback, tier failure, and crash boundaries. Tests record any selected race as an observation; they do not promote a simulated receipt into evidence about real hardware.

The common conformance suite runs over deterministic, threaded, readiness, completion, polling, native, and VM implementations. Lifecycle, resource release, replay identity, and result encodings must agree even when physical completion order does not.

## Ownership and boundaries

The language owns test declaration typing and test-only visibility. The compiler owns descriptor lowering and source mappings; the bytecode verifier owns descriptor/function/type consistency. The VM owns program transitions, traps, snapshots, and rewind. The test runner owns isolation, fixtures, selection, attempts, event reduction, and report publication.

The package system owns exact test source sets, dependency locks, capabilities, and test policies. Quantum targets own target execution evidence but not pass semantics. The proof kernel owns certificate validity. Coverage belongs to WIP-0020. Documentation examples and doctests belong to WIP-0019.

JUnit adapters consume semantic reports during migration. They do not discover Wheeler tests or decide Wheeler outcomes.

## Migration and deletion

1. Define test values, stable diagnostics, descriptor identities, and the runner event reducer.
2. Add a bounded classical test declaration and fresh-VM runner vertical slice.
3. Add test selection to runnable package targets, exact discovery, tags, parameter rows, and canonical reports.
4. Add inverse, rewind, trap, malformed-artifact, package, and recovery assertions.
5. Add deterministic generators and shrinking.
6. Add exact-simulator, sampled-target, replay, and proof assertions.
7. Port compiler, VM, package, runtime, and example semantic suites from JUnit to Wheeler.
8. Make stage 0 and Wheeler runners consume the same descriptors and compare semantic reports.
9. Delete duplicated JUnit semantic suites and Java-only discovery helpers after parity. Retain small host-launcher and adapter tests only while Java remains a supported stage-0 host.
10. Move the accepted runner into the canonical Wheeler tools package; delete incubator copies from examples.

## Progress

- [x] The stage-0 runner discovers only exact runnable `test` target source sets. It derives separate case, source, artifact, execution, and report identities. Each case gets a fresh runtime. Compile errors, runtime traps, and failed assertions map to `WTEST001..003`. Cases are sorted canonically, and the terminal report is stable across reruns.
- [x] Classical `test void name()` declarations and bounded one-scalar `cases(...)` rows parse in the compiler and Tree-sitter grammar. For a selected target or modular root, the compiler finds names lexically and links the exact reachable package graph. It emits one verified artifact whose only test entry is the selected declaration. Ordinary artifacts omit every test body, and normal `run` behavior stays unchanged.
- [ ] Full test descriptor semantics, including modular qualification, parameters, fixtures, tags, and limits, are accepted.
- [x] Two Wheeler cases compile from one exact package target, run in separate fresh VMs, carry distinct identities and coverage reports, and reduce into one rerun-stable report.
- [x] Bounded inline `long` and `boolean` parameter rows parse, receive indexed stable names, compile through a synthetic no-argument entry wrapper, and execute independently.
- [ ] Parameter products, lifecycle fixtures, tags, and deterministic sharding execute.
- [ ] Inverse, rewind, quantum, workflow, package, and proof assertions execute with distinct semantics.
- [ ] A Wheeler-written runner reproduces the stage-0 semantic report.
- [ ] Superseded JUnit semantic authorities are deleted.

## Testing and acceptance

- [ ] Discovery order and case identities are stable under source-map, filesystem, locale, and worker-order variation.
- [ ] Fresh-case isolation prevents global, heap, history, output, fixture, and target leakage.
- [ ] Parameter products, explicit seeds, generation, and shrinking are deterministic and bounded.
- [ ] Lifecycle acquire/release ordering is exact across pass, assertion fail, trap, cancel, and process recovery.
- [ ] Language inverse, VM rewind, uncomputation, replay, and retry tests distinguish every boundary.
- [ ] Exact simulator tests cover amplitudes, global phase, generated adjoints, and clean ancillas.
- [ ] Sampled tests retain evidence and cannot satisfy exact or proof assertions.
- [ ] Proof tests accept valid certificates and reject forged subjects, rules, arguments, and payloads.
- [ ] Malformed descriptors, duplicate cases, unknown tags, exhausted limits, and oversized reports fail closed.
- [ ] Parallel shards merge to the byte-identical semantic report produced by serial execution.
- [ ] Terminal, JSON, and JUnit XML adapters agree on semantic outcomes.
- [ ] An end-to-end package suite compiles and tests the self-hosted compiler using no Java discovery.
- [ ] Current reference documentation describes only implemented runner behavior.

## Alternatives

### Keep JUnit as the permanent runner

Rejected. It keeps reflection, Java process semantics, and Java exceptions in the bootstrap trust chain and cannot define Wheeler inverse, rewind, coherent, replay, or proof assertions.

### Copy JUnit 5 annotations and extension APIs

Rejected. Annotation spelling is the least interesting part of JUnit. Copying its class-loader extension model would import the host boundary while omitting the semantics Wheeler actually needs.

### Treat tests as ordinary entry programs

Useful for tiny fixtures, but insufficient for canonical discovery, isolation, parameterization, lifecycle, report merging, capabilities, and release evidence. The integrated model may lower each case to an ordinary verified function; it still needs descriptors and a runner contract.

### Let every library choose a test framework

Rejected. Multiple frameworks mean multiple discovery and report authorities. Assertion helper libraries may exist, but one runner owns case semantics.

### Make every test reversible

Rejected. Assertions, event recording, target submission, fixture I/O, and report publication are observations or effects. Tests can verify reversible code while keeping assertions, reports, and other observations irreversible.

## Open questions

- Which explicit grammar should extend accepted `test void name()` declarations with parameter rows, tags, fixtures, and per-case limits (owner: language and tooling maintainers; decision point: before descriptor implementation)?
- Which canonical report encoding is smallest while remaining independently inspectable during bootstrap (owner: runtime and package maintainers; decision point: before report persistence)?
- Which exact simulator tolerance profiles are portable enough for semantic assertions (owner: quantum and numerical maintainers; decision point: before quantum assertion acceptance)?
- Which fixture capabilities belong in the first self-host compiler suite (owner: compiler and package maintainers; decision point: before bootstrap runner promotion)?

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0015](WIP-0015-certified-adversarial-schedule-exploration.md)
- [WIP-0019](WIP-0019-integrated-documentation-publication.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0021](WIP-0021-uniform-call-and-assertion-syntax.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
