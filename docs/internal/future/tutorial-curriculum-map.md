# Tutorial curriculum map

This appendix records the complete planned step map owned by
[WIP-0042](../proposals/WIP-0042-first-principles-reversible-and-quantum-tutorials.md).
It describes future tutorial contracts, not current language or runtime behavior. Public tutorial
navigation exposes only release units that pass the proposal's publication gates. A map is useful.
A map claiming the bridge is finished is how carts enter rivers.

### Curriculum map

The curriculum uses stable step IDs. Titles may improve after reader review. The first accepted map contains about ninety short
steps. Maintainers may split a step without renumbering later semantic identities by adding a lowercase suffix. They may merge
only steps that introduce no separate conceptual dependency.

#### Opening: The destination

- `T00` opens aboard the *Vela* after a failed return check, then shows the mission's small Bell-pair Wheeler program as an unexplained destination. It labels every unfamiliar line as something the series will earn. It asks what the crew can claim from one recorded output and makes no claim that the reader understands the quantum result.

The series then returns to Tala's first day aboard *Vela*. It puts the Bell program aside until `T57` and closes the return report
at `T93`.

#### Part 1: What a program does

- `T01` creates one Wheeler source file.
- `T02` runs one program and reads the completion line.
- `T03` introduces one named `state` value.
- `T04` changes that value with one assignment.
- `T05` observes that statements run in source order.
- `T06` checks one expected result with `assert`.
- `T07` gives a known sequence of statements one method name and calls it.

The checkpoint changes one literal, predicts the final state, and explains one failed assertion. It introduces no bit or
reversible terminology.

#### Part 2: Bits and finite state

- `T08` restricts one example value to two allowed states.
- `T09` names those states `0` and `1` without assuming binary arithmetic.
- `T10` lists every possible input in a two-row table.
- `T11` introduces the identity operation.
- `T12` introduces the flip operation as two arrows.
- `T13` applies the flip twice and restores the initial state.

The checkpoint asks the reader to draw and execute a two-state map. It does not yet call the map reversible.

#### Part 3: Information loss and reversible computation

- `T14` overwrites both possible inputs with zero.
- `T15` notices that two input arrows collide at one output.
- `T16` asks why the output cannot identify the earlier input.
- `T17` saves the earlier value as explicit history and accounts for the extra information.
- `T18` defines an inverse as a new operation that reconstructs the exact input from the current state.
- `T19` places an overwrite inside `rev` and reads the compiler rejection.
- `T20` writes the first reversible XOR flip.
- `T21` invokes `reverse flip();` as new forward work.
- `T22` composes two known reversible operations and derives reverse execution order.
- `T23` commits VM history, then runs a generated inverse to distinguish inverse execution from rewind.

A following conceptual note introduces finite permutations. A separate bounded sidebar introduces Landauer's principle and states
its thermodynamic assumptions and nonclaims.

The checkpoint classifies tiny operations as one-to-one, information-losing, history backed, or rejected from `rev`.

#### Part 4: Trials, outcomes, and probability

- `T24` distinguishes one trial from its one observed outcome.
- `T25` repeats a preparation to create fresh trials.
- `T26` counts outcomes without interpreting the counts.
- `T27` draws a histogram.
- `T28` compares frequency with a stated probability model.
- `T29` explains why one outcome does not reveal a distribution.

These steps may use a fixed recorded binary data set before quantum syntax appears. The fixed data teaches counting, not
randomness. A later quantum experiment supplies its own fresh seeded trials.

The checkpoint reads two histograms and rejects conclusions that the sample cannot support.

#### Part 5: Paths, signed contributions, and interference

- `T30` draws two alternative paths to one destination.
- `T31` assigns one real contribution to each path.
- `T32` adds contributions with the same sign.
- `T33` cancels equal contributions with opposite signs.
- `T34` names relative sign as the first simple phase distinction.
- `T35` explains why ordinary probabilities cannot model this cancellation.

These steps introduce no qubit. They prepare the calculation rule that the Hadamard experiments will need.

The checkpoint computes four two-path sums and only then squares their magnitudes.

#### Part 6: One qubit

- `T36` introduces a physical system with two distinguished measurement outcomes.
- `T37` names one computational basis `|0>` and `|1>`.
- `T38` declares one Wheeler `qreg` without applying a gate.
- `T39` prepares the known basis state `|0>`.
- `T40` measures the prepared state and records one classical outcome.
- `T41` repeats fresh preparation and measurement with an explicit shot count.
- `T42` applies `X` and compares it with the familiar classical flip on basis states.
- `T43` applies `H` and inspects a seeded histogram before explaining it.
- `T44` separates the premeasurement state from one measured outcome.
- `T45` writes the first two-row amplitude table.
- `T46` introduces normalization and the amplitude-magnitude-squared probability rule.
- `T47` applies `H` twice and uses path addition to explain the deterministic return.
- `T48` applies `Z`, observes no basis-probability change, then uses `H`, `Z`, `H` to reveal relative phase.
- `T49` distinguishes global phase from relative phase through observable predictions.
- `T50` introduces general phase angles and complex numbers as planar arrows.

