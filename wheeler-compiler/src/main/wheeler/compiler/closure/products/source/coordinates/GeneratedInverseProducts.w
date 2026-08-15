//! Generates inverse instruction windows from source-ordered callable coordinates.

module wheeler.compiler.closure.generated_inverse_products;

import wheeler.compiler.closure.generated_inverse_relocations;
import wheeler.compiler.opcodes;
import wheeler.core.encoding.binary;

classical class GeneratedInverseProducts {
  private const long CALLABLE_CODE_LENGTH_ROW = 192;
  private const long CALLABLE_CODE_START_ROW = 128;
  private const long CALLABLE_INSTRUCTION_COUNT_ROW = 64;
  private const long CALLABLE_ROWS = 320;
  private const long INVERSE_CODE_LENGTH_ROW = 64;
  private const long INVERSE_INSTRUCTION_COUNT_ROW = 128;
  private const long INVERSE_ROWS = 192;
  private const long MAX_CALLABLES = 64;
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_INSTRUCTIONS = 32768;

  /// Reports complete generated inverse instruction and byte extents.
  public record GeneratedInversePlan(
    long callableCount,
    long instructionCount,
    long codeLength,
    boolean valid
  ) {}

  /// Returns the sole generated inverse opcode for the admitted reversible profile.
  public long inverseGeneratedOpcode(long opcode) {
    if (opcode == OPCODE_ADD_CONST) {
      return OPCODE_SUB_CONST;
    }

    if (opcode == OPCODE_SUB_CONST) {
      return OPCODE_ADD_CONST;
    }

    if (opcode == OPCODE_XOR_CONST) {
      return OPCODE_XOR_CONST;
    }

    if (opcode == OPCODE_CALL) {
      return OPCODE_UNCALL;
    }

    if (opcode == OPCODE_UNCALL) {
      return OPCODE_CALL;
    }

    if (opcode == OPCODE_EXPECT_EQ) {
      return OPCODE_EXPECT_EQ;
    }

    if (opcode == OPCODE_EXPECT_TRUE) {
      return OPCODE_EXPECT_TRUE;
    }

    if (opcode == OPCODE_RESULT_FILL_CONSTANT) {
      return OPCODE_RESULT_FILL_CONSTANT;
    }

    if (opcode == OPCODE_RESULT_FILL_SOURCE) {
      return OPCODE_RESULT_FILL_SOURCE;
    }

    if (opcode == OPCODE_RESULT_FILL_BINARY) {
      return OPCODE_RESULT_FILL_BINARY;
    }

    if (opcode == OPCODE_RESULT_FILL_BINARY_SOURCES) {
      return OPCODE_RESULT_FILL_BINARY_SOURCES;
    }

    return -1;
  }

  private boolean terminalOpcode(long opcode) {
    if (opcode == OPCODE_RETURN) {
      return true;
    }

    return opcode == OPCODE_RETURN_RESULT_SLOT;
  }

  private void writeOpcode(long opcode, borrow mut bytes output, long start) {
    setByte(output, start, opcode % 256);
    setByte(output, start + 1, opcode / 256);
  }

  private void copyInstruction(
    borrow byteview forwardCode,
    long forwardStart,
    long length,
    borrow mut bytes inverseCode,
    long inverseStart
  ) {
    long instructionByte = 0;
    while (instructionByte < length) limit 520 {
      setByte(
        inverseCode,
        inverseStart + instructionByte,
        forwardCode[forwardStart + instructionByte]
      );
      instructionByte += 1;
    }
  }

  /// Reverses each callable window without deriving another local or type coordinate.
  public GeneratedInversePlan materializeGeneratedInverseProducts(
    long callableCount,
    borrow mut words callableRows,
    borrow byteview forwardCode,
    long forwardCodeLength,
    borrow mut words inverseRows,
    borrow mut bytes inverseCode
  ) {
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(callableRows) == CALLABLE_ROWS);
    assert(-1 < forwardCodeLength);
    assert(forwardCodeLength < MAX_CODE_BYTES + 1);
    assert(forwardCodeLength < bufferLength(forwardCode) + 1);
    assert(bufferLength(inverseRows) == INVERSE_ROWS);
    assert(bufferLength(inverseCode) == MAX_CODE_BYTES);

    region staging = new region(/* bytes= */ 525824, /* allocations= */ 3);
    words instructionStarts = allocate(staging, MAX_INSTRUCTIONS);
    words stagedRows = allocate(staging, INVERSE_ROWS);
    bytes stagedCode = allocateBytes(staging, MAX_CODE_BYTES);
    boolean valid = true;
    long expectedCodeStart = 0;
    long instructionBase = 0;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long codeStart = callableRows[CALLABLE_CODE_START_ROW + callable];
      long codeLength = callableRows[CALLABLE_CODE_LENGTH_ROW + callable];
      long expectedInstructionCount = callableRows[CALLABLE_INSTRUCTION_COUNT_ROW + callable];
      if (codeStart != expectedCodeStart) {
        valid = false;
      }

      if (codeLength < 8) {
        valid = false;
      }

      if (codeStart < 0) {
        valid = false;
      }

      if (forwardCodeLength < codeStart) {
        valid = false;
      }

      if (valid) {
        if (forwardCodeLength - codeStart < codeLength) {
          valid = false;
        }
      }

      if (expectedInstructionCount < 1) {
        valid = false;
      }

      if (MAX_INSTRUCTIONS - instructionBase < expectedInstructionCount) {
        valid = false;
      }

      long cursor = codeStart;
      long end = codeStart + codeLength;
      long instructionCount = 0;
      if (valid) {
        while (cursor < end) limit MAX_INSTRUCTIONS {
          if (end - cursor < 8) {
            valid = false;
            cursor = end;
          } else {
            long instructionLength = readUnsigned(forwardCode, cursor + 4, 4);
            if (instructionLength < 8) {
              valid = false;
              cursor = end;
            } else {
              if (end - cursor < instructionLength) {
                valid = false;
                cursor = end;
              } else {
                if (519 < instructionLength) {
                  valid = false;
                  cursor = end;
                } else {
                  if (MAX_INSTRUCTIONS - instructionBase < instructionCount + 1) {
                    valid = false;
                    cursor = end;
                  } else {
                    set(instructionStarts, instructionBase + instructionCount, cursor);
                    instructionCount += 1;
                    cursor += instructionLength;
                  }
                }
              }
            }
          }
        }
      }

      if (cursor != end) {
        valid = false;
      }

      if (instructionCount != expectedInstructionCount) {
        valid = false;
      }

      if (valid) {
        long terminal = instructionStarts[instructionBase + instructionCount - 1];
        if (terminalOpcode(readUnsigned(forwardCode, terminal, 2)) == false) {
          valid = false;
        }

        long reversible = 0;
        while (reversible < instructionCount - 1) limit MAX_INSTRUCTIONS {
          long selected = instructionStarts[instructionBase + reversible];
          if (inverseGeneratedOpcode(readUnsigned(forwardCode, selected, 2)) < 0) {
            valid = false;
          }

          reversible += 1;
        }
      }

      set(stagedRows, callable, expectedCodeStart);
      set(stagedRows, INVERSE_CODE_LENGTH_ROW + callable, codeLength);
      set(stagedRows, INVERSE_INSTRUCTION_COUNT_ROW + callable, expectedInstructionCount);
      expectedCodeStart += codeLength;
      instructionBase += instructionCount;
      callable += 1;
    }

    if (expectedCodeStart != forwardCodeLength) {
      valid = false;
    }

    long inverseCursor = 0;
    long forwardInstructionBase = 0;
    if (valid) {
      callable = 0;
      while (callable < callableCount) limit MAX_CALLABLES {
        long callableInstructionCount = callableRows[CALLABLE_INSTRUCTION_COUNT_ROW + callable];
        long inverseInstruction = 0;
        while (inverseInstruction < callableInstructionCount - 1) limit MAX_INSTRUCTIONS {
          long forwardInstruction = callableInstructionCount - 2 - inverseInstruction;
          long forwardStart = instructionStarts[forwardInstructionBase + forwardInstruction];
          long emittedLength = readUnsigned(forwardCode, forwardStart + 4, 4);
          copyInstruction(forwardCode, forwardStart, emittedLength, stagedCode, inverseCursor);
          writeOpcode(
            inverseGeneratedOpcode(readUnsigned(forwardCode, forwardStart, 2)),
            stagedCode,
            inverseCursor
          );
          inverseCursor += emittedLength;
          inverseInstruction += 1;
        }

        long terminalStart = instructionStarts[forwardInstructionBase + callableInstructionCount
          - 1];
        long terminalLength = readUnsigned(forwardCode, terminalStart + 4, 4);
        copyInstruction(forwardCode, terminalStart, terminalLength, stagedCode, inverseCursor);
        inverseCursor += terminalLength;
        forwardInstructionBase += callableInstructionCount;
        callable += 1;
      }
    }

    if (inverseCursor != forwardCodeLength) {
      valid = false;
    }

    if (valid) {
      long row = 0;
      while (row < INVERSE_ROWS) limit INVERSE_ROWS {
        set(inverseRows, row, stagedRows[row]);
        row += 1;
      }

      long codeByte = 0;
      while (codeByte < forwardCodeLength) limit MAX_CODE_BYTES {
        setByte(inverseCode, codeByte, stagedCode[codeByte]);
        codeByte += 1;
      }
    }

    drop(stagedCode);
    drop(stagedRows);
    drop(instructionStarts);
    drop(staging);
    if (valid == false) {
      return new GeneratedInversePlan(0, 0, 0, false);
    }

    return new GeneratedInversePlan(callableCount, instructionBase, inverseCursor, true);
  }
}
