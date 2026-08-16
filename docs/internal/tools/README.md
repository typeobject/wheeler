# Narrative authoring tools

`prose_variation.py` supports composition without choosing canon or technical meaning.
It has no third-party dependencies.

Draw cards from decks shuffled without replacement. With no seed, Python reads
operating-system entropy and reports the selected seed:

```bash
python3 docs/internal/tools/prose_variation.py draw \
  --count 13 \
  --output docs/internal/world/prose-draws.json
```

Repeat a draw by passing the recorded seed:

```bash
python3 docs/internal/tools/prose_variation.py draw --count 13 --seed 12345
```

Audit narrative Markdown while ignoring front matter, headings, tables, inline code,
and fenced code:

```bash
python3 docs/internal/tools/prose_variation.py audit \
  docs/public/tutorials/*.md docs/public/tutorials/index.mdx
```

The audit reports repetition for editorial review. It never changes prose. Standard
technical terms may recur because their identity matters. The editor decides which
repetitions are structural and which are necessary.
