//! Emits exact root signed declaration products.

module wheeler.compiler.closure.direct_long_declaration_products;

import wheeler.compiler.closure.direct_buffer_projection_products;
import wheeler.compiler.closure.direct_scalar_encoding;
import wheeler.compiler.closure.direct_scalar_relations;
import wheeler.compiler.closure.direct_statement_coordinates;
import wheeler.compiler.closure.direct_utf8_scalar_products;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.closure.structured_source_coordinates;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.storage_opcodes;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class DirectLongDeclarationProducts {
  private const long MAX_CODE_BYTES = 262144;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports one exact signed declaration instruction and type extent.
  public record DirectLongDeclarationProduct(
    long next,
    long instructionCount,
    long typeCount,
    boolean valid
  ) {}

  private DirectLongDeclarationProduct invalidLongDeclaration() {
    return new DirectLongDeclarationProduct(0, 0, 0, false);
  }

  /// Writes one complete root signed declaration initializer.
  public DirectLongDeclarationProduct writeDirectLongDeclaration(
    borrow utf8 source,
    borrow byteview symbolNames,
    long token,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long moduleOwner,
    long owner,
    long ordinal,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts,
    long valueCount,
    borrow mut words valueRows,
    long symbolCount,
    borrow mut words symbolOwners,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolTypes,
    borrow mut words symbolValues,
    borrow mut words symbolResolved,
    borrow mut words typeRows,
    long typeCount,
    borrow mut bytes output,
    long cursor,
    long localBase
  ) {
    assert(bufferLength(typeRows) == 12288);
    assert(-1 < typeCount);
    assert(typeCount < 4093);
    assert(bufferLength(output) == MAX_CODE_BYTES);
    if (token < 0) {
      return invalidLongDeclaration();
    }

    if (tokenCount < token + 5) {
      return invalidLongDeclaration();
    }

    if (tokenKinds[token + 1] != 1) {
      return invalidLongDeclaration();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 2, PUNCTUATION_ASSIGN) == false
    ) {
      return invalidLongDeclaration();
    }

    LoopBodyValue destination = resolveLoopBodyValue(
      source,
      tokenStarts[token + 1],
      tokenLengths[token + 1],
      owner,
      ordinal + 1,
      valueCount,
      valueRows
    );
    if (destination.valid == false) {
      return invalidLongDeclaration();
    }

    long sourceToken = token + 3;
    boolean indexed = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      sourceToken + 1,
      PUNCTUATION_OPEN_SQUARE
    );
    if (indexed) {
      DirectBufferProjectionProduct projection = writeDirectBufferProjection(
        source,
        sourceToken,
        tokenCount,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        owner,
        ordinal,
        statementCount,
        statementRows,
        statementLocalRows,
        statementPhysicalStarts,
        valueCount,
        valueRows,
        typeRows,
        typeCount,
        output,
        cursor,
        localBase
      );
      if (projection.valid == false) {
        return invalidLongDeclaration();
      }

      return new DirectLongDeclarationProduct(projection.next, 4, projection.typeCount, true);
    }

    boolean utf8ScalarInitializer = tokenHash(source, tokenStarts, tokenLengths, sourceToken)
      == TOKEN_UTF8_SCALAR;
    if (utf8ScalarInitializer) {
      DirectUtf8ScalarProduct utf8Projection = writeDirectUtf8Scalar(
        source,
        sourceToken,
        tokenCount,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        owner,
        ordinal,
        statementCount,
        statementRows,
        statementLocalRows,
        statementPhysicalStarts,
        valueCount,
        valueRows,
        typeRows,
        typeCount,
        output,
        cursor,
        localBase
      );
      if (utf8Projection.valid == false) {
        return invalidLongDeclaration();
      }

      return new DirectLongDeclarationProduct(
        utf8Projection.next,
        4,
        utf8Projection.typeCount,
        true
      );
    }

    boolean bufferLengthInitializer = false;
    if (tokenKinds[sourceToken] == 1) {
      if (
        tokenHash(source, tokenStarts, tokenLengths, sourceToken) == TOKEN_BUFFER_LENGTH
      ) {
        bufferLengthInitializer = punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          sourceToken + 1,
          PUNCTUATION_OPEN_PAREN
        );
      }
    }

    if (bufferLengthInitializer) {
      if (tokenKinds[sourceToken + 2] != 1) {
        return invalidLongDeclaration();
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          sourceToken + 3,
          PUNCTUATION_CLOSE_PAREN
        ) == false
      ) {
        return invalidLongDeclaration();
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, sourceToken + 4, PUNCTUATION_SEMICOLON)
          == false
      ) {
        return invalidLongDeclaration();
      }

      LoopBodyValue buffer = resolveLoopBodyValue(
        source,
        tokenStarts[sourceToken + 2],
        tokenLengths[sourceToken + 2],
        owner,
        ordinal,
        valueCount,
        valueRows
      );
      if (buffer.valid == false) {
        return invalidLongDeclaration();
      }

      long bufferLocal = physicalValueLocal(
        owner,
        buffer.local,
        statementCount,
        statementRows,
        statementLocalRows,
        valueCount,
        valueRows,
        statementPhysicalStarts
      );
      if (bufferLocal < 0) {
        return invalidLongDeclaration();
      }

      long bufferType = directBufferLocalType(
        source,
        owner,
        buffer.local,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      );
      if (bufferType < 0) {
        return invalidLongDeclaration();
      }

      if (253 < localBase) {
        return invalidLongDeclaration();
      }

      if (MAX_CODE_BYTES - 72 < cursor) {
        return invalidLongDeclaration();
      }

      long bufferNext = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      bufferNext = writeUnsignedLittleEndian(output, bufferNext, localBase, U64);
      bufferNext = writeUnsignedLittleEndian(output, bufferNext, bufferLocal, U64);
      bufferNext = writeInstructionHeader(
        output,
        bufferNext,
        OPCODE_BUFFER_LENGTH,
        INSTRUCTION_FORM_BINARY
      );
      bufferNext = writeUnsignedLittleEndian(output, bufferNext, localBase + 1, U64);
      bufferNext = writeUnsignedLittleEndian(output, bufferNext, localBase, U64);
      bufferNext = writeInstructionHeader(
        output,
        bufferNext,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      bufferNext = writeUnsignedLittleEndian(output, bufferNext, localBase + 2, U64);
      bufferNext = writeUnsignedLittleEndian(output, bufferNext, localBase + 1, U64);
      set(typeRows, typeCount, owner);
      set(typeRows, 4096 + typeCount, localBase);
      set(typeRows, 8192 + typeCount, bufferType);
      typeCount += 1;
      long bufferOffset = 1;
      while (bufferOffset < 3) limit 2 {
        set(typeRows, typeCount, owner);
        set(typeRows, 4096 + typeCount, localBase + bufferOffset);
        set(typeRows, 8192 + typeCount, TYPE_SIGNED);
        typeCount += 1;
        bufferOffset += 1;
      }

      return new DirectLongDeclarationProduct(bufferNext, 3, typeCount, true);
    }

    DirectReturnConstant constant = resolveDirectReturnConstant(
      source,
      symbolNames,
      moduleOwner,
      tokenStarts[sourceToken],
      tokenLengths[sourceToken],
      symbolCount,
      symbolOwners,
      symbolStarts,
      symbolLengths,
      symbolTypes,
      symbolValues,
      symbolResolved
    );
    DirectScalarRelationProduct initializer = resolveDirectScalarRelation(
      source,
      symbolNames,
      sourceToken,
      tokenCount,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      moduleOwner,
      owner,
      ordinal,
      statementCount,
      statementRows,
      statementLocalRows,
      statementPhysicalStarts,
      valueCount,
      valueRows,
      symbolCount,
      symbolOwners,
      symbolStarts,
      symbolLengths,
      symbolTypes,
      symbolValues,
      symbolResolved
    );
    if (initializer.valid) {
      boolean binaryInitializer = initializer.kind == RESULT_RELATION_BINARY;
      if (initializer.kind == RESULT_RELATION_BINARY_SOURCES) {
        binaryInitializer = true;
      }

      if (binaryInitializer) {
        DirectScalarExtent scalar = writeDirectScalarDeclaration(
          output,
          cursor,
          initializer.kind,
          localBase,
          initializer.left,
          initializer.leftType,
          initializer.operation,
          initializer.right,
          initializer.rightType,
          TYPE_SIGNED,
          initializer.immediate
        );
        if (scalar.valid == false) {
          return invalidLongDeclaration();
        }

        long scalarOffset = 0;
        while (scalarOffset < scalar.localCount) limit 4 {
          set(typeRows, typeCount, owner);
          set(typeRows, 4096 + typeCount, localBase + scalarOffset);
          set(typeRows, 8192 + typeCount, TYPE_SIGNED);
          typeCount += 1;
          scalarOffset += 1;
        }

        return new DirectLongDeclarationProduct(
          scalar.next,
          scalar.instructionCount,
          typeCount,
          true
        );
      }
    }

    if (254 < localBase) {
      return invalidLongDeclaration();
    }

    long sourceOpcode = OPCODE_LOCAL_CONST;
    long sourceOperand = 0;
    if (tokenKinds[sourceToken] == 1) {
      if (constant.found) {
        if (constant.valid == false) {
          return invalidLongDeclaration();
        }

        if (
          punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            sourceToken + 1,
            PUNCTUATION_SEMICOLON
          ) == false
        ) {
          return invalidLongDeclaration();
        }

        sourceOperand = constant.value;
      } else {
        if (initializer.valid == false) {
          return invalidLongDeclaration();
        }

        if (initializer.kind != RESULT_RELATION_SOURCE) {
          return invalidLongDeclaration();
        }

        if (initializer.leftType != TOKEN_LONG) {
          return invalidLongDeclaration();
        }

        sourceOpcode = OPCODE_LOCAL_MOVE;
        sourceOperand = initializer.left;
      }
    } else {
      long signedWidth = signedNumberWidth(source, tokenKinds, tokenStarts, sourceToken);
      if (signedWidth < 1) {
        return invalidLongDeclaration();
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          sourceToken + signedWidth,
          PUNCTUATION_SEMICOLON
        ) == false
      ) {
        return invalidLongDeclaration();
      }

      if (signedNumberValid(source, tokenStarts, tokenLengths, sourceToken) == false) {
        return invalidLongDeclaration();
      }

      sourceOperand = parsedSignedNumber(source, tokenStarts, tokenLengths, sourceToken);
    }

    if (MAX_CODE_BYTES - 48 < cursor) {
      return invalidLongDeclaration();
    }

    long finalNext = writeInstructionHeader(
      output,
      cursor,
      sourceOpcode,
      INSTRUCTION_FORM_BINARY
    );
    finalNext = writeUnsignedLittleEndian(output, finalNext, localBase, U64);
    if (sourceOpcode == OPCODE_LOCAL_MOVE) {
      finalNext = writeUnsignedLittleEndian(output, finalNext, sourceOperand, U64);
    } else {
      finalNext = writeSignedLittleEndian(output, finalNext, sourceOperand, U64);
    }

    finalNext = writeInstructionHeader(
      output,
      finalNext,
      OPCODE_LOCAL_MOVE,
      INSTRUCTION_FORM_BINARY
    );
    finalNext = writeUnsignedLittleEndian(output, finalNext, localBase + 1, U64);
    finalNext = writeUnsignedLittleEndian(output, finalNext, localBase, U64);
    long finalOffset = 0;
    while (finalOffset < 2) limit 2 {
      set(typeRows, typeCount, owner);
      set(typeRows, 4096 + typeCount, localBase + finalOffset);
      set(typeRows, 8192 + typeCount, TYPE_SIGNED);
      typeCount += 1;
      finalOffset += 1;
    }

    return new DirectLongDeclarationProduct(finalNext, 2, typeCount, true);
  }
}
