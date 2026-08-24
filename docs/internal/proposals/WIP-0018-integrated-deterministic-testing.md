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

2. A reversible case snapshots state, executes `rev` code forward, invokes the language inverse, and proves exact restoration. A second assertion rewinds VM history. The report records both operations separately. Substituting rewind for inverse fails the case.

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

An **attempt** is one execution of one case under one exact runner, target, fixture, and policy identity. Retry creates a new attempt. Replay does not.

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

Discovery reads only the exact source set of a test-selected runnable package target. It does not scan classpaths, process resources, current directories, or loaded modules. The runner sorts descriptors by canonical qualified declaration identity. It sorts parameter cases by canonical encoded value unless the source declares an already canonical finite sequence.

Duplicate qualified names, duplicate case identities, unstable encodings, unsupported parameter types, and cases exceeding declared limits fail compilation or discovery before execution.

A test declaration cannot be called from a production target. Shared setup and assertion helpers live in ordinary test-source modules. Production builds omit test descriptors and bodies by source-set construction instead of bytecode stripping.

## Assertions

Direct assertions use the single `assert(condition);` form defined by WIP-0021 and lower to runner-recognized outcomes. The framework does not duplicate Boolean truth as `assertTrue`, `assertEquals`, or matcher syntax. Reversible, rewind, quantum, workflow, and proof operations produce distinct typed evidence over which a case may assert. They do not collapse into aliases. Assertions do not throw Java exceptions or mutate hidden test globals.

The first profile includes:

- exact signed, Boolean, finite-enum, record, variant, array, slice, UTF-8, and digest equality.
- exact artifact bytes, canonical decode/re-encode, and expected verification rejection.
- expected trap code and source/bytecode location.
- state snapshot equality and selected-state predicates.
- expected forward instruction and retained-history ceilings.
- language inverse restoration.
- VM rewind restoration.
- generated adjoint restoration under an exact simulator.
- clean ancillary quantum resources.
- bounded sampled predicates with an explicit shot count and acceptance rule.
- event-log, replay, retry, commit, and recovery expectations.
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

Fixture release runs after pass or ordinary fail. A VM trap rolls back only according to VM semantics. The runner then releases host fixtures. Process death relies on durable fixture ownership and recovery records. Cleanup failure is a separate diagnostic and cannot erase the primary failure.

## Parameterized and property cases

Parameter sources are finite, typed, bounded, and canonical. Sources may be literal tables, finite enum products, fixed ranges, package resources with locked identities, or deterministic generators with explicit seed and count.

A property attempt records generator identity, seed, ordinal, generated value identity, and bounds. Shrinking is deterministic breadth-first over a declared finite shrink relation. The first failing value in canonical shrink order is the semantic counterexample. Timeout or exhausted shrink bounds retains the original failure and marks minimization incomplete.

Random seeds never default from wall time. An omitted seed is a compile or command diagnostic, not an invitation for the runner to feel lucky.

## Tags, selection, and sharding

Tags are canonical package-scoped names. Selection uses explicit command arguments or package test-target policy. Unknown tags fail. They do not select an empty suite successfully.

Shard assignment is:

```text
shard(case_identity, shard_count) -> [0, shard_count)
```

using one specified digest domain. Worker count and completion order cannot alter assignment or result order. A merge rejects duplicate terminal attempts unless a retry policy identifies one accepted attempt and records the rejected duplicates.

Disabled tests require a checked-in reason code and optional issue reference. Runtime conditionals use assumptions and produce `Skip`. They cannot silently avoid assertions.

## Reversibility and history

Test execution is an external observation and is not logically reversible. Runner events are append-only attempt history.

Within a case:

- a language inverse executes inverse instructions and is counted as program execution.
- VM rewind consumes retained undo records and is counted as rewind.
- uncomputation is checked against clean-resource obligations.
- replay reduces recorded events and does not execute the original effects.
- retry creates new effects and a new attempt identity.

Assertions may checkpoint and rewind machine state. Rewinding does not delete runner events. The report records both the forward and rewind observations. Coverage integrates through WIP-0020 and likewise separates attempted execution from final net state.

History exhaustion traps before the next mutation and fails the case with the exact bound. The runner may not raise the artifact's semantic limits after verification.

## Concurrency and determinism

Cases are isolated and may execute concurrently. Within one case, scheduling follows the verified program and WIP-0004/WIP-0015 event rules.

The runner sorts the semantic report by case identity, then attempt identity, then event sequence. Durations, CPU use, worker names, and wall timestamps are optional presentation fields outside semantic comparison.

A fail-fast command may stop scheduling new cases, but unscheduled selected cases appear as `Cancel(fail_fast)`. Running cases reach a declared cancellation boundary. The semantic report records every case as selected.

Resource locks are explicit fixture capabilities sorted by canonical identity. Cyclic or dynamically discovered lock sets fail before any case executes. Tests cannot use their usual database order as synchronization.

## Quantum and proof implications

Exact quantum assertions execute only on a deterministic exact simulator profile and compare canonical state representations under a declared tolerance and global-phase rule. Generated adjoint tests execute the actual lowered adjoint and require clean ancillas.

Sampled assertions record target identity, circuit identity, shots, seed when supported, counts, confidence rule, and acceptance threshold. Hardware evidence may be replayed but never promoted to an exact assertion or theorem.

