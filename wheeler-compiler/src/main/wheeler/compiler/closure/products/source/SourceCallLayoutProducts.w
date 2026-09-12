//! Measures typed call locals before callable coordinate publication.

module wheeler.compiler.closure.source_call_layout_products;

import wheeler.compiler.closure.source_call_argument_layouts;
import wheeler.compiler.closure.source_global_schema;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.instruction_forms;
import wheeler.compiler.opcodes;
import wheeler.compiler.type_codes;

classical class SourceCallLayoutProducts {
  private const long CALL_COUNT_LIMIT = SOURCE_CALL_COUNT_LIMIT;
  private const long CALL_ROWS = 1024;
  /// Names a call without a result destination.
  public const long CALL_VOID = 0;
  /// Names a Boolean helper call guarding an exact `return false;` child.
  public const long CALL_CONDITION_FALSE_BOOLEAN = 5;
  /// Names a Boolean helper call guarding an exact `return true;` child.
  public const long CALL_CONDITION_TRUE_BOOLEAN = 6;
  /// Names a Boolean helper call guarding an exact signed-constant return.
  public const long CALL_CONDITION_SIGNED_CONSTANT = 7;
  /// Names a Boolean helper call guarding an exact signed-literal return.
  public const long CALL_CONDITION_SIGNED_LITERAL = 8;
  /// Names an immediate Boolean return destination.
  public const long CALL_FORWARD_BOOLEAN = 4;
  /// Names an immediate signed return destination.
  public const long CALL_FORWARD_SIGNED = 3;
  /// Names a new Boolean local destination.
  public const long CALL_VALUE_BOOLEAN = 2;
  /// Names a new signed local destination.
  public const long CALL_VALUE_SIGNED = 1;
  /// Names a validated declaration-ordinal signed store destination.
  public const long CALL_STORE_GLOBAL_SIGNED = 9;
  private const long MAX_SIGNATURE_TYPES = 4096;
  private const long MAX_STATEMENTS = 4096;
  private const long RESULT_LOCALS = 1;
  private const long DECLARATION_LOCALS = 1;
  private const long STAGING_WORDS = CALL_ROWS + MAX_STATEMENTS + CALL_COUNT_LIMIT;
  private const long STAGING_BYTES = STAGING_WORDS * ENCODING_WIDTH_U64;
  private const long STAGING_BUFFERS = 3;

  /// Reports one complete call-kind and physical-width product set.
  public record SourceCallLayoutPlan(long callCount, long localTypeCount, boolean valid) {}

  /// Reports whether a call result kind has a canonical encoding.
  public boolean validSourceCallKind(long kind) {
    if (kind == CALL_VOID) {
      return true;
    }

    if (kind == CALL_VALUE_SIGNED) {
      return true;
    }

    if (kind == CALL_VALUE_BOOLEAN) {
      return true;
    }

    if (kind == CALL_FORWARD_SIGNED) {
      return true;
    }

    if (kind == CALL_FORWARD_BOOLEAN) {
      return true;
    }

    if (kind == CALL_CONDITION_FALSE_BOOLEAN) {
      return true;
    }

    if (kind == CALL_CONDITION_TRUE_BOOLEAN) {
      return true;
    }

    if (kind == CALL_CONDITION_SIGNED_CONSTANT) {
      return true;
    }

    if (kind == CALL_CONDITION_SIGNED_LITERAL) {
      return true;
    }

    return kind == CALL_STORE_GLOBAL_SIGNED;
  }

  /// Validates the selected child value or global ordinal, including inactive zeroes.
  public boolean sourceCallResultOperandValid(long kind, long operand) {
    if (validSourceCallKind(kind) == false) {
      return false;
    }

    if (kind == CALL_STORE_GLOBAL_SIGNED) {
      if (operand < 0) {
        return false;
      }

      return operand < MAX_SOURCE_GLOBALS;
    }

    if (kind == CALL_CONDITION_TRUE_BOOLEAN) {
      return operand == 1;
    }

    if (sourceCallReturnsSignedChild(kind)) {
      return true;
    }

    return operand == 0;
  }

  /// Reports whether one call condition returns a signed child value.
  public boolean sourceCallReturnsSignedChild(long kind) {
    if (kind == CALL_CONDITION_SIGNED_CONSTANT) {
      return true;
    }

    return kind == CALL_CONDITION_SIGNED_LITERAL;
  }

  /// Reports whether one Boolean call result controls an exact return child.
  public boolean sourceCallConditionsResult(long kind) {
    if (kind == CALL_CONDITION_FALSE_BOOLEAN) {
      return true;
    }

    if (kind == CALL_CONDITION_TRUE_BOOLEAN) {
      return true;
    }

    return sourceCallReturnsSignedChild(kind);
  }

  /// Reports whether one value call returns its result directly.
  public boolean sourceCallForwardsResult(long kind) {
    if (kind == CALL_FORWARD_SIGNED) {
      return true;
    }

    return kind == CALL_FORWARD_BOOLEAN;
  }

  /// Returns the exact instruction count for one typed call.
  public long sourceCallInstructionCount(long kind, long arity) {
    assert(validSourceCallKind(kind));
    assert(-1 < arity);
    assert(arity < SOURCE_CALL_ARITY_LIMIT + 1);
    long argumentInstructions = arity * SOURCE_CALL_ARGUMENT_PHASES;
    long callInstructions = 1;
    if (kind == CALL_VOID) {
      return argumentInstructions + callInstructions;
    }

    if (sourceCallConditionsResult(kind)) {
      long branchInstructions = 1;
      long childInstructions = 2;
      long exitInstructions = 1;
      return argumentInstructions + callInstructions + branchInstructions + childInstructions
        + exitInstructions;
    }

    long destinationInstructions = 1;
    return argumentInstructions + callInstructions + destinationInstructions;
  }

  private long instructionBytes(long opcode) {
    return ENCODING_INSTRUCTION_HEADER_BYTES + expectedOperandCount(opcode) * ENCODING_WIDTH_U64;
  }

  /// Derives byte lengths from canonical forms and argument preparation phases.
  public long sourceCallLength(long kind, long arity) {
    assert(validSourceCallKind(kind));
    assert(-1 < arity);
    assert(arity < SOURCE_CALL_ARITY_LIMIT + 1);
    long argumentBytes = arity * SOURCE_CALL_ARGUMENT_PHASES * instructionBytes(OPCODE_LOCAL_MOVE);
    if (kind == CALL_VOID) {
      if (arity == 0) {
        return instructionBytes(OPCODE_CALL);
      }

      return argumentBytes + instructionBytes(OPCODE_CALL_VOID);
    }

    long callBytes = argumentBytes + instructionBytes(OPCODE_CALL_VALUE);
    if (sourceCallForwardsResult(kind)) {
      return callBytes + instructionBytes(OPCODE_RETURN_VALUE);
    }

    if (sourceCallConditionsResult(kind)) {
      return callBytes + instructionBytes(OPCODE_JUMP_IF_ZERO) + instructionBytes(
        OPCODE_LOCAL_CONST
      ) + instructionBytes(OPCODE_RETURN_VALUE) + instructionBytes(OPCODE_JUMP);
    }

    if (kind == CALL_STORE_GLOBAL_SIGNED) {
      return callBytes + instructionBytes(OPCODE_LOCAL_STORE_GLOBAL);
    }

    return callBytes + instructionBytes(OPCODE_LOCAL_MOVE);
  }

  /// Returns the exact physical local width for one typed call.
  public long sourceCallLocalCount(long kind, long arity) {
    assert(validSourceCallKind(kind));
    assert(-1 < arity);
    assert(arity < SOURCE_CALL_ARITY_LIMIT + 1);
    long argumentLocals = arity * SOURCE_CALL_ARGUMENT_PHASES;
    if (kind == CALL_VOID) {
      return argumentLocals;
    }

    long resultLocals = argumentLocals + RESULT_LOCALS;
    if (kind == CALL_STORE_GLOBAL_SIGNED) {
      return resultLocals;
    }

    if (sourceCallForwardsResult(kind)) {
      return resultLocals;
    }

    if (sourceCallConditionsResult(kind)) {
      return resultLocals;
    }

    return resultLocals + DECLARATION_LOCALS;
  }

  private long kindForSourceResult(long type) {
    if (type == 0) {
      return CALL_VOID;
    }

    if (type == TYPE_SIGNED) {
      return CALL_VALUE_SIGNED;
    }

    if (type == TYPE_BOOLEAN) {
      return CALL_VALUE_BOOLEAN;
    }

    return -1;
  }

  /// Validates and publishes exact typed call-statement widths atomically.
  public SourceCallLayoutPlan materializeSourceCallLayoutProducts(
    long callCount,
    borrow mut words sourceCalls,
    borrow mut words callStatements,
    borrow mut words callArgumentStarts,
    borrow mut words callArgumentCounts,
    borrow mut words arguments,
    long targetCount,
    borrow mut words targetParameterStarts,
    borrow mut words targetParameterCounts,
    borrow mut words targetParameterTypes,
    borrow mut words targetResultTypes,
    borrow mut words statementRows,
    borrow mut words statementPhysicalWidths,
    borrow mut words resolvedCalls,
    borrow mut words callLocalWidths
  ) {
    assert(-1 < callCount);
    assert(callCount < CALL_COUNT_LIMIT + 1);
    assert(bufferLength(sourceCalls) == CALL_ROWS);
    assert(bufferLength(callStatements) == CALL_COUNT_LIMIT);
    assert(bufferLength(callArgumentStarts) == CALL_COUNT_LIMIT);
    assert(bufferLength(callArgumentCounts) == CALL_COUNT_LIMIT);
    assert(bufferLength(arguments) == SOURCE_CALL_ARGUMENT_ROWS);
    assert(-1 < targetCount);
    assert(targetCount < MAX_SIGNATURE_TYPES + 1);
    assert(bufferLength(targetParameterStarts) == MAX_SIGNATURE_TYPES);
    assert(bufferLength(targetParameterCounts) == MAX_SIGNATURE_TYPES);
    assert(bufferLength(targetParameterTypes) == 16384);
    assert(bufferLength(targetResultTypes) == MAX_SIGNATURE_TYPES);
    assert(bufferLength(statementRows) == 28672);
    assert(bufferLength(statementPhysicalWidths) == MAX_STATEMENTS);
    assert(bufferLength(resolvedCalls) == CALL_ROWS);
    assert(bufferLength(callLocalWidths) == CALL_COUNT_LIMIT);

    region staging = new region(STAGING_BYTES, STAGING_BUFFERS);
    words stagedCalls = allocate(staging, CALL_ROWS);
    words stagedWidths = allocate(staging, MAX_STATEMENTS);
    words stagedCallWidths = allocate(staging, CALL_COUNT_LIMIT);
    boolean valid = true;
    long localTypeCount = 0;
    long argumentEnd = 0;
    long call = 0;
    while (call < callCount) limit CALL_COUNT_LIMIT {
      long target = sourceCalls[768 + call];
      long ownedStatement = callStatements[call];
      long firstArgument = callArgumentStarts[call];
      long arity = callArgumentCounts[call];
      if (target < 0) {
        valid = false;
      }

      if (targetCount - 1 < target) {
        valid = false;
      }

      if (ownedStatement < 0) {
        valid = false;
      }

      if (MAX_STATEMENTS - 1 < ownedStatement) {
        valid = false;
      }

      if (firstArgument != argumentEnd) {
        valid = false;
      }

      if (arity < 0) {
        valid = false;
      }

      if (SOURCE_CALL_ARITY_LIMIT < arity) {
        valid = false;
      }

      if (firstArgument < 0) {
        valid = false;
      }

      if (SOURCE_CALL_ARGUMENT_LIMIT < firstArgument) {
        valid = false;
      }

      if (valid) {
        if (SOURCE_CALL_ARGUMENT_LIMIT - firstArgument < arity) {
          valid = false;
        }
      }

      long kind = -1;
      if (-1 < target) {
        if (target < targetCount) {
          kind = kindForSourceResult(targetResultTypes[target]);
          if (targetParameterCounts[target] != arity) {
            valid = false;
          }
        }
      }

      if (validSourceCallKind(kind) == false) {
        valid = false;
      }

      if (valid) {
        long firstParameter = targetParameterStarts[target];
        if (firstParameter < 0) {
          valid = false;
        }

        if (16384 - arity < firstParameter) {
          valid = false;
        }

        if (valid) {
          long argument = 0;
          while (argument < arity) limit SOURCE_CALL_ARITY_LIMIT {
            long expectedType = targetParameterTypes[firstParameter + argument];
            if (expectedType < 1) {
              valid = false;
            }

            if (
              arguments[SOURCE_CALL_ARGUMENT_TYPE_ROW + firstArgument + argument] != expectedType
            ) {
              valid = false;
            }

            argument += 1;
          }
        }
      }

      if (valid) {
        long width = sourceCallLocalCount(kind, arity);
        if (statementPhysicalWidths[ownedStatement] == width - 1) {
          if (kind == CALL_VALUE_SIGNED) {
            kind = CALL_FORWARD_SIGNED;
          }

          if (kind == CALL_VALUE_BOOLEAN) {
            kind = CALL_FORWARD_BOOLEAN;
          }

          width = sourceCallLocalCount(kind, arity);
        }

        if (statementPhysicalWidths[ownedStatement] != width) {
          valid = false;
        }

        if (255 < width) {
          valid = false;
        } else {
          set(stagedWidths, ownedStatement, width);
          set(stagedCallWidths, call, width);
          set(stagedCalls, call, statementRows[ownedStatement]);
          set(stagedCalls, 256 + call, kind);
          set(stagedCalls, 512 + call, sourceCalls[call]);
          set(stagedCalls, 768 + call, target);
          localTypeCount += width;
        }
      }

      if (valid) {
        argumentEnd = firstArgument + arity;
      }

      call += 1;
    }

    if (MAX_SIGNATURE_TYPES < localTypeCount) {
      valid = false;
    }

    SourceCallLayoutPlan result = new SourceCallLayoutPlan(callCount, localTypeCount, valid);
    if (valid) {
      long column = 0;
      while (column < 4) limit 4 {
        long callRow = 0;
        while (callRow < callCount) limit CALL_COUNT_LIMIT {
          set(
            resolvedCalls,
            column * CALL_COUNT_LIMIT + callRow,
            stagedCalls[column * CALL_COUNT_LIMIT + callRow]
          );
          callRow += 1;
        }

        column += 1;
      }

      long publishedCall = 0;
      while (publishedCall < callCount) limit CALL_COUNT_LIMIT {
        long publishedStatement = callStatements[publishedCall];
        set(statementPhysicalWidths, publishedStatement, stagedWidths[publishedStatement]);
        set(callLocalWidths, publishedCall, stagedCallWidths[publishedCall]);
        publishedCall += 1;
      }
    }

    drop(stagedCallWidths);
    drop(stagedWidths);
    drop(stagedCalls);
    drop(staging);
    return result;
  }
}
