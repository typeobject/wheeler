//! Resolves exact statement, loop, call, and physical-value coordinates.

module wheeler.compiler.closure.structured_source_coordinates;

import wheeler.compiler.closure.loop_body_layouts;

classical class StructuredSourceCoordinates {
  private const long MAX_STATEMENTS = 4096;

  /// Returns the sole call owned by a statement, or minus one.
  public long callAtStatement(long statement, long callCount, borrow mut words callStatements) {
    long selected = -1;
    long matches = 0;
    long call = 0;
    while (call < callCount) limit 256 {
      if (callStatements[call] == statement) {
        selected = call;
        matches += 1;
      }

      call += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  /// Returns the sole child-owning statement at one source ordinal.
  public long statementAtLoop(
    long owner,
    long ordinal,
    long statementCount,
    borrow mut words statementRows
  ) {
    long selected = -1;
    long matches = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      if (statementRows[statement] == owner) {
        if (statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement] == ordinal) {
          if (0 < statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + statement]) {
            selected = statement;
            matches += 1;
          }
        }
      }

      statement += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  /// Returns the sole statement at one owner-local source ordinal.
  public long statementAtOrdinal(
    long owner,
    long ordinal,
    long statementCount,
    borrow mut words statementRows
  ) {
    long selected = -1;
    long matches = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      if (statementRows[statement] == owner) {
        if (statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement] == ordinal) {
          selected = statement;
          matches += 1;
        }
      }

      statement += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  /// Maps one exact logical value product onto its planned physical local.
  public long physicalValueLocal(
    long owner,
    long local,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementLocalRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words statementPhysicalStarts
  ) {
    long selected = -1;
    long matches = 0;
    long value = 0;
    while (value < valueCount) limit 1024 {
      if (valueRows[value] == owner) {
        if (valueRows[3072 + value] == local) {
          selected = value;
          matches += 1;
        }
      }

      value += 1;
    }

    if (matches != 1) {
      return -1;
    }

    long ordinal = valueRows[4096 + selected];
    if (ordinal == 0) {
      return local;
    }

    long statement = statementAtOrdinal(owner, ordinal, statementCount, statementRows);
    if (statement < 0) {
      return -1;
    }

    long logicalBase = statementLocalRows[statement];
    if (local < logicalBase) {
      return -1;
    }

    return statementPhysicalStarts[statement] + local - logicalBase;
  }
}
