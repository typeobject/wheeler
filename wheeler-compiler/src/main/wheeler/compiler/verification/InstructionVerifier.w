//! Verifies bounded instruction streams, operands, local types, and branch targets.
module wheeler.compiler.instruction_verifier;

import wheeler.compiler.aggregate_verifier;
import wheeler.compiler.instruction_forms;
import wheeler.compiler.opcode_kinds;
import wheeler.compiler.opcodes;
import wheeler.compiler.result_slot_verifier;
import wheeler.compiler.storage_opcodes;
import wheeler.compiler.storage_verifier;
import wheeler.compiler.type_codes;
import wheeler.core.encoding.binary;

classical class InstructionVerifier {
  private boolean differs(long left, long right) {
    if (left < right) {
      return true;
    }

    return right < left;
  }

  private long localType(borrow byteview artifact, long activeTypes, long local) {
    return readUnsigned(artifact, activeTypes + local * 4, 4);
  }

  private boolean localHasType(
    borrow byteview artifact,
    long activeTypes,
    long local,
    long expected
  ) {
    return localType(artifact, activeTypes, local) == expected;
  }

  private long descriptorBase(long functionsOffset, long function) {
    return functionsOffset + 4 + function * 40;
  }

  private boolean resultSlotDisjoint(long base, long count, long slot) {
    if (count == 0) {
      return true;
    }

    long argumentEnd = base + count;
    if (argumentEnd < slot) {
      return true;
    }

    if (argumentEnd == slot) {
      return true;
    }

    long slotEnd = slot + 2;
    if (slotEnd < base) {
      return true;
    }

    return slotEnd == base;
  }

  private boolean functionHasFlag(
    borrow byteview artifact,
    long functionsOffset,
    long function,
    long flag
  ) {
    long flags = readUnsigned(artifact, descriptorBase(functionsOffset, function) + 8, 4);
    return(flags & flag) == flag;
  }

  private long functionParameterCount(
    borrow byteview artifact,
    long functionsOffset,
    long function
  ) {
    return readUnsigned(artifact, descriptorBase(functionsOffset, function) + 28, 4);
  }

  private long functionTypeStart(
    borrow byteview artifact,
    long functionsOffset,
    long functionCount,
    long function
  ) {
    long descriptor = descriptorBase(functionsOffset, function);
    long typeOffset = readUnsigned(artifact, descriptor + 36, 4);
    long start = functionsOffset + 4 + functionCount * 40 + typeOffset * 4;
    if (functionHasFlag(artifact, functionsOffset, function, 4)) {
      start += 4;
    }

    return start;
  }

  private long functionResultType(
    borrow byteview artifact,
    long functionsOffset,
    long functionCount,
    long function
  ) {
    long descriptor = descriptorBase(functionsOffset, function);
    long typeOffset = readUnsigned(artifact, descriptor + 36, 4);
    return readUnsigned(artifact, functionsOffset + 4 + functionCount * 40 + typeOffset * 4, 4);
  }

  private long callArgumentsValid(
    borrow byteview artifact,
    long functionsOffset,
    long functionCount,
    long activeTypes,
    long localCount,
    long target,
    long argumentBase,
    long argumentCount
  ) {
    if (target < functionCount) {} else {
      return 0;
    }

    if (
      differs(argumentCount, functionParameterCount(artifact, functionsOffset, target))
    ) {
      return 0;
    }

    if (localCount < argumentBase + argumentCount) {
      return 0;
    }

    long targetTypes = functionTypeStart(artifact, functionsOffset, functionCount, target);
    long argument = 0;
    while (argument < argumentCount) limit INTERPRETER_LOCAL_WIDTH {
      if (
        differs(
          localType(artifact, activeTypes, argumentBase + argument),
          localType(artifact, targetTypes, argument)
        )
      ) {
        return 0;
      }

      argument += 1;
    }

    return 1;
  }

  private long instructionCount(borrow byteview artifact, long start, long end) {
    long cursor = start;
    long count = 0;
    while (cursor < end) limit MAX_CODE_INSTRUCTIONS {
      if (end - cursor < 8) {
        return -1;
      }

      long length = readUnsigned(artifact, cursor + 4, 4);
      if (length < 8) {
        return -1;
      }

      if (end < cursor + length) {
        return -1;
      }

      cursor += length;
      count += 1;
    }

    if (differs(cursor, end)) {
      return -1;
    }

    return count;
  }

  private long instructionOperandsValid(
    borrow byteview artifact,
    long cursor,
    long opcode,
    long typesOffset,
    long variantsOffset,
    long globalCount,
    long recordCount,
    long variantCount,
    long arrayCount,
    long sliceCount,
    long functionCount,
    long localCount,
    long activeStart,
    long activeEnd,
    long activeTypes,
    long activeResultType,
    long activeResultSlot,
    long functionsOffset
  ) {
    if (opcode == OPCODE_HALT) {
      return 1;
    }

    if (opcode == OPCODE_RETURN) {
      return 1;
    }

    long first = readUnsigned(artifact, cursor + 8, 8);
    if (opcode < OPCODE_RECORD_NEW) {} else {
      if (OPCODE_SLICE_GET < opcode) {} else {
        long aggregateValid = aggregateOperandsValid(
          artifact,
          cursor,
          opcode,
          typesOffset,
          variantsOffset,
          globalCount,
          recordCount,
          variantCount,
          arrayCount,
          sliceCount,
          localCount,
          activeTypes
        );
        return aggregateValid;
      }
    }

    if (opcode < OPCODE_OWNED_MOVE) {} else {
      if (OPCODE_REGION_BORROW < opcode) {} else {
        long storageValid = storageOperandsValid(
          artifact,
          cursor,
          opcode,
          localCount,
          activeTypes
        );
        return storageValid;
      }
    }

    if (isGlobalConstantOpcode(opcode)) {
      if (first < globalCount) {
        return 1;
      }

      return 0;
    }

    if (opcode == OPCODE_RETURN_VALUE) {
      if (first < localCount) {
        if (localType(artifact, activeTypes, first) == activeResultType) {
          return 1;
        }
      }

      return 0;
    }

    if (opcode == OPCODE_CALL) {
      if (first < functionCount - 1) {
        if (functionParameterCount(artifact, functionsOffset, first) == 0) {
          if (functionHasFlag(artifact, functionsOffset, first, 4)) {} else {
            return 1;
          }
        }
      }

      return 0;
    }

    if (opcode == OPCODE_UNCALL) {
      if (first < functionCount - 1) {
        if (functionParameterCount(artifact, functionsOffset, first) == 0) {
          if (functionHasFlag(artifact, functionsOffset, first, 1)) {
            if (functionHasFlag(artifact, functionsOffset, first, 4)) {} else {
              return 1;
            }
          }
        }
      }

      return 0;
    }

    if (opcode == OPCODE_CALL_VALUE) {
      long valueArgumentBase = readUnsigned(artifact, cursor + 16, 8);
      long valueArgumentCount = readUnsigned(artifact, cursor + 24, 8);
      long valueDestination = readUnsigned(artifact, cursor + 32, 8);
      if (first < functionCount - 1) {
        if (valueDestination < localCount) {
          if (functionHasFlag(artifact, functionsOffset, first, 4)) {
            if (
              localType(artifact, activeTypes, valueDestination) == functionResultType(
                artifact,
                functionsOffset,
                functionCount,
                first
              )
            ) {
              return callArgumentsValid(
                artifact,
                functionsOffset,
                functionCount,
                activeTypes,
                localCount,
                first,
                valueArgumentBase,
                valueArgumentCount
              );
            }
          }
        }
      }

      return 0;
    }

    if (opcode == OPCODE_CALL_VOID) {
      long voidArgumentBase = readUnsigned(artifact, cursor + 16, 8);
      long voidArgumentCount = readUnsigned(artifact, cursor + 24, 8);
      if (first < functionCount - 1) {
        if (functionHasFlag(artifact, functionsOffset, first, 4)) {} else {
          return callArgumentsValid(
            artifact,
            functionsOffset,
            functionCount,
            activeTypes,
            localCount,
            first,
            voidArgumentBase,
            voidArgumentCount
          );
        }
      }

      return 0;
    }

    boolean resultSlotCall = opcode == OPCODE_CALL_RESULT_SLOT;
    if (opcode == OPCODE_UNCALL_RESULT_SLOT) {
      resultSlotCall = true;
    }

    if (resultSlotCall) {
      long slotArgumentBase = readUnsigned(artifact, cursor + 16, 8);
      long slotArgumentCount = readUnsigned(artifact, cursor + 24, 8);
      long resultSlot = readUnsigned(artifact, cursor + 32, 8);
      if (first < functionCount - 1) {
        if (resultSlot + 1 < localCount) {
          if (resultSlotDisjoint(slotArgumentBase, slotArgumentCount, resultSlot)) {} else {
            return 0;
          }

          if (functionHasFlag(artifact, functionsOffset, first, 13)) {
            if (localType(artifact, activeTypes, resultSlot) == TYPE_BOOLEAN) {
              if (
                localType(artifact, activeTypes, resultSlot + 1) == functionResultType(
                  artifact,
                  functionsOffset,
                  functionCount,
                  first
                )
              ) {
                return callArgumentsValid(
                  artifact,
                  functionsOffset,
                  functionCount,
                  activeTypes,
                  localCount,
                  first,
                  slotArgumentBase,
                  slotArgumentCount
                );
              }
            }
          }
        }
      }

      return 0;
    }

    if (opcode < OPCODE_RESULT_FILL_CONSTANT) {} else {
      if (OPCODE_RESULT_FILL_BINARY_SOURCES < opcode) {} else {
        if (resultSlotBodyValid(activeResultSlot)) {} else {
          return 0;
        }

        if (activeResultType == TYPE_SIGNED) {} else {
          return 0;
        }

        if (1 < localCount) {} else {
          return 0;
        }

        long expectedResultSlot = localCount - 2;
        long verifiedResultSlot = resultSlotOperand(artifact, cursor);
        if (verifiedResultSlot == first) {} else {
          return 0;
        }

        if (verifiedResultSlot == expectedResultSlot) {} else {
          return 0;
        }

        if (localHasType(artifact, activeTypes, verifiedResultSlot, TYPE_BOOLEAN)) {} else {
          return 0;
        }

        long payloadSlot = verifiedResultSlot + 1;
        if (localHasType(artifact, activeTypes, payloadSlot, TYPE_SIGNED)) {} else {
          return 0;
        }

        if (opcode == OPCODE_RETURN_RESULT_SLOT) {
          return 1;
        }

        if (opcode == OPCODE_RESULT_FILL_CONSTANT) {
          return 1;
        }

        long verifiedSource = resultSlotSourceOperand(artifact, cursor);
        if (resultSlotSourcePrecedes(verifiedResultSlot, verifiedSource)) {} else {
          return 0;
        }

        if (localHasType(artifact, activeTypes, verifiedSource, TYPE_SIGNED)) {} else {
          return 0;
        }

        if (opcode == OPCODE_RESULT_FILL_SOURCE) {
          return 1;
        }

        long operation = resultSlotOperationOperand(artifact, cursor);
        if (operation < OPCODE_LOCAL_ADD) {
          return 0;
        }

        if (OPCODE_LOCAL_AND < operation) {
          return 0;
        }

        if (opcode == OPCODE_RESULT_FILL_BINARY) {
          return 1;
        }

        long rightSource = resultSlotRightSourceOperand(artifact, cursor);
        if (resultSlotSourcePrecedes(verifiedResultSlot, rightSource)) {} else {
          return 0;
        }

        if (localHasType(artifact, activeTypes, rightSource, TYPE_SIGNED)) {
          return 1;
        }

        return 0;
      }
    }

    if (opcode == OPCODE_EXPECT_EQ) {
      if (first < globalCount) {
        return 1;
      }

      return 0;
    }

    if (opcode == OPCODE_EXPECT_TRUE) {
      if (first < localCount) {
        if (localHasType(artifact, activeTypes, first, TYPE_BOOLEAN)) {
          return 1;
        }
      }

      return 0;
    }

    if (opcode == OPCODE_LOCAL_CONST) {
      if (first < localCount) {
        long destinationType = localType(artifact, activeTypes, first);
        if (destinationType == TYPE_SIGNED) {
          return 1;
        }

        if (destinationType == TYPE_BOOLEAN) {
          if (readUnsigned(artifact, cursor + 16, 8) < 2) {
            return 1;
          }
        }

        if (destinationType == TYPE_DONE) {
          if (readUnsigned(artifact, cursor + 16, 8) == 0) {
            return 1;
          }
        }
      }

      return 0;
    }

    if (opcode == OPCODE_LOCAL_LOAD_GLOBAL) {
      long global = readUnsigned(artifact, cursor + 16, 8);
      if (first < localCount) {
        if (global < globalCount) {
          if (localHasType(artifact, activeTypes, first, TYPE_SIGNED)) {
            return 1;
          }
        }
      }

      return 0;
    }

    if (opcode == OPCODE_LOCAL_STORE_GLOBAL) {
      long local = readUnsigned(artifact, cursor + 16, 8);
      if (first < globalCount) {
        if (local < localCount) {
          if (localHasType(artifact, activeTypes, local, TYPE_SIGNED)) {
            return 1;
          }
        }
      }

      return 0;
    }

    if (opcode == OPCODE_LOCAL_MOVE) {
      long source = readUnsigned(artifact, cursor + 16, 8);
      if (first < localCount) {
        if (source < localCount) {
          if (
            localType(artifact, activeTypes, first) == localType(artifact, activeTypes, source)
          ) {
            return 1;
          }
        }
      }

      return 0;
    }

    if (isLocalMathOpcode(opcode)) {
      long left = readUnsigned(artifact, cursor + 16, 8);
      long right = readUnsigned(artifact, cursor + 24, 8);
      if (first < localCount) {
        if (left < localCount) {
          if (right < localCount) {
            long mathDestinationType = localType(artifact, activeTypes, first);
            if (opcode == OPCODE_LOCAL_XOR) {
              if (mathDestinationType == TYPE_SIGNED) {
                if (localHasType(artifact, activeTypes, left, TYPE_SIGNED)) {
                  if (localHasType(artifact, activeTypes, right, TYPE_SIGNED)) {
                    return 1;
                  }
                }
              }

              if (mathDestinationType == TYPE_BOOLEAN) {
                if (localHasType(artifact, activeTypes, left, TYPE_BOOLEAN)) {
                  if (localHasType(artifact, activeTypes, right, TYPE_BOOLEAN)) {
                    return 1;
                  }
                }
              }
            } else {
              if (mathDestinationType == TYPE_SIGNED) {
                if (localHasType(artifact, activeTypes, left, TYPE_SIGNED)) {
                  if (localHasType(artifact, activeTypes, right, TYPE_SIGNED)) {
                    return 1;
                  }
                }
              }
            }
          }
        }
      }

      return 0;
    }

    if (opcode == OPCODE_LOCAL_EQ) {
      long equalityLeft = readUnsigned(artifact, cursor + 16, 8);
      long equalityRight = readUnsigned(artifact, cursor + 24, 8);
      if (first < localCount) {
        if (equalityLeft < localCount) {
          if (equalityRight < localCount) {
            if (localHasType(artifact, activeTypes, first, TYPE_BOOLEAN)) {
              if (
                localType(artifact, activeTypes, equalityLeft) == localType(
                  artifact,
                  activeTypes,
                  equalityRight
                )
              ) {
                return 1;
              }
            }
          }
        }
      }

      return 0;
    }

    if (opcode == OPCODE_LOCAL_LT) {
      long lessLeft = readUnsigned(artifact, cursor + 16, 8);
      long lessRight = readUnsigned(artifact, cursor + 24, 8);
      if (first < localCount) {
        if (lessLeft < localCount) {
          if (lessRight < localCount) {
            if (localHasType(artifact, activeTypes, first, TYPE_BOOLEAN)) {
              if (localHasType(artifact, activeTypes, lessLeft, TYPE_SIGNED)) {
                if (localHasType(artifact, activeTypes, lessRight, TYPE_SIGNED)) {
                  return 1;
                }
              }
            }
          }
        }
      }

      return 0;
    }

    long activeInstructions = instructionCount(artifact, activeStart, activeEnd);
    if (activeInstructions < 0) {
      return 0;
    }

    if (opcode == OPCODE_JUMP) {
      if (first < activeInstructions) {
        return 1;
      }

      return 0;
    }

    if (opcode == OPCODE_JUMP_IF_ZERO) {
      long target = readUnsigned(artifact, cursor + 16, 8);
      if (first < localCount) {
        if (target < activeInstructions) {
          if (localHasType(artifact, activeTypes, first, TYPE_BOOLEAN)) {
            return 1;
          }
        }
      }

      return 0;
    }

    if (opcode == OPCODE_LOCAL_LOOP_CHECK) {
      long limit = readUnsigned(artifact, cursor + 16, 8);
      if (first < localCount) {
        if (limit < localCount) {
          if (localHasType(artifact, activeTypes, first, TYPE_SIGNED)) {
            if (localHasType(artifact, activeTypes, limit, TYPE_SIGNED)) {
              return 1;
            }
          }
        }
      }

      return 0;
    }

    return 1;
  }

  /// Verifies `functionCode` under the bounded bootstrap profile.
  public long verifyFunctionCode(
    borrow byteview artifact,
    long codeStart,
    long codeLength,
    long functionsOffset,
    long typesOffset,
    long variantsOffset,
    long globalCount,
    long recordCount,
    long variantCount,
    long arrayCount,
    long sliceCount,
    long functionCount,
    long localCount,
    long activeTypes,
    long resultType,
    long resultSlotBody,
    long entryBody
  ) {
    long cursor = codeStart;
    long end = codeStart + codeLength;
    long lastOpcode = -1;
    long instructionIndex = 0;
    while (cursor < end) limit MAX_CODE_INSTRUCTIONS {
      if (end - cursor < 8) {
        return 0;
      }

      long opcode = readUnsigned(artifact, cursor, 2);
      if (resultSlotBody == 1) {
        if (instructionIndex == 0) {
          boolean resultFill = opcode == OPCODE_RESULT_FILL_CONSTANT;
          if (opcode == OPCODE_RESULT_FILL_SOURCE) {
            resultFill = true;
          }

          if (opcode == OPCODE_RESULT_FILL_BINARY) {
            resultFill = true;
          }

          if (opcode == OPCODE_RESULT_FILL_BINARY_SOURCES) {
            resultFill = true;
          }

          if (resultFill) {} else {
            return 0;
          }
        } else {
          if (instructionIndex == 1) {
            if (opcode == OPCODE_RETURN_RESULT_SLOT) {} else {
              return 0;
            }
          } else {
            return 0;
          }
        }
      }

      long operandCount = readUnsigned(artifact, cursor + 2, 2);
      long expectedOperands = expectedOperandCount(opcode);
      if (expectedOperands < 0) {
        return 0;
      }

      if (differs(operandCount, expectedOperands)) {
        return 0;
      }

      long instructionLength = readUnsigned(artifact, cursor + 4, 4);
      long expectedLength = 8 + operandCount * 8;
      if (differs(instructionLength, expectedLength)) {
        return 0;
      }

      if (end < cursor + instructionLength) {
        return 0;
      }

      if (
        instructionOperandsValid(
          artifact,
          cursor,
          opcode,
          typesOffset,
          variantsOffset,
          globalCount,
          recordCount,
          variantCount,
          arrayCount,
          sliceCount,
          functionCount,
          localCount,
          codeStart,
          end,
          activeTypes,
          resultType,
          resultSlotBody,
          functionsOffset
        ) == 0
      ) {
        return 0;
      }

      if (opcode == OPCODE_HALT) {
        if (entryBody == 1) {
          if (differs(cursor + instructionLength, end)) {
            return 0;
          }
        } else {
          return 0;
        }
      }

      if (opcode == OPCODE_RETURN) {
        if (entryBody == 0) {
          if (resultType == 0) {} else {
            return 0;
          }
        } else {
          return 0;
        }
      }

      if (opcode == OPCODE_RETURN_VALUE) {
        if (entryBody == 0) {
          if (0 < resultType) {} else {
            return 0;
          }
        } else {
          return 0;
        }
      }

      if (opcode == OPCODE_RETURN_RESULT_SLOT) {
        if (entryBody == 0) {
          if (resultSlotBody == 1) {} else {
            return 0;
          }
        } else {
          return 0;
        }
      }

      lastOpcode = opcode;
      cursor += instructionLength;
      instructionIndex += 1;
    }

    if (differs(cursor, end)) {
      return 0;
    }

    if (resultSlotBody == 1) {
      if (differs(instructionIndex, 2)) {
        return 0;
      }
    }

    if (entryBody == 1) {
      if (lastOpcode == OPCODE_HALT) {
        return 1;
      }

      return 0;
    }

    if (0 < resultType) {
      if (resultSlotBody == 1) {
        if (lastOpcode == OPCODE_RETURN_RESULT_SLOT) {
          return 1;
        }
      } else {
        if (lastOpcode == OPCODE_RETURN_VALUE) {
          return 1;
        }
      }

      return 0;
    }

    if (lastOpcode == OPCODE_RETURN) {
      return 1;
    }

    return 0;
  }

}
