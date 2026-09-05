//! Emits exact root Boolean declaration products.

module wheeler.compiler.closure.direct_boolean_declaration_products;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.closure.direct_scalar_encoding;
import wheeler.compiler.closure.direct_scalar_relations;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class DirectBooleanDeclarationProducts {
  private const long MAX_CODE_BYTES = 262144;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports one exact Boolean declaration instruction and type extent.
  public record DirectBooleanDeclarationProduct(
    long next,
    long instructionCount,
    long typeCount,
    boolean valid
  ) {}

  private DirectBooleanDeclarationProduct invalidBooleanDeclaration() {
    return new DirectBooleanDeclarationProduct(0, 0, 0, false);
  }

  /// Writes one complete root Boolean declaration initializer.
  public DirectBooleanDeclarationProduct writeDirectBooleanDeclaration(
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
      return invalidBooleanDeclaration();
    }

    if (tokenCount < token + 5) {
      return invalidBooleanDeclaration();
    }

    if (tokenKinds[token + 1] != 1) {
      return invalidBooleanDeclaration();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 2, PUNCTUATION_ASSIGN) == false
    ) {
      return invalidBooleanDeclaration();
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
      return invalidBooleanDeclaration();
    }

    long sourceToken = token + 3;
    long sourceHash = tokenHash(source, tokenStarts, tokenLengths, sourceToken);
    boolean literal = sourceHash == TOKEN_TRUE;
    if (sourceHash == TOKEN_FALSE) {
      literal = true;
    }

    if (literal) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, sourceToken + 1, PUNCTUATION_SEMICOLON)
          == false
      ) {
        return invalidBooleanDeclaration();
      }

      if (254 < localBase) {
        return invalidBooleanDeclaration();
      }

      if (MAX_CODE_BYTES - 48 < cursor) {
        return invalidBooleanDeclaration();
      }

      long value = 0;
      if (sourceHash == TOKEN_TRUE) {
        value = 1;
      }

      long literalNext = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_CONST,
        INSTRUCTION_FORM_BINARY
      );
      literalNext = writeUnsignedLittleEndian(output, literalNext, localBase, U64);
      literalNext = writeSignedLittleEndian(output, literalNext, value, U64);
      literalNext = writeInstructionHeader(
        output,
        literalNext,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      literalNext = writeUnsignedLittleEndian(output, literalNext, localBase + 1, U64);
      literalNext = writeUnsignedLittleEndian(output, literalNext, localBase, U64);
      long literalOffset = 0;
      while (literalOffset < 2) limit 2 {
        set(typeRows, typeCount, owner);
        set(typeRows, 4096 + typeCount, localBase + literalOffset);
        set(typeRows, 8192 + typeCount, TYPE_BOOLEAN);
        typeCount += 1;
        literalOffset += 1;
      }

      return new DirectBooleanDeclarationProduct(literalNext, 2, typeCount, true);
    }

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
    if (initializer.valid == false) {
      return invalidBooleanDeclaration();
    }

    if (initializer.kind == RESULT_RELATION_SOURCE) {
      if (initializer.leftType != TOKEN_BOOLEAN) {
        return invalidBooleanDeclaration();
      }

      if (254 < localBase) {
        return invalidBooleanDeclaration();
      }

      if (MAX_CODE_BYTES - 48 < cursor) {
        return invalidBooleanDeclaration();
      }

      long sourceNext = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      sourceNext = writeUnsignedLittleEndian(output, sourceNext, localBase, U64);
      sourceNext = writeUnsignedLittleEndian(output, sourceNext, initializer.left, U64);
      sourceNext = writeInstructionHeader(
        output,
        sourceNext,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      sourceNext = writeUnsignedLittleEndian(output, sourceNext, localBase + 1, U64);
      sourceNext = writeUnsignedLittleEndian(output, sourceNext, localBase, U64);
      long sourceOffset = 0;
      while (sourceOffset < 2) limit 2 {
        set(typeRows, typeCount, owner);
        set(typeRows, 4096 + typeCount, localBase + sourceOffset);
        set(typeRows, 8192 + typeCount, TYPE_BOOLEAN);
        typeCount += 1;
        sourceOffset += 1;
      }

      return new DirectBooleanDeclarationProduct(sourceNext, 2, typeCount, true);
    }

    if (
      directRelationResultType(initializer.operation, initializer.leftType) != TYPE_BOOLEAN
    ) {
      return invalidBooleanDeclaration();
    }

    if (
      directReturnTypesValid(
        /* reversibleCallableCount= */ 0,
        initializer.kind,
        initializer.operation,
        initializer.leftType,
        initializer.rightType
      ) == false
    ) {
      return invalidBooleanDeclaration();
    }

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
      TYPE_BOOLEAN,
      initializer.immediate
    );
    if (scalar.valid == false) {
      return invalidBooleanDeclaration();
    }

    long scalarOffset = 0;
    while (scalarOffset < 4) limit 4 {
      long scalarType = TYPE_BOOLEAN;
      if (scalarOffset == 0) {
        scalarType = directReturnType(initializer.leftType);
      }

      if (scalarOffset == 1) {
        scalarType = directReturnType(initializer.rightType);
      }

      set(typeRows, typeCount, owner);
      set(typeRows, 4096 + typeCount, localBase + scalarOffset);
      set(typeRows, 8192 + typeCount, scalarType);
      typeCount += 1;
      scalarOffset += 1;
    }

    return new DirectBooleanDeclarationProduct(
      scalar.next,
      scalar.instructionCount,
      typeCount,
      true
    );
  }
}
