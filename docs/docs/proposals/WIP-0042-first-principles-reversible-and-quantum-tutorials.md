# WIP-0042: First-principles reversible and quantum computing tutorials

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler documentation, language, compiler, runtime, quantum, tooling, and example maintainers |
| Created | 2026-08-02 |
| Updated | 2026-08-02 |
| Area | Tutorials, pedagogy, executable examples, reversible computing, quantum computing |
| Depends on | WIP-0001, WIP-0002, WIP-0003, WIP-0004, WIP-0005, WIP-0006, WIP-0009, WIP-0018, WIP-0019 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler will publish one first-principles tutorial series that starts with running a tiny ordinary program and reaches reversible
computing, amplitudes, interference, qubits, entanglement, small quantum algorithms, target execution, and hybrid replay. The
series assumes that a reader has heard the word quantum but knows no quantum mechanics, reversible computing, binary arithmetic,
probability, complex numbers, or linear algebra. It assumes only that the reader can follow instructions to edit a text file and
run a terminal command.

The series uses short experiments rather than broad survey chapters. One tutorial asks one central question, introduces at most
one new conceptual dependency, runs or inspects one bounded experiment, and ends with the question that motivates the next
tutorial. New Wheeler syntax carries an already familiar idea. New physics uses already familiar syntax. The series introduces
mathematical notation only after an experiment creates a need for it.

The tutorial carries one original science-fiction return voyage titled **Instructions for Returning**. Tala, an
adult systems analyst aboard the courier *Vela*, understands ordinary software but lacks precise models for reversible and quantum
work. A human-authored field manual preserves experiments and disputes from earlier engineers while the crew crosses habitats
with different incomplete ideas about memory and evidence. Close third-person prose earns its vocabulary in the same order as
Tala. It describes an observation first, discovers where an ordinary word fails, and only then introduces the accepted technical
term.

This WIP takes curriculum ownership if maintainers accept it. WIP-0006 will continue to own concrete syntax and editor tooling.
WIP-0010 will continue to own application conformance. This WIP will own lesson order, reader prerequisites, tutorial fixtures,
explanatory standards, and the boundary between implemented lessons and planned work. After the first complete foundation through
entanglement track lands, the tutorial index will replace the compact `Teaching path` list in the language reference. The
executable example catalog will remain a catalog rather than a second tutorial sequence.

## Motivation

The current documentation explains Wheeler's design and records its executable surface. It does not yet teach that surface to a
complete quantum beginner.

The introduction moves across reversible state, coherent reuse, QFT, target workflows, proofs, and systems programming in one
survey. The language profile serves as a dense reference. The examples page catalogs large conformance fixtures. The compact
teaching path correctly orders major areas, but one row may still contain several unfamiliar language, mathematical, and physical
ideas.

A reader who does not know quantum computing encounters hidden prerequisites long before `QFT.w`:

- what a program state is.
- what a bit is.
- what a mapping or truth table says.
- how an overwrite loses information.
- what an inverse means.
- why inverse execution differs from debugger rewind.
- what one trial and one outcome mean.
- how repeated trials form a distribution.
- why amplitudes are not probabilities.
- how signs and phases create interference.
- what preparation and measurement do.
- why a qubit state differs from one measured bit.
- how two-system state spaces combine.
- why correlation alone does not define entanglement.

A tutorial that explains `H`, amplitudes, the Born rule, measurement, and interference on one page still assumes quantum
knowledge. A tutorial that explains `rev`, generated inverses, VM history, and commit on one page still assumes
reversible-computing knowledge.

Wheeler needs a slower path because its central contribution crosses both subjects. A reader should understand ordinary
information loss before Wheeler asks them to value `rev`. They should understand finite reversible permutations before Wheeler
lifts one coherently. They should observe interference before Wheeler introduces a complex phase. They should understand a
generated adjoint before QFT uses one.

The repository also needs one executable teaching authority. Hand-copied snippets, unchecked shell transcripts, speculative `.w`
files, and broad examples that happen to look educational will drift. Tutorial code must compile, parse, run, and report its
current limits through the same compiler, bytecode, verifier, runtime, target, package, and documentation paths as other Wheeler
code.

## Use cases

### Reader with no quantum background

A reader starts with one classical state field and one assertion. Over several short lessons, the reader draws a two-state
machine, observes an overwrite, learns why the old input cannot be recovered, and writes a reversible XOR flip. The word qubit
does not carry any unexplained work.

Later, the reader prepares and measures basis states before using `H`. They gather a bounded seeded histogram before the text
defines probability amplitudes. They run `H` twice before the text names interference. Each new term answers a question created by
an experiment they already performed.

### Experienced programmer with no physics background

An experienced programmer may move quickly through Wheeler syntax while still following the same conceptual order. Checkpoint
pages provide compact review exercises. Optional "programmer route" links may group already completed syntax lessons, but they do
not skip information, probability, amplitude, measurement, or multi-system foundations.

### Reader using only a source checkout

A reader builds the existing stage-0 launcher once, copies or downloads one complete lesson source, and uses ordinary `wheeler
compile`, `wheeler run`, `wheeler disassemble`, or `wheeler qasm` commands. The tutorial requires no network, provider
credentials, notebook service, browser execution, or paid target.

Every exact experiment records its expected result. Every sampled experiment records an explicit simulator, seed, shot count, and
acceptance explanation. Repeating the documented command produces the documented semantic result or one explicitly described
bounded sample.

### Lesson whose desired feature does not exist

A planned lesson needs structured ancilla cleanup. The current compiler cannot execute that source. The tutorial navigation omits
the lesson and the repository contains no aspirational `.w` file. The curriculum map records the dependency on WIP-0034. Current
pages may explain the boundary in prose, but they do not present future syntax as usable.

### Reader comparing evidence

A reader runs a circuit followed by its generated adjoint and observes basis-state restoration. The lesson calls this an
executable check. A later lesson inspects a finite `GENERATED_ADJOINT` certificate and calls it structural evidence. Neither
lesson calls a sampled run a theorem or claims that the current proof kernel proves the full mathematical correctness of QFT.

## Goals

