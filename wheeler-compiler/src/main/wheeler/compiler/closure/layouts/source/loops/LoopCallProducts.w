//! Joins planned source calls to typed code and stable relocation products.

module wheeler.compiler.closure.loop_call_products;

import wheeler.compiler.call_arguments;
import wheeler.compiler.closure.source_call_layout_products;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.opcodes;
import wheeler.compiler.type_codes;

classical class LoopCallProducts {
  private const long ARGUMENT_COUNT_LIMIT = 1792;
  private const long ARGUMENT_ROWS = 3584;
  private const long ARGUMENT_TYPE_ROW = 1792;
  private const long CALL_COUNT_LIMIT = 256;
  private const long CALL_KIND_ROW = 256;
  private const long CALL_TARGET_ROW = 768;
  private const long CALL_ROWS = 1024;
  private const long CALL_VOID = 0;
  private const long CALL_VALUE_BOOLEAN = 2;
  private const long CALL_VALUE_SIGNED = 1;
  private const long IDENTITY_BYTES = 32;
  private const long LOCAL_TYPE_COUNT_LIMIT = 4096;
  private const long LOCAL_TYPE_ROWS = 12288;
  private const long MAX_ARGUMENTS_PER_CALL = 7;
  private const long MAX_CODE_BYTES = 262144;
  private const long RELOCATION_IDENTITY_BYTES = 8192;
  private const long RELOCATION_ROWS = 768;
  private const long TARGET_COUNT_LIMIT = 4096;
  private const long TARGET_IDENTITY_BYTES = 131072;
  private const long TARGET_PARAMETER_ROWS = 16384;
  private const long STATEMENT_COUNT_LIMIT = 4096;
  private const long U64 = ENCODING_WIDTH_U64;
  private const long VALUE_COUNT_LIMIT = 1024;

  /// Reports one complete loop call, local-type, and relocation extent.
  public record LoopCallPlan(
    long instructionCount,
    long length,
    long relocationCount,
    long localTypeCount,
    boolean valid
  ) {}

  private boolean validArguments(
    long firstArgument,
    long arity,
    borrow mut words argumentRows,
    borrow mut words argumentValueProducts,
    borrow mut words valuePhysicalStarts,
    long firstParameter,
    borrow mut words targetParameterTypes,
    long localBase
  ) {
    long argument = 0;
    while (argument < arity) limit MAX_ARGUMENTS_PER_CALL {
      long valueProduct = argumentValueProducts[firstArgument + argument];
      long valueOffset = argumentValueProducts[ARGUMENT_TYPE_ROW + firstArgument + argument];
      if (valueProduct < 0) {
        return false;
      }

      if (VALUE_COUNT_LIMIT - 1 < valueProduct) {
        return false;
      }

      if (valueOffset < 0) {
        return false;
      }

      if (255 < valueOffset) {
        return false;
      }

      long source = valuePhysicalStarts[valueProduct] + valueOffset;
      long sourceType = argumentRows[ARGUMENT_TYPE_ROW + firstArgument + argument];
      if (source < 0) {
        return false;
      }

      if (localBase - 1 < source) {
        return false;
      }

      if (sourceType < 1) {
        return false;
      }

      if (sourceType != targetParameterTypes[firstParameter + argument]) {
        return false;
      }

      argument += 1;
    }

    return true;
  }

  private long writeArguments(
    borrow mut bytes output,
    long cursor,
    long firstArgument,
    long arity,
    borrow mut words argumentRows,
    borrow mut words argumentValueProducts,
    borrow mut words valuePhysicalStarts,
    long localBase
  ) {
    long argument = 0;
    while (argument < arity) limit MAX_ARGUMENTS_PER_CALL {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + argument, U64);
      long valueProduct = argumentValueProducts[firstArgument + argument];
      long valueOffset = argumentValueProducts[ARGUMENT_TYPE_ROW + firstArgument + argument];
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        valuePhysicalStarts[valueProduct] + valueOffset,
        U64
      );
      argument += 1;
    }

    argument = 0;
    while (argument < arity) limit MAX_ARGUMENTS_PER_CALL {
      long sourceType = argumentRows[ARGUMENT_TYPE_ROW + firstArgument + argument];
      cursor = writeInstructionHeader(
        output,
        cursor,
        callArgumentOpcode(sourceType),
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + arity + argument, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + argument, U64);
      argument += 1;
    }

    return cursor;
  }

  private long writeCall(
    borrow mut bytes output,
    long cursor,
    long kind,
    long localBase,
    long target,
    long firstArgument,
    long arity,
    borrow mut words argumentRows,
    borrow mut words argumentValueProducts,
    borrow mut words valuePhysicalStarts
  ) {
    if (arity == 0) {
      if (kind == CALL_VOID) {
        cursor = writeInstructionHeader(output, cursor, OPCODE_CALL, INSTRUCTION_FORM_UNARY);
        return writeUnsignedLittleEndian(output, cursor, target, U64);
      }
    } else {
      cursor = writeArguments(
        output,
        cursor,
        firstArgument,
        arity,
        argumentRows,
        argumentValueProducts,
        valuePhysicalStarts,
        localBase
      );
    }

    if (kind == CALL_VOID) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_CALL_VOID,
        INSTRUCTION_FORM_TERNARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + arity, U64);
      return writeUnsignedLittleEndian(output, cursor, arity, U64);
    }

    cursor = writeInstructionHeader(
      output,
      cursor,
      OPCODE_CALL_VALUE,
      INSTRUCTION_FORM_QUATERNARY
    );
    cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
    long argumentBase = 0;
    if (0 < arity) {
      argumentBase = localBase + arity;
    }

    cursor = writeUnsignedLittleEndian(output, cursor, argumentBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, arity, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + arity * 2, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + arity * 2 + 1, U64);
    return writeUnsignedLittleEndian(output, cursor, localBase + arity * 2, U64);
  }

  private long writeCallLocalTypes(
    borrow mut words stagedTypes,
    long typeCursor,
    long owner,
    long localBase,
    long kind,
    long firstArgument,
    long arity,
    borrow mut words argumentRows
  ) {
    long argument = 0;
    while (argument < arity) limit MAX_ARGUMENTS_PER_CALL {
      long type = argumentRows[ARGUMENT_TYPE_ROW + firstArgument + argument];
      set(stagedTypes, typeCursor, owner);
      set(stagedTypes, 4096 + typeCursor, localBase + argument);
      set(stagedTypes, 8192 + typeCursor, type);
      typeCursor += 1;
      argument += 1;
    }

    argument = 0;
    while (argument < arity) limit MAX_ARGUMENTS_PER_CALL {
      long transferType = argumentRows[ARGUMENT_TYPE_ROW + firstArgument + argument];
      set(stagedTypes, typeCursor, owner);
      set(stagedTypes, 4096 + typeCursor, localBase + arity + argument);
      set(stagedTypes, 8192 + typeCursor, transferType);
      typeCursor += 1;
      argument += 1;
    }

    if (kind != CALL_VOID) {
      long resultType = TYPE_SIGNED;
      if (kind == CALL_VALUE_BOOLEAN) {
        resultType = TYPE_BOOLEAN;
      }

      set(stagedTypes, typeCursor, owner);
      set(stagedTypes, 4096 + typeCursor, localBase + arity * 2);
      set(stagedTypes, 8192 + typeCursor, resultType);
      set(stagedTypes, typeCursor + 1, owner);
      set(stagedTypes, 4096 + typeCursor + 1, localBase + arity * 2 + 1);
      set(stagedTypes, 8192 + typeCursor + 1, resultType);
      typeCursor += 2;
    }

    return typeCursor;
  }

  /// Emits typed zero- through seven-argument calls and relocations atomically.
  public LoopCallPlan writeLoopCallProducts(
    long callCount,
    borrow mut words callRows,
    borrow mut words callArgumentStarts,
    borrow mut words callArgumentCounts,
    borrow mut words callStatements,
    borrow mut words callInstructionStarts,
    borrow mut words argumentRows,
    borrow mut words argumentValueProducts,
    borrow mut words valuePhysicalStarts,
    long targetCount,
    borrow byteview targetIdentities,
    borrow mut words targetParameterStarts,
    borrow mut words targetParameterCounts,
    borrow mut words targetParameterTypes,
    borrow mut words relocationRows,
    borrow mut bytes relocationIdentities,
    borrow mut words localTypeRows,
    borrow mut words callLocalWidths,
    borrow mut words statementPhysicalStarts,
    borrow mut words statementPhysicalWidths,
    borrow mut bytes output
  ) {
    assert(-1 < callCount);
    assert(callCount < CALL_COUNT_LIMIT + 1);
    assert(bufferLength(callRows) == CALL_ROWS);
    assert(bufferLength(callArgumentStarts) == CALL_COUNT_LIMIT);
    assert(bufferLength(callArgumentCounts) == CALL_COUNT_LIMIT);
    assert(bufferLength(callStatements) == CALL_COUNT_LIMIT);
    assert(bufferLength(callInstructionStarts) == CALL_COUNT_LIMIT);
    assert(bufferLength(argumentRows) == ARGUMENT_ROWS);
    assert(bufferLength(argumentValueProducts) == ARGUMENT_ROWS);
    assert(bufferLength(valuePhysicalStarts) == VALUE_COUNT_LIMIT);
    assert(-1 < targetCount);
    assert(targetCount < TARGET_COUNT_LIMIT + 1);
    assert(bufferLength(targetIdentities) == TARGET_IDENTITY_BYTES);
    assert(bufferLength(targetParameterStarts) == TARGET_COUNT_LIMIT);
    assert(bufferLength(targetParameterCounts) == TARGET_COUNT_LIMIT);
    assert(bufferLength(targetParameterTypes) == TARGET_PARAMETER_ROWS);
    assert(bufferLength(relocationRows) == RELOCATION_ROWS);
    assert(bufferLength(relocationIdentities) == RELOCATION_IDENTITY_BYTES);
    assert(bufferLength(localTypeRows) == LOCAL_TYPE_ROWS);
    assert(bufferLength(callLocalWidths) == CALL_COUNT_LIMIT);
    assert(bufferLength(statementPhysicalStarts) == STATEMENT_COUNT_LIMIT);
    assert(bufferLength(statementPhysicalWidths) == STATEMENT_COUNT_LIMIT);
    assert(bufferLength(output) == MAX_CODE_BYTES);

    boolean valid = true;
    long length = 0;
    long instructionCount = 0;
    long localTypeCount = 0;
    long previousArgumentEnd = 0;
    long call = 0;
    while (call < callCount) limit CALL_COUNT_LIMIT {
      long kind = callRows[CALL_KIND_ROW + call];
      long localBase = -1;
      long target = callRows[CALL_TARGET_ROW + call];
      long firstArgument = callArgumentStarts[call];
      long arity = callArgumentCounts[call];
      long statement = callStatements[call];
      long instructionStart = callInstructionStarts[call];
      if (validSourceCallKind(kind) == false) {
        valid = false;
      }

      if (statement < 0) {
        valid = false;
      }

      if (STATEMENT_COUNT_LIMIT - 1 < statement) {
        valid = false;
      }

      if (instructionStart < 0) {
        valid = false;
      }

      if (32767 < instructionStart) {
        valid = false;
      }

      if (-1 < statement) {
        if (statement < STATEMENT_COUNT_LIMIT) {
          localBase = statementPhysicalStarts[statement];
        }
      }

      if (localBase < 0) {
        valid = false;
      }

      if (255 < localBase) {
        valid = false;
      }

      if (target < 0) {
        valid = false;
      }

      if (targetCount - 1 < target) {
        valid = false;
      }

      if (firstArgument != previousArgumentEnd) {
        valid = false;
      }

      if (arity < 0) {
        valid = false;
      }

      if (MAX_ARGUMENTS_PER_CALL < arity) {
        valid = false;
      }

      if (ARGUMENT_COUNT_LIMIT - firstArgument < arity) {
        valid = false;
      }

      if (valid) {
        long firstParameter = targetParameterStarts[target];
        long parameterCount = targetParameterCounts[target];
        if (parameterCount != arity) {
          valid = false;
        }

        if (firstParameter < 0) {
          valid = false;
        }

        if (TARGET_PARAMETER_ROWS - firstParameter < arity) {
          valid = false;
        }

        if (valid) {
          valid = validArguments(
            firstArgument,
            arity,
            argumentRows,
            argumentValueProducts,
            valuePhysicalStarts,
            firstParameter,
            targetParameterTypes,
            localBase
          );
        }
      }

      long selectedLocalCount = sourceCallLocalCount(kind, arity);
      if (256 - localBase < selectedLocalCount) {
        valid = false;
      }

      if (callLocalWidths[call] != selectedLocalCount) {
        valid = false;
      }

      if (-1 < statement) {
        if (statement < STATEMENT_COUNT_LIMIT) {
          if (statementPhysicalWidths[statement] != selectedLocalCount) {
            valid = false;
          }
        }
      }

      localTypeCount += selectedLocalCount;
      if (LOCAL_TYPE_COUNT_LIMIT < localTypeCount) {
        valid = false;
      }

      length += sourceCallLength(kind, arity);
      instructionCount += sourceCallInstructionCount(kind, arity);
      if (MAX_CODE_BYTES < length) {
        valid = false;
      }

      previousArgumentEnd = firstArgument + arity;
      call += 1;
    }

    if (valid == false) {
      return new LoopCallPlan(0, 0, 0, 0, false);
    }

    region staging = new region(/* bytes= */ 409600, /* allocations= */ 6);
    words stagedRelocations = allocate(staging, RELOCATION_ROWS);
    bytes stagedIdentities = allocateBytes(staging, RELOCATION_IDENTITY_BYTES);
    words stagedTypes = allocate(staging, LOCAL_TYPE_ROWS);
    words stagedLocalWidths = allocate(staging, CALL_COUNT_LIMIT);
    words stagedStatementWidths = allocate(staging, STATEMENT_COUNT_LIMIT);
    bytes stagedCode = allocateBytes(staging, MAX_CODE_BYTES);
    long statementRow = 0;
    while (statementRow < STATEMENT_COUNT_LIMIT) limit STATEMENT_COUNT_LIMIT {
      set(stagedStatementWidths, statementRow, statementPhysicalWidths[statementRow]);
      statementRow += 1;
    }

    long cursor = 0;
    long typeCursor = 0;
    call = 0;
    while (call < callCount) limit CALL_COUNT_LIMIT {
      long emittedKind = callRows[CALL_KIND_ROW + call];
      long emittedStatement = callStatements[call];
      long emittedLocalBase = statementPhysicalStarts[emittedStatement];
      long emittedTarget = callRows[CALL_TARGET_ROW + call];
      long emittedFirstArgument = callArgumentStarts[call];
      long emittedArity = callArgumentCounts[call];
      set(stagedRelocations, call, callInstructionStarts[call] + emittedArity * 2);
      set(stagedRelocations, CALL_COUNT_LIMIT + call, emittedTarget);
      set(stagedRelocations, CALL_COUNT_LIMIT * 2 + call, callRows[call]);
      long identityByte = 0;
      while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
        setByte(
          stagedIdentities,
          call * IDENTITY_BYTES + identityByte,
          targetIdentities[emittedTarget * IDENTITY_BYTES + identityByte]
        );
        identityByte += 1;
      }

      cursor = writeCall(
        stagedCode,
        cursor,
        emittedKind,
        emittedLocalBase,
        emittedTarget,
        emittedFirstArgument,
        emittedArity,
        argumentRows,
        argumentValueProducts,
        valuePhysicalStarts
      );
      long emittedLocalWidth = sourceCallLocalCount(emittedKind, emittedArity);
      set(stagedLocalWidths, call, emittedLocalWidth);
      typeCursor = writeCallLocalTypes(
        stagedTypes,
        typeCursor,
        callRows[call],
        emittedLocalBase,
        emittedKind,
        emittedFirstArgument,
        emittedArity,
        argumentRows
      );
      call += 1;
    }

    long row = 0;
    while (row < RELOCATION_ROWS) limit RELOCATION_ROWS {
      set(relocationRows, row, stagedRelocations[row]);
      row += 1;
    }

    long identityOffset = 0;
    while (identityOffset < RELOCATION_IDENTITY_BYTES) limit RELOCATION_IDENTITY_BYTES {
      setByte(relocationIdentities, identityOffset, stagedIdentities[identityOffset]);
      identityOffset += 1;
    }

    row = 0;
    while (row < LOCAL_TYPE_ROWS) limit LOCAL_TYPE_ROWS {
      set(localTypeRows, row, stagedTypes[row]);
      row += 1;
    }

    row = 0;
    while (row < CALL_COUNT_LIMIT) limit CALL_COUNT_LIMIT {
      set(callLocalWidths, row, stagedLocalWidths[row]);
      row += 1;
    }

    row = 0;
    while (row < STATEMENT_COUNT_LIMIT) limit STATEMENT_COUNT_LIMIT {
      set(statementPhysicalWidths, row, stagedStatementWidths[row]);
      row += 1;
    }

    long codeByte = 0;
    while (codeByte < cursor) limit MAX_CODE_BYTES {
      setByte(output, codeByte, stagedCode[codeByte]);
      codeByte += 1;
    }

    drop(stagedCode);
    drop(stagedStatementWidths);
    drop(stagedLocalWidths);
    drop(stagedTypes);
    drop(stagedIdentities);
    drop(stagedRelocations);
    drop(staging);
    return new LoopCallPlan(instructionCount, cursor, callCount, typeCursor, true);
  }
}
