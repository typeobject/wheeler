//! Parses bounded scalar relations through explicit statement or predicate terminators.

module wheeler.compiler.closure.source_reversible_result_relations;

import wheeler.compiler.closure.reversible_token_coordinates;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class SourceReversibleResultRelations {
  /// Names a result copied from one preserved source local.
  public const long RESULT_RELATION_SOURCE = 1;
  /// Names a result computed from one source and one right immediate.
  public const long RESULT_RELATION_BINARY = 2;
  /// Names a result computed from two named sources.
  public const long RESULT_RELATION_BINARY_SOURCES = 3;
  /// Names a signed result materialized from one exact constant product.
  public const long RESULT_RELATION_CONSTANT = 4;
  /// Names a result materialized from one exact source literal.
  public const long RESULT_RELATION_LITERAL = 5;
  /// Preserves the source order of a left signed literal and a named right operand.
  public const long RESULT_RELATION_LEFT_LITERAL = 6;

  /// Reserves the destination of one copied or materialized scalar.
  public const long SCALAR_RESULT_LOCALS = 1;
  /// Counts the separate left and right expression operands.
  public const long SCALAR_BINARY_OPERANDS = 2;
  /// Reserves both operands and the computed scalar result.
  public const long SCALAR_BINARY_VALUE_LOCALS = SCALAR_BINARY_OPERANDS + SCALAR_RESULT_LOCALS;
  private const long ASSERTION_ENVELOPE_TOKENS = 4;
  private const long MINIMUM_SCALAR_TOKENS = 1;

  /// Carries source operand coordinates, a full immediate, and the exact terminating token.
  public record SourceReversibleResultRelation(
    long kind,
    long leftToken,
    long operation,
    long rightToken,
    long immediate,
    long endToken,
    boolean valid
  ) {}

  private SourceReversibleResultRelation invalidRelation() {
    return new SourceReversibleResultRelation(0, 0, 0, 0, 0, 0, false);
  }

  private long resultOperation(long scalar) {
    if (scalar == 43) {
      return OPCODE_LOCAL_ADD;
    }

    if (scalar == 45) {
      return OPCODE_LOCAL_SUB;
    }

    if (scalar == 42) {
      return OPCODE_LOCAL_MUL;
    }

    if (scalar == 47) {
      return OPCODE_LOCAL_DIV;
    }

    if (scalar == 37) {
      return OPCODE_LOCAL_MOD;
    }

    if (scalar == 94) {
      return OPCODE_LOCAL_XOR;
    }

    if (scalar == 38) {
      return OPCODE_LOCAL_AND;
    }

    if (scalar == PUNCTUATION_LESS_THAN) {
      return OPCODE_LOCAL_LT;
    }

    return -1;
  }

  /// Parses syntax without resolving names or inventing frame locations for global operands.
  public SourceReversibleResultRelation sourceScalarRelation(
    borrow utf8 source,
    long leftToken,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long terminator
  ) {
    assert(-1 < tokenCount);
    assert(tokenCount < MAX_COMPILER_TOKENS + 1);
    assert(bufferLength(tokenKinds) == MAX_COMPILER_TOKENS);
    assert(bufferLength(tokenStarts) == MAX_COMPILER_TOKENS);
    assert(bufferLength(tokenLengths) == MAX_COMPILER_TOKENS);
    if (terminator != PUNCTUATION_SEMICOLON) {
      if (terminator != PUNCTUATION_CLOSE_PAREN) {
        return invalidRelation();
      }
    }

    if (leftToken < 0) {
      return invalidRelation();
    }

    if (tokenCount - 2 < leftToken) {
      return invalidRelation();
    }

    long leftWidth = 1;
    boolean leftLiteral = tokenKinds[leftToken] != 1;
    long immediate = 0;
    if (leftLiteral) {
      leftWidth = signedNumberWidth(source, tokenKinds, tokenStarts, leftToken);
      if (leftWidth < 1) {
        return invalidRelation();
      }

      if (tokenCount - leftToken < leftWidth + 1) {
        return invalidRelation();
      }

      if (signedNumberValid(source, tokenStarts, tokenLengths, leftToken) == false) {
        return invalidRelation();
      }

      immediate = parsedSignedNumber(source, tokenStarts, tokenLengths, leftToken);
    }

    long operationToken = leftToken + leftWidth;
    if (punctuationAt(source, tokenKinds, tokenStarts, operationToken, terminator)) {
      long sourceKind = RESULT_RELATION_SOURCE;
      if (leftLiteral) {
        sourceKind = RESULT_RELATION_LITERAL;
      }

      return new SourceReversibleResultRelation(
        sourceKind,
        leftToken,
        0,
        0,
        immediate,
        operationToken,
        true
      );
    }

    if (tokenCount - operationToken < 3) {
      return invalidRelation();
    }

    if (tokenKinds[operationToken] != 3) {
      return invalidRelation();
    }

    long operationScalar = utf8Scalar(source, tokenStarts[operationToken]);
    long operation = resultOperation(operationScalar);
    long rightToken = operationToken + 1;
    if (operationScalar == PUNCTUATION_ASSIGN) {
      if (tokenCount - operationToken < 4) {
        return invalidRelation();
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, rightToken, PUNCTUATION_ASSIGN) == false
      ) {
        return invalidRelation();
      }

      if (tokenStarts[rightToken] != tokenStarts[operationToken] + 1) {
        return invalidRelation();
      }

      operation = OPCODE_LOCAL_EQ;
      rightToken += 1;
    }

    if (operation < 0) {
      return invalidRelation();
    }

    long kind = RESULT_RELATION_BINARY_SOURCES;
    long endToken = rightToken + 1;
    if (tokenKinds[rightToken] != 1) {
      if (leftLiteral) {
        return invalidRelation();
      }

      long rightWidth = signedNumberWidth(source, tokenKinds, tokenStarts, rightToken);
      if (rightWidth < 1) {
        return invalidRelation();
      }

      if (tokenCount - rightToken < rightWidth + 1) {
        return invalidRelation();
      }

      if (signedNumberValid(source, tokenStarts, tokenLengths, rightToken) == false) {
        return invalidRelation();
      }

      kind = RESULT_RELATION_BINARY;
      endToken = rightToken + rightWidth;
      immediate = parsedSignedNumber(source, tokenStarts, tokenLengths, rightToken);
    } else {
      if (leftLiteral) {
        kind = RESULT_RELATION_LEFT_LITERAL;
      }
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, endToken, terminator) == false
    ) {
      return invalidRelation();
    }

    return new SourceReversibleResultRelation(
      kind,
      leftToken,
      operation,
      rightToken,
      immediate,
      endToken,
      true
    );
  }

  /// Counts one scalar result, or two operands plus one binary result.
  public long scalarRelationValueWidth(long kind) {
    long resultLocals = SCALAR_RESULT_LOCALS;
    long binaryOperands = SCALAR_BINARY_OPERANDS;
    if (kind == RESULT_RELATION_SOURCE) {
      return resultLocals;
    }

    if (kind == RESULT_RELATION_CONSTANT) {
      return resultLocals;
    }

    if (kind == RESULT_RELATION_LITERAL) {
      return resultLocals;
    }

    if (kind == RESULT_RELATION_BINARY) {
      return binaryOperands + resultLocals;
    }

    if (kind == RESULT_RELATION_BINARY_SOURCES) {
      return binaryOperands + resultLocals;
    }

    if (kind == RESULT_RELATION_LEFT_LITERAL) {
      return binaryOperands + resultLocals;
    }

    return 0;
  }

  /// Validates the complete assertion envelope before any operand name can bind.
  public SourceReversibleResultRelation sourceAssertionRelation(
    borrow utf8 source,
    long token,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    assert(-1 < tokenCount);
    assert(tokenCount < MAX_COMPILER_TOKENS + 1);
    assert(bufferLength(tokenKinds) == MAX_COMPILER_TOKENS);
    assert(bufferLength(tokenStarts) == MAX_COMPILER_TOKENS);
    assert(bufferLength(tokenLengths) == MAX_COMPILER_TOKENS);
    if (token < 0) {
      return invalidRelation();
    }

    if (tokenCount - ASSERTION_ENVELOPE_TOKENS - MINIMUM_SCALAR_TOKENS < token) {
      return invalidRelation();
    }

    if (sourceTokenCode(source, tokenStarts, tokenLengths, token) != TOKEN_ASSERT) {
      return invalidRelation();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_OPEN_PAREN) == false
    ) {
      return invalidRelation();
    }

    SourceReversibleResultRelation result = sourceScalarRelation(
      source,
      token + 2,
      tokenCount,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      PUNCTUATION_CLOSE_PAREN
    );
    if (result.valid == false) {
      return result;
    }

    if (tokenCount - 2 < result.endToken) {
      return invalidRelation();
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        result.endToken + 1,
        PUNCTUATION_SEMICOLON
      ) == false
    ) {
      return invalidRelation();
    }

    return result;
  }

  /// Resolves one reversible relation after its return token.
  public SourceReversibleResultRelation sourceReversibleResultRelation(
    borrow utf8 source,
    long token,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (token < 0) {
      return invalidRelation();
    }

    if (tokenCount - 1 < token) {
      return invalidRelation();
    }

    return sourceScalarRelation(
      source,
      nextSourceToken(token),
      tokenCount,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      PUNCTUATION_SEMICOLON
    );
  }
}
