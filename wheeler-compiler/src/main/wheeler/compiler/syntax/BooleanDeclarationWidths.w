//! Validates bounded Boolean and signed-comparison local declaration widths.

module wheeler.compiler.boolean_declaration_widths;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;

classical class BooleanDeclarationWidths {
  /// Returns the token width of one nonnegated Boolean local declaration.
  public long booleanDeclarationWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long statementKind
  ) {
    if (tokenKinds[statementStart + 1] == 1) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
      ) {
        if (statementKind == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED) {
          if (tokenKinds[statementStart + 3] == 1) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                statementStart + 4,
                PUNCTUATION_LESS_THAN
              )
            ) {
              long lessThanWidth = signedNumberWidth(
                source,
                tokenKinds,
                tokenStarts,
                statementStart + 5
              );
              if (0 < lessThanWidth) {
                if (
                  signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 5)
                ) {
                  if (
                    punctuationAt(
                      source,
                      tokenKinds,
                      tokenStarts,
                      statementStart + 5 + lessThanWidth,
                      PUNCTUATION_SEMICOLON
                    )
                  ) {
                    return 6 + lessThanWidth;
                  }
                }
              }
            }
          }

          return -1;
        }

        if (statementKind == STATEMENT_LOCAL_LONG_LT_NAMED) {
          if (tokenKinds[statementStart + 3] == 1) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                statementStart + 4,
                PUNCTUATION_LESS_THAN
              )
            ) {
              if (tokenKinds[statementStart + 5] == 1) {
                if (
                  punctuationAt(
                    source,
                    tokenKinds,
                    tokenStarts,
                    statementStart + 6,
                    PUNCTUATION_SEMICOLON
                  )
                ) {
                  return 7;
                }
              }
            }
          }

          return -1;
        }

        boolean literalEquality = statementKind == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED;
        boolean literalInequality = statementKind == STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED;
        boolean literalComparison = literalEquality;
        if (literalInequality) {
          literalComparison = true;
        }

        if (literalComparison) {
          long comparisonOperator = PUNCTUATION_ASSIGN;
          if (literalInequality) {
            comparisonOperator = PUNCTUATION_BANG;
          }

          if (tokenKinds[statementStart + 3] == 1) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                statementStart + 4,
                comparisonOperator
              )
            ) {
              if (
                punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 5,
                  PUNCTUATION_ASSIGN
                )
              ) {
                long equalityWidth = signedNumberWidth(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 6
                );
                if (0 < equalityWidth) {
                  if (
                    signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 6)
                  ) {
                    if (
                      punctuationAt(
                        source,
                        tokenKinds,
                        tokenStarts,
                        statementStart + 6 + equalityWidth,
                        PUNCTUATION_SEMICOLON
                      )
                    ) {
                      return 7 + equalityWidth;
                    }
                  }
                }
              }
            }
          }

          return -1;
        }

        boolean localEquality = statementKind == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED;
        boolean localInequality = statementKind == STATEMENT_LOCAL_BOOLEAN_NE_NAMED;
        boolean localComparison = localEquality;
        if (localInequality) {
          localComparison = true;
        }

        if (localComparison) {
          long localComparisonOperator = PUNCTUATION_ASSIGN;
          if (localInequality) {
            localComparisonOperator = PUNCTUATION_BANG;
          }

          if (tokenKinds[statementStart + 3] == 1) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                statementStart + 4,
                localComparisonOperator
              )
            ) {
              if (
                punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 5,
                  PUNCTUATION_ASSIGN
                )
              ) {
                if (tokenKinds[statementStart + 6] == 1) {
                  if (
                    punctuationAt(
                      source,
                      tokenKinds,
                      tokenStarts,
                      statementStart + 7,
                      PUNCTUATION_SEMICOLON
                    )
                  ) {
                    return 8;
                  }
                }
              }
            }
          }

          return -1;
        }

        if (statementKind == STATEMENT_LOCAL_BOOLEAN_NAMED) {
          if (tokenKinds[statementStart + 3] == 1) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                statementStart + 4,
                PUNCTUATION_SEMICOLON
              )
            ) {
              return 5;
            }
          }

          return -1;
        }

        // `true` and `false` use the same stable token hash as every keyword.
        long booleanLiteralHash = tokenHash(
          source,
          tokenStarts,
          tokenLengths,
          statementStart + 3
        );
        if (booleanLiteralHash == TOKEN_TRUE) {
          if (
            punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              statementStart + 4,
              PUNCTUATION_SEMICOLON
            )
          ) {
            return 5;
          }
        }

        if (booleanLiteralHash == TOKEN_FALSE) {
          if (
            punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              statementStart + 4,
              PUNCTUATION_SEMICOLON
            )
          ) {
            return 5;
          }
        }
      }
    }

    return -1;
  }
}