Measurement is irreversible and cannot be uncalled. A test expecting measurement replay consumes recorded measurement evidence.

Proof assertions invoke the trusted kernel on an exact proposition and certificate. Kernel acceptance proves only that proposition under the named kernel profile. Any test that expects acceptance of a forged certificate must always fail immediately. Finding a theorem by name does not verify its proposition or certificate.

## Bytecode, reports, and compatibility

Canonical `.wbc` format 1.0 gains an optional test-descriptor section only after WIP-0001 verification rules are accepted. The section references ordinary verified functions and canonical parameter metadata. Unknown required descriptor kinds reject. No second bytecode format is introduced.

A canonical Wheeler value schema with domain-separated identities represents test-report semantics. The runner derives terminal text, JSON, JUnit XML, and CI service messages from that schema. Adapter bytes are not proof evidence and don't define result ordering.

Reports include package, lock, compiler, artifact, runner, target, fixture-policy, and test-selection identities. Reports containing secrets, absolute host paths, or ambient environment snapshots reject publication.

Format evolution uses optional fields and explicit required-feature identities inside the report schema. Readers fail closed on unknown required semantics. Reports used as release evidence do not allow best-effort decoding.

## Safety, limits, and failures

Every run declares maxima for selected cases, parameter rows, generator attempts, shrink nodes, steps, call depth, machine history, fixture bytes/objects, output bytes, diagnostics, report bytes, quantum jobs, shots, replay events, and wall-policy cancellation.

Semantic timeouts are step, event, shot, or job-state bounds. A host wall timeout may cancel an attempt but cannot be reported as a deterministic program timeout.

Malformed descriptors, duplicate identities, unsupported assertions, invalid fixture capabilities, leaked owned values, dirty ancillas, stale target evidence, invalid proof certificates, report overflow, and cleanup failure produce stable diagnostics.

The runner publishes a report only after canonical reduction succeeds. Partial worker files remain untrusted recovery inputs and are never mistaken for a complete run.

## I/O conformance testing

WIP-0032 supplies a deterministic backend that schedules inline or delayed completions in bounded chosen orders and injects partial progress, cancellation races, exhausted credits, uncertain outcomes, fallback, tier failure, and crash boundaries. Tests record any selected race as an observation. They do not promote a simulated receipt into evidence about real hardware.

The common conformance suite runs over deterministic, threaded, readiness, completion, polling, native, and VM implementations. Lifecycle, resource release, replay identity, and result encodings must agree even when physical completion order does not.

## Ownership and boundaries

The language owns test declaration typing and test-only visibility. The compiler owns descriptor lowering and source mappings. The bytecode verifier owns descriptor/function/type consistency. The VM owns program transitions, traps, snapshots, and rewind. The test runner owns isolation, fixtures, selection, attempts, event reduction, and report publication.

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
10. Move the accepted runner into the canonical Wheeler tools package. Delete incubator copies from examples.

## Progress

