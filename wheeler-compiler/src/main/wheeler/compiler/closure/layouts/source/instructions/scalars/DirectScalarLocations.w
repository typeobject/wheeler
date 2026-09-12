//! Binds scalar source locations without replacing mutable state with constant values.

module wheeler.compiler.closure.direct_scalar_locations;

import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.source_global_references;
import wheeler.compiler.closure.source_global_schema;
import wheeler.compiler.closure.structured_source_coordinates;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_identifier_ranges;

classical class DirectScalarLocations {
  /// Distinguishes a frame copy from a declaration-ordered global load.
  public record DirectScalarLocation(
    long loadOpcode,
    long operand,
    long sourceType,
    boolean valid
  ) {}

  /// Resolves one named source. Global/local shadowing remains an explicit rejection.
  public DirectScalarLocation resolveDirectScalarLocation(
    borrow utf8 source,
    long start,
    long length,
    borrow byteview globalNames,
    long globalCount,
    long globalProductStart,
    borrow mut words globals,
    long owner,
    long ordinal,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long global = sourceGlobalOrdinal(
      source,
      start,
      length,
      globalNames,
      globalCount,
      globalProductStart,
      globals
    );
    if (-1 < global) {
      long value = 0;
      while (value < valueCount) limit LOOP_VALUE_COUNT_LIMIT {
        if (valueRows[value] == owner) {
          if (
            matchesSourceIdentifier(
              source,
              valueRows[LOOP_VALUE_COUNT_LIMIT + value],
              valueRows[LOOP_VALUE_COUNT_LIMIT * 2 + value],
              globalNames,
              globals[globalProductStart + global],
              globals[globalProductStart + SOURCE_GLOBAL_LENGTH_ROW + global]
            )
          ) {
            return new DirectScalarLocation(0, 0, 0, false);
          }
        }

        value += 1;
      }

      return new DirectScalarLocation(OPCODE_LOCAL_LOAD_GLOBAL, global, TOKEN_LONG, true);
    }

    LoopBodyValue selected = resolveLoopBodyValue(
      source,
      start,
      length,
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (selected.valid == false) {
      return new DirectScalarLocation(0, 0, 0, false);
    }

    long type = loopBodyValueType(
      source,
      owner,
      selected.local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (type != TOKEN_LONG) {
      if (type != TOKEN_BOOLEAN) {
        return new DirectScalarLocation(0, 0, 0, false);
      }
    }

    long physical = physicalValueLocal(
      owner,
      selected.local,
      statementCount,
      statementRows,
      statementLocalRows,
      valueCount,
      valueRows,
      statementPhysicalStarts
    );
    if (physical < 0) {
      return new DirectScalarLocation(0, 0, 0, false);
    }

    return new DirectScalarLocation(OPCODE_LOCAL_MOVE, physical, type, true);
  }
}