- Teach Wheeler, reversible computing, and quantum computing from an explicit zero-knowledge reader baseline.
- Use short, cumulative experiments whose code and output remain small enough to inspect by hand.
- Introduce one central conceptual dependency per tutorial.
- Separate syntax acquisition, computational reasoning, physical interpretation, and mathematical formalization.
- Derive later questions from earlier observations instead of presenting a glossary before a need exists.
- Keep inverse, rewind, uncompute, adjoint, measurement, replay, retry, cancellation, compensation, and proof distinct from their first appearances.
- Give every executable lesson compiler, Tree-sitter, bytecode, verifier, runtime or target, and documentation validation.
- Give every sampled lesson explicit seed, shot, target, ordering, and evidence contracts.
- Keep every conceptual analogy paired with a precise statement of where it stops.
- Provide static, accessible diagrams that remain useful in the generated site, source Markdown, and a printed or offline reading order.
- Publish complete parts rather than navigation full of placeholders.
- Replace the compact language-reference teaching path after the foundation through entanglement track becomes complete.
- Keep the executable examples page as a capability catalog and WIP-0010 as the application portfolio.
- Let future language and target work add lessons without changing the foundations already taught.

## Non-goals

- Teach all of computer science, classical programming, physics, or linear algebra before the first Wheeler program.
- Assume that a reader has used Java because Wheeler syntax looks familiar.
- Present Wheeler as Java with quantum keywords.
- Turn the language reference, proposal index, or executable example catalog into a second copy of the tutorial.
- Require one lesson to contain every caveat about a subject. Later lessons may refine an earlier bounded model without contradicting it.
- Use "both zero and one," "quantum parallelism tries every answer," or similar phrases as substitutes for amplitude semantics.
- Claim quantum speedup from fixture-sized examples.
- Claim that reversible logic consumes no energy or that Landauer's bound predicts total device power.
- Claim that measurement reveals a basis value that always existed before measurement.
- Treat simulator state-vector diagnostics as portable hardware observations.
- Treat repeated experimental success as proof.
- Add speculative source syntax so the curriculum can mention a desired topic early.
- Add a browser runtime, JavaScript playground, theme system, or network dependency to the trusted documentation build.
- Freeze every final lesson title before reader testing. Stable lesson identities, prerequisites, and claims matter more than titles.

## Terms and semantic model

### Reader baseline

The **reader baseline** assumes that a reader can:

- read plain English.
- create or edit a text file by following instructions.
- copy a terminal command and inspect its output.
- perform ordinary whole-number arithmetic with guidance.

The baseline does not assume programming vocabulary, binary notation, truth tables, probability, waves, complex numbers, vectors,
matrices, physics, reversible computing, or quantum computing.

The opening pages may offer a faster route for readers who already know variables, methods, bits, and probability. The canonical
dependency order remains the same. A fast route changes how many explanations a reader chooses to review. It does not change what
a later lesson may assume.

### Tutorial part

A **tutorial part** is one complete sequence around a broad dependency boundary, such as ordinary state, information loss,
probability, one qubit, or two qubits. Navigation publishes a part only when every required lesson in that part passes its
acceptance gate.

### Tutorial chapter and step

A **tutorial chapter** is one continuous story scene and the navigation publication unit. It may contain several ordered tutorial
steps when the scene gives those steps one causal arc.

A **tutorial step** is the smallest conceptual unit. It has one stable ID, one central question, a closed prerequisite set, one new
conceptual dependency, one bounded activity, and one bridge into the next step. Chapter metadata lists every contained step in
order and binds each step to its experiment, terminology, and evidence.

A step may add a few tokens that form one source construct. For example, `reverse flip();` adds a keyword and one call form while
teaching one idea, inverse invocation. A step must not also introduce VM rewind, commit, and quantum adjoints. Grouping steps into
one chapter changes narrative pacing, not the dependency graph.

### Experiment

An **experiment** is one bounded action whose result the reader can inspect. It may be:

- compilation and execution of one complete Wheeler program.
- expected rejection of one complete malformed or semantically invalid Wheeler program.
- deterministic disassembly or OpenQASM emission.
- bounded seeded simulation with an explicit shot count.
- ideal state-vector inspection under a simulator-only diagnostic profile.
- hand reduction of one truth table, state map, histogram, amplitude table, or circuit.

An experiment does not need to mutate Wheeler state. A conceptual step may reuse the previous program and inspect one new
representation of its result.

### Tiny program

A **tiny program** is a complete Wheeler source that a learner can inspect without scrolling through unrelated declarations. The
default target is at most 30 nonblank, noncomment source lines. A lesson that exceeds the target must split its idea or explain
why syntax required for the one concept cannot fit.

Mandatory repository API documentation does not consume this teaching budget when the lesson source comes from an independently
checked documentation fence. A source-backed lesson that displays an authored `.w` file must explain or hide no semantic line.

### Conceptual interlude

A **conceptual interlude** introduces no Wheeler syntax. It uses an already familiar program result, diagram, table, or bounded
physical model. Probability and interference need several interludes before the first Hadamard experiment receives a mathematical
explanation.

An interlude never uses invented source as decoration. If a page shows a complete Wheeler program, the documentation gate compiles
it or checks its declared rejection.

### Bridge question

A **bridge question** names the unresolved issue that the next step answers. The current step may not require the next answer for
its own explanation.

Examples include:

- "If both inputs become zero, where could an inverse find the old bit?"
- "Probabilities only add. What kind of quantity could cancel?"
- "The phase changed, but measurement did not. How could we make phase observable?"
- "CNOT correlated the outcomes. Does that mean it copied the first qubit?"

### Current boundary

A **current boundary** states the last behavior that the repository implements. It names the owning reference page or WIP for
unfinished work. It does not show future source as a runnable listing.

### Evidence label

Every quantum or proof result carries one visible **evidence label**:

- exact classical execution.
- ideal state-vector simulation under the named numerical profile.
- seeded sampled simulation.
- recorded hardware evidence.
- finite structural certificate.
- formal theorem certificate.
- planned or conceptual behavior.

The label follows the result in the page and generated index. Presentation cannot promote one label to another.

## Ownership and boundaries

This WIP owns:

- the reader baseline.
- tutorial-step identities and prerequisite order.
- the chapter contract and pacing rules.
- the first-principles curriculum map.
- tutorial-specific source and result metadata.
- the lesson publication and replacement gates.
- reader-facing distinctions among kinds of evidence.

WIP-0005 owns source-language meaning. A tutorial cannot simplify a construct into a new semantic rule.

