#!/usr/bin/env python3
"""Run the README's single quickstart command and check its final output."""

from pathlib import Path
import re
import shlex
import subprocess
import sys


def fenced_section(text, marker, language):
    pattern = rf"<!-- {re.escape(marker)} -->\n```{language}\n(.*?)\n```"
    matches = re.findall(pattern, text, re.DOTALL)
    if len(matches) != 1 or not matches[0].strip():
        raise ValueError(f"README needs one nonempty {marker} fence")
    return matches[0]


def final_output_matches(output, expected):
    return bool(expected) and output.splitlines()[-len(expected):] == expected


def main():
    root = Path(__file__).resolve().parents[2]
    readme = (root / "README.md").read_text(encoding="utf-8")
    command = fenced_section(readme, "quickstart-command", "bash")
    expected = fenced_section(readme, "quickstart-output", "text").splitlines()
    arguments = shlex.split(command)
    if len(command.splitlines()) != 1 or arguments[0] != "./bootstrap/gradlew":
        raise ValueError("quickstart must invoke the checked-in wrapper in one command")
    result = subprocess.run(
        arguments, cwd=root, text=True, capture_output=True, timeout=300, check=False
    )
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    if result.returncode != 0:
        return result.returncode
    # A fresh wrapper can print distribution download progress before task output.
    if not final_output_matches(result.stdout, expected):
        raise ValueError("quickstart output differs from README")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, subprocess.TimeoutExpired) as failure:
        sys.exit(f"README quickstart failed: {failure}")