- [x] The stage-0 runner discovers only exact runnable `test` target source sets. It derives separate case, source, artifact, execution, and report identities. Each case gets a fresh runtime. Compile errors, runtime traps, and failed assertions map to `WTEST001..003`. Cases are sorted canonically, and the terminal report is stable across reruns.
- [x] Classical `test void name()` declarations and bounded one-scalar `cases(...)` rows parse in the compiler and Tree-sitter grammar. For a selected target or modular root, the compiler finds names lexically and links the exact reachable package graph. It emits one verified artifact whose only test entry is the selected declaration. Ordinary artifacts omit every test body, and normal `run` behavior stays unchanged.
- [x] The scalar stage-0 descriptor profile accepts reachable modular qualification, parameterless or one-scalar declarations, bounded inline cases, canonical tags, per-case step and history limits, and the first unparameterized lifecycle fixture declaration. Capability-bearing fixtures, generators, target capabilities, and wider parameter products remain later descriptor extensions.
- [x] Two Wheeler cases compile from one exact package target, run in separate fresh VMs, carry distinct identities and coverage reports, and reduce into one rerun-stable report.
- [x] Bounded inline `long` and `boolean` parameter rows parse, receive indexed stable names, compile through a synthetic no-argument entry wrapper, and execute independently.
- [x] Bounded scalar parameter products and digest-assigned deterministic shards execute for the accepted profile. WIP-0194 reproduces the complete case-identity shard assignment in a Wheeler conformance target. WIP-0195 derives that case identity from the canonical profile-2 transcript. WIP-0196 sorts and summarizes the complete bounded outcome set without host collections. WIP-0197 moves identity and shard semantics from conformance executables into the canonical runtime library. WIP-0198 does the same for canonical summary reduction. WIP-0199 reproduces the complete profile-2 report identity for one passing or failing case. WIP-0200 adds the canonical empty report. WIP-0201 replaces both transitional frame shapes with one counted, arrival-independent profile for up to 64 complete cases. WIP-0202 moves fresh bounded artifact execution and storage teardown into the runtime API shared by native coverage and the emerging runner. WIP-0203 classifies successful artifacts and verifier errors into one fixed native outcome frame without Java exceptions. WIP-0204 reproduces complete classical, quantum, and hybrid execution-result identities in the runtime. WIP-0205 derives the stage-0 coverage identity from one canonical Wheeler-reduced transition report. WIP-0206 carries the complete eight-slot global result vector from native execution into test policy. WIP-0207 projects the matching program kind, program name, and global names from the verified artifact without host metadata. WIP-0208 composes those fields and the native outcome into the byte-identical stage-0 execution identity. WIP-0209 executes one passing classical artifact once and composes artifact, execution, coverage, assertion, case, and final report identities entirely inside Wheeler. WIP-0210 adds assertion-failure reports and deletes the pass-only composition path. WIP-0211 executes one passing and one failing artifact in reverse semantic order, retains complete case rows, and reduces one canonical report. WIP-0212 derives both runner case identities from the manifest, target, and source transcript inside Wheeler. WIP-0213 applies runtime shard assignment before artifact verification and execution, including empty and one-case shards. WIP-0214 publishes the runtime-reduced selected, passed, failed, and successful summary beside the report identity. WIP-0215 moves verifier, assertion, and interpreter failure diagnostics into the runtime reporter and removes caller overrides. WIP-0216 replaces fixture-coded runner metadata with bounded discovered descriptor frames and native source hashing. WIP-0217 moves complete descriptor validation, scheduling, execution, and reduction into the canonical runtime library. WIP-0218 replaces the fixed two-case scheduler with one counted zero-to-64-case descriptor runner. WIP-0219 binds every case to one shared package manifest identity in the run header. WIP-0220 derives that identity inside Wheeler from exact canonical manifest bytes. WIP-0221 validates package metadata and test-target selection against those bytes before execution. WIP-0222 hashes one canonical target source plan and binds complete discovered case names to every identity and report row. WIP-0223 validates source count, path normalization, ordering, lengths, and the exact plan boundary before hashing. WIP-0224 adds strict bounded UTF-8 validation for every source payload. WIP-0225 validates complete case names in strict canonical discovery order before identity derivation or execution. WIP-0226 binds dependency-free runs to exact schema-3 lock bytes and the native manifest identity. WIP-0227 binds the first source-plan entry to the selected manifest path. WIP-0228 generalizes that boundary to every exact-file selector and removes concatenated fixture sources. WIP-0229 requires a deployable target whose root belongs to that selected source set. WIP-0230 binds the target module to the root declaration. WIP-0231 validates canonical module preambles in every selected source and shares that parser with root matching. WIP-0232 rejects duplicate module owners across the complete source plan. WIP-0233 validates and resolves bounded package-local imports after complete framing. WIP-0234 requires strict canonical import order and rejects duplicate edges. WIP-0235 rejects cycles through bounded allocation-free reachability. WIP-0236 proved direct native source compilation and execution. WIP-0237 moves that boundary into the canonical runner and requires byte-identical profile-2 products against transported artifacts. WIP-0238 selects the manifest root and compiles one local imported source with it. WIP-0239 extends the same exact report path to two imported sources. WIP-0240 moves source ownership and fixed-arity compiler dispatch out of report reduction. WIP-0241 extends that authority to three imported sources. WIP-0242 extends it to four imported sources. WIP-0243 extends it to five imported sources. WIP-0244 extends it to six imported sources. WIP-0245 closes the public fixed compiler profile at seven imported sources. WIP-0246 derives the direct entry-case name from the selected target. WIP-0247 discovers and binds one parameterless root test through the native lexer. WIP-0248 generalizes exact discovery to 64 complete parameterless cases. WIP-0249 discovers canonical `long` and `boolean` parameter rows and binds their ordinal case names. WIP-0250 gives each selected artifact one retained verifier attempt. WIP-0251 binds each verified transported artifact to the manifest-selected root module and discovered function. WIP-0252 binds synthetic entries to exact native-discovered parameter values. WIP-0253 compiles one discovered parameterless test without a transported artifact. WIP-0254 extends that path through the complete fixed eight-source graph. WIP-0255 compiles up to 64 parameterless declarations as independent native cases. WIP-0256 separates native source lowering from declaration discovery. WIP-0257 compiles discovered `long` and `boolean` rows without transported artifacts. WIP-0258 rejects unsupported declaration metadata. WIP-0259 parses canonical limits and enforces source step bounds for transported and native-compiled artifacts. WIP-0260 parses native tags and selects complete descriptor sets by canonical conjunction. WIP-0261 constructs selected descriptor names and scalar metadata from source without Java case input. WIP-0262 makes native summary parity a mandatory `wheeler test` gate for dependency-free one-source modular packages. WIP-0263 derives module-qualified package case names from the validated root source. WIP-0264 extends package gating through seven local constant-import modules. WIP-0265 invokes and count-checks every eligible test-selected target. WIP-0266 applies package tag conjunction natively per target. WIP-0267 rejects package-wide unknown tags through metadata-only native probes before stage-0 discovery. WIP-0268 reduces target reports and summaries into one arrival-independent native package evidence identity. WIP-0269 parses complete schema-3 lock structure. WIP-0270 binds every direct manifest dependency name to that lock before discovery. WIP-0271 checks stable exact, caret, and tilde constraints against the locked version. WIP-0272 adds native prerelease grammar and precedence without allowing stable ranges to select previews. WIP-0273 rejects locked dependency edges whose package target is absent. WIP-0274 rejects lock cycles and packages unreachable from direct manifest dependencies. WIP-0275 sends physical nonempty locks through the native package gate when selected test imports remain local. WIP-0276 publishes complete native profile-2 rows and removes Java discovery, compilation, execution, and outcome policy from eligible package commands. WIP-0277 publishes each target's rows in strict native case-identity order with count-sized output and no retained outer rewind history. WIP-0278 sorts the complete bounded package row set and derives its combined profile-2 identity natively. WIP-0279 adds a checked-in compiler package target that compiles seven physical compiler modules through the eight-source native boundary and returns one passing case without Java discovery. WIP-0280 resolves and checks a production compiler constant in that case. WIP-0281 performs checked addition over the imported value. WIP-0282 extends the native case through subtraction, multiplication, division, remainder, and six assertion attempts. WIP-0283 adds bitwise operations, ordered comparison, nine assertions, and 128-row native coverage. WIP-0284 gives all seven imported compiler modules independent native cases and reduces seven package rows. WIP-0285 executes a physical imported compiler function from every case. WIP-0287 records its physical function, instruction, and branch coordinates in each native coverage identity. WIP-0314 raises complete native coverage framing to the terminal one-byte count of 255 transitions. WIP-0328 raises the complete case, discovery, report, reduction, and adapter profile to 128 after the compiler suite fills the former case bound.
- [x] Bounded canonical dotted tags attach to test declarations, survive modular linking, and sort in descriptor metadata. Repeated `--tag` filters select the intersection without an ambient registry.
- [x] Optional `limits(steps = N, history = M)` metadata survives modular linking and rewrites only that case artifact's verified machine ceilings before hashing and execution.
- [x] The first source-declared lifecycle fixture profile names four distinct zero-argument `void` functions in `fixtures(suite_acquire = ..., case_acquire = ..., case_release = ..., suite_release = ...)`. The compiler resolves exact artifact function identities. The runner executes the phases around one unparameterized case in that order and attempts both releases after pass, assertion failure, runtime trap, or case-release failure.
- [x] `TestEvidence` gives classical, language-inverse, VM-rewind, uncomputation, exact-quantum, sampled-quantum, workflow, package, proof, and malformed-artifact evidence distinct closed kinds through assertion reduction. The current Java seed exercises the reducer. Source syntax and the Wheeler-written runner remain.
- [x] A Wheeler-written runner reproduces the stage-0 semantic report for the accepted one-case passing classical profile. Multi-case discovery, scheduling, and failing-case diagnostics remain before runner promotion.
- [ ] Superseded JUnit semantic authorities are deleted. Eligible fixed-profile package commands now consume native case rows directly. Packages outside that profile and the remaining semantic suites still use JUnit.