WIP-0006 owns concrete syntax, compiler locations, Tree-sitter nodes, and editor grammar. This WIP replaces only its compact
curriculum ownership after acceptance. It does not replace its parser or tooling decisions.

WIP-0001 owns reversible VM state, inverse calls, step history, rewind, and commit horizons. Tutorial traces consume those
meanings without redefining them.

WIP-0002 owns coherent and quantum semantics. WIP-0003 owns simulator and target contracts. WIP-0004 owns hybrid jobs, replay,
retry, and transaction phases.

WIP-0010 owns the executable application portfolio. Its examples may become destinations or capstones. This WIP owns the smaller
steps that prepare a reader for them.

WIP-0018 owns executable test cases and semantic reports. WIP-0019 owns documentation nodes, fenced-example validation, static
rendering, navigation, downloadable assets, and publication.

The language reference owns concise current contracts. It links to the tutorial after the replacement gate. It does not retain a
competing ordered curriculum.

The executable examples page owns current fixture discovery, expected results, and scope boundaries. It may state which tutorial
arrives at an example. It does not explain every prerequisite again.

Hosts own terminal, files, process launch, and optional hardware credentials. The core series uses no ambient network,
home-directory state, live provider, or credential.

## Design

### Narrative frame

**Instructions for Returning** opens in the middle of the voyage. The *Vela* has reached home coordinates, but its return check
reports unrestored workspace and incomplete result lineage. Mara reads position, Osei reads state restoration, Sana reads evidence,
and Tala notices that *return* has accumulated incompatible meanings across old software layers.

The narrative then moves to the construction berth, where Tala joins the crew as an experienced classical systems analyst. An
unofficial field manual contains small checked programs and annotations from earlier engineers. It does not speak, reveal pages,
judge answers, or supply semantic authority. Tala and the crew run its experiments because the programs expose disagreements that
the mission will later make operational.

The voyage supplies the technical pressure. An archive demonstrates the power and limit of retained history. Uncertain signals
create the need for trials and distributions. Interfering contributions create the need for amplitudes and phase. Paired
instruments tempt the crew to infer entanglement from correlation. An ideal simulator offers complete inspection without becoming
a physical target. A contract machine answers only the question its oracle encodes. The return passage introduces measurement,
noise, replay, retry, and evidence lineage.

Tala remains the viewpoint character. She begins with real competence, revises that competence when new evidence demands narrower
language, and eventually becomes capable of auditing the failed return. Mara, Osei, and Sana have different responsibilities,
private histories, and reasonable incomplete models. Action and disagreement introduce them. No paragraph pauses to give a crew
member a tutorial role or biography.

The final return does not erase the journey. Tala must preserve the useful result, restore only the state covered by an accepted
contract, account for records and observations that remain, and state what the evidence proves. Her verified amendments become the
next open edition of the field manual.

The story assumes the complete accepted Wheeler language, compiler, runtime, target, workflow, correction, and proof system. It
never interrupts a scene with repository implementation status or presents a feature as future work. Separate publication gates
still require every displayed program, result, target event, and certificate to execute before the chapter becomes authoritative.

### Earned lexicon

The series begins with broad operational words that hide distinctions:

| Early word | Terms that later experiments separate |
| --- | --- |
| return | inverse, rewind, uncompute, adjoint, replay, retry |
| result | state, outcome, observation, sample, distribution, evidence |
| same | equal value, restored state, repeated preparation, replayed record |
| linked | dependent, correlated, product state, entangled |
| random | unknown, sampled, probabilistic, seeded, noisy |
| proof | exact execution, sampled evidence, structural certificate, theorem |

A required term enters the story through five beats:

1. An event produces a concrete observation without requiring the term.
2. Existing vocabulary creates an ambiguity, failed prediction, or conflict between characters.
3. A program, table, or record exposes the exact distinction that the old word cannot express.
4. Narration or dialogue introduces the accepted technical term and its nearest nonexample.
5. Later action requires the crew to use the distinction correctly.

The narrative vocabulary changes permanently after that point. It does not retain an invented story synonym that competes with an
accepted quantum or Wheeler term, and it never teaches a false statement merely to repair it later. Stable metadata records each
step's required and introduced glossary identities. Mechanical validation checks those declared identities and links, while
editorial and reader review catch undeclared assumptions in natural language.

### Pacing law

Each tutorial step retains one central conceptual dependency even when several steps share a chapter. Reviewers apply these checks:

1. Earlier chapter steps establish every prerequisite used by the current beat.
2. New syntax expresses one new idea or routine mechanics already established in the story.
3. No mathematical symbol appears before an experiment or table gives it work.
4. Each bounded source listing or activity remains small enough to inspect.
5. A character commits to a prediction or claim before the result appears.
6. The story explains the observed result before it generalizes.
7. A nearby nonclaim blocks the most tempting misconception without stopping the scene.
8. The consequence of the result creates the next conceptual question.

A beat that fails these checks splits into more steps. A scene that cannot connect its steps causally splits into more chapters.

### Chapter contract

A tutorial chapter reads as continuous close third-person fiction. It uses no visible lesson template and never addresses the
reader, announces the curriculum, asks for homework, or refers to a page as a tutorial. Code, commands, tables, diagrams, and
checked output appear as objects the characters create, run, inspect, and preserve.

Every executable step still contains one complete primary source listing or an exact source-backed listing, one bounded command,
one checked result, and enough surrounding action to establish the prediction, explanation, nearest nonclaim, and consequence.
Conceptual steps produce an inspectable table, diagram, count, or deduction inside the scene.

Chapter transitions follow causes in the story. A failed claim, unresolved result, operational constraint, or changed relationship
opens the next question. Links may appear in diegetic records or chapter references, but navigation does not require a character to
announce the next lesson.

The public story landing links only to `T00`. It does not list or name later chapters. Each nonfinal chapter reveals its single successor
after the closing consequence creates that next question. The sidebar exposes only the story landing, while direct chapter routes,
search records, and sitemap entries remain available for stable references and returning readers.

### Narrative voice

Tutorial prose follows the repository documentation style and adds these rules:

