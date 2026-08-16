# Goal: Recast Wheeler as a Spacefaring Age-of-Sail Appendix and Novella

Create a canonical world appendix and revise the Wheeler tutorial/novella into a unified literary and technical work set during a spacefaring Age of Sail. Preserve Wheeler’s technical accuracy while giving the setting historical depth, the characters role-driven conflict, and the prose an original poetic rhythm.

## Canonical world

Build the setting around this premise:

> Humanity learned to build durable islands in space before it learned to make distance cheap.

Establish a coherent history covering:

- orbital settlement as public works and charter infrastructure
- precision science and quantum metrology advancing faster than propulsion
- slow voyages governed by orbital seasons, radiation weather, fuel, and repair
- the withdrawal of distant charter powers
- the rise of pressure law, resident government, port republics, and cooperatives
- Catenary’s formation from independently built wheels and yards
- the Archive’s emergence as a neutral keeper of identity, obligations, and technical lineage
- Sable’s passage from abandoned navigation camp to scientific cooperative
- the origins of the Thorn Families and other vessel communities
- Wheeler’s development from reversible, safety-critical, and quantum-control engineering
- the present Second Navigation Age, in which autonomous settlements are attempting to reconnect without restoring remote imperial control

## Deliverables

### 1. Internal world bible

Create an internal canonical source covering:

- chronology
- geography and orbital relationships
- institutions and political history
- technology and its limits
- law, trade, labor, residency, and pressure customs
- naming conventions
- character histories and obligations
- facts that later chapters must not contradict
- unresolved questions reserved for the story

Keep this document exact enough to support continuity, even where its prose remains graceful.

### 2. Public literary appendix

Create a public appendix provisionally titled **The Reckoning of the Reach**.

Use varied, evocative headings rather than repeating “Of the.” Possible models include:

- Earth Before the Roads
- The Charter Years
- When the Ships Stopped Coming
- Air Made Law
- Catenary
- The Black Vault
- Roads of Light
- Sable at the Weatherward Edge
- The Families Between Ports
- Wheeler and the Work of Return
- Calendar of the Reach
- Names, Offices, and Measures

The appendix should feel like a history assembled from surviving records, civic memory, and disputed accounts. It should deepen the voyage without revealing its final resolution.

### 3. Revised tutorial/novella

Revise `docs/public/tutorials/index.mdx` and chapters `00` through `12` so the world history shapes every location, institution, and decision.

Preserve the existing tutorial progression and central plot:

- home and return
- classical state
- finite operations
- reversibility
- probability
- interference
- qubits and entanglement
- coherent lifting and uncomputation
- oracles and search
- QFT
- physical targets, evidence, replay, and return contracts

Keep the gray field manual as a living, annotated artifact. Connect it to the appendix’s history, perhaps as a shipboard recension of an older work rather than a final authority.

## Character conflict

Build conflict from incompatible duties rather than foolishness or generic banter:

- **Mara:** physical safety, fuel, and deadlines
- **Osei:** recoverable machinery and clean working state
- **Sana:** provenance and honest claims
- **Tala:** correct problem definition and scope
- **Iona:** physical truth and Sable’s local responsibility
- **Venn:** continuity across an entire population and traffic system

Each major chapter should force at least two legitimate duties into tension. Humor may arise from professional habits, but characters should retain distinct voices.

## Concept introduction

Introduce each technical concept through this sequence where practical:

1. A physical or institutional problem appears.
2. Characters offer competing interpretations.
3. An experiment or failure separates those interpretations.
4. The surviving distinction receives its standard technical name.
5. Exact code or mathematics expresses it.
6. The concept changes a consequential decision.

Local vocabulary may precede a formal term, but standard Wheeler and quantum terminology must remain clear and stable.

## Prose requirements

Write in an original voice informed by mythic historical depth, professional conflict, and concepts discovered through custom and experiment. Do not closely imitate any living author.