## Testing and acceptance

- [x] Stage-0 discovery expands selected source trees into lexical logical-path maps, resolves modules by canonical names, sorts declarations by qualified lexical identity, and sorts the reduced report by case identity. Case and report hashes consume explicit UTF-8 and fixed-width fields. No locale, filesystem enumeration order, source-map order, worker, or completion order enters the implemented profile.
- [x] Every implemented stage-0 case compiles to its own entry artifact and runs in a newly constructed VM. The multi-case fixture mutates state in one case and proves a later lexical case still observes the declared initial global. Fixtures and target-bearing cases remain future work.
- [x] The implemented inline signed and Boolean `cases(...)` products retain declaration order, use stable indexed identities, reject duplicate or mistyped rows, and cap one product at 1,024 values. Seeds, generation, and shrinking remain outside the profile.
- [x] Lifecycle acquire/release ordering is exact for the accepted in-process profile across pass, assertion failure, runtime trap, and cleanup failure. The runner preserves the primary diagnostic, records cleanup failures and post-cleanup globals, and attempts suite release after case release fails. Cancellation and process recovery require durable fixture capabilities and remain outside this profile.
- [x] Transition evidence distinguishes forward, language inverse, rewind-forward, and rewind-inverse directions. Hybrid tests separately prove replay performs no submission and retry creates a new branch and provider lineage. Typed uncomputation assertions remain.
- [x] Exact semantic-simulator tests inspect canonical complex amplitudes, including a nonzero imaginary phase. They execute the generated adjoint and require exact initial-amplitude restoration, which also proves the entangled ancilla returned to zero for the accepted fixture. A source-level typed exact assertion remains part of the broader assertion profile.
- [x] Sampled assertion evidence requires at least one bounded observation identity and retains its sampled kind. `Inconclusive` reduces only to `INCONCLUSIVE`. It becomes pass or fail only through an explicit content-identified `SampledComparison`, and that conversion cannot be applied to exact or proof evidence.
- [x] The current kernel fixture accepts a canonical generated-inverse certificate and rejects a nonreversible subject, an invalid rule argument, and a forged inverse body. The runner still needs a source-level typed proof assertion rather than a Java harness.
- [x] The accepted scalar profile rejects malformed result rows, duplicate inline cases, duplicate report identities, unknown selected tags, a 1,025th parameter row, and a 65,536th report row before publication. General descriptor kinds and remaining execution limits stay outside this closure.
- [x] `--shard INDEX/COUNT` assigns each implemented case by its complete case-identity digest. Shards are disjoint and complete. Canonical reduction sorts arrival-independent rows, rejects duplicate case identities, and reproduces the serial profile-2 report identity.
- [x] Terminal, canonical JSON, and JUnit XML adapters consume one sorted profile-2 report. Each carries the same case status, diagnostics, assertion count, source, artifact, execution, coverage, and report identities. WIP-0289 moves exact empty, passing, and failing JSON rendering into the runtime for native package commands. WIP-0290 adds byte-identical native terminal rendering and one shared adapter-frame parser. WIP-0291 adds byte-identical native JUnit XML. All three formats now render inside the runtime for admitted package suites. Adapter bytes remain outside semantic identity.
- [ ] An end-to-end package suite compiles and tests the complete self-hosted compiler using no Java discovery. WIP-0279 proves the package command and native case-row path over a seven-module physical compiler spine. WIP-0292 adds a second seven-module physical compiler partition. WIP-0293 adds three call-syntax and loop-layout modules, raising the checked-in suite to seventeen native cases. WIP-0304 adds the physical type-kind decoder. WIP-0305 adds the call-assignment arity decoder and a nineteenth native case. WIP-0310 removes the native compiler's multi-helper entry restriction. WIP-0311 adds the three nested assignment-call width decoders. WIP-0312 adds the physical assignment-call operand owner group. WIP-0313 adds both three-member void-call operand owners. WIP-0314 admits complete coverage for passing native artifacts through 255 transitions instead of trapping after execution. WIP-0315 adds both ordinary void-call width functions. WIP-0316 adds source and resolved local-width paths. WIP-0317 adds all three unresolved void-call form queries. WIP-0318 raises canonical native manifest transport to 12,288 bytes. WIP-0319 executes all three resolved shape queries directly. WIP-0320 adds both assignment-call column maps. WIP-0321 executes all four assignment-call identity queries. WIP-0322 retains the nine-member helper-signature owner and executes its parameter-count map. WIP-0323 executes all nine public signature queries and raises the package suite to forty-nine cases. WIP-0324 executes every physical wide-return source packer and decoder, bringing the suite to fifty-eight cases. WIP-0325 executes the physical instruction-form authority and adds a fifty-ninth case. WIP-0326 executes all four physical opcode-family classifiers and raises the suite to sixty-three cases. WIP-0327 fixes single imported helper ownership and fills the sixty-four-case bound with the physical identifier-start classifier. WIP-0328 raises the complete native case and report profile to 128. WIP-0329 executes all three physical resolved local-return queries and raises the compiler suite to sixty-seven cases. WIP-0330 admits one dependency owner with the complete 256-constant compiler bound. WIP-0331 raises the exhausted manifest transport to 16,384 bytes. WIP-0332 executes all three resolved local-equality queries. WIP-0333 executes the matching inequality surface. WIP-0334 executes all four resolved local-assignment queries. WIP-0335 executes all eight resolved copy and signed-operation queries. WIP-0336 executes all four resolved local-loop form decoders. WIP-0337 executes both packed local-loop operand decoders. WIP-0338 executes the complete resolved local-loop classifier and raises the compiler suite to ninety-two cases. WIP-0339 raises the exhausted manifest transport to 20,480 bytes. WIP-0340 executes the terminal resolved local less-than classifier. WIP-0341 executes all seven local-literal comparison queries. WIP-0342 executes all nine resolved assertion queries. WIP-0343 executes both resolved early-comparison classifiers. WIP-0344 executes all eight resolved early-result classifiers and raises the compiler suite to one hundred nineteen cases. WIP-0345 raises the exhausted manifest transport to 24,576 bytes. WIP-0346 executes all six resolved return-call queries. WIP-0347 executes the complete 128-case compiler profile with terminal early-return source and named return-operand evidence. WIP-0348 raises the exhausted complete test and report profile to the one-byte terminal count of 255. WIP-0349 executes all eight unresolved Boolean, signed, and arithmetic return classifiers and raises the compiler suite to 136 cases. WIP-0350 raises the exhausted manifest transport to 28,672 bytes. WIP-0351 executes three conditional classifier and operand owners. WIP-0352 executes the remaining thirteen standalone Boolean-local and literal-comparison conditional queries and raises the compiler suite to 152 cases. WIP-0353 raises the exhausted complete source-plan boundary to 40,960 bytes. WIP-0354 executes all six conditional operation and base-map queries and raises the compiler suite to 158 cases. WIP-0355 raises the exhausted manifest transport to 32,768 bytes. WIP-0356 executes ten local assignment, update, and signed-operation queries. WIP-0357 executes eleven Boolean declaration, literal-comparison, direct-comparison, and return-opcode queries and raises the compiler suite to 179 cases. WIP-0294 binds bounded dependency archives and their manifests to exact lock rows before external test sources are admitted. WIP-0295 projects exact checked archive entry paths and source bytes. WIP-0296 merges one projected entry into a canonical package-qualified source plan. WIP-0297 compiles and executes one external imported module from that evidence. WIP-0298 carries one exact vendored external import through the package command. WIP-0299 validates and compiles both entries of one archive, including an external-to-external edge. WIP-0300 validates complete source sets from two direct package archives. WIP-0301 binds each transported archive's normal dependency list to its lock graph edges. WIP-0302 follows one locked external-to-external edge while preserving direct root visibility. WIP-0303 raises the native test-manifest ceiling to 8,192 bytes while retaining the 32,768-byte source plan. WIP-0318 raises only that exhausted ceiling to 12,288 bytes. WIP-0306 carries up to four complete archive entries. WIP-0307 fills that archive bound. WIP-0308 fills the eight-source compiler plan with seven external modules. WIP-0309 fills that bound through one locked transitive package edge. The complete source graph and broader dependency profile remain.
- [x] `reference/packages.md` and `reference/language-profile.md` describe only the implemented stage-0 runner: selected root tests, bounded scalar cases, fresh VMs, the first in-process lifecycle fixture profile, canonical order, identities, diagnostics, assertion attempts, transition coverage, and the zero-case report. Capability-bearing fixtures, generators, non-root modules, and new adapters remain explicitly assigned to this WIP.