- Use close third person through Tala except where a bounded record supplies another voice.
- Vary sentence length and clause structure according to thought and pressure rather than alternating simple declarations.
- Let long sentences accumulate system history or ambiguity, then use short sentences for decisions and failures.
- Begin paragraphs with time, condition, image, consequence, or action instead of repeatedly naming the speaker first.
- Introduce characters through choices, attention, and conflict rather than role descriptions.
- Keep dialogue sparse. No character exists to ask obvious questions or deliver uninterrupted exposition.
- Prefer concrete state transitions to metaphors and define a term only after the scene creates its need.
- State target, simulator, and proof limits beside the result they qualify.
- Use dry humor as pressure relief, not as the mandatory last sentence of each paragraph.
- Avoid claims about consciousness, many worlds, quantum mysticism, or philosophical interpretation unless a later nonsemantic appendix compares interpretations carefully.

Each paragraph must arise from the image, action, claim, or unresolved detail before it. Paragraph endings create pressure or space
for what follows instead of supplying a repeated aphorism. Every recurring report, disagreement, image, or question receives a
payoff at a named later step.

### Worldbuilding discipline

The setting develops through material constraints, institutions, and choices rather than detachable encyclopedia paragraphs.
Every chapter advances at least one element of the inhabited world while preserving the pace of its technical experiment:

- Catenary establishes home as a changing network of habitats, yards, civic rules, traffic deadlines, and physical arrival rather
  than a static destination.
- The cold reach makes delay, bandwidth, heat, water, maintenance, and local authority operational facts rather than generic space
  decoration.
- The Archive turns retained history into inheritance, economy, public ritual, and political disagreement without treating memory
  as inverse execution.
- Sable and the far instrument show how isolation, repair, target calibration, environmental limits, and light-delay shape a small
  technical community.
- The particle front and beacon deadline connect the calibration result to ordinary civic infrastructure without claiming mystical
  quantum prediction or fixture-sized speedup.

Recurring objects and practices carry setting across chapter boundaries. The field manual accumulates accountable amendments. The
Archive bird changes orientation with local gravity. Pre-commit manifests move from institutional argument to mission policy and
finally resolve the broken return lineage. Food, tools, pressure boundaries, risk budgets, and maintenance shifts reveal how people
live around the machines.

Worldbuilding cannot grant semantic authority. A culture may hold an incomplete belief about records, a pilot may use inherited
language, and a station may preserve a misleading motto, but Wheeler behavior still follows the accepted language, runtime,
target, and proof contracts. Fictional history creates pressure to discover a distinction. It never changes the distinction.

### Secondary plot discipline

A secondary storyline remains only when it changes a decision, relationship, artifact, or payoff in the return voyage. It cannot
exist solely to supply genre incident, and it cannot carry the only statement of a technical rule.

The accepted relational threads reinforce the main action:

- Tala's earlier conflict with Neris Venn turns the final acceptance deadline into a renewed choice between a convenient current
  value and the larger system that value fails to account for.
- Sana and Edrin's unresolved Archive argument produces the fixed memorial overlay, the pre-commit manifest practice, and the
  lineage repair that closes the mission.
- Osei and Iona's mature love story distinguishes a true shared past from a shared life that neither person can restore. Their next
  contact must be new work freely chosen from the present, not an inverse of their separation.

These threads enter through action, maintenance, records, and bounded dialogue. No romance turns consent into a technical analogy.
No death, hidden culprit, or investigation manufactures urgency that the voyage and its evidence contracts already provide. A
subplot that delays its chapter's experiment without changing the final return is removed.

### Analogy discipline

Every analogy has three parts:

1. the feature it models.
2. the exact rule the lesson uses.
3. the point where the analogy stops.

A coin may illustrate repeated binary outcomes. It does not model amplitude cancellation. A water wave may illustrate
reinforcement and cancellation. It does not model an affine quantum resource. Two correlated envelopes may illustrate classical
correlation. They do not establish entanglement.

The tutorial introduces precise state and operation tables before an analogy begins to hide more than it reveals.

### Mathematical progression

The series introduces mathematics in this order:

1. named values and state transitions.
2. finite tables and arrows.
3. functions as input-output mappings.
4. one-to-one finite permutations.
5. counts, frequencies, and probabilities.
6. signed real contributions.
7. amplitude magnitude and normalization.
8. basis notation such as `|0>` and `|1>`.
9. vectors as amplitude tables.
10. simple real matrices as operation tables.
11. relative phase.
12. complex numbers as planar arrows.
13. tensor products as the rule for combining independent systems.
14. nonfactorable joint states.
15. unitary operations and adjoints.

The main path never requires a mathematical operation before a worked example. Optional math sidebars may formalize the same idea
more deeply, but later required steps cannot depend on an optional sidebar without promoting it into the main path.

### Source and documentation authority

A self-contained executable step uses one complete primary `wheeler` fence in its chapter. Chapter metadata identifies the step
and fence as one of:

- exact execution.
- expected compiler rejection.
- ideal state-vector simulation under a named numerical profile.
- seeded sampled simulation.
- source display only for a conceptual trace.

The documentation generator treats the primary fence as authored Wheeler source. It extracts the exact bytes, runs the compiler
and Tree-sitter grammar, verifies canonical bytecode when compilation should succeed, executes the declared mode, and checks the
bounded expectation. The generated site publishes the exact source as a downloadable `.w` asset.

This model gives the lesson one source authority. It does not require a copied file under `wheeler-examples`. A reader may save
the displayed bytes and run the same commands.

A source-backed capstone may instead identify one checked-in `.w` file and package target. The generator reads that exact source
through the package graph. A copied complete listing must match the named source bytes or a specified deterministic display
projection. The first profile should prefer a link plus generated complete listing over manually copied fragments.

Invalid teaching source lives only in an expected-rejection fence or compiler test input. It never enters an ordinary package
source set where every `.w` file must compile.

Each tutorial page receives bounded scalar front-matter metadata under a new documentation profile. The profile includes at least:

```text
tutorial_id
tutorial_part
tutorial_order
tutorial_kind
tutorial_source
tutorial_expectation
tutorial_evidence
```

WIP-0019 owns the exact bundle encoding. Unknown required tutorial kinds fail before site publication.

### Command contract

The main path uses ordinary Wheeler commands. A source-checkout setup page may define one short local launcher for the rest of the
session, but it may not hide a second compiler or runtime.

The baseline command set is:

