//! Resolves identifier-led scalar relations onto exact physical products.

module wheeler.compiler.closure.direct_scalar_relations;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.closure.direct_scalar_encoding;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.closure.structured_source_coordinates;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class DirectScalarRelations {
  /// Carries one exact scalar relation over physical locals or an immediate.
  public record DirectScalarRelationProduct(
    long kind,
    long operation,
    long left,
    long right,
    long immediate,
    long leftType,
    long rightType,
    boolean valid
  ) {}

  /// Resolves one complete identifier-led relation without reading dependency source.
  public DirectScalarRelationProduct resolveDirectScalarRelation(
    borrow utf8 source,
    borrow byteview symbolNames,
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
    borrow mut words symbolResolved
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

    SourceReversibleResultRelation relation = sourceScalarRelation(
      source,
      leftToken,
      tokenCount,
      tokenKinds,
      tokenStarts,
      tokenLengths
    );
    if (relation.valid == false) {
      return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
    }

    LoopBodyValue leftValue = resolveLoopBodyValue(
      source,
      tokenStarts[relation.leftToken],
      tokenLengths[relation.leftToken],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (leftValue.valid == false) {
      return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
    }

    long leftType = loopBodyValueType(
      source,
      owner,
      leftValue.local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (leftType != TOKEN_LONG) {
      if (leftType != TOKEN_BOOLEAN) {
        return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
      }
    }

    long left = physicalValueLocal(
      owner,
      leftValue.local,
      statementCount,
      statementRows,
      statementLocalRows,
      valueCount,
      valueRows,
      statementPhysicalStarts
    );
    if (left < 0) {
      return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
    }

    if (relation.kind == RESULT_RELATION_SOURCE) {
      return new DirectScalarRelationProduct(
        relation.kind,
        relation.operation,
        left,
        0,
        relation.immediate,
        leftType,
        0,
        true
      );
    }

    if (relation.kind == RESULT_RELATION_BINARY) {
      return new DirectScalarRelationProduct(
        relation.kind,
        relation.operation,
        left,
        0,
        relation.immediate,
        leftType,
        TOKEN_LONG,
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
        return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
      }

      return new DirectScalarRelationProduct(
        RESULT_RELATION_BINARY,
        relation.operation,
        left,
        0,
        constant.value,
        leftType,
        TOKEN_LONG,
        true
      );
    }

    LoopBodyValue rightValue = resolveLoopBodyValue(
      source,
      tokenStarts[relation.rightToken],
      tokenLengths[relation.rightToken],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (rightValue.valid == false) {
      return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
    }

    long rightType = loopBodyValueType(
      source,
      owner,
      rightValue.local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (rightType != TOKEN_LONG) {
      if (rightType != TOKEN_BOOLEAN) {
        return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
      }
    }

    long right = physicalValueLocal(
      owner,
      rightValue.local,
      statementCount,
      statementRows,
      statementLocalRows,
      valueCount,
      valueRows,
      statementPhysicalStarts
    );
    if (right < 0) {
      return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
    }

    return new DirectScalarRelationProduct(
      relation.kind,
      relation.operation,
      left,
      right,
      0,
      leftType,
      rightType,
      true
    );
  }

  /// Resolves one complete return relation with constant precedence on its left source.
  public DirectScalarRelationProduct resolveDirectReturnRelation(
    borrow utf8 source,
    borrow byteview symbolNames,
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
    borrow mut words symbolResolved
  ) {
    if (-1 < leftToken) {
      if (leftToken + 1 < tokenCount) {
        long literalHash = tokenHash(source, tokenStarts, tokenLengths, leftToken);
        boolean booleanLiteral = literalHash == TOKEN_TRUE;
        if (literalHash == TOKEN_FALSE) {
          booleanLiteral = true;
        }

        if (booleanLiteral) {
          if (
            punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              leftToken + 1,
              PUNCTUATION_SEMICOLON
            ) == false
          ) {
            return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
          }

          long literalValue = 0;
          if (literalHash == TOKEN_TRUE) {
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
            true
          );
        }
      }
    }

    long signedWidth = signedNumberWidth(source, tokenKinds, tokenStarts, leftToken);
    if (0 < signedWidth) {
      if (tokenCount < leftToken + signedWidth + 1) {
        return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          leftToken + signedWidth,
          PUNCTUATION_SEMICOLON
        ) == false
      ) {
        return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
      }

      if (signedNumberValid(source, tokenStarts, tokenLengths, leftToken) == false) {
        return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
      }

      return new DirectScalarRelationProduct(
        RESULT_RELATION_LITERAL,
        0,
        parsedSignedNumber(source, tokenStarts, tokenLengths, leftToken),
        0,
        0,
        TOKEN_LONG,
        0,
        true
      );
    }

    SourceReversibleResultRelation relation = sourceScalarRelation(
      source,
      leftToken,
      tokenCount,
      tokenKinds,
      tokenStarts,
      tokenLengths
    );
    if (relation.valid == false) {
      return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
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
        return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
      }

      if (relation.kind != RESULT_RELATION_SOURCE) {
        return new DirectScalarRelationProduct(0, 0, 0, 0, 0, 0, 0, false);
      }

      return new DirectScalarRelationProduct(
        RESULT_RELATION_CONSTANT,
        0,
        constant.value,
        0,
        0,
        TOKEN_LONG,
        0,
        true
      );
    }

    return resolveDirectScalarRelation(
      source,
      symbolNames,
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
      symbolResolved
    );
  }
}
