#!/usr/bin/env python3
"""Draw non-repeating composition prompts and audit narrative Markdown.

The draw command takes its default seed from operating-system entropy. Supply that
reported seed to reproduce a deck. The audit command ignores front matter and
fenced code so Wheeler syntax does not distort the prose report.
"""

from __future__ import annotations

import argparse
import collections
import json
import random
import re
import secrets
import sys
from pathlib import Path

DECKS = {
    "opening_scale": [
        "astronomical",
        "civic",
        "domestic",
        "mechanical",
        "personal",
        "institutional",
        "historical",
    ],
    "physical_anchor": [
        "an inherited tool",
        "a pressure seal",
        "a handwritten correction",
        "a sound in the hull",
        "a public notice",
        "a worn piece of clothing",
        "a moving light",
        "a shared meal",
        "a repaired surface",
    ],
    "dominant_sense": [
        "sound",
        "temperature",
        "motion",
        "texture",
        "smell",
        "light",
        "weight",
    ],
    "exposition_method": [
        "repair",
        "professional disagreement",
        "ceremony",
        "failed test",
        "legal decision",
        "journey",
        "work account",
        "lesson by demonstration",
    ],
    "cadence": [
        "short opening followed by gradual expansion",
        "long approach ending in a short decision",
        "quiet sequence of medium sentences",
        "periodic sentence relieved by plain statements",
        "abrupt opening followed by patient observation",
        "dialogue framed by a slower descriptive passage",
    ],
    "closing_gesture": [
        "physical image",
        "irreversible action",
        "change of scale",
        "new obligation",
        "unanswered practical question",
        "movement toward the next place",
        "altered meaning of an earlier object",
    ],
    "forbidden_habit": [
        "negative antithesis",
        "a row of fragments",
        "a closing aphorism",
        "a list of three",
        "corrective dialogue",
        "the same noun in neighboring sentences",
        "an abstract opening sentence",
    ],
}

ABSTRACT_WORDS = (
    "bounded",
    "exact",
    "claim",
    "claims",
    "record",
    "records",
    "return",
    "returns",
    "state",
    "states",
)
WORD_RE = re.compile(r"[A-Za-z][A-Za-z'’-]*")
SENTENCE_RE = re.compile(r"(?<=[.!?])(?:[\"”’)]*)\s+")


def shuffled_cycle(values: list[str], count: int, rng: random.Random) -> list[str]:
    result: list[str] = []
    previous: str | None = None
    while len(result) < count:
        cycle = list(values)
        rng.shuffle(cycle)
        if previous is not None and len(cycle) > 1 and cycle[0] == previous:
            cycle[0], cycle[1] = cycle[1], cycle[0]
        take = min(count - len(result), len(cycle))
        result.extend(cycle[:take])
        previous = result[-1]
    return result


def draw_cards(count: int, seed: int, source: str) -> dict[str, object]:
    rng = random.Random(seed)
    columns = {
        name: shuffled_cycle(values, count, rng)
        for name, values in DECKS.items()
    }
    cards = [
        {name: columns[name][index] for name in DECKS}
        for index in range(count)
    ]
    return {
        "schema": 1,
        "seed": seed,
        "source": source,
        "method": "shuffle without replacement; reshuffle only after a deck is exhausted",
        "cards": cards,
    }


def prose_from_markdown(text: str) -> str:
    lines = text.splitlines()
    kept: list[str] = []
    in_front_matter = bool(lines and lines[0].strip() == "---")
    in_fence = False
    for index, line in enumerate(lines):
        stripped = line.strip()
        if index == 0 and in_front_matter:
            continue
        if in_front_matter:
            if stripped == "---":
                in_front_matter = False
            continue
        if stripped.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence or stripped.startswith("|") or stripped.startswith("#"):
            continue
        line = re.sub(r"`[^`]*`", " ", line)
        line = re.sub(r"\[[^]]+\]\([^)]*\)", " ", line)
        line = re.sub(r"[*_>]", " ", line)
        kept.append(line)
    return "\n".join(kept)


