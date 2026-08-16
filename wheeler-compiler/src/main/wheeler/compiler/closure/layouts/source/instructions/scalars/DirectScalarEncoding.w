//! Emits bounded scalar relations from exact source products.

module wheeler.compiler.closure.direct_scalar_encoding;

import wheeler.compiler.closure.module_symbols;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.opcodes;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class DirectScalarEncoding {
  private const long MAX_CODE_BYTES = 262144;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports one exact imported constant use.
  public record DirectReturnConstant(long value, boolean found, boolean valid) {}

  /// Reports the exact code, instruction, and local extent of one scalar relation.
  public record DirectScalarExtent(
    long next,
    long instructionCount,
    long localCount,
    boolean valid
  ) {}

  /// Reports the exact code, instruction, and local extent of one return.
  public record DirectReturnExtent(
    long next,
    long instructionCount,
    long localCount,
    boolean valid
  ) {}

  private boolean returnOperation(long operation) {
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

  private boolean sameSourceName(borrow utf8 source, long left, long right, long length) {
    long offset = 0;
    while (offset < length) limit 256 {
      if (utf8Scalar(source, left + offset) != utf8Scalar(source, right + offset)) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  /// Resolves one imported constant from a local source-anchored name product.
  public DirectReturnConstant resolveDirectReturnConstant(
    borrow utf8 source,
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
        if (symbolLengths[symbol] == tokenLength) {
          long symbolStart = symbolStarts[symbol];
          boolean bounded = -1 < symbolStart;
          if (bufferLength(source) - tokenLength < symbolStart) {
            bounded = false;
          }

          if (bounded) {
            if (sameSourceName(source, tokenStart, symbolStart, tokenLength)) {
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

  /// Checks source types before one ordinary or reversible return emits.
  public boolean directReturnTypesValid(
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

    if (returnOperation(operation) == false) {
      return false;
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
    long localBase,
    long left,
    long leftType,
    long operation,
    long right,
    long rightType,
    long immediate
  ) {
    assert(bufferLength(output) == MAX_CODE_BYTES);
    if (cursor < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (kind == RESULT_RELATION_SOURCE) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (returnOperation(operation) == false) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (leftType != TOKEN_LONG) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (rightType != TOKEN_LONG) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (localBase < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (252 < localBase) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (left < 0) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (255 < left) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    if (kind == RESULT_RELATION_BINARY_SOURCES) {
      if (right < 0) {
        return new DirectScalarExtent(0, 0, 0, false);
      }

      if (255 < right) {
        return new DirectScalarExtent(0, 0, 0, false);
      }
    } else {
      if (kind != RESULT_RELATION_BINARY) {
        return new DirectScalarExtent(0, 0, 0, false);
      }
    }

    if (MAX_CODE_BYTES - 104 < cursor) {
      return new DirectScalarExtent(0, 0, 0, false);
    }

    long next = writeInstructionHeader(
      output,
      cursor,
      OPCODE_LOCAL_MOVE,
      INSTRUCTION_FORM_BINARY
    );
    next = writeUnsignedLittleEndian(output, next, localBase, U64);
    next = writeUnsignedLittleEndian(output, next, left, U64);
    long rightDestination = localBase + 1;
    if (kind == RESULT_RELATION_BINARY) {
      next = writeInstructionHeader(output, next, OPCODE_LOCAL_CONST, INSTRUCTION_FORM_BINARY);
      next = writeUnsignedLittleEndian(output, next, rightDestination, U64);
      next = writeSignedLittleEndian(output, next, immediate, U64);
    } else {
      next = writeInstructionHeader(output, next, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
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
    return new DirectScalarExtent(next, 4, 4, true);
  }

  /// Writes one copied source or one binary source relation.
  public DirectReturnExtent writeDirectReturn(
    borrow mut bytes output,
    long cursor,
    long kind,
    long destination,
    long left,
    long operation,
    long right,
    long immediate
  ) {
    assert(bufferLength(output) == MAX_CODE_BYTES);
    if (cursor < 0) {
      return new DirectReturnExtent(0, 0, 0, false);
    }

    if (destination < 0) {
      return new DirectReturnExtent(0, 0, 0, false);
    }

    if (255 < destination) {
      return new DirectReturnExtent(0, 0, 0, false);
    }

    if (left < 0) {
      return new DirectReturnExtent(0, 0, 0, false);
    }

    if (255 < left) {
      return new DirectReturnExtent(0, 0, 0, false);
    }

    long length = 40;
    long localCount = 1;
    long instructionCount = 2;
    if (kind != RESULT_RELATION_SOURCE) {
      if (returnOperation(operation) == false) {
        return new DirectReturnExtent(0, 0, 0, false);
      }

      if (253 < destination) {
        return new DirectReturnExtent(0, 0, 0, false);
      }

      if (kind == RESULT_RELATION_BINARY_SOURCES) {
        if (right < 0) {
          return new DirectReturnExtent(0, 0, 0, false);
        }

        if (255 < right) {
          return new DirectReturnExtent(0, 0, 0, false);
        }
      } else {
        if (kind != RESULT_RELATION_BINARY) {
          return new DirectReturnExtent(0, 0, 0, false);
        }
      }

      length = 96;
      localCount = 3;
      instructionCount = 4;
    }

    if (MAX_CODE_BYTES - length < cursor) {
      return new DirectReturnExtent(0, 0, 0, false);
    }

    long next = writeInstructionHeader(
      output,
      cursor,
      OPCODE_LOCAL_MOVE,
      INSTRUCTION_FORM_BINARY
    );
    next = writeUnsignedLittleEndian(output, next, destination, U64);
    next = writeUnsignedLittleEndian(output, next, left, U64);
    if (kind == RESULT_RELATION_SOURCE) {
      next = writeInstructionHeader(output, next, OPCODE_RETURN_VALUE, INSTRUCTION_FORM_UNARY);
      next = writeUnsignedLittleEndian(output, next, destination, U64);
      return new DirectReturnExtent(next, instructionCount, localCount, true);
    }

    long rightDestination = destination + 1;
    if (kind == RESULT_RELATION_BINARY) {
      next = writeInstructionHeader(output, next, OPCODE_LOCAL_CONST, INSTRUCTION_FORM_BINARY);
      next = writeUnsignedLittleEndian(output, next, rightDestination, U64);
      next = writeSignedLittleEndian(output, next, immediate, U64);
    } else {
      next = writeInstructionHeader(output, next, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
      next = writeUnsignedLittleEndian(output, next, rightDestination, U64);
      next = writeUnsignedLittleEndian(output, next, right, U64);
    }

    long result = destination + 2;
    next = writeInstructionHeader(output, next, operation, INSTRUCTION_FORM_TERNARY);
    next = writeUnsignedLittleEndian(output, next, result, U64);
    next = writeUnsignedLittleEndian(output, next, destination, U64);
    next = writeUnsignedLittleEndian(output, next, rightDestination, U64);
    next = writeInstructionHeader(output, next, OPCODE_RETURN_VALUE, INSTRUCTION_FORM_UNARY);
    next = writeUnsignedLittleEndian(output, next, result, U64);
    return new DirectReturnExtent(next, instructionCount, localCount, true);
  }
}
