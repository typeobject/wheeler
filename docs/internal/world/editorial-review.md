# Editorial and continuity review

This review covers the public state after the Reach appendix, mission-account,
and instrument-appendix migration.

## Controlled variation

`prose-draws.json` records operating-system seed `12560211606378549288` and 26
cards drawn from decks shuffled without replacement. Twelve cards informed the
public *Reckoning*. Thirteen informed the mission chapters. One informed the
mission index. The cards influenced scale, sensory anchor, exposition method,
cadence, closing motion, and a rhetorical habit to avoid. They made no decision
about canon, mathematics, character action, or source semantics.

Repeating the draw with the recorded seed reproduced every card before assignment
labels were added.

## Narrative repetition

`narrative-audit.json` covers the thirteen mission chapters, their index, and the
public *Reckoning*. Its final pass contains 20,408 prose words. The selected
rhetorical-template counts are:

| Template | Count |
| --- | ---: |
| `not X but Y` | 0 |
| `not X. It was Y` | 0 |
| paired `No` fragments | 0 |
| nearby `same` and `different` antithesis | 0 |

The audit finds no prose use of *bounded* and three uses of *exact*. It finds five
forms of *claim*, 18 forms of *record*, 24 forms of *return*, and 100 forms of
*state*. The last two are named technical and thematic subjects across a 37-day
account. The first two remain concentrated where Sana's office and evidence
require them.

Repeated five-word phrases were reviewed manually. These recurrences remain by
design:

- `The Common Book of Return` is a proper title.
- `What is remembered can be returned` is the Archive's public motto and the
  subject of its internal correction.
- `recension of the Common Book` identifies the gray artifact at the frame's
  opening and close.

Historical descriptions copied too closely between the appendix and voyage were
rewritten. The Thorn mark, Archive evacuation, Sable orbit, camp names, exposed
labor, and instrument trusses now carry their facts in different sentences.

Paragraph-opening repetition is limited to proper subjects and widely separated
acts. Three paragraphs begin with the Common Book and three with the far
instrument across more than twenty thousand words. Character openings that recur
twice appear in separate chapters and attach to different actions.

## Instrument prose

`instrument-prose-audit.json` covers the Catenary introduction, executable ledger,
and public technical appendices. Its 14,128 prose words contain no use of
*bounded*. Sixty-six uses of *exact* remain because exact identity, byte equality,
count, width, and source relation are part of the accepted contracts. Substituting
ornamental synonyms would weaken those statements.

Repeated `Expected result` openings belong to the ledger's stable entry format.
Repeated size phrases state independent 16 MiB ceilings. The audit's sole
`not X but Y` match occurs inside the named `honest-but-curious` threat model and
is not a rhetorical contrast.

## Historical continuity

The internal canon and public account agree on these points:

- The Reach surrounds the Giant and contains no convenient planetary surface.
- Catenary formed from charter works joined first through utilities and traffic
  law.
- The Archive began as a neutral clearinghouse and later made complete critical
  machine history a civic doctrine after twelve deaths.
- Sable follows an irregular captured orbit at the weatherward edge of the
  Giant's magnetic field.
- The Long Withdrawal had several causes and unfolded as a sequence of absences.
- The Covenant of Air placed emergency authority beside shared physical risk.
- The Second Navigation seeks common standards among autonomous ports.
- Thorn vessel trusts grew from inhabited ships abandoned by charter owners.
- The Common Book has many recensions and no accepted author.
- *Vela*'s complete departure and return account spans thirty-seven days.

The public *Reckoning* leaves the Giant's formal name, one definitive cause for the
Withdrawal, the Common Book's first author, and the Second Navigation's political
future unsettled as required by canon.

## Character obligations by chapter

| Chapter | Duties placed in tension |
| --- | --- |
| Home | Mara's burn window, Osei's restoration state, Sana's lineage, and Tala's scope |
| Departure | Mara's physical interlock, Osei's source order, and Sana's executable evidence |
| Two Signals | Mara's operational flip, Sana's complete mapping, and Mara's unanswered Thorn berth |
| The Archive | Mara's usable endpoint, Osei's road back, Sana's human frame, and Edrin's retained history |
| Long Count | Mara's decision schedule, Sana's assumptions, Tala's finite evidence, and Tala's doubt about her own veto |
| Contributions That Cancel | Osei's physical diagnosis, Sana's arithmetic order, and Mara's detector account |
| One Qubit | Iona's instrument discipline, Mara's cost and schedule, and Tala's model language |
| Two Systems | Sable's local authority, Osei's restoration, and Sana's refusal to infer entanglement from bars |
| Crossing | Osei's reuse, Sana's shared-risk warning, and Iona's physical resource account |
| Contract Machine | Tala's need for more queries, Iona's paid call, and Venn's advancing traffic deadline |
| Search | Mara's direct inspection, Iona's qualification purpose, Sana's narrow evidence, and Venn's remaining window |
| Far Instrument | Mara's chamber window, Osei and Iona's inherited source, and Sana's proof lineage |
| Weather | Local chamber authority, Catenary continuity, physical observation, public traffic cost, and the final burn |

No conflict requires a character to ignore the responsibility of their office.
Each duty produces a useful answer and a characteristic temptation.