def normalize_words(text: str) -> list[str]:
    return [word.lower().replace("’", "'") for word in WORD_RE.findall(text)]


def repeated_ngrams(words: list[str], size: int, limit: int = 20) -> list[dict[str, object]]:
    counts = collections.Counter(
        tuple(words[index:index + size])
        for index in range(max(0, len(words) - size + 1))
    )
    rows = [
        {"phrase": " ".join(phrase), "count": count}
        for phrase, count in counts.most_common()
        if count > 1
    ]
    return rows[:limit]


def audit(paths: list[Path]) -> dict[str, object]:
    combined_parts: list[str] = []
    paragraphs: list[str] = []
    for path in paths:
        prose = prose_from_markdown(path.read_text(encoding="utf-8"))
        combined_parts.append(prose)
        paragraphs.extend(part.strip() for part in re.split(r"\n\s*\n", prose) if part.strip())
    combined = "\n\n".join(combined_parts)
    words = normalize_words(combined)
    frequencies = collections.Counter(words)
    openings = collections.Counter(
        " ".join(normalize_words(paragraph)[:3])
        for paragraph in paragraphs
        if len(normalize_words(paragraph)) >= 3
    )
    sentences = [segment.strip() for segment in SENTENCE_RE.split(combined) if segment.strip()]
    lengths = [len(normalize_words(sentence)) for sentence in sentences]
    cadence_runs: list[dict[str, object]] = []
    for index in range(len(lengths) - 2):
        triple = lengths[index:index + 3]
        if max(triple) - min(triple) <= 2 and min(triple) >= 4:
            cadence_runs.append({"sentence": index + 1, "word_lengths": triple})
    templates = {
        "not_x_but_y": len(re.findall(r"\bnot\b[^.!?]{0,100}\bbut\b", combined, re.I)),
        "not_x_it_was_y": len(re.findall(r"\b(?:it|this|that) was not\b[^.!?]*[.!?]\s+(?:It|This|That) was\b", combined)),
        "no_fragment_pair": len(re.findall(r"(?:^|[.!?]\s+)No\s+[^.!?]{1,50}[.!?]\s+No\s+", combined)),
        "same_different": len(re.findall(r"\bsame\b[^.!?]{0,100}\bdifferent\b", combined, re.I)),
    }
    return {
        "schema": 1,
        "files": [str(path) for path in paths],
        "word_count": len(words),
        "paragraph_count": len(paragraphs),
        "sentence_count": len(sentences),
        "abstract_words": {word: frequencies[word] for word in ABSTRACT_WORDS},
        "templates": templates,
        "repeated_paragraph_openings": [
            {"opening": opening, "count": count}
            for opening, count in openings.most_common(20)
            if count > 1
        ],
        "repeated_four_grams": repeated_ngrams(words, 4),
        "repeated_five_grams": repeated_ngrams(words, 5),
        "similar_cadence_runs": cadence_runs[:30],
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    draw = subparsers.add_parser("draw", help="draw composition cards")
    draw.add_argument("--count", type=int, required=True)
    draw.add_argument("--seed", type=int)
    draw.add_argument("--output", type=Path)

    audit_parser = subparsers.add_parser("audit", help="audit narrative Markdown")
    audit_parser.add_argument("paths", nargs="+", type=Path)
    audit_parser.add_argument("--output", type=Path)
    return parser.parse_args()


def emit(payload: dict[str, object], output: Path | None) -> None:
    text = json.dumps(payload, indent=2, ensure_ascii=False) + "\n"
    if output is None:
        sys.stdout.write(text)
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    args = parse_args()
    if args.command == "draw":
        if args.count < 1 or args.count > 10_000:
            raise SystemExit("--count must be between 1 and 10000")
        source = "operating-system entropy" if args.seed is None else "provided seed"
        selected_seed = secrets.randbits(64) if args.seed is None else args.seed
        emit(draw_cards(args.count, selected_seed, source), args.output)
    else:
        missing = [path for path in args.paths if not path.is_file()]
        if missing:
            raise SystemExit("missing input: " + ", ".join(map(str, missing)))
        emit(audit(args.paths), args.output)
