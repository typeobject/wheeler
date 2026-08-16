//! Parses bounded reversible result relations from one source return.

module wheeler.compiler.closure.source_reversible_result_relations;

import wheeler.compiler.closure.reversible_token_coordinates;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class SourceReversibleResultRelations {
  /// Names a result copied from one preserved source local.
  public const long RESULT_RELATION_SOURCE = 1;
  /// Names a result computed from one source local and one immediate.
  public const long RESULT_RELATION_BINARY = 2;
  /// Names a result computed from two preserved source locals.
  public const long RESULT_RELATION_BINARY_SOURCES = 3;
  /// Names a signed result materialized from one exact constant product.
  public const long RESULT_RELATION_CONSTANT = 4;

  /// Carries one exact reversible result relation.
  public record SourceReversibleResultRelation(
    long kind,
    long leftToken,
    long operation,
    long rightToken,
    long immediate,
    boolean valid
  ) {}

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

    return -1;
  }

  /// Resolves one identifier-led scalar relation through its exact semicolon.
  public SourceReversibleResultRelation sourceScalarRelation(
    borrow utf8 source,
    long leftToken,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (leftToken < 0) {
      return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
    }

    if (tokenCount < leftToken + 2) {
      return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
    }

    if (tokenKinds[leftToken] != 1) {
      return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, leftToken + 1, PUNCTUATION_SEMICOLON)
    ) {
      return new SourceReversibleResultRelation(
        RESULT_RELATION_SOURCE,
        leftToken,
        0,
        0,
        0,
        true
      );
    }

    if (tokenCount < leftToken + 4) {
      return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
    }

    long operationToken = leftToken + 1;
    long operationScalar = utf8Scalar(source, tokenStarts[operationToken]);
    long operation = resultOperation(operationScalar);
    long rightToken = leftToken + 2;
    if (operationScalar == PUNCTUATION_LESS_THAN) {
      operation = OPCODE_LOCAL_LT;
    }

    if (operationScalar == PUNCTUATION_ASSIGN) {
      if (tokenCount < leftToken + 5) {
        return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, operationToken + 1, PUNCTUATION_ASSIGN)
          == false
      ) {
        return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
      }

      operation = OPCODE_LOCAL_EQ;
      rightToken = leftToken + 3;
    }

    if (operation < 0) {
      return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
    }

    if (tokenKinds[rightToken] == 1) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, rightToken + 1, PUNCTUATION_SEMICOLON)
          == false
      ) {
        return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
      }

      return new SourceReversibleResultRelation(
        RESULT_RELATION_BINARY_SOURCES,
        leftToken,
        operation,
        rightToken,
        0,
        true
      );
    }

    long signedWidth = signedNumberWidth(source, tokenKinds, tokenStarts, rightToken);
    if (signedWidth < 1) {
      return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
    }

    if (tokenCount < rightToken + signedWidth + 1) {
      return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        rightToken + signedWidth,
        PUNCTUATION_SEMICOLON
      ) == false
    ) {
      return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
    }

    if (signedNumberValid(source, tokenStarts, tokenLengths, rightToken) == false) {
      return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
    }

    return new SourceReversibleResultRelation(
      RESULT_RELATION_BINARY,
      leftToken,
      operation,
      0,
      parsedSignedNumber(source, tokenStarts, tokenLengths, rightToken),
      true
    );
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
      return new SourceReversibleResultRelation(0, 0, 0, 0, 0, false);
    }

    return sourceScalarRelation(
      source,
      nextSourceToken(token),
      tokenCount,
      tokenKinds,
      tokenStarts,
      tokenLengths
    );
  }
}
