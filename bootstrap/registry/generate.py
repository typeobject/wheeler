#!/usr/bin/env python3
"""Generate bounded Java and Wheeler instruction-registry views."""

from __future__ import annotations

import argparse
import dataclasses
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = ROOT / "registry/instructions.wreg"
JAVA_OUTPUT = (
    ROOT
    / "bootstrap/core/src/main/java/com/typeobject/wheeler/core/bytecode/GeneratedInstructionRegistry.java"
)
WHEELER_OUTPUT = ROOT / "registry/generated/GeneratedInstructionRegistry.w"
NAME = re.compile(r"[A-Z][A-Z0-9_]*\Z")
FORM = re.compile(r"[A-Z][A-Z0-9_]*\Z")
HEX_IDENTITY = re.compile(r"0x[0-9a-f]{4}\Z")
REVERSIBILITIES = {"INTRINSIC": 0, "CHECKED": 1, "LOGGED": 2, "BARRIER": 3}


@dataclasses.dataclass(frozen=True)
class Entry:
    name: str
    identity: int
    form: str
    roles: tuple[str, ...]
    reversibility: str


def read_entries() -> list[Entry]:
    entries: list[Entry] = []
    names: set[str] = set()
    identities: set[int] = set()
    forms: dict[str, tuple[str, ...]] = {}
    roles: set[str] = set()
    for line_number, raw in enumerate(SOURCE.read_text(encoding="utf-8").splitlines(), 1):
        if not raw or raw.startswith("#"):
            continue
        fields = raw.split("|")
        if len(fields) != 5:
            fail(line_number, "expected five pipe-separated fields")
        name, identity_text, form, role_text, reversibility = fields
        ordered_roles = tuple(role_text.split(",")) if role_text else ()
        if not NAME.fullmatch(name) or name in names:
            fail(line_number, f"invalid or duplicate instruction name {name!r}")
        if not HEX_IDENTITY.fullmatch(identity_text):
            fail(line_number, f"invalid instruction identity {identity_text!r}")
        identity = int(identity_text, 16)
        if identity in identities:
            fail(line_number, f"duplicate instruction identity {identity_text}")
        if not FORM.fullmatch(form):
            fail(line_number, f"invalid instruction form {form!r}")
        if any(not NAME.fullmatch(role) for role in ordered_roles):
            fail(line_number, "invalid operand role")
        if reversibility not in REVERSIBILITIES:
            fail(line_number, f"invalid reversibility {reversibility!r}")
        prior_roles = forms.setdefault(form, ordered_roles)
        if prior_roles != ordered_roles:
            fail(line_number, f"form {form} has inconsistent roles")
        names.add(name)
        identities.add(identity)
        roles.update(ordered_roles)
        entries.append(Entry(name, identity, form, ordered_roles, reversibility))
    if not entries or entries != sorted(entries, key=lambda entry: entry.identity):
        raise SystemExit("registry entries must be nonempty and sorted by identity")
    if len(roles) > 31:
        raise SystemExit("registry role form exceeds five-bit role identities")
    return entries


def fail(line_number: int, message: str) -> None:
    raise SystemExit(f"{SOURCE}:{line_number}: {message}")


def java_view(entries: list[Entry]) -> str:
    rows = []
    for entry in entries:
        roles = ", ".join(f"OperandRole.{role}" for role in entry.roles)
        role_list = f"List.of({roles})" if roles else "List.of()"
        rows.append(
            "      new Entry(\n"
            f'          "{entry.name}", 0x{entry.identity:04x}, "{entry.form}",\n'
            f"          {role_list}, Reversibility.{entry.reversibility})"
        )
    joined = ",\n".join(rows)
    return f"""package com.typeobject.wheeler.core.bytecode;

import com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole;
import java.util.List;

/** Generated from registry/instructions.wreg. Do not edit this view. */
final class GeneratedInstructionRegistry {{
  private static final List<Entry> ENTRIES = List.of(
{joined});

  static List<Entry> entries() {{
    return ENTRIES;
  }}

  record Entry(
      String name,
      int identity,
      String form,
      List<OperandRole> roles,
      Reversibility reversibility) {{
    Entry {{
      roles = List.copyOf(roles);
    }}
  }}

  private GeneratedInstructionRegistry() {{}}
}}
"""


def wheeler_view(entries: list[Entry]) -> str:
    role_names = sorted({role for entry in entries for role in entry.roles})
    role_ids = {role: index + 1 for index, role in enumerate(role_names)}
    lines = [
        "//! Generated instruction-registry view. Do not edit this module.",
        "",
        "module wheeler.compiler.generated_instruction_registry;",
        "",
        "classical class GeneratedInstructionRegistry {",
    ]
    for name, value in REVERSIBILITIES.items():
        lines.extend([
            f"  /// `{name}` reversibility.",
            f"  public const long REVERSIBILITY_{name} = {value};",
        ])
    lines.append("")
    for role, value in role_ids.items():
        lines.extend([
            f"  /// `{role}` operand role.",
            f"  public const long ROLE_{role} = {value};",
        ])
    for entry in entries:
        packed = sum(role_ids[role] << (index * 5) for index, role in enumerate(entry.roles))
        lines.extend([
            "",
            f"  /// `{entry.name}` opcode identity.",
            f"  public const long OPCODE_{entry.name} = 0x{entry.identity:04x};",
            f"  /// `{entry.name}` operand count.",
            f"  public const long OPCODE_{entry.name}_OPERAND_COUNT = {len(entry.roles)};",
            f"  /// `{entry.name}` packed operand roles.",
            f"  public const long OPCODE_{entry.name}_ROLE_FORM = 0x{packed:x};",
            f"  /// `{entry.name}` reversibility.",
            "  public const long OPCODE_"
            f"{entry.name}_REVERSIBILITY = REVERSIBILITY_{entry.reversibility};",
        ])
    lines.extend(["}", ""])
    return "\n".join(lines)


def publish(path: pathlib.Path, content: str, check: bool) -> bool:
    current = path.read_text(encoding="utf-8") if path.exists() else None
    if current == content:
        return True
    if check:
        print(f"stale generated instruction registry: {path.relative_to(ROOT)}", file=sys.stderr)
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(content, encoding="utf-8", newline="\n")
    temporary.replace(path)
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    arguments = parser.parse_args()
    entries = read_entries()
    valid = publish(JAVA_OUTPUT, java_view(entries), arguments.check)
    valid &= publish(WHEELER_OUTPUT, wheeler_view(entries), arguments.check)
    return 0 if valid else 1


if __name__ == "__main__":
    raise SystemExit(main())
