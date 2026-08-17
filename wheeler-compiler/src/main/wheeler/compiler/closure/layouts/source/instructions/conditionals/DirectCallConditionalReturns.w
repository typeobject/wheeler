//! Validates exact helper-call conditions with Boolean literal returns.

module wheeler.compiler.closure.direct_call_conditional_returns;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.source_call_layout_products;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class DirectCallConditionalReturns {
  private const long MAX_STATEMENTS = 4096;
  private const long STATEMENT_FIRST_CHILD_ROW = 20480;

  /// Reports one exact call-conditioned Boolean return product.
  public record DirectCallConditionalReturn(
    long callKind,
    long childStatement,
    long failureCode,
    boolean valid
  ) {}

  private DirectCallConditionalReturn invalid(long failureCode) {
    return new DirectCallConditionalReturn(0, 0, failureCode, false);
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

  private long closingCallParen(
    borrow utf8 source,
    long openToken,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts
  ) {
    long depth = 1;
    long token = openToken + 1;
    while (token < tokenCount) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, token, PUNCTUATION_OPEN_PAREN)
      ) {
        depth += 1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, token, PUNCTUATION_CLOSE_PAREN)
      ) {
        depth -= 1;
        if (depth == 0) {
          return token;
        }
      }

      token += 1;
    }

    return -1;
  }

  /// Validates one exact `if (helper(args)) { return literal; }` product.
  public DirectCallConditionalReturn directCallConditionalReturn(
    borrow utf8 source,
    long token,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long callStart,
    long callLocalWidth,
    long owner,
    long statement,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts
  ) {
    if (token < 0) {
      return invalid(1);
    }

    if (tokenCount < token + 10) {
      return invalid(2);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_OPEN_PAREN) == false
    ) {
      return invalid(3);
    }

    long callToken = token + 2;
    if (tokenKinds[callToken] != 1) {
      return invalid(4);
    }

    if (tokenStarts[callToken] != callStart) {
      return invalid(5);
    }

    long callOpen = callToken + 1;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, callOpen, PUNCTUATION_OPEN_PAREN) == false
    ) {
      return invalid(6);
    }

    long callClose = closingCallParen(source, callOpen, tokenCount, tokenKinds, tokenStarts);
    if (callClose < 0) {
      return invalid(7);
    }

    if (tokenCount < callClose + 4) {
      return invalid(12);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, callClose + 1, PUNCTUATION_CLOSE_PAREN)
        == false
    ) {
      return invalid(8);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, callClose + 2, PUNCTUATION_OPEN_BRACE) == false
    ) {
      return invalid(9);
    }

    long childBlock = statementRows[STATEMENT_FIRST_CHILD_ROW + statement];
    long childStatement = childStatementForBlock(
      owner,
      childBlock,
      statementCount,
      statementRows
    );
    if (childStatement < 0) {
      return invalid(10);
    }

    if (statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + childStatement] != 0) {
      return invalid(11);
    }

    long childToken = callClose + 3;
    if (tokenCount < childToken + 4) {
      return invalid(12);
    }

    if (
      tokenStarts[childToken] != statementRows[LOOP_STATEMENT_START_ROW + childStatement]
    ) {
      return invalid(13);
    }

    if (tokenHash(source, tokenStarts, tokenLengths, childToken) != TOKEN_RETURN) {
      return invalid(14);
    }

    long literalHash = tokenHash(source, tokenStarts, tokenLengths, childToken + 1);
    long callKind = CALL_CONDITION_TRUE_BOOLEAN;
    if (literalHash == TOKEN_FALSE) {
      callKind = CALL_CONDITION_FALSE_BOOLEAN;
    } else {
      if (literalHash != TOKEN_TRUE) {
        return invalid(15);
      }
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, childToken + 2, PUNCTUATION_SEMICOLON) == false
    ) {
      return invalid(16);
    }

    long expectedSemicolon = statementRows[LOOP_STATEMENT_START_ROW + childStatement]
      + statementRows[LOOP_STATEMENT_LENGTH_ROW + childStatement] - 1;
    if (tokenStarts[childToken + 2] != expectedSemicolon) {
      return invalid(17);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, childToken + 3, PUNCTUATION_CLOSE_BRACE)
        == false
    ) {
      return invalid(18);
    }

    long statementEnd = statementRows[LOOP_STATEMENT_START_ROW + statement]
      + statementRows[LOOP_STATEMENT_LENGTH_ROW + statement];
    if (tokenStarts[childToken + 3] + tokenLengths[childToken + 3] != statementEnd) {
      return invalid(19);
    }

    if (callLocalWidth < 1) {
      return invalid(20);
    }

    if (statementLocalRows[4096 + statement] != callLocalWidth) {
      return invalid(21);
    }

    if (statementLocalRows[4096 + childStatement] != 1) {
      return invalid(22);
    }

    long localBase = statementPhysicalStarts[statement];
    if (localBase < 0) {
      return invalid(23);
    }

    if (statementPhysicalStarts[childStatement] != localBase + callLocalWidth) {
      return invalid(24);
    }

    if (254 < localBase + callLocalWidth) {
      return invalid(25);
    }

    return new DirectCallConditionalReturn(callKind, childStatement, 0, true);
  }
}