Use:

- concrete materials and physical actions
- varied sentence lengths
- recurring motifs of air, weight, light, clocks, roads, names, and seals
- lyrical passages grounded by plain technical explanation
- location-specific sensory vocabularies
- occasional aphorisms only at genuine turns in the story

Avoid habitual constructions such as:

- “It was not X. It was Y.”
- “No X. No Y.”
- “Same destination. Different road.”
- repeated sets of sentence fragments
- constant tricolons
- repeated paragraph openings
- excessive corrective dialogue
- ornamental synonyms for exact technical terms
- repeated use of `bounded`, `exact`, `claim`, or `record` where a concrete limit or object can be named

Use **bounded** only when it identifies a real technical property. Prefer explicit language such as “accepts at most 64 imports” or “uses a 16 MiB arena.”

Poetic rhythm should not make technical statements ambiguous.

## Controlled variation

Add a small authoring tool that uses operating-system entropy to shuffle composition prompts without replacement. Its decks may vary:

- opening scale
- physical anchor
- dominant sense
- exposition method
- sentence cadence
- closing gesture
- rhetorical device forbidden in the current section

Record the seed when a draw informs published work. Randomness may influence presentation, never canon, technical meaning, character decisions, or plot.

Add or use a repetition audit that identifies:

- repeated multiword phrases
- repeated paragraph openings
- clusters of negative antithesis
- recurring sentence templates
- nearby sentences with identical cadence
- unusually frequent abstract words

Treat the output as editorial evidence, not an automatic rewrite.

## Public reference migration

Do not delete `docs/public/reference` at the beginning.

First inventory every implemented contract currently documented there. Then replace the reader-facing presentation with concise technical appendices covering:

- the Wheeler language
- meanings of return
- artifacts and execution
- packages and bytecode
- quantum targets and hybrid runs
- observations, replay, and retry
- evidence and certificates
- exact limits and compatibility

Move implementation journals, bootstrap progress, and maintainer-only material into internal engineering documentation. Preserve all current technical facts that remain implemented.

Exact layouts, commands, limits, and tables must stay searchable and unambiguous. Remove the old public pages only after a coverage map proves that every necessary contract has a new home.

Keep the migration within the existing documentation system. If changing the public `reference` route or navigation would require edits outside `docs/`, retain the existing route and reshape its contents as appendices instead.

## Technical constraints

- Keep the entire public documentation site inside the world. Public introductions, examples, tutorials, appendices, technical references, navigation text, and link language must read as documents produced or preserved in the Reach. Do not call the work fiction, a story, a novella, a tutorial for an external reader, a website, or documentation, and do not otherwise break the fourth wall. Internal authoring and engineering files may speak plainly about the project.
- Modify only files beneath the repository’s `docs/` directory. Do not change compiler, runtime, build tooling, site-generation code, tests, examples, or configuration stored elsewhere in the repository.
- Place any authoring or repetition-audit tools required by this goal beneath `docs/internal/`.
- Preserve executable Wheeler source, shell commands, expected output, seeds, and mathematical results unless a verified implementation change requires correction.
- Do not let literary prose claim behavior absent from the implementation.
- Keep simulation, hardware observation, theorem, certificate, replay, retry, rewind, inverse, and adjoint distinct.
- Do not modify unrelated working-tree changes.
- Maintain valid internal and public links.

## Completion criteria

The goal is complete when:

1. The internal world bible establishes a consistent canon.
2. The public world appendix presents that canon in polished literary form.
3. All tutorial chapters follow the new setting, voice, and character obligations.
4. Technical concepts retain their correct sequence and meaning.
5. The public technical appendix covers every necessary fact from the old reference.
6. Repetition and vocabulary audits have been reviewed manually.
7. Documentation navigation, links, style checks, executable examples, and site generation pass.
8. A final continuity review finds no known contradiction among the appendix, novella, examples, and implemented Wheeler behavior.