## Alternatives

### Keep JUnit as the permanent runner

Rejected. It keeps reflection, Java process semantics, and Java exceptions in the bootstrap trust chain and cannot define Wheeler inverse, rewind, coherent, replay, or proof assertions.

### Copy JUnit 5 annotations and extension APIs

Rejected. Annotation spelling is the least interesting part of JUnit. Copying its class-loader extension model would import the host boundary while omitting the semantics Wheeler actually needs.

### Treat tests as ordinary entry programs

Useful for tiny fixtures, but insufficient for canonical discovery, isolation, parameterization, lifecycle, report merging, capabilities, and release evidence. The integrated model may lower each case to an ordinary verified function. It still needs descriptors and a runner contract.

### Let every library choose a test framework

Rejected. Multiple frameworks mean multiple discovery and report authorities. Assertion helper libraries may exist, but one runner owns case semantics.

### Make every test reversible

Rejected. Assertions, event recording, target submission, fixture I/O, and report publication are observations or effects. Tests can verify reversible code while keeping assertions, reports, and other observations irreversible.

## Open questions

- Which fixture grammar should follow accepted `cases(...)`, `tags(...)`, and `limits(steps = N, history = M)` metadata (owner: language and tooling maintainers. Decision point: before fixture implementation)?
- Which canonical report encoding is smallest while remaining independently inspectable during bootstrap (owner: runtime and package maintainers. Decision point: before report persistence)?
- Which exact simulator tolerance profiles are portable enough for semantic assertions (owner: quantum and numerical maintainers. Decision point: before quantum assertion acceptance)?
- Which fixture capabilities belong in the first self-host compiler suite (owner: compiler and package maintainers. Decision point: before bootstrap runner promotion)?

