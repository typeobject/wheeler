//! Maps source ownership effects through planned statement and value coordinates.

module wheeler.compiler.closure.source_ownership_products;

classical class SourceOwnershipProducts {
  private const long COORDINATE_ROWS = 32768;
  private const long EFFECT_COUNT_LIMIT = 8192;
  private const long EFFECT_ROWS = 40960;
  private const long INSTRUCTION_OFFSET_ROW = 16384;
  private const long DESTINATION_OFFSET_ROW = 24576;
  private const long SOURCE_VALUE_ROW = 32768;
  private const long STATEMENT_COUNT_LIMIT = 4096;
  private const long STATEMENT_ROW = 8192;
  private const long VALUE_COUNT_LIMIT = 1024;

  /// Reports one complete source ownership coordinate product.
  public record SourceOwnershipPlan(long effectCount, boolean valid) {}

  private boolean validKind(long kind) {
    if (kind < 1) {
      return false;
    }

    return kind < 6;
  }

  /// Publishes planned statement, instruction, destination, and source rows atomically.
  public SourceOwnershipPlan materializeSourceOwnershipProducts(
    long effectCount,
    borrow mut words effectRows,
    borrow mut words sourceValueOffsets,
    borrow mut words statementPhysicalStarts,
    borrow mut words statementPhysicalWidths,
    borrow mut words statementInstructionStarts,
    borrow mut words valuePhysicalStarts,
    borrow mut words coordinateRows
  ) {
    assert(-1 < effectCount);
    assert(effectCount < EFFECT_COUNT_LIMIT + 1);
    assert(bufferLength(effectRows) == EFFECT_ROWS);
    assert(bufferLength(sourceValueOffsets) == EFFECT_COUNT_LIMIT);
    assert(bufferLength(statementPhysicalStarts) == STATEMENT_COUNT_LIMIT);
    assert(bufferLength(statementPhysicalWidths) == STATEMENT_COUNT_LIMIT);
    assert(bufferLength(statementInstructionStarts) == STATEMENT_COUNT_LIMIT);
    assert(bufferLength(valuePhysicalStarts) == VALUE_COUNT_LIMIT);
    assert(bufferLength(coordinateRows) == COORDINATE_ROWS);

    region staging = new region(/* bytes= */ 262144, /* allocations= */ 1);
    words stagedCoordinates = allocate(staging, COORDINATE_ROWS);
    boolean valid = true;
    long effect = 0;
    while (effect < effectCount) limit EFFECT_COUNT_LIMIT {
      long kind = effectRows[effect];
      long statement = effectRows[STATEMENT_ROW + effect];
      long instructionOffset = effectRows[INSTRUCTION_OFFSET_ROW + effect];
      long destinationOffset = effectRows[DESTINATION_OFFSET_ROW + effect];
      long sourceValue = effectRows[SOURCE_VALUE_ROW + effect];
      long sourceOffset = sourceValueOffsets[effect];
      if (validKind(kind) == false) {
        valid = false;
      }

      if (statement < 0) {
        valid = false;
      }

      if (STATEMENT_COUNT_LIMIT - 1 < statement) {
        valid = false;
      }

      if (instructionOffset < 0) {
        valid = false;
      }

      long statementStart = 0;
      long statementWidth = 0;
      long plannedInstruction = -1;
      if (-1 < statement) {
        if (statement < STATEMENT_COUNT_LIMIT) {
          statementStart = statementPhysicalStarts[statement];
          statementWidth = statementPhysicalWidths[statement];
          plannedInstruction = statementInstructionStarts[statement] + instructionOffset;
        }
      }

      if (statementStart < 0) {
        valid = false;
      }

      if (statementWidth < 0) {
        valid = false;
      }

      if (plannedInstruction < 0) {
        valid = false;
      }

      if (32767 < plannedInstruction) {
        valid = false;
      }

      long destination = -1;
      if (-1 < destinationOffset) {
        if (statementWidth - 1 < destinationOffset) {
          valid = false;
        } else {
          destination = statementStart + destinationOffset;
          if (255 < destination) {
            valid = false;
          }
        }
      }

      long source = -1;
      if (-1 < sourceValue) {
        if (VALUE_COUNT_LIMIT - 1 < sourceValue) {
          valid = false;
        } else {
          if (sourceOffset < 0) {
            valid = false;
          }

          if (255 < sourceOffset) {
            valid = false;
          }

          source = valuePhysicalStarts[sourceValue] + sourceOffset;
          if (255 < source) {
            valid = false;
          }
        }
      }

      if (kind == 5) {
        if (destination < 0) {
          valid = false;
        }

        if (-1 < source) {
          valid = false;
        }
      }

      if (kind == 4) {
        if (-1 < destination) {
          valid = false;
        }

        if (source < 0) {
          valid = false;
        }
      }

      if (kind < 4) {
        if (destination < 0) {
          valid = false;
        }

        if (source < 0) {
          valid = false;
        }
      }

      set(stagedCoordinates, effect, statement);
      set(stagedCoordinates, 8192 + effect, plannedInstruction);
      set(stagedCoordinates, 16384 + effect, destination);
      set(stagedCoordinates, 24576 + effect, source);
      effect += 1;
    }

    if (valid == false) {
      drop(stagedCoordinates);
      drop(staging);
      return new SourceOwnershipPlan(0, false);
    }

    long column = 0;
    while (column < 4) limit 4 {
      long row = 0;
      while (row < effectCount) limit EFFECT_COUNT_LIMIT {
        set(
          coordinateRows,
          column * EFFECT_COUNT_LIMIT + row,
          stagedCoordinates[column * EFFECT_COUNT_LIMIT + row]
        );
        row += 1;
      }

      column += 1;
    }

    drop(stagedCoordinates);
    drop(staging);
    return new SourceOwnershipPlan(effectCount, true);
  }
}