```text
wheeler compile
wheeler run
wheeler disassemble
wheeler qasm
wheeler test
```

Several lessons need better observation than the current CLI exposes:

- bounded fixed-seed shot sampling with a histogram.
- bounded ideal state-vector amplitude inspection before measurement.
- a readable circuit or workflow view.
- a bounded transition view that distinguishes forward, language inverse, rewind-forward, and rewind-inverse observations.
- a bounded hybrid-event view that distinguishes submission, result application, replay, and retry.

This WIP specifies teaching requirements for those views, not a second execution model. The owning runtime, target, coverage, and
documentation WIPs must accept the final command contracts. A dependent lesson does not publish until the view exists and its
output passes conformance tests.

Shot sampling always names a positive bounded shot count and explicit seed. Each shot prepares a fresh state and executes a
complete submission. Repeating one measured state is not a substitute.

Amplitude inspection is an ideal-simulator diagnostic. It rejects unsupported dynamic workflows and artifacts outside its declared
qubit and output bounds. It never appears as a portable hardware result or a source-visible coherent read.

Transition and event views observe immutable records after successful semantic transitions. They cannot mutate program state, add
bytecode counters, alter scheduling, or erase attempted execution.

### Static visual language

The tutorial uses one fixed visual vocabulary:

- boxes for classical state locations.
- arrows for finite mappings.
- rows for truth tables and amplitude tables.
- left-to-right wires for circuits.
- filled measurement markers for classical observations.
- separate styles for inverse calls, VM rewind, adjoints, and replay.

Every diagram includes text labels and a plain-text explanation. Meaning cannot depend on color alone. Source Markdown retains a
useful table or ASCII form when the site renders a derived static SVG.

Generated diagrams bind their source artifact or table identity. A decorative circuit image cannot become circuit authority.

### Curriculum map

The complete planned `T00` through `T93` step map lives in the
[future curriculum map](../future/tutorial-curriculum-map.md). That appendix keeps the ninety-four
step contracts readable without turning this proposal into a doorstop. This WIP owns the map and
its stability rules. The appendix merely gives the long table somewhere to put its elbows.

The map groups the steps into foundations, amplitudes, entanglement and coherent reuse,
algorithms, then targets and evidence. The checked-in thirteen-chapter **Instructions for
Returning** revision covers the full sequence as developmental prose. Publication still follows
the release gates below. A complete draft is not executable evidence, however good the weather on
*Vela* looks.

### Curriculum release units

The documentation publishes the map through complete release units:

1. **Foundations** contains `T01` through `T23`.
2. **Amplitudes** contains `T24` through `T50`.
3. **Entanglement and coherent reuse** contains `T51` through `T68`.
4. **Algorithms** contains `T69` through `T82`.
5. **Targets and evidence** contains `T83` through `T93`.

`T00` publishes with the first unit and links forward only to published units.

A release unit has no placeholder pages. This proposal may name later release units as a roadmap. The public story landing does not
list them or expose their chapter titles.

### Replacement of the current teaching path

The current `Wheeler source language profile` contains a compact `Teaching path`. It remains useful until this WIP supplies a
complete beginner path.

The replacement gate requires:

- release units 1 through 3 are published.
- every step from `T00` through `T68` passes the documentation and execution contracts.
- setup works from a clean source checkout.
- fixed-seed sampling and bounded ideal amplitude inspection support the required lessons.
- navigation, previous and next links, checkpoints, downloadable source, and evidence labels are complete.
- at least one editorial review follows the zero-knowledge reader baseline from `T00` through `T68` without relying on draft pages.

At that gate, the implementation patch:

1. replaces the compact `Teaching path` list with a short link to the tutorial index and a link to the executable example catalog.
2. updates WIP-0006 to identify this WIP as curriculum owner without changing WIP-0006 syntax decisions.
3. updates WIP-0010 to identify its teaching applications as capstone fixtures rather than the ordered beginner path.
4. keeps no second lesson-order list in the reference or examples page.

Later release units extend the sequential chapter chain in place. They do not turn the story landing into a chapter list or restore
the old reference list.

### Reader testing

Mechanical tests cannot establish good pacing. Each release unit receives structured reader review from people who did not design
the relevant language or quantum feature. Review notes record:

- the first unexplained term each reader reports.
- predictions that fail because the page omitted a prerequisite.
- command or setup friction.
- diagrams that require oral explanation.
- phrases that create a false physical model.
- steps that introduce more than one central idea.
- bridge questions that do not follow from the experiment.
- fictional passages that delay the experiment, make a character permanently foolish, or imply false quantum behavior.
- technical words that appear before their defining observation, contrast, and declared prerequisite.
- term introductions that rename an observation without improving the reader's prediction or explanation.
- opening reports, character disagreements, and voyage questions that never receive an earned payoff.

The author resolves or explicitly defers every finding before publication. Reader review never replaces semantic tests. It checks
pedagogy, not compiler correctness.

### Current and future feature gates

The curriculum tracks implementation state per step:

| Area | Current base | Additional gate before publication |
| --- | --- | --- |
| Ordinary Wheeler syntax | Classes, state, methods, assertions, bounded control | Beginner setup and fenced-source extraction |
| Reversible foundations | Generated inverses, reverse calls and blocks, commit, VM rewind semantics | Bounded readable transition presentation for the rewind comparison |
| Probability | Deterministic test and target seeds exist internally | Reader-facing bounded shot command and histogram |
| One-qubit gates | `X`, `H`, `Z`, `Phase`, preparation, and measurement exist | Bounded ideal amplitude diagnostic and lesson fixtures |
| Two-qubit gates | CNOT, CZ, controlled phase, swap, and generated adjoints exist | Bell sampling and static diagrams |
| Coherent reuse | Exact XOR lifting exists | Superposition diagnostic and focused rejection lessons |
| Static algorithms | Baseline gates can express fixed Deutsch, Grover, and QFT circuits | End-to-end tiny fixtures and checked explanations |
| Hybrid workflow | Jobs, events, replay, retry, and commit exist in bounded slices | Reader-facing bounded event inspection |
| Dynamic correction | Static kernel and capability vocabulary exist | Dynamic measurement, reset, and target-resident control remain unfinished |
| General proofs | Four finite structural rules exist | General quantum propositions and resource proofs remain unfinished |

A page may mention a future gate only as a current boundary. It cannot inherit executable status from a proposal checklist.