## Narrative pressure and personal consequence

Venn's deadline now crosses four consecutive mission stages. Her traffic plan
first names the public cost of delay. The final chamber notice narrows the work to
one window. At Catenary, extending *Vela*'s hold diverts an ore carrier and a
passenger ship. Venn remains responsible rather than villainous because every
concession moves risk onto traffic she must protect.

The personal roads also close through new actions rather than restored pasts:

- Mara receives a Thorn berth offer from the vessel where she learned docking.
  After choosing Catenary as home, she answers with its coordinates and offers a
  berth outward.
- Tala carries Venn's old warning throughout the voyage. Their final private
  exchange acknowledges the fourteen cars without converting memory into an
  apology or erasing the original report.
- Osei and Iona keep the blue cup, the repaired bearing, and a new correspondence.
  They make no return-date promise.
- Sana and Edrin amend the evacuation account while preserving their disagreement
  and the twelve deaths.

The first physical phase estimate is now a qualification rather than the mission
answer. Its current diagnostic exposes chamber weather. Replay cannot improve the
sample, retry confirms the mismatch, and the evidence causes Iona to protect the
production register. The compact manifest follows that production observation.
This chain makes the late technical sequence one escalating instrument decision
instead of a catalogue after the mission has already succeeded.

The mission index explicitly shelves the voyage before the historical reckoning,
so the public appendix deepens events after their first dramatic encounter.

## Full prose replacement

The mission index and all thirteen account files now contain no prose paragraph
preserved verbatim from their state before the Reach recast. A block comparison
against the repository baseline excludes front matter, headings, the publication
contract's required opening link, fenced technical material, and Markdown tables,
then reports zero surviving legacy narrative or explanatory prose blocks in every
file.

The rewrite keeps a close operational focus on Tala while allowing the offices
around her to reveal Catenary, the Archive, the Thorn Families, and Sable through
work. It replaces tutorial-like transitions with physical causes: signal traffic
leads to finite mappings, Archive law forces the distinction between rewind and
inverse, Sable's calibration greeting forces sampling language, and chamber
weather drives the complete physical evidence chain.

All 131 fenced blocks and 25 Markdown tables remain byte-for-byte identical and
in the same order as before this full prose pass. This preserves source,
commands, expected output, seeds, amplitudes, contracts, and mathematical tables
while replacing the surrounding narration and exposition.

## Scenic continuity

The immersive pass uses no repeated day-and-location labels. Its private calendar
prevents contradictions, while elapsed time enters the account through passage
sleep, meals, watch changes, signal loss, target cooling, depleted windows, and
changing light.

Place accumulates through repeated movement. Tala learns *Vela* from service lock
to machine room, central passage, galley, chart table, bridge, and fixed crew
stations. The Archive curves from dock through its public gallery to the inward
evacuation exhibit and verification room. At Sable, the frost-lined laboratory
leads over Osei's marked bridge weld to the algorithm racks, farther outward to
the main-array gallery, then down the pressure stair to the physical chamber.
Later scenes assume the route instead of introducing each room again.

World history now appears in occupied evidence: obsolete charter seals beneath
working pipes, a family dividing Archive keys, Sable's crossed-out sponsor seal,
a bandwidth ballot beside the water ledger, and source metadata carrying Osei
and Iona's former address. Exposition follows something Tala can see, touch,
hear, or infer in the current scene.

## Technical sequence

The mission account preserves this order:

1. source, artifact, deterministic execution, state, call, and assertion
2. two-state mappings and completeness
3. overwrite, retained history, inverse execution, reverse order, and commit
4. outcome, trial, sample, histogram, frequency, and probability model
5. signed contributions, interference, and phase
6. one qubit, amplitude, superposition, measurement, H, X, Z, and complex phase
7. product states, CNOT, Bell preparation, entanglement, measurement, and adjoint
8. coherent lifting, ancillas, and uncomputation
9. oracle promise, phase kickback, and Deutsch classification
10. phase marking, diffusion, and one four-state Grover iteration
11. little-endian QFT order, forward amplitude checks, generated adjoint, and
   structural certificate
12. target planning, capability rejection, hybrid jobs, physical samples,
   decoherence, replay, retry, error correction, theorem evidence, and explicit
   return contracts

The account keeps simulator state vectors, seeded samples, hardware observations,
statistical inference, generated certificates, and theorem evidence separate.
Measurement ends access to the earlier unknown quantum state. The final burn
remains new propulsion.

## Public technical continuity

The ten former public reference sources were preserved byte for byte as internal
snapshots. `public-reference-migration.md` maps all 101 former second-level
sections. Public appendices retain source forms, wire layouts, commands, limits,
lifecycle states, proof rules, target capabilities, physical nonclaims, and
compatibility policy. Module catalogues, fixture inventories, proposal status, and
native cutover history remain internal.

The introduction, ledger, mission account, world appendix, and technical
appendices now speak as material issued or preserved in the Reach. Rendered output
contains no description of the work as fiction, a novella, a website, or an
external tutorial.

## Preserved executable material

No mission code fence, shell command, expected output, seed, histogram,
amplitude table, or mathematical result changed during the prose revision. The
preexisting little-endian QFT corrections in the introduction and executable
ledger remain intact.