`T43` does not say that the qubit is a hidden coin. `T46` does not say that measurement merely reads a value that always existed.
`T50` does not make complex-number fluency a prerequisite for the earlier real-amplitude path.

The checkpoint predicts exact outcomes for `X`, `H H`, and `H Z H`, then explains one sampled `H` histogram.

#### Part 7: Two qubits and entanglement

- `T51` lists the four two-qubit basis labels.
- `T52` connects basis labels to Wheeler's canonical little-endian measurement integers.
- `T53` builds a product-state amplitude table from two independent one-qubit tables.
- `T54` samples two independently prepared superpositions and sees all four outcomes.
- `T55` evaluates CNOT on all four basis inputs.
- `T56` explains why coherent control is not an ordinary measured `if` statement.
- `T57` returns to the opening Bell circuit and executes it.
- `T58` samples the Bell circuit and sees only correlated outcomes `00` and `11`.
- `T59` compares the Bell histogram with an ordinary classically correlated data set.
- `T60` shows that the Bell amplitude table cannot factor into two independent one-qubit tables and names entanglement.
- `T61` explains why CNOT copies a known basis bit in one case but cannot clone an arbitrary qubit state.
- `T62` runs the Bell circuit's generated adjoint and restores the prepared basis state.

The checkpoint distinguishes independence, classical correlation, and entanglement using state and preparation facts rather than
histogram shape alone.

#### Part 8: Wheeler's reversible-to-coherent bridge

- `T63` revisits the classical XOR flip and its finite permutation table.
- `T64` requires coherent eligibility with `coherent rev`.
- `T65` applies the same function to a quantum basis state.
- `T66` applies the permutation to a superposition and tracks amplitudes without measurement.
- `T67` tests rejected coherent bodies containing overwrite, measurement, I/O, or unsupported arithmetic.
- `T68` introduces paired compute and use regions, clean ancillas, and exact generated uncomputation.

The checkpoint explains, in words and a table, why exact finite permutations lift while information-losing functions do not.

#### Part 9: Interference as an algorithmic tool

- `T69` prepares the target state used for phase kickback.
- `T70` runs one controlled operation and converts kicked-back phase into a basis outcome.
- `T71` introduces an oracle as an operation with an exact input-output contract rather than a magical black box.
- `T72` builds the constant case of Deutsch's problem.
- `T73` builds the balanced case.
- `T74` compares the two circuits and identifies the one-call distinction.
- `T75` prepares an equal four-state superposition for two-qubit search.
- `T76` marks one basis state with phase.
- `T77` constructs the diffusion step from already known gates.
- `T78` runs the complete four-state Grover experiment and states why the tiny fixture proves no practical speedup.
- `T79` identifies the one-qubit Fourier transform with `H`.
- `T80` constructs a two-qubit QFT one gate at a time.
- `T81` reaches the checked-in three-qubit `QFT.w` after every gate and angle role is familiar.
- `T82` runs the generated adjoint and inspects the finite structural certificate.

The checkpoint distinguishes algorithm, oracle contract, implementation, sampled result, and proof claim.

Broader arithmetic oracles, reusable lookup, structured workspace, phase estimation, and amplitude estimation remain gated on
WIP-0010 and WIP-0033 through WIP-0036.

#### Part 10: Quantum programs in the world

- `T83` distinguishes an ideal semantic simulator from a physical target.
- `T84` separates exact amplitudes, seeded samples, hardware samples, and statistical claims.
- `T85` emits OpenQASM and identifies it as derived target text rather than Wheeler semantics.
- `T86` inspects target capabilities and one pre-submission rejection.
- `T87` follows one asynchronous quantum job even when the local target completes immediately.
- `T88` treats measurement as a classical observation rather than an inverse-bearing mutation.
- `T89` replays one recorded observation without target execution.
- `T90` retries the same preparation as a new physical lineage.
- `T91` introduces noise and decoherence as physical behavior outside the ideal state-vector model.
- `T92` runs `SurfaceCode.w` through bounded dynamic syndrome measurement, reset, decoding, and target-resident correction.
- `T93` compares executable tests, sampled evidence, finite structural certificates, and general theorem certificates.

The final checkpoint asks the reader to classify inverse, rewind, uncompute, adjoint, measurement, replay, and retry across one
complete hybrid story.