### Accessibility and offline use

The generated series supports keyboard navigation, heading structure, visible focus, textual equations, alt text, and
high-contrast diagrams. Tables have row and column headers. Circuit meaning does not depend on wire color.

Every command and source asset works offline after the source checkout and toolchain setup. The site contains no remote fonts,
content-supplied scripts, analytics, video requirement, or provider embed. One fixed local helper copies a code block after an
explicit reader action. A printable reading order retains code, output, captions, evidence labels, and bridge questions.

## Reversibility and history

Tutorial generation and rendering are bounded deterministic transformations until output publication. They have no language
inverse. Publication follows WIP-0019 atomic staging and makes no durability claim beyond its accepted host boundary.

Lesson experiments preserve Wheeler's existing distinctions:

- A language inverse executes new inverse instructions.
- VM rewind consumes retained step records.
- Uncomputation applies coherent inverse work to clean temporary state.
- An adjoint reverses a unitary operation.
- Replay consumes a recorded observation without target execution.
- Retry creates a fresh target lineage.

The documentation runner records experiment execution outside program state. Rewinding a VM does not delete the lesson result or
documentation event. Replaying a hybrid result does not rerun the target. Regenerating a sampled lesson with another seed creates
new sample evidence and must update the page expectation identity.

Expected-rejection lessons make no partial output authoritative. A failed lesson build publishes no tutorial bundle or site.

## Concurrency and determinism

Tutorial steps have one canonical order from stable IDs and explicit prerequisites. Filesystem order and worker completion cannot
change navigation.

Documentation generation may compile and run independent lessons concurrently. Final results sort by tutorial ID, experiment
identity, and diagnostic location. Serial and parallel generation must produce identical semantic bundle bytes for exact lessons.

Seeded simulation names its seed and shot count. Hardware results never enter the core release gate. Operational duration, worker
name, CPU count, and job completion order do not enter tutorial result identity.

A hybrid lesson follows WIP-0004 event order. A target job may complete concurrently, but submission identity and continuation
order select its result. The prose does not explain arrival order as semantic program order.

## Quantum and proof implications

The series treats quantum state as a typed physical and mathematical model, not a metaphor for ordinary uncertainty.

The required explanation rules include:

- A qubit state assigns amplitudes to basis outcomes. It is not merely a hidden classical bit.
- Measurement produces one classical observation under the declared basis and result model.
- Repeating a measurement experiment requires fresh preparation unless a target contract says otherwise.
- CNOT can copy known computational-basis information into a clean target. It does not clone an arbitrary state.
- Correlated measurement counts alone do not prove entanglement. The lesson also identifies the preparation and nonfactorable ideal state.
- A generated adjoint is another physical computation when sent to a target. It is not VM rewind.
- State-vector amplitudes are simulator diagnostics. Hardware does not return them as ordinary measurement data.
- A sampled result is evidence about one declared run. It is not a universal claim.
- A finite structural certificate proves only its named rule over its exact artifact subjects.
- Current `QFTProof.w` remains an executable inverse law until a trusted theorem certificate proves a stronger proposition.

The tutorial proof labels consume WIP-0011 rules. They do not enlarge the trusted kernel. A future proof lesson enters the current
path only after its proposition, assumptions, certificate, and kernel profile execute end to end.

## Bytecode, persistence, and compatibility

This WIP adds no Wheeler source syntax, opcode, bytecode section, or runtime persistence format.

Each successful executable lesson still lowers to canonical `.wbc` and completes a byte-identical decode and re-encode check. A
tutorial expectation binds source, compiler, artifact, execution mode, target profile, seed and shots when present, output, and
evidence label through WIP-0018 and WIP-0019 identities.

Tutorial metadata changes the documentation bundle profile, not `.wbc` semantics. Older documentation readers reject unknown
required tutorial node or experiment kinds. Ordinary Wheeler runtimes ignore documentation bundles.

Lesson IDs remain stable after Review. A title or prose correction may keep the ID. A semantic experiment change updates source
and result identities. A lesson split adds a stable suffix or new ID without silently retargeting incoming links.

Downloaded `.w` assets are derived from exact checked tutorial source fences. They are convenience files, not another package or
artifact authority.

## Safety, limits, and failures

The documentation gate bounds:

- tutorial parts and steps.
- prerequisite edges and depth.
- source bytes, tokens, and diagnostics.
- compilation and execution steps.
- history records and trace rows.
- qreg size and displayed basis rows.
- shots, outcomes, histogram rows, and sample bytes.
- circuit operations and diagram nodes.
- output bytes and line width.
- links, assets, equations, and generated pages.
- total documentation work.

A tutorial prerequisite graph must be acyclic and rooted at `T00` or the first setup step. Every required prior term resolves to
an earlier published step. Duplicate IDs, missing steps, order disagreement, or a link into an unpublished release unit fails
generation.

Exact experiments fail on output drift. Sampled experiments fail on malformed results, wrong target or seed identity, wrong shot
count, impossible outcomes, or a declared statistical acceptance failure. They never retry silently with another seed.

Amplitude diagnostics reject nonfinite values, unsupported workflows, excess qubits, excess output, and unknown operations before
publication. Formatting may round for presentation only when the page retains the exact diagnostic identity and states its
rounding rule.

The site escapes tutorial source and output as inert text. A code block cannot add raw HTML, scripts, provider credentials, host
paths, environment contents, or remote assets.

A conceptual error found after publication receives a normal correction with a clear note when it changes a physical or
mathematical claim. The project does not preserve a false explanation for page-link compatibility.

## Migration and deletion

