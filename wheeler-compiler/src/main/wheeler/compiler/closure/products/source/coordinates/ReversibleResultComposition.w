//! Rewrites reversible result returns into explicit presence-slot products.

module wheeler.compiler.closure.reversible_result_composition;

import wheeler.compiler.opcodes;
import wheeler.compiler.type_codes;
import wheeler.core.encoding.binary;

classical class ReversibleResultComposition {
  private const long CALLABLE_ROWS = 320;
  private const long MAX_CALLABLES = 64;
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_LOCAL_TYPES = 4096;
  private const long TYPE_ROWS = 12288;

  /// Reports one complete reversible result-slot composition.
  public record ReversibleResultCompositionPlan(long typeCount, boolean valid) {}

  private void writeOpcode(long opcode, borrow mut bytes code, long start) {
    setByte(code, start, opcode % 256);
    setByte(code, start + 1, opcode / 256);
  }

  /// Replaces terminal value returns and inserts exact presence and payload local types.
  public ReversibleResultCompositionPlan materializeReversibleResultCompositionProducts(
    long callableCount,
    borrow mut words functionResultTypes,
    borrow mut words composedCallables,
    borrow mut words composedTypes,
    long typeCount,
    borrow mut bytes composedCode,
    long codeLength
  ) {
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(functionResultTypes) == MAX_CALLABLES);
    assert(bufferLength(composedCallables) == CALLABLE_ROWS);
    assert(bufferLength(composedTypes) == TYPE_ROWS);
    assert(-1 < typeCount);
    assert(typeCount < MAX_LOCAL_TYPES + 1);
    assert(bufferLength(composedCode) == MAX_CODE_BYTES);
    assert(-1 < codeLength);
    assert(codeLength < MAX_CODE_BYTES + 1);

    region staging = new region(/* bytes= */ 100352, /* allocations= */ 5);
    words stagedTypes = allocate(staging, TYPE_ROWS);
    words moveStarts = allocate(staging, MAX_CALLABLES);
    words returnStarts = allocate(staging, MAX_CALLABLES);
    words returnLocals = allocate(staging, MAX_CALLABLES);
    words readyRelations = allocate(staging, MAX_CALLABLES);
    boolean valid = true;
    long resultCallableCount = 0;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long resultType = functionResultTypes[callable];
      boolean resultTypeValid = resultType == 0;
      if (resultType == TYPE_SIGNED) {
        resultTypeValid = true;
      }

      if (resultType == TYPE_BOOLEAN) {
        resultTypeValid = true;
      }

      if (resultTypeValid == false) {
        valid = false;
      }

      long codeStart = composedCallables[callable];
      long codeExtent = composedCallables[64 + callable];
      long instructionCount = composedCallables[128 + callable];
      long localTypeStart = composedCallables[192 + callable];
      long localCount = composedCallables[256 + callable];
      if (codeStart < 0) {
        valid = false;
      }

      if (codeExtent < 8) {
        valid = false;
      }

      if (instructionCount < 1) {
        valid = false;
      }

      if (codeLength < codeStart + codeExtent) {
        valid = false;
      }

      if (localTypeStart < 0) {
        valid = false;
      }

      if (localCount < 0) {
        valid = false;
      }

      if (typeCount < localTypeStart + localCount) {
        valid = false;
      }

      long cursor = codeStart;
      long instruction = 0;
      long previousStart = -1;
      long terminalStart = -1;
      while (instruction < instructionCount) limit 32768 {
        if (codeStart + codeExtent - cursor < 8) {
          valid = false;
          break;
        }

        long instructionLength = readUnsigned(composedCode, cursor + 4, 4);
        if (instructionLength < 8) {
          valid = false;
          break;
        }

        if (codeStart + codeExtent < cursor + instructionLength) {
          valid = false;
          break;
        }

        previousStart = terminalStart;
        terminalStart = cursor;
        cursor += instructionLength;
        instruction += 1;
      }

      if (cursor != codeStart + codeExtent) {
        valid = false;
      }

      if (resultType == 0) {
        if (readUnsigned(composedCode, terminalStart, 2) != OPCODE_RETURN) {
          valid = false;
        }
      } else {
        resultCallableCount += 1;
        if (instructionCount < 2) {
          valid = false;
        }

        if (previousStart < codeStart) {
          valid = false;
        }

        long relationOpcode = readUnsigned(composedCode, previousStart, 2);
        long terminalOpcode = readUnsigned(composedCode, terminalStart, 2);
        boolean readyRelation = terminalOpcode == OPCODE_RETURN_RESULT_SLOT;
        if (readyRelation) {
          boolean relationOpcodeValid = relationOpcode == OPCODE_RESULT_FILL_SOURCE;
          if (relationOpcode == OPCODE_RESULT_FILL_CONSTANT) {
            relationOpcodeValid = true;
          }

          if (resultType == TYPE_SIGNED) {
            if (relationOpcode == OPCODE_RESULT_FILL_BINARY) {
              relationOpcodeValid = true;
            }

            if (relationOpcode == OPCODE_RESULT_FILL_BINARY_SOURCES) {
              relationOpcodeValid = true;
            }
          }

          if (relationOpcodeValid == false) {
            valid = false;
          }
        } else {
          if (relationOpcode != OPCODE_LOCAL_MOVE) {
            valid = false;
          }

          if (readUnsigned(composedCode, previousStart + 2, 2) != 2) {
            valid = false;
          }

          if (readUnsigned(composedCode, previousStart + 4, 4) != 24) {
            valid = false;
          }

          if (terminalOpcode != OPCODE_RETURN_VALUE) {
            valid = false;
          }
        }

        if (readUnsigned(composedCode, terminalStart + 2, 2) != 1) {
          valid = false;
        }

        if (readUnsigned(composedCode, terminalStart + 4, 4) != 16) {
          valid = false;
        }

        long returnLocal = readUnsigned(composedCode, terminalStart + 8, 8);
        if (returnLocal + 1 != localCount) {
          valid = false;
        }

        if (readUnsigned(composedCode, previousStart + 8, 8) != returnLocal) {
          valid = false;
        }

        if (readyRelation) {
          set(readyRelations, callable, 1);
        }

        if (valid) {
          long returnTypeRow = localTypeStart + returnLocal;
          if (composedTypes[returnTypeRow] != callable) {
            valid = false;
          }

          if (composedTypes[4096 + returnTypeRow] != returnLocal) {
            valid = false;
          }

          if (composedTypes[8192 + returnTypeRow] != resultType) {
            valid = false;
          }
        }

        set(moveStarts, callable, previousStart);
        set(returnStarts, callable, terminalStart);
        set(returnLocals, callable, returnLocal);
      }

      callable += 1;
    }

    long stagedTypeCount = typeCount + resultCallableCount;
    if (MAX_LOCAL_TYPES < stagedTypeCount) {
      valid = false;
    }

    long stagedType = 0;
    callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long rebuildTypeStart = composedCallables[192 + callable];
      long rebuildLocalCount = composedCallables[256 + callable];
      long rebuildResultType = functionResultTypes[callable];
      long local = 0;
      while (local < rebuildLocalCount) limit 256 {
        long sourceType = rebuildTypeStart + local;
        if (composedTypes[sourceType] != callable) {
          valid = false;
        }

        if (composedTypes[4096 + sourceType] != local) {
          valid = false;
        }

        set(stagedTypes, stagedType, callable);
        set(stagedTypes, 4096 + stagedType, local);
        long type = composedTypes[8192 + sourceType];
        if (0 < rebuildResultType) {
          if (local == returnLocals[callable]) {
            type = TYPE_BOOLEAN;
          }
        }

        set(stagedTypes, 8192 + stagedType, type);
        stagedType += 1;
        local += 1;
      }

      if (0 < rebuildResultType) {
        set(stagedTypes, stagedType, callable);
        set(stagedTypes, 4096 + stagedType, rebuildLocalCount);
        set(stagedTypes, 8192 + stagedType, rebuildResultType);
        stagedType += 1;
      }

      callable += 1;
    }

    if (stagedType != stagedTypeCount) {
      valid = false;
    }

    if (valid) {
      long column = 0;
      while (column < 3) limit 3 {
        long publishedType = 0;
        while (publishedType < stagedTypeCount) limit MAX_LOCAL_TYPES {
          set(
            composedTypes,
            column * MAX_LOCAL_TYPES + publishedType,
            stagedTypes[column * MAX_LOCAL_TYPES + publishedType]
          );
          publishedType += 1;
        }

        column += 1;
      }

      long publishedTypeStart = 0;
      callable = 0;
      while (callable < callableCount) limit MAX_CALLABLES {
        set(composedCallables, 192 + callable, publishedTypeStart);
        long publishedLocalCount = composedCallables[256 + callable];
        if (0 < functionResultTypes[callable]) {
          set(composedCallables, 256 + callable, publishedLocalCount + 1);
          if (readyRelations[callable] == 0) {
            writeOpcode(OPCODE_RESULT_FILL_SOURCE, composedCode, moveStarts[callable]);
            writeOpcode(OPCODE_RETURN_RESULT_SLOT, composedCode, returnStarts[callable]);
          }

          publishedTypeStart += publishedLocalCount + 1;
        } else {
          publishedTypeStart += publishedLocalCount;
        }

        callable += 1;
      }
    } else {
      stagedTypeCount = 0;
    }

    drop(readyRelations);
    drop(returnLocals);
    drop(returnStarts);
    drop(moveStarts);
    drop(stagedTypes);
    drop(staging);
    return new ReversibleResultCompositionPlan(stagedTypeCount, valid);
  }
}
