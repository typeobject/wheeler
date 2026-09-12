//! Resolves identifier-led scalar relations onto exact frame and global locations.

module wheeler.compiler.closure.direct_scalar_relations;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.closure.direct_scalar_encoding;
import wheeler.compiler.closure.direct_scalar_locations;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.source_global_references;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class DirectScalarRelations {
  /// Carries one exact relation with explicit load instructions for named operands.
  public record DirectScalarRelationProduct(
    long kind,
    long operation,
    long left,
    long right,
    long immediate,
    long leftType,
    long rightType,
    long leftLoadOpcode,
    long rightLoadOpcode,
    boolean valid
  ) {}

  private DirectScalarRelationProduct invalidRelation() {
    return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, 0, 0, false);
  }

  /// Resolves one complete identifier-led relation without reading dependency source.
  public DirectScalarRelationProduct resolveDirectScalarRelation(
    borrow utf8 source,
    borrow byteview symbolNames,
    borrow byteview globalNames,
    long globalCount,
    long globalProductStart,
    borrow mut words globals,
    long leftToken,
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
    long terminator
  ) {
    assert(-1 < leftToken);
    assert(-1 < tokenCount);
    assert(tokenCount < MAX_COMPILER_TOKENS + 1);
    assert(bufferLength(tokenKinds) == MAX_COMPILER_TOKENS);
    assert(bufferLength(tokenStarts) == MAX_COMPILER_TOKENS);
    assert(bufferLength(tokenLengths) == MAX_COMPILER_TOKENS);
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < owner);
    assert(owner < 64);
    assert(-1 < ordinal);
    assert(-1 < statementCount);
    assert(statementCount < 4097);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(bufferLength(statementLocalRows) == 8192);
    assert(bufferLength(statementPhysicalStarts) == 4096);
    assert(-1 < valueCount);
    assert(valueCount < 1025);
    assert(bufferLength(valueRows) == LOOP_VALUE_ROWS);
    requireSourceGlobalNames(globalNames, globalCount, globalProductStart, globals);

    SourceReversibleResultRelation relation = sourceScalarRelation(
      source,
      leftToken,
      tokenCount,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      terminator
    );
    if (relation.valid == false) {
      return invalidRelation();
    }

    long boundToken = relation.leftToken;
    if (relation.kind == RESULT_RELATION_LEFT_LITERAL) {
      if (terminator != PUNCTUATION_CLOSE_PAREN) {
        return invalidRelation();
      }

      boundToken = relation.rightToken;
    }

    DirectScalarLocation left = resolveDirectScalarLocation(
      source,
      tokenStarts[boundToken],
      tokenLengths[boundToken],
      globalNames,
      globalCount,
      globalProductStart,
      globals,
      owner,
      ordinal,
      statementCount,
      statementRows,
      statementLocalRows,
      statementPhysicalStarts,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (left.valid == false) {
      return invalidRelation();
    }

    if (relation.kind == RESULT_RELATION_LEFT_LITERAL) {
      return new DirectScalarRelationProduct(
        relation.kind,
        relation.operation,
        0,
        left.operand,
        relation.immediate,
        TOKEN_LONG,
        left.sourceType,
        OPCODE_LOCAL_MOVE,
        left.loadOpcode,
        true
      );
    }

    if (relation.kind == RESULT_RELATION_SOURCE) {
      return new DirectScalarRelationProduct(
        relation.kind,
        relation.operation,
        left.operand,
        0,
        relation.immediate,
        left.sourceType,
        0,
        left.loadOpcode,
        OPCODE_LOCAL_MOVE,
        true
      );
    }

    if (relation.kind == RESULT_RELATION_BINARY) {
      return new DirectScalarRelationProduct(
        relation.kind,
        relation.operation,
        left.operand,
        0,
        relation.immediate,
        left.sourceType,
        TOKEN_LONG,
        left.loadOpcode,
        OPCODE_LOCAL_MOVE,
        true
      );
    }

    DirectReturnConstant constant = resolveDirectReturnConstant(
      source,
      symbolNames,
      moduleOwner,
      tokenStarts[relation.rightToken],
      tokenLengths[relation.rightToken],
      symbolCount,
      symbolOwners,
      symbolStarts,
      symbolLengths,
      symbolTypes,
      symbolValues,
      symbolResolved
    );
    if (constant.found) {
      if (constant.valid == false) {
        return invalidRelation();
      }

      if (
        -1 < sourceGlobalOrdinal(
          source,
          tokenStarts[relation.rightToken],
          tokenLengths[relation.rightToken],
          globalNames,
          globalCount,
          globalProductStart,
          globals
        )
      ) {
        return invalidRelation();
      }

      return new DirectScalarRelationProduct(
        RESULT_RELATION_BINARY,
        relation.operation,
        left.operand,
        0,
        constant.value,
        left.sourceType,
        TOKEN_LONG,
        left.loadOpcode,
        OPCODE_LOCAL_MOVE,
        true
      );
    }

    DirectScalarLocation right = resolveDirectScalarLocation(
      source,
      tokenStarts[relation.rightToken],
      tokenLengths[relation.rightToken],
      globalNames,
      globalCount,
      globalProductStart,
      globals,
      owner,
      ordinal,
      statementCount,
      statementRows,
      statementLocalRows,
      statementPhysicalStarts,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (right.valid == false) {
      return invalidRelation();
    }

    return new DirectScalarRelationProduct(
      relation.kind,
      relation.operation,
      left.operand,
      right.operand,
      0,
      left.sourceType,
      right.sourceType,
      left.loadOpcode,
      right.loadOpcode,
      true
    );
  }

  /// Resolves a complete scalar value without allowing a constant to replace declared state.
  public DirectScalarRelationProduct resolveDirectScalarValue(
    borrow utf8 source,
    borrow byteview symbolNames,
    borrow byteview globalNames,
    long globalCount,
    long globalProductStart,
    borrow mut words globals,
    long leftToken,
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
    long terminator
  ) {
    requireSourceGlobalNames(globalNames, globalCount, globalProductStart, globals);
    if (-1 < leftToken) {
      if (leftToken + 1 < tokenCount) {
        long literalWordCode = sourceTokenCode(source, tokenStarts, tokenLengths, leftToken);
        boolean booleanLiteral = literalWordCode == TOKEN_TRUE;
        if (literalWordCode == TOKEN_FALSE) {
          booleanLiteral = true;
        }

        if (booleanLiteral) {
          if (
            punctuationAt(source, tokenKinds, tokenStarts, leftToken + 1, terminator) == false
          ) {
            return invalidRelation();
          }

          long literalValue = 0;
          if (literalWordCode == TOKEN_TRUE) {
            literalValue = 1;
          }

          return new DirectScalarRelationProduct(
            RESULT_RELATION_LITERAL,
            0,
            literalValue,
            0,
            0,
            TOKEN_BOOLEAN,
            0,
            OPCODE_LOCAL_MOVE,
            OPCODE_LOCAL_MOVE,
            true
          );
        }
      }
    }

    long signedWidth = signedNumberWidth(source, tokenKinds, tokenStarts, leftToken);
    if (0 < signedWidth) {
      if (tokenCount < leftToken + signedWidth + 1) {
        return invalidRelation();
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, leftToken + signedWidth, terminator)
      ) {
        if (signedNumberValid(source, tokenStarts, tokenLengths, leftToken) == false) {
          return invalidRelation();
        }

        return new DirectScalarRelationProduct(
          RESULT_RELATION_LITERAL,
          0,
          parsedSignedNumber(source, tokenStarts, tokenLengths, leftToken),
          0,
          0,
          TOKEN_LONG,
          0,
          OPCODE_LOCAL_MOVE,
          OPCODE_LOCAL_MOVE,
          true
        );
      }

      if (terminator != PUNCTUATION_CLOSE_PAREN) {
        return invalidRelation();
      }
    }

    SourceReversibleResultRelation relation = sourceScalarRelation(
      source,
      leftToken,
      tokenCount,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      terminator
    );
    if (relation.valid == false) {
      return invalidRelation();
    }

    DirectReturnConstant constant = resolveDirectReturnConstant(
      source,
      symbolNames,
      moduleOwner,
      tokenStarts[relation.leftToken],
      tokenLengths[relation.leftToken],
      symbolCount,
      symbolOwners,
      symbolStarts,
      symbolLengths,
      symbolTypes,
      symbolValues,
      symbolResolved
    );
    if (constant.found) {
      if (constant.valid == false) {
        return invalidRelation();
      }

      if (relation.kind != RESULT_RELATION_SOURCE) {
        return invalidRelation();
      }

      if (
        -1 < sourceGlobalOrdinal(
          source,
          tokenStarts[relation.leftToken],
          tokenLengths[relation.leftToken],
          globalNames,
          globalCount,
          globalProductStart,
          globals
        )
      ) {
        return invalidRelation();
      }

      return new DirectScalarRelationProduct(
        RESULT_RELATION_CONSTANT,
        0,
        constant.value,
        0,
        0,
        TOKEN_LONG,
        0,
        OPCODE_LOCAL_MOVE,
        OPCODE_LOCAL_MOVE,
        true
      );
    }

    return resolveDirectScalarRelation(
      source,
      symbolNames,
      globalNames,
      globalCount,
      globalProductStart,
      globals,
      leftToken,
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
      symbolResolved,
      terminator
    );
  }
}