1. Accept the reader baseline, pacing law, chapter contract, evidence labels, and curriculum ownership.
2. Add tutorial chapter and step metadata, prerequisite graph validation, and stable navigation to the WIP-0019 documentation model.
3. Add extraction, Tree-sitter parsing, compilation, canonical bytecode checks, execution, expected rejection, and downloadable source for primary Wheeler fences.
4. Establish one short source-checkout setup path and verify it on a clean machine profile.
5. Implement release unit 1, `T00` through `T23`, with exact classical and reversible fixtures.
6. Add the bounded shot and ideal-amplitude observation contracts under WIP-0003 and the stage-0 tools.
7. Implement release unit 2, `T24` through `T50`, with probability, interference, and one-qubit fixtures.
8. Add static circuit diagrams and complete Bell-state sampling support.
9. Implement release unit 3, `T51` through `T68`, with two-qubit and coherent-reuse fixtures.
10. Run the replacement gate and replace the language profile's compact `Teaching path` with the tutorial and example links.
11. Update WIP-0006 and WIP-0010 ownership text. Delete duplicate ordered teaching lists.
12. Implement release unit 4, `T69` through `T82`, only from accepted static source and target behavior.
13. Add bounded hybrid-event inspection and implement release unit 5, `T83` through `T93`, through the current dynamic boundary.
14. Port tutorial generation and experiment reduction to Wheeler under WIP-0019. Require byte-identical bundle output before deleting the Java stage-0 path.
15. Delete temporary tutorial scripts, copied source mirrors, unchecked transcripts, and any navigation assembled outside the documentation graph.

## Progress

- [ ] Reader baseline, narrative frame, earned lexicon, and pacing law receive review.
- [x] Thirteen continuous-story chapters cover every step from `T00` through `T93` in a complete developmental prose revision with sustained setting, character conflict, mission stakes, and causal payoff.
- [x] The documentation gate validates unique stable tutorial identities, contiguous page order, complete required metadata, and exact ordered coverage of `T00` through `T93`. The current linear route makes each prior page the prerequisite prefix.
- [x] Thirteen routed tutorial nodes carry explicit `tutorial_id`, covered-step range, part, order, kind, source class, expected outcome, and evidence class metadata. `tutorials/index.mdx` is the stable entrance and the series covers `T00` through `T93` without placeholder nodes.
- [ ] Primary fenced Wheeler source compiles and runs through the documentation gate.
- [ ] Expected-rejection fences check stable diagnostics.
- [ ] Downloadable `.w` assets reproduce exact fenced source.
- [ ] Release unit 1 is complete.
- [x] **The Long Count** records the target, 32-shot budget, seed `104729`, outcome width, exact observed bars, and the boundary between a finite frequency and the declared probability model.
- [x] **One Qubit**, **Two Systems**, **The Search**, and **The Far Instrument** use bounded exact amplitude tables. They label state access as an ideal-simulator diagnostic and do not present it as hardware observation.
- [ ] Release unit 2 is complete.
- [ ] Static circuit diagrams pass accessibility and identity checks.
- [ ] Release unit 3 is complete.
- [x] The language reference points to the first-principles tutorial as the sole ordered curriculum. The examples page remains a conformance inventory rather than a parallel teaching list.
- [x] WIP-0006 assigns the teaching sequence to documentation and examples, while WIP-0010 defines the teaching-track fixture contract and links back to WIP-0006. This WIP owns the first-principles curriculum nodes.
- [ ] Release unit 4 is complete.
- [ ] Bounded hybrid event presentation is available.
- [ ] Release unit 5 is complete through the implemented dynamic boundary.
- [ ] Reader-review findings are resolved for every release unit.
- [ ] A Wheeler-written generator reproduces the tutorial bundle.
- [ ] Duplicate curriculum and unchecked example paths are deleted.

## Testing and acceptance

- [ ] A clean checkout follows the documented setup and runs the first lesson without ambient dependencies.
- [x] The parser-owned tutorial graph rejects duplicate IDs, duplicate or noncontiguous orders, malformed steps, gaps, and order disagreement. Exact `T00` through `T93` coverage forms one bounded acyclic linear route.
- [x] `tutorials/index.mdx` exposes one entrance, `T00` in **Home**. Each chapter ends with exactly one link to the next numbered chapter through **Weather**, and every Markdown node remains directly routable by its stable file path.
- [ ] Every declared required term resolves to an earlier published introduction in the stable glossary graph.
- [ ] Every introduced term follows an observation, states its nearest contrast, and supports a later prediction or explanation.
- [ ] Fictional scenes remain removable without removing the only technical definition or evidence boundary.
- [ ] Every chapter advances setting through a material constraint, institution, recurring object, or consequential character choice without making fictional worldbuilding semantic authority.
- [ ] Every secondary plot changes a main-story decision, relationship, artifact, or payoff and contains no scene retained only for genre decoration.
- [x] **Two Systems** returns to the `T00` Bell artifact, distinguishes correlation from entanglement at `T57`, and executes unmeasured Bell restoration rather than VM rewind at `T62`. **Weather** resolves the failed return report and measured-workspace warning at `T93`.
- [ ] Every page introduces no unexplained required term or notation according to its declared prerequisite inventory.
- [ ] Every exact primary fence parses with Tree-sitter, compiles, verifies, round-trips canonically, and produces its expected result.
- [ ] Every expected-rejection fence fails with its named stable diagnostic and publishes no artifact.
- [x] The current sampled tutorial experiment names the ideal target, seed, 32 shots, binary outcome width, exact histogram, and its accepted claim. Hardware discussion remains explicitly unexecuted.
- [ ] Repeating the full seeded sample suite produces the same canonical semantic reports.
- [x] Every current amplitude experiment labels its table as ideal state-vector or ideal-simulator evidence. **Weather** states that hardware does not expose those amplitudes.
- [x] The quantum chapters distinguish ideal amplitude state, one measured classical outcome, seeded repeated counts, hardware samples, and formal structural evidence. No sampled histogram is presented as state access or proof.
- [x] Reversible chapters describe generated inverse or adjoint operations as new execution and reserve VM rewind for retained transition history. The Bell restoration payoff states the distinction explicitly.
- [x] **Weather** treats measurement as the quantum-classical boundary, replay as reuse of recorded evidence without submission, and retry as a fresh physical preparation with a new lineage.
- [x] **Two Systems** says the Bell histogram establishes correlation but not entanglement by shape alone. It derives nonfactorability from the amplitude table and explains why CNOT copying basis information is not universal quantum cloning.
- [ ] Landauer text states the bound and its assumptions without claiming zero-energy computation.
- [x] **The Far Instrument** separates one executable prepared-state restoration from the generated finite structural certificate and states that a general QFT theorem over all normalized inputs and phase equivalence remains absent.
- [x] **Weather** names the measurement, reset, and target-resident conditional requirements. The static target rejects that complete capability set in canonical order before provider work, while the bounded dynamic target executes it.
- [ ] Every diagram has a text equivalent and does not depend on color.
- [ ] Source Markdown, static HTML, downloadable source, and printable order contain the same lesson graph.
- [ ] Serial and parallel documentation builds produce byte-identical semantic bundles.
- [ ] A failed lesson compile, run, sample, link, or render leaves the previous publication unchanged.
- [x] The published route contains thirteen complete chapter nodes covering `T00` through `T93`. The graph gate requires every routed chapter file and exact contiguous step coverage, so the release route contains no linked placeholder node.
- [ ] Structured reader review covers the zero-knowledge path through `T68` before the replacement gate.
- [x] The compact language-reference teaching list is deleted. The reference keeps one tutorial entrance and one unordered executable-evidence inventory.
- [x] Current reference pages remain implementation-only. `intro.md` links to the first-principles tutorial index, while no reference contract depends on a tutorial's draft metadata or narrative claims.

