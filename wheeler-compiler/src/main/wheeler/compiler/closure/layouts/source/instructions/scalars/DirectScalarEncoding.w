//! Emits bounded scalar relations from exact source products.

module wheeler.compiler.closure.direct_scalar_encoding;

import wheeler.compiler.closure.module_symbols;
import wheeler.compiler.closure.source_global_schema;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_identifier_ranges;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class DirectScalarEncoding {
  private const long MAX_CODE_BYTES = 262144;
  private const long U64 = ENCODING_WIDTH_U64;
  private const long MAX_FRAME_LOCALS = 256;
  private const long SOURCE_LOAD_BYTES = ENCODING_INSTRUCTION_HEADER_BYTES + INSTRUCTION_FORM_BINARY
    * U64;
  private const long RESULT_OPERATION_BYTES = ENCODING_INSTRUCTION_HEADER_BYTES
    + INSTRUCTION_FORM_TERNARY * U64;
  private const long RETURN_BYTES = ENCODING_INSTRUCTION_HEADER_BYTES + INSTRUCTION_FORM_UNARY
    * U64;
  private const long SOURCE_RETURN_BYTES = SOURCE_LOAD_BYTES + RETURN_BYTES;
  private const long BINARY_RETURN_BYTES = SOURCE_LOAD_BYTES * 2 + RESULT_OPERATION_BYTES
    + RETURN_BYTES;
  private const long BINARY_DECLARATION_BYTES = SOURCE_LOAD_BYTES * 3 + RESULT_OPERATION_BYTES;

  /// Reports one exact imported constant use.
  public record DirectReturnConstant(long value, boolean found, boolean valid) {}

  /// Reports the exact code, instruction, and local extent of one scalar relation.
  public record DirectScalarExtent(
    long next,
    long instructionCount,
    long localCount,
    boolean valid
  ) {}

  private boolean scalarLoadOpcodeValid(long opcode) {
    if (opcode == OPCODE_LOCAL_MOVE) {
      return true;
    }

    return opcode == OPCODE_LOCAL_LOAD_GLOBAL;
  }

  private boolean scalarLoadValid(long opcode, long operand) {
    if (operand < 0) {
      return false;
    }

    if (opcode == OPCODE_LOCAL_MOVE) {
      return operand < MAX_FRAME_LOCALS;
    }

    if (opcode == OPCODE_LOCAL_LOAD_GLOBAL) {
      return operand < MAX_SOURCE_GLOBALS;
    }

    return false;
  }

  private boolean comparisonOperation(long operation) {
    if (operation == OPCODE_LOCAL_EQ) {
      return true;
    }

    return operation == OPCODE_LOCAL_LT;
  }

  private boolean returnOperation(long operation) {
    if (comparisonOperation(operation)) {
      return true;
    }

    if (operation == OPCODE_LOCAL_ADD) {
      return true;
    }

    if (operation == OPCODE_LOCAL_SUB) {
      return true;
    }

    if (operation == OPCODE_LOCAL_MUL) {
      return true;
    }

    if (operation == OPCODE_LOCAL_DIV) {
      return true;
    }

    if (operation == OPCODE_LOCAL_MOD) {
      return true;
    }

    if (operation == OPCODE_LOCAL_XOR) {
      return true;
    }

    return operation == OPCODE_LOCAL_AND;
  }

  private boolean materializedReturn(long kind) {
    if (kind == RESULT_RELATION_CONSTANT) {
      return true;
    }

    return kind == RESULT_RELATION_LITERAL;
  }

  /// Resolves one constant against its packed name bytes, not a source-use coordinate.
  public DirectReturnConstant resolveDirectReturnConstant(
    borrow utf8 source,
    borrow byteview symbolNames,
    long moduleOwner,
    long tokenStart,
    long tokenLength,
    long symbolCount,
    borrow mut words symbolOwners,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolTypes,
    borrow mut words symbolValues,
    borrow mut words symbolResolved
  ) {
    assert(-1 < moduleOwner);
    assert(-1 < tokenStart);
    assert(0 < tokenLength);
    assert(tokenLength < 257);
    assert(-1 < symbolCount);
    assert(symbolCount < 16385);
    assert(bufferLength(symbolOwners) == 16384);
    assert(bufferLength(symbolStarts) == 16384);
    assert(bufferLength(symbolLengths) == 16384);
    assert(bufferLength(symbolTypes) == 16384);
    assert(bufferLength(symbolValues) == 16384);
    assert(bufferLength(symbolResolved) == 16384);

    long matches = 0;
    long selected = 0;
    boolean valid = true;
    long symbol = 0;
    while (symbol < symbolCount) limit 16384 {
      if (symbolOwners[symbol] == moduleOwner) {
        if (
          matchesSourceIdentifier(
            source,
            tokenStart,
            tokenLength,
            symbolNames,
            symbolStarts[symbol],
            symbolLengths[symbol]
          )
        ) {
          matches += 1;
          selected = symbolValues[symbol];
          if (symbolResolved[symbol] != 1) {
            valid = false;
          }

          if (symbolTypes[symbol] != MODULE_SYMBOL_SIGNED) {
            valid = false;
          }
        }
      }

      symbol += 1;
    }

    if (matches == 0) {
      return new DirectReturnConstant(0, false, true);
    }

    if (matches != 1) {
      valid = false;
    }

    return new DirectReturnConstant(selected, true, valid);
  }

  /// Maps one source scalar to its canonical local type.
  public long directReturnType(long sourceType) {
    if (sourceType == TOKEN_LONG) {
      return TYPE_SIGNED;
    }

    if (sourceType == TOKEN_BOOLEAN) {
      return TYPE_BOOLEAN;
    }

    return -1;
  }

  /// Returns one relation result type from its operand type and operation.
  public long directRelationResultType(long operation, long leftType) {
    if (comparisonOperation(operation)) {
      return TYPE_BOOLEAN;
    }

    return directReturnType(leftType);
  }

  /// Checks operand types before an ordinary scalar destination or reversible result emits.
  public boolean directScalarTypesValid(
    long reversibleCallableCount,
    long kind,
    long operation,
    long leftType,
    long rightType
  ) {
    if (leftType != TOKEN_LONG) {
      if (leftType != TOKEN_BOOLEAN) {
        return false;
      }
    }

    if (kind == RESULT_RELATION_SOURCE) {
      return true;
    }

    if (materializedReturn(kind)) {
      return reversibleCallableCount == 0;
    }

    if (kind == RESULT_RELATION_LEFT_LITERAL) {
      if (reversibleCallableCount != 0) {
        return false;
      }

      if (leftType != TOKEN_LONG) {
        return false;
      }

      if (rightType != TOKEN_LONG) {
        return false;
      }

      return comparisonOperation(operation);
    }

    if (returnOperation(operation) == false) {
      return false;
    }

    if (comparisonOperation(operation)) {
      if (0 < reversibleCallableCount) {
        return false;
      }

      if (leftType == TOKEN_BOOLEAN) {
        if (operation != OPCODE_LOCAL_EQ) {
          return false;
        }

        if (kind != RESULT_RELATION_BINARY_SOURCES) {
          return false;
        }

        return rightType == TOKEN_BOOLEAN;
      }

      if (leftType != TOKEN_LONG) {
        return false;
      }

      if (kind == RESULT_RELATION_BINARY) {
        return true;
      }

      if (kind != RESULT_RELATION_BINARY_SOURCES) {
        return false;
      }

      return rightType == TOKEN_LONG;
    }

    if (0 < reversibleCallableCount) {
      if (leftType == TOKEN_BOOLEAN) {
        return false;
      }
    }

    if (kind == RESULT_RELATION_BINARY) {
      return leftType == TOKEN_LONG;
    }

    if (kind != RESULT_RELATION_BINARY_SOURCES) {
      return false;
    }

    if (rightType != leftType) {
      return false;
    }

    if (leftType == TOKEN_BOOLEAN) {
      return operation == OPCODE_LOCAL_XOR;
    }

    return true;
  }

  /// Writes one binary relation followed by its named destination move.
  public DirectScalarExtent writeDirectScalarDeclaration(
    borrow mut bytes output,
    long cursor,
    long kind,
    long leftLoadOpcode,
    long rightLoadOpcode,
    long localBase,
    long left,
    long leftType,
    long operation,
    long right,
    long rightType,
    long resultType,
    long immediate
  ) {
    assert(bufferLength(output) == MAX_CODE_BYTES);
    if (scalarLoadOpcodeValid(leftLoadOpcode) == false) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (scalarLoadOpcodeValid(rightLoadOpcode) == false) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (kind != RESULT_RELATION_BINARY_SOURCES) {
      if (rightLoadOpcode != OPCODE_LOCAL_MOVE) {
        return new DirectScalarExtent(0, 0, 0, false);
      }
    }

    if (cursor < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (kind != RESULT_RELATION_BINARY) {
      if (kind != RESULT_RELATION_BINARY_SOURCES) {
        return new DirectScalarExtent(0, 0, 0, false);
      }
    }

    if (returnOperation(operation) == false) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (directRelationResultType(operation, leftType) != resultType) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    boolean operandTypesValid = leftType == TOKEN_LONG;
    if (rightType != TOKEN_LONG) {
      operandTypesValid = false;
    }

    if (operation == OPCODE_LOCAL_EQ) {
      if (leftType == TOKEN_BOOLEAN) {
        operandTypesValid = rightType == TOKEN_BOOLEAN;
      }
    }

    if (operandTypesValid == false) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (localBase < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (252 < localBase) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (scalarLoadValid(leftLoadOpcode, left) == false) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (kind == RESULT_RELATION_BINARY_SOURCES) {
      if (scalarLoadValid(rightLoadOpcode, right) == false) {
        return new DirectScalarExtent(0, 0, 0, false);
      }
    } else {
      if (kind != RESULT_RELATION_BINARY) {
        return new DirectScalarExtent(0, 0, 0, false);
      }
    }

    if (MAX_CODE_BYTES - BINARY_DECLARATION_BYTES < cursor) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    DirectScalarExtent resultPlan = new DirectScalarExtent(
      cursor + BINARY_DECLARATION_BYTES,
      4,
      4,
      true
    );
    long next = writeInstructionHeader(output, cursor, leftLoadOpcode, INSTRUCTION_FORM_BINARY);
    next = writeUnsignedLittleEndian(output, next, localBase, U64);
    next = writeUnsignedLittleEndian(output, next, left, U64);
    long rightDestination = localBase + 1;
    if (kind == RESULT_RELATION_BINARY) {
      next = writeInstructionHeader(output, next, OPCODE_LOCAL_CONST, INSTRUCTION_FORM_BINARY);
      next = writeUnsignedLittleEndian(output, next, rightDestination, U64);
      next = writeSignedLittleEndian(output, next, immediate, U64);
    } else {
      next = writeInstructionHeader(output, next, rightLoadOpcode, INSTRUCTION_FORM_BINARY);
      next = writeUnsignedLittleEndian(output, next, rightDestination, U64);
      next = writeUnsignedLittleEndian(output, next, right, U64);
    }

    long result = localBase + 2;
    next = writeInstructionHeader(output, next, operation, INSTRUCTION_FORM_TERNARY);
    next = writeUnsignedLittleEndian(output, next, result, U64);
    next = writeUnsignedLittleEndian(output, next, localBase, U64);
    next = writeUnsignedLittleEndian(output, next, rightDestination, U64);
    next = writeInstructionHeader(output, next, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    next = writeUnsignedLittleEndian(output, next, localBase + 3, U64);
    next = writeUnsignedLittleEndian(output, next, result, U64);
    assert(next == resultPlan.next);
    return resultPlan;
  }

  private long writeDestination(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long target,
    long value
  ) {
    long form = INSTRUCTION_FORM_UNARY;
    if (opcode == OPCODE_LOCAL_STORE_GLOBAL) {
      form = INSTRUCTION_FORM_BINARY;
    }

    long next = writeInstructionHeader(output, cursor, opcode, form);
    if (opcode == OPCODE_LOCAL_STORE_GLOBAL) {
      next = writeUnsignedLittleEndian(output, next, target, U64);
    }

    return writeUnsignedLittleEndian(output, next, value, U64);
  }

  /// Preflights the complete scalar operand and destination window without publishing bytes.
  public DirectScalarExtent measureDirectScalarDestination(
    long cursor,
    long destinationOpcode,
    long destinationOperand,
    long kind,
    long leftLoadOpcode,
    long rightLoadOpcode,
    long destination,
    long left,
    long operation,
    long right
  ) {
    boolean leftMaterialized = materializedReturn(kind);
    if (kind == RESULT_RELATION_LEFT_LITERAL) {
      if (left != 0) {
        return new DirectScalarExtent(0, 0, 0, false);
      }

      leftMaterialized = true;
    }

    boolean rightSource = kind == RESULT_RELATION_BINARY_SOURCES;
    if (kind == RESULT_RELATION_LEFT_LITERAL) {
      rightSource = true;
    }

    if (scalarLoadOpcodeValid(leftLoadOpcode) == false) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (scalarLoadOpcodeValid(rightLoadOpcode) == false) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (leftMaterialized) {
      if (leftLoadOpcode != OPCODE_LOCAL_MOVE) {
        return new DirectScalarExtent(0, 0, 0, false);
      }
    }

    if (rightSource == false) {
      if (rightLoadOpcode != OPCODE_LOCAL_MOVE) {
        return new DirectScalarExtent(0, 0, 0, false);
      }
    }

    if (cursor < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (destination < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (MAX_FRAME_LOCALS - 1 < destination) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (leftMaterialized == false) {
      if (scalarLoadValid(leftLoadOpcode, left) == false) {
        return new DirectScalarExtent(0, 0, 0, false);
      }
    }

    long destinationBytes = RETURN_BYTES;
    if (destinationOpcode == OPCODE_LOCAL_STORE_GLOBAL) {
      if (destinationOperand < 0) {
        return new DirectScalarExtent(0, 0, 0, false);
      }

      if (MAX_SOURCE_GLOBALS - 1 < destinationOperand) {
        return new DirectScalarExtent(0, 0, 0, false);
      }

      destinationBytes = SOURCE_LOAD_BYTES;
    } else {
      if (destinationOpcode != OPCODE_RETURN_VALUE) {
        if (destinationOpcode != OPCODE_EXPECT_TRUE) {
          return new DirectScalarExtent(0, 0, 0, false);
        }
      }

      if (destinationOperand != 0) {
        return new DirectScalarExtent(0, 0, 0, false);
      }
    }

    long length = SOURCE_RETURN_BYTES - RETURN_BYTES + destinationBytes;
    long localCount = 1;
    long instructionCount = 2;
    boolean binaryRelation = kind != RESULT_RELATION_SOURCE;
    if (materializedReturn(kind)) {
      binaryRelation = false;
    }

    if (binaryRelation) {
      if (returnOperation(operation) == false) {
        return new DirectScalarExtent(0, 0, 0, false);
      }

      if (MAX_FRAME_LOCALS - 3 < destination) {
        return new DirectScalarExtent(0, 0, 0, false);
      }

      if (rightSource) {
        if (scalarLoadValid(rightLoadOpcode, right) == false) {
          return new DirectScalarExtent(0, 0, 0, false);
        }
      } else {
        if (kind != RESULT_RELATION_BINARY) {
          return new DirectScalarExtent(0, 0, 0, false);
        }
      }

      length = BINARY_RETURN_BYTES - RETURN_BYTES + destinationBytes;
      localCount = 3;
      instructionCount = 4;
    }

    if (MAX_CODE_BYTES - length < cursor) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    return new DirectScalarExtent(cursor + length, instructionCount, localCount, true);
  }

  /// Writes a preflighted value in source order and its return, store, or assertion destination.
  public DirectScalarExtent writeDirectScalarDestination(
    borrow mut bytes output,
    long cursor,
    long destinationOpcode,
    long destinationOperand,
    long kind,
    long leftLoadOpcode,
    long rightLoadOpcode,
    long destination,
    long left,
    long operation,
    long right,
    long immediate
  ) {
    assert(bufferLength(output) == MAX_CODE_BYTES);
    DirectScalarExtent resultPlan = measureDirectScalarDestination(
      cursor,
      destinationOpcode,
      destinationOperand,
      kind,
      leftLoadOpcode,
      rightLoadOpcode,
      destination,
      left,
      operation,
      right
    );
    if (resultPlan.valid == false) {
      return resultPlan;
    }

    boolean binaryRelation = resultPlan.localCount != 1;
    boolean leftMaterialized = materializedReturn(kind);
    long literalValue = left;
    if (kind == RESULT_RELATION_LEFT_LITERAL) {
      leftMaterialized = true;
      literalValue = immediate;
    }

    long sourceOpcode = leftLoadOpcode;
    if (leftMaterialized) {
      sourceOpcode = OPCODE_LOCAL_CONST;
    }

    long next = writeInstructionHeader(output, cursor, sourceOpcode, INSTRUCTION_FORM_BINARY);
    next = writeUnsignedLittleEndian(output, next, destination, U64);
    if (leftMaterialized) {
      next = writeSignedLittleEndian(output, next, literalValue, U64);
    } else {
      next = writeUnsignedLittleEndian(output, next, left, U64);
    }

    if (binaryRelation == false) {
      next = writeDestination(output, next, destinationOpcode, destinationOperand, destination);
      assert(next == resultPlan.next);
      return resultPlan;
    }

    long rightDestination = destination + 1;
    if (kind == RESULT_RELATION_BINARY) {
      next = writeInstructionHeader(output, next, OPCODE_LOCAL_CONST, INSTRUCTION_FORM_BINARY);
      next = writeUnsignedLittleEndian(output, next, rightDestination, U64);
      next = writeSignedLittleEndian(output, next, immediate, U64);
    } else {
      next = writeInstructionHeader(output, next, rightLoadOpcode, INSTRUCTION_FORM_BINARY);
      next = writeUnsignedLittleEndian(output, next, rightDestination, U64);
      next = writeUnsignedLittleEndian(output, next, right, U64);
    }

    long result = destination + 2;
    next = writeInstructionHeader(output, next, operation, INSTRUCTION_FORM_TERNARY);
    next = writeUnsignedLittleEndian(output, next, result, U64);
    next = writeUnsignedLittleEndian(output, next, destination, U64);
    next = writeUnsignedLittleEndian(output, next, rightDestination, U64);
    next = writeDestination(output, next, destinationOpcode, destinationOperand, result);
    assert(next == resultPlan.next);
    return resultPlan;
  }
}