## Integration with reversible concurrency

### Program tasks versus test workers

Runner workers execute independent cases outside program semantics. A task-aware case runs one WIP-0039 machine under a declared canonical, replay, or exploration plan.

Attempt identity includes schedule profile and concrete plan when results depend on them. Worker completion cannot select program schedule.

Assertions may inspect task trees, deadlock diagnostics, EventIds, atomic observations, global rewind, WIP-0040 inverse restoration, and witness cleanliness. Runner cancellation remains distinct from source task and external-operation cancellation.

## References
- [WIP-0039](WIP-0039-deterministic-structured-task-machine-and-global-rewind.md)
- [WIP-0040](WIP-0040-explicit-schedule-witnesses-for-reversible-task-scopes.md)

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
- [WIP-0194](WIP-0194-native-test-shard-assignment.md)
- [WIP-0195](WIP-0195-native-test-case-identity.md)
- [WIP-0196](WIP-0196-native-test-summary-reduction.md)
- [WIP-0197](WIP-0197-runtime-test-selection-authority.md)
- [WIP-0198](WIP-0198-runtime-test-summary-authority.md)
- [WIP-0199](WIP-0199-native-one-case-report-identity.md)
- [WIP-0200](WIP-0200-native-empty-report-identity.md)
- [WIP-0201](WIP-0201-bounded-native-multi-case-reports.md)
- [WIP-0202](WIP-0202-runtime-artifact-execution-authority.md)
- [WIP-0203](WIP-0203-native-test-artifact-outcomes.md)
- [WIP-0204](WIP-0204-native-test-execution-identity.md)
- [WIP-0205](WIP-0205-native-test-coverage-identity.md)
- [WIP-0206](WIP-0206-complete-native-artifact-outcomes.md)
- [WIP-0207](WIP-0207-native-test-artifact-metadata.md)
- [WIP-0208](WIP-0208-native-artifact-execution-identity.md)
- [WIP-0209](WIP-0209-native-one-case-test-runner.md)
- [WIP-0210](WIP-0210-native-failing-test-reports.md)
- [WIP-0211](WIP-0211-native-two-case-test-runner.md)
- [WIP-0212](WIP-0212-native-runner-case-identities.md)
- [WIP-0213](WIP-0213-native-runner-shard-selection.md)
- [WIP-0214](WIP-0214-native-runner-summary-publication.md)
- [WIP-0215](WIP-0215-native-test-failure-diagnostics.md)
- [WIP-0216](WIP-0216-native-runner-descriptor-frames.md)
- [WIP-0217](WIP-0217-runtime-test-runner-authority.md)
- [WIP-0218](WIP-0218-bounded-native-descriptor-runner.md)
- [WIP-0219](WIP-0219-shared-runner-manifest-identity.md)
- [WIP-0220](WIP-0220-native-runner-manifest-hashing.md)
- [WIP-0221](WIP-0221-native-test-manifest-selection.md)
- [WIP-0222](WIP-0222-native-target-source-identity.md)
- [WIP-0223](WIP-0223-native-target-source-plan-validation.md)
- [WIP-0224](WIP-0224-native-target-source-utf8.md)
- [WIP-0225](WIP-0225-native-case-discovery-order.md)
- [WIP-0226](WIP-0226-native-root-lock-provenance.md)
- [WIP-0227](WIP-0227-native-single-source-selection.md)
- [WIP-0228](WIP-0228-native-multi-source-selection.md)
- [WIP-0229](WIP-0229-native-runnable-target-root.md)
- [WIP-0230](WIP-0230-native-root-module-binding.md)
- [WIP-0231](WIP-0231-native-source-module-declarations.md)
- [WIP-0232](WIP-0232-native-source-module-uniqueness.md)
- [WIP-0233](WIP-0233-native-local-import-resolution.md)
- [WIP-0234](WIP-0234-native-canonical-import-order.md)
- [WIP-0235](WIP-0235-native-import-cycle-rejection.md)
- [WIP-0236](WIP-0236-native-source-test-execution.md)
- [WIP-0237](WIP-0237-native-compiled-test-reports.md)
- [WIP-0238](WIP-0238-native-two-source-test-compilation.md)
- [WIP-0239](WIP-0239-native-three-source-test-compilation.md)
- [WIP-0240](WIP-0240-native-source-compilation-authority.md)
- [WIP-0241](WIP-0241-native-four-source-test-compilation.md)
- [WIP-0242](WIP-0242-native-five-source-test-compilation.md)
- [WIP-0243](WIP-0243-native-six-source-test-compilation.md)
- [WIP-0244](WIP-0244-native-seven-source-test-compilation.md)
- [WIP-0245](WIP-0245-native-eight-source-test-compilation.md)
- [WIP-0246](WIP-0246-native-entry-case-identity.md)
- [WIP-0247](WIP-0247-native-parameterless-test-discovery.md)
- [WIP-0248](WIP-0248-native-counted-test-discovery.md)
- [WIP-0249](WIP-0249-native-parameter-row-discovery.md)
- [WIP-0250](WIP-0250-single-pass-artifact-verification.md)
- [WIP-0251](WIP-0251-native-artifact-function-binding.md)
- [WIP-0252](WIP-0252-native-artifact-row-binding.md)
- [WIP-0253](WIP-0253-native-parameterless-test-compilation.md)
- [WIP-0254](WIP-0254-native-imported-test-compilation.md)
- [WIP-0255](WIP-0255-native-counted-test-compilation.md)
- [WIP-0256](WIP-0256-native-test-lowering-authority.md)
- [WIP-0257](WIP-0257-native-parameter-row-compilation.md)
- [WIP-0258](WIP-0258-native-bare-test-metadata-profile.md)
- [WIP-0259](WIP-0259-native-test-step-limits.md)
- [WIP-0260](WIP-0260-native-test-tag-selection.md)
- [WIP-0261](WIP-0261-native-test-descriptor-construction.md)
- [WIP-0262](WIP-0262-native-one-source-package-test-gate.md)
- [WIP-0263](WIP-0263-native-package-case-names.md)
- [WIP-0264](WIP-0264-native-fixed-import-package-test-gate.md)
- [WIP-0265](WIP-0265-native-multi-target-package-test-gate.md)
- [WIP-0266](WIP-0266-native-multi-target-tag-gate.md)
- [WIP-0267](WIP-0267-native-package-tag-existence.md)
- [WIP-0268](WIP-0268-native-package-test-report-identity.md)
- [WIP-0269](WIP-0269-native-dependency-lock-structure.md)
- [WIP-0270](WIP-0270-native-direct-dependency-binding.md)
- [WIP-0271](WIP-0271-native-stable-dependency-versions.md)
- [WIP-0272](WIP-0272-native-prerelease-dependency-versions.md)
- [WIP-0273](WIP-0273-native-lock-edge-closure.md)
- [WIP-0274](WIP-0274-native-lock-graph-validation.md)
- [WIP-0275](WIP-0275-native-locked-package-test-gate.md)
- [WIP-0276](WIP-0276-native-package-case-rows.md)
- [WIP-0277](WIP-0277-canonical-native-target-rows.md)
- [WIP-0278](WIP-0278-native-package-row-reduction.md)
- [WIP-0279](WIP-0279-native-compiler-package-suite.md)
- [WIP-0280](WIP-0280-native-compiler-constant-assertion.md)
- [WIP-0281](WIP-0281-native-compiler-arithmetic-coverage.md)
- [WIP-0282](WIP-0282-native-compiler-scalar-arithmetic.md)
- [WIP-0283](WIP-0283-bounded-native-bitwise-coverage.md)
- [WIP-0284](WIP-0284-native-compiler-constant-suite.md)
- [WIP-0285](WIP-0285-native-compiler-callable-suite.md)
- [WIP-0287](WIP-0287-native-call-branch-coverage.md)
- [WIP-0289](WIP-0289-native-test-json.md)
- [WIP-0290](WIP-0290-native-test-terminal.md)
- [WIP-0291](WIP-0291-native-test-junit.md)
- [WIP-0292](WIP-0292-native-compiler-syntax-suite.md)
- [WIP-0293](WIP-0293-native-compiler-call-syntax-suite.md)
- [WIP-0294](WIP-0294-native-locked-archive-provenance.md)
- [WIP-0295](WIP-0295-native-locked-archive-source.md)
- [WIP-0296](WIP-0296-native-external-source-plan.md)
- [WIP-0297](WIP-0297-native-external-import-compilation.md)
- [WIP-0298](WIP-0298-native-package-external-import.md)
- [WIP-0299](WIP-0299-native-two-source-archive-import.md)
- [WIP-0300](WIP-0300-native-two-package-import.md)
- [WIP-0301](WIP-0301-native-archive-dependency-binding.md)
- [WIP-0302](WIP-0302-native-transitive-archive-closure.md)
- [WIP-0303](WIP-0303-native-test-manifest-bound.md)
- [WIP-0304](WIP-0304-native-compiler-type-kind-suite.md)
- [WIP-0305](WIP-0305-native-compiler-call-arity-suite.md)
- [WIP-0306](WIP-0306-native-four-entry-archives.md)
- [WIP-0307](WIP-0307-native-four-source-archive-import.md)
- [WIP-0308](WIP-0308-native-external-source-plan-bound.md)
- [WIP-0309](WIP-0309-native-transitive-source-plan-bound.md)
- [WIP-0310](WIP-0310-native-multi-helper-entry-programs.md)
- [WIP-0311](WIP-0311-native-compiler-call-width-suite.md)
- [WIP-0312](WIP-0312-native-compiler-call-operand-suite.md)
- [WIP-0313](WIP-0313-native-compiler-void-call-operand-suite.md)
- [WIP-0314](WIP-0314-native-255-transition-coverage.md)
- [WIP-0315](WIP-0315-native-compiler-void-call-width-suite.md)
- [WIP-0316](WIP-0316-native-compiler-void-call-source-width-suite.md)
- [WIP-0317](WIP-0317-native-compiler-void-call-source-form-suite.md)
- [WIP-0318](WIP-0318-native-test-manifest-bound.md)
- [WIP-0319](WIP-0319-native-compiler-void-call-kind-suite.md)
- [WIP-0320](WIP-0320-native-compiler-call-column-suite.md)
- [WIP-0321](WIP-0321-native-compiler-call-kind-suite.md)
- [WIP-0322](WIP-0322-native-compiler-helper-parameter-suite.md)
- [WIP-0323](WIP-0323-native-compiler-helper-signature-suite.md)
- [WIP-0324](WIP-0324-native-compiler-wide-return-source-suite.md)
- [WIP-0325](WIP-0325-native-compiler-instruction-form-suite.md)
- [WIP-0326](WIP-0326-native-compiler-opcode-kind-suite.md)
- [WIP-0327](WIP-0327-native-single-imported-helper-ownership.md)
- [WIP-0328](WIP-0328-native-128-case-test-profile.md)
- [WIP-0329](WIP-0329-native-compiler-resolved-local-return-suite.md)
- [WIP-0330](WIP-0330-native-256-constant-owner-profile.md)
- [WIP-0331](WIP-0331-native-16k-test-manifest-bound.md)
- [WIP-0332](WIP-0332-native-compiler-resolved-local-equality-suite.md)
- [WIP-0333](WIP-0333-native-compiler-resolved-local-inequality-suite.md)
- [WIP-0334](WIP-0334-native-compiler-resolved-local-assignment-suite.md)
- [WIP-0335](WIP-0335-native-compiler-resolved-local-operation-suites.md)
- [WIP-0336](WIP-0336-native-compiler-resolved-local-loop-form-suite.md)
- [WIP-0337](WIP-0337-native-compiler-resolved-local-loop-operand-suite.md)
- [WIP-0338](WIP-0338-native-compiler-resolved-local-loop-kind-suite.md)
- [WIP-0339](WIP-0339-native-20k-test-manifest-bound.md)
- [WIP-0340](WIP-0340-native-compiler-resolved-local-less-than-suite.md)
- [WIP-0341](WIP-0341-native-compiler-local-literal-comparison-suite.md)
- [WIP-0342](WIP-0342-native-compiler-resolved-assertion-suite.md)
- [WIP-0343](WIP-0343-native-compiler-resolved-early-comparison-suite.md)
- [WIP-0344](WIP-0344-native-compiler-resolved-early-result-suite.md)
- [WIP-0345](WIP-0345-native-24k-test-manifest-bound.md)
- [WIP-0346](WIP-0346-native-compiler-resolved-return-call-suite.md)
- [WIP-0347](WIP-0347-native-compiler-terminal-return-profile.md)
- [WIP-0348](WIP-0348-native-255-case-test-profile.md)
- [WIP-0349](WIP-0349-native-compiler-named-return-suite.md)
- [WIP-0350](WIP-0350-native-28k-test-manifest-bound.md)
- [WIP-0351](WIP-0351-native-compiler-conditional-value-suite.md)
- [WIP-0352](WIP-0352-native-compiler-conditional-classifier-suite.md)
- [WIP-0353](WIP-0353-native-40k-source-plan-bound.md)
- [WIP-0354](WIP-0354-native-compiler-conditional-mapping-suite.md)
- [WIP-0355](WIP-0355-native-32k-test-manifest-bound.md)
- [WIP-0356](WIP-0356-native-compiler-local-update-suite.md)
- [WIP-0357](WIP-0357-native-compiler-comparison-suite.md)