## Alternatives

### Keep the current compact teaching path

Rejected as the complete beginner curriculum. Its dependency order is sound, but each row contains too many hidden prerequisites
for a reader who only knows the word quantum. It remains useful until release units 1 through 3 pass the replacement gate.

### Start with qubits and explain classical reversibility later

Rejected. Quantum gates then look like arbitrary restrictions. Starting with information loss, inverses, and finite permutations
gives coherent lifting a reason rather than a keyword.

### Start with linear algebra

Rejected as the required path. Vectors and matrices provide the precise model, but a full formal introduction front-loads notation
before the reader has an experiment to explain. The chosen path introduces amplitude tables first and matrices after operation
tables are familiar. Optional math sidebars may go deeper.

### Explain each major topic in one chapter

Rejected. A chapter that introduces Hadamard, superposition, amplitudes, probability, measurement, and interference still assumes
the conceptual model it claims to teach. The tutorial step remains the conceptual and validation unit, while the chapter remains
the navigation and story publication unit.

### Use only the existing executable examples

Rejected. Existing examples prove broad implementation slices and contain several ideas at once. They remain valuable capstones
and conformance fixtures. They do not become tiny merely because a page explains them slowly.

### Maintain separate prose snippets and source files

Rejected. Two editable code authorities will drift. Self-contained lessons own one checked primary fence. Source-backed capstones
identify one exact package source and use generated listings or checked projections.

### Add a browser playground first

Rejected as a prerequisite. A browser runtime would add scripts, another execution host, publication policy, and accessibility
work before the curriculum exists. Offline terminal experiments and static diagrams provide the first complete path.

### Use live hardware to make the physics real

Rejected for the core path. Credentials, queue state, cost, noise, and provider drift make poor beginner dependencies. The ideal
simulator teaches semantic rules. Later pages label optional hardware runs as sampled evidence under explicit target and budget
identities.

### Use one broad quantum metaphor

Rejected. Coins, waves, arrows, and parallel worlds each hide a different rule. The series uses local analogies with explicit
stopping points, then moves to amplitude tables and unitary operations.

### Publish placeholder pages for the full roadmap

Rejected. Placeholder navigation turns planned syntax into apparent product surface and leads beginners into dead ends. The
proposal may retain an unlinked release-unit roadmap, while the public story landing exposes only its first chapter.

## Open questions

- Which final command surface should expose fixed-seed shots and histograms. **Owner:** runtime, target, and tools maintainers. **Decide by:** before release unit 2 implementation.
- Which bounded numeric and presentation profile should expose ideal amplitudes without making floating formatting semantic Wheeler output. **Owner:** quantum runtime and documentation maintainers. **Decide by:** before `T45` implementation.
- Should primary tutorial fences use page front matter alone or one additional fenced-block attribute to declare execution mode. **Owner:** WIP-0019 maintainers. **Decide by:** before tutorial metadata acceptance.
- Which deterministic display projection may omit source-attached `//!` and `///` documentation from a source-backed capstone listing. **Owner:** compiler and documentation maintainers. **Decide by:** before the first source-backed capstone.
- Which static circuit representation should generate both accessible HTML and useful source Markdown. **Owner:** quantum tooling and documentation maintainers. **Decide by:** before release unit 3.
- How many independent zero-knowledge reader reviews are required for a release unit. **Owner:** documentation maintainers. **Decide by:** before release unit 1 publication.
- Which chapter and anchor metadata binds several stable tutorial steps to one continuous story page without creating a second ordering authority. **Owner:** documentation and publication maintainers. **Decide by:** before tutorial metadata acceptance.
- Which crew names and fictional settings survive zero-knowledge reader testing, and should **Instructions for Returning** remain the public series title. **Owner:** documentation maintainers. **Decide by:** before release unit 1 publication.
- Which glossary identity and front-matter fields encode required, introduced, sharpened, and retired language. **Owner:** documentation and language maintainers. **Decide by:** before tutorial metadata acceptance.

## References

### Wheeler proposals

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0003](WIP-0003-quantum-target-and-qiskit-backend.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0006](WIP-0006-concrete-syntax-tooling-and-teaching.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0019](WIP-0019-integrated-documentation-publication.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0033](WIP-0033-typed-coherent-values-and-reversible-embeddings.md)
- [WIP-0034](WIP-0034-structured-uncomputation-and-clean-ancilla-scopes.md)
- [WIP-0035](WIP-0035-reversible-and-coherent-control-flow.md)
- [WIP-0036](WIP-0036-symbolic-resource-contracts-and-compositional-cost-evidence.md)
- [WIP-0037](WIP-0037-hierarchical-semantic-routine-graphs.md)

### Current documentation

- [What is Wheeler?](../intro.md)
- [Wheeler source language profile](../reference/language-profile.md)
- [Executable examples](../examples.md)
- [Quantum targets](../reference/quantum-targets.md)
- [Hybrid runs and replay](../reference/hybrid-runs.md)
- [Reversible virtual machine](../reference/virtual-machine.md)

### Teaching and subject references

- Richard P. Feynman, *Feynman Lectures on Computation*.
- David A. Patterson and John L. Hennessy, *Computer Organization and Design*, for finite-state and information foundations.
- N. David Mermin, *Quantum Computer Science: An Introduction*.
- Michael A. Nielsen and Isaac L. Chuang, *Quantum Computation and Quantum Information*.
- Rolf Landauer, "Irreversibility and Heat Generation in the Computing Process," 1961.
