//! Emits one-arm root conditionals with exact literal returns.

module wheeler.compiler.closure.direct_conditional_return_products;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.closure.direct_scalar_encoding;
import wheeler.compiler.closure.direct_scalar_relations;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.closure.structured_source_coordinates;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class DirectConditionalReturnProducts {
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_STATEMENTS = 4096;
  private const long STATEMENT_FIRST_CHILD_ROW = 20480;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports one complete root conditional and its consumed child statement.
  public record DirectConditionalReturnProduct(
    long next,
    long childStatement,
    long instructionCount,
    long typeCount,
    long resultType,
    long failureCode,
    boolean valid
  ) {}

  private DirectConditionalReturnProduct invalidConditionalReturn(long failureCode) {
    return new DirectConditionalReturnProduct(0, 0, 0, 0, 0, failureCode, false);
  }

  private long childStatementForBlock(
    long owner,
    long childBlock,
    long statementCount,
    borrow mut words statementRows
  ) {
    long selected = -1;
    long matches = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      if (statementRows[statement] == owner) {
        if (statementRows[4096 + statement] == childBlock) {
          selected = statement;
          matches += 1;
        }
      }

      statement += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  /// Writes one exact `if (left op right) { return literal; }` product.
  public DirectConditionalReturnProduct writeDirectConditionalReturn(
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
    long statement,
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
    long instructionStart
  ) {
    assert(bufferLength(typeRows) == 12288);
    assert(-1 < typeCount);
    assert(typeCount < 4089);
    assert(bufferLength(output) == MAX_CODE_BYTES);
    if (token < 0) {
      return invalidConditionalReturn(1);
    }

    if (tokenCount < token + 9) {
      return invalidConditionalReturn(2);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_OPEN_PAREN) == false
    ) {
      return invalidConditionalReturn(3);
    }

    long leftToken = token + 2;
    if (tokenKinds[leftToken] != 1) {
      return invalidConditionalReturn(4);
    }

    long operationToken = leftToken + 1;
    long operation = -1;
    long rightToken = operationToken + 1;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, operationToken, PUNCTUATION_LESS_THAN)
    ) {
      operation = OPCODE_LOCAL_LT;
    } else {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, operationToken, PUNCTUATION_ASSIGN)
      ) {
        if (
          punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            operationToken + 1,
            PUNCTUATION_ASSIGN
          )
        ) {
          operation = OPCODE_LOCAL_EQ;
          rightToken += 1;
        }
      }
    }

    if (operation < 0) {
      return invalidConditionalReturn(5);
    }

    LoopBodyValue leftValue = resolveLoopBodyValue(
      source,
      tokenStarts[leftToken],
      tokenLengths[leftToken],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (leftValue.valid == false) {
      return invalidConditionalReturn(6);
    }

    boolean signedCondition = signedLoopBodyLocal(
      source,
      owner,
      leftValue.local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    boolean booleanCondition = booleanLoopBodyLocal(
      source,
      owner,
      leftValue.local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (signedCondition == false) {
      if (booleanCondition == false) {
        return invalidConditionalReturn(7);
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
      return invalidConditionalReturn(8);
    }

    long right = 0;
    long rightOpcode = OPCODE_LOCAL_CONST;
    long rightWidth = 1;
    if (booleanCondition) {
      if (operation != OPCODE_LOCAL_EQ) {
        return invalidConditionalReturn(39);
      }

      long booleanHash = tokenHash(source, tokenStarts, tokenLengths, rightToken);
      if (booleanHash == TOKEN_TRUE) {
        right = 1;
      } else {
        if (booleanHash != TOKEN_FALSE) {
          return invalidConditionalReturn(40);
        }
      }
    } else {
      if (tokenKinds[rightToken] == 1) {
        DirectReturnConstant constant = resolveDirectReturnConstant(
          source,
          symbolNames,
          moduleOwner,
          tokenStarts[rightToken],
          tokenLengths[rightToken],
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
            return invalidConditionalReturn(9);
          }

          right = constant.value;
        } else {
          LoopBodyValue rightValue = resolveLoopBodyValue(
            source,
            tokenStarts[rightToken],
            tokenLengths[rightToken],
            owner,
            ordinal,
            valueCount,
            valueRows
          );
          if (rightValue.valid == false) {
            return invalidConditionalReturn(10);
          }

          if (
            signedLoopBodyLocal(
              source,
              owner,
              rightValue.local,
              valueCount,
              valueRows,
              tokenCount,
              tokenStarts,
              tokenLengths
            ) == false
          ) {
            return invalidConditionalReturn(11);
          }

          right = physicalValueLocal(
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
            return invalidConditionalReturn(12);
          }

          rightOpcode = OPCODE_LOCAL_MOVE;
        }
      } else {
        rightWidth = signedNumberWidth(source, tokenKinds, tokenStarts, rightToken);
        if (rightWidth < 1) {
          return invalidConditionalReturn(13);
        }

        if (signedNumberValid(source, tokenStarts, tokenLengths, rightToken) == false) {
          return invalidConditionalReturn(14);
        }

        right = parsedSignedNumber(source, tokenStarts, tokenLengths, rightToken);
      }
    }

    long closeToken = rightToken + rightWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, closeToken, PUNCTUATION_CLOSE_PAREN) == false
    ) {
      return invalidConditionalReturn(15);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, closeToken + 1, PUNCTUATION_OPEN_BRACE)
        == false
    ) {
      return invalidConditionalReturn(16);
    }

    long childBlock = statementRows[STATEMENT_FIRST_CHILD_ROW + statement];
    long childStatement = childStatementForBlock(
      owner,
      childBlock,
      statementCount,
      statementRows
    );
    if (childStatement < 0) {
      return invalidConditionalReturn(17);
    }

    if (statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + childStatement] != 0) {
      return invalidConditionalReturn(18);
    }

    long childToken = closeToken + 2;
    if (tokenCount < childToken + 4) {
      return invalidConditionalReturn(32);
    }

    if (
      tokenStarts[childToken] != statementRows[LOOP_STATEMENT_START_ROW + childStatement]
    ) {
      return invalidConditionalReturn(19);
    }

    if (tokenHash(source, tokenStarts, tokenLengths, childToken) != TOKEN_RETURN) {
      return invalidConditionalReturn(20);
    }

    long semicolonToken = -1;
    long semicolonMatches = 0;
    long expectedSemicolonStart = statementRows[LOOP_STATEMENT_START_ROW + childStatement]
      + statementRows[LOOP_STATEMENT_LENGTH_ROW + childStatement] - 1;
    long candidateToken = childToken + 1;
    long childTokenEnd = childToken + 8;
    if (tokenCount < childTokenEnd) {
      childTokenEnd = tokenCount;
    }

    while (candidateToken < childTokenEnd) limit 7 {
      if (tokenStarts[candidateToken] == expectedSemicolonStart) {
        semicolonToken = candidateToken;
        semicolonMatches += 1;
      }

      candidateToken += 1;
    }

    if (semicolonMatches != 1) {
      return invalidConditionalReturn(22);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, semicolonToken, PUNCTUATION_SEMICOLON) == false
    ) {
      return invalidConditionalReturn(22);
    }

    if (tokenCount < semicolonToken + 2) {
      return invalidConditionalReturn(32);
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        semicolonToken + 1,
        PUNCTUATION_CLOSE_BRACE
      ) == false
    ) {
      return invalidConditionalReturn(33);
    }

    if (
      tokenStarts[semicolonToken + 1] + tokenLengths[semicolonToken
        + 1] != statementRows[LOOP_STATEMENT_START_ROW + statement]
        + statementRows[LOOP_STATEMENT_LENGTH_ROW + statement]
    ) {
      return invalidConditionalReturn(34);
    }

    long literalHash = tokenHash(source, tokenStarts, tokenLengths, childToken + 1);
    boolean literalChild = literalHash == TOKEN_TRUE;
    if (literalHash == TOKEN_FALSE) {
      literalChild = true;
    }

    long literal = 0;
    if (literalHash == TOKEN_TRUE) {
      literal = 1;
    }

    long childKind = 0;
    long childOperation = 0;
    long childLeft = 0;
    long childRight = 0;
    long childImmediate = 0;
    long childLeftType = 0;
    long childRightType = 0;
    long childLocalCount = 1;
    long childInstructionCount = 2;
    long childResultType = TYPE_BOOLEAN;
    if (literalChild == false) {
      DirectScalarRelationProduct childRelation = resolveDirectReturnRelation(
        source,
        symbolNames,
        childToken + 1,
        tokenCount,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        moduleOwner,
        owner,
        statementRows[LOOP_STATEMENT_ORDINAL_ROW + childStatement],
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
      if (childRelation.valid == false) {
        return invalidConditionalReturn(21);
      }

      childResultType = directRelationResultType(childRelation.operation, childRelation.leftType);
      if (childResultType != TYPE_SIGNED) {
        if (childResultType != TYPE_BOOLEAN) {
          return invalidConditionalReturn(35);
        }

        if (childRelation.kind != RESULT_RELATION_SOURCE) {
          return invalidConditionalReturn(35);
        }
      }

      if (
        directReturnTypesValid(
          /* reversibleCallableCount= */ 0,
          childRelation.kind,
          childRelation.operation,
          childRelation.leftType,
          childRelation.rightType
        ) == false
      ) {
        return invalidConditionalReturn(36);
      }

      childKind = childRelation.kind;
      childOperation = childRelation.operation;
      childLeft = childRelation.left;
      childRight = childRelation.right;
      childImmediate = childRelation.immediate;
      childLeftType = childRelation.leftType;
      childRightType = childRelation.rightType;
      boolean binaryChild = childKind != RESULT_RELATION_SOURCE;
      if (childKind == RESULT_RELATION_CONSTANT) {
        binaryChild = false;
      }

      if (childKind == RESULT_RELATION_LITERAL) {
        binaryChild = false;
      }

      if (binaryChild) {
        childLocalCount = 3;
        childInstructionCount = 4;
      }
    }

    long localBase = statementPhysicalStarts[statement];
    long childLocal = statementPhysicalStarts[childStatement];
    if (localBase < 0) {
      return invalidConditionalReturn(23);
    }

    if (252 < localBase) {
      return invalidConditionalReturn(24);
    }

    if (childLocal != localBase + 3) {
      return invalidConditionalReturn(25);
    }

    if (statementLocalRows[4096 + statement] != 3) {
      return invalidConditionalReturn(26);
    }

    if (statementLocalRows[4096 + childStatement] != childLocalCount) {
      return invalidConditionalReturn(27);
    }

    if (256 - childLocalCount < childLocal) {
      return invalidConditionalReturn(37);
    }

    if (instructionStart < 0) {
      return invalidConditionalReturn(28);
    }

    long totalInstructionCount = childInstructionCount + 5;
    if (32768 - totalInstructionCount < instructionStart) {
      return invalidConditionalReturn(29);
    }

    if (MAX_CODE_BYTES - 224 < cursor) {
      return invalidConditionalReturn(30);
    }

    long branchTarget = instructionStart + totalInstructionCount;
    long next = writeInstructionHeader(
      output,
      cursor,
      OPCODE_LOCAL_MOVE,
      INSTRUCTION_FORM_BINARY
    );
    next = writeUnsignedLittleEndian(output, next, localBase, U64);
    next = writeUnsignedLittleEndian(output, next, left, U64);
    next = writeInstructionHeader(output, next, rightOpcode, INSTRUCTION_FORM_BINARY);
    next = writeUnsignedLittleEndian(output, next, localBase + 1, U64);
    if (rightOpcode == OPCODE_LOCAL_MOVE) {
      next = writeUnsignedLittleEndian(output, next, right, U64);
    } else {
      next = writeSignedLittleEndian(output, next, right, U64);
    }

    next = writeInstructionHeader(output, next, operation, INSTRUCTION_FORM_TERNARY);
    next = writeUnsignedLittleEndian(output, next, localBase + 2, U64);
    next = writeUnsignedLittleEndian(output, next, localBase, U64);
    next = writeUnsignedLittleEndian(output, next, localBase + 1, U64);
    next = writeInstructionHeader(output, next, OPCODE_JUMP_IF_ZERO, INSTRUCTION_FORM_BINARY);
    next = writeUnsignedLittleEndian(output, next, localBase + 2, U64);
    next = writeUnsignedLittleEndian(output, next, branchTarget, U64);
    if (literalChild) {
      next = writeInstructionHeader(output, next, OPCODE_LOCAL_CONST, INSTRUCTION_FORM_BINARY);
      next = writeUnsignedLittleEndian(output, next, childLocal, U64);
      next = writeSignedLittleEndian(output, next, literal, U64);
      next = writeInstructionHeader(output, next, OPCODE_RETURN_VALUE, INSTRUCTION_FORM_UNARY);
      next = writeUnsignedLittleEndian(output, next, childLocal, U64);
    } else {
      DirectReturnExtent childExtent = writeDirectReturn(
        output,
        next,
        childKind,
        childLocal,
        childLeft,
        childOperation,
        childRight,
        childImmediate
      );
      if (childExtent.valid == false) {
        return invalidConditionalReturn(38);
      }

      next = childExtent.next;
    }

    next = writeInstructionHeader(output, next, OPCODE_JUMP, INSTRUCTION_FORM_UNARY);
    next = writeUnsignedLittleEndian(output, next, branchTarget, U64);
    long parentLocalOffset = 0;
    while (parentLocalOffset < 3) limit 3 {
      long parentLocalType = TYPE_SIGNED;
      if (booleanCondition) {
        parentLocalType = TYPE_BOOLEAN;
      } else {
        if (parentLocalOffset == 2) {
          parentLocalType = TYPE_BOOLEAN;
        }
      }

      set(typeRows, typeCount, owner);
      set(typeRows, 4096 + typeCount, localBase + parentLocalOffset);
      set(typeRows, 8192 + typeCount, parentLocalType);
      typeCount += 1;
      parentLocalOffset += 1;
    }

    long childLocalOffset = 0;
    while (childLocalOffset < childLocalCount) limit 3 {
      long childLocalType = childResultType;
      if (literalChild == false) {
        if (childKind != RESULT_RELATION_SOURCE) {
          if (childLocalOffset == 0) {
            childLocalType = directReturnType(childLeftType);
          }

          if (childLocalOffset == 1) {
            childLocalType = directReturnType(childRightType);
          }
        }
      }

      set(typeRows, typeCount, owner);
      set(typeRows, 4096 + typeCount, childLocal + childLocalOffset);
      set(typeRows, 8192 + typeCount, childLocalType);
      typeCount += 1;
      childLocalOffset += 1;
    }

    return new DirectConditionalReturnProduct(
      next,
      childStatement,
      totalInstructionCount,
      typeCount,
      childResultType,
      0,
      true
    );
  }
}
