//! Evaluates bounded same-class scalar constant dependency expressions.

module wheeler.compiler.constant_expressions;

import wheeler.compiler.constant_declarations;
import wheeler.compiler.tokens;

classical class ConstantExpressions {
  /// Caps recursive dependency and expression work for one lookup.
  public const long MAX_CONSTANT_EVALUATION_STEPS = 4096;
  /// Caps a same-class dependency path, including cycle detection.
  public const long MAX_CONSTANT_DEPENDENCY_DEPTH = 64;

  /// Carries one parsed expression value and its first unread token.
  public record ExpressionValue(long value, long next, boolean signed, boolean valid) {}

  /// Carries one named dependency lookup without a scalar sentinel.
  public record ExpressionResolution(long value, boolean found, boolean signed, boolean valid) {}

  private boolean scalarAt(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token,
    long scalar
  ) {
    if (tokenLengths[token] == 1) {
      return utf8Scalar(source, tokenStarts[token]) == scalar;
    }

    return false;
  }

  private boolean consumeStep(borrow mut words steps) {
    long next = steps[0] + 1;
    set(steps, 0, next);
    return next < MAX_CONSTANT_EVALUATION_STEPS + 1;
  }

  private boolean numberToken(borrow utf8 source, borrow mut words tokenStarts, long token) {
    long first = utf8Scalar(source, tokenStarts[token]);
    if (first < SCALAR_DIGIT_ZERO) {
      return false;
    }

    return first < SCALAR_DIGIT_NINE + 1;
  }

  private ExpressionValue invalidExpression(long next) {
    return new ExpressionValue(0, next, false, false);
  }

  private ExpressionResolution findAndEvaluate(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long assertedName,
    long dependencyDepth,
    borrow mut words steps
  ) {
    if (MAX_CONSTANT_DEPENDENCY_DEPTH < dependencyDepth + 1) {
      return new ExpressionResolution(0, false, false, false);
    }

    long cursor = firstDeclaration;
    long count = 0;
    while (cursor < memberStart) limit MAX_CONSTANT_DEPENDENCY_DEPTH {
      if (consumeStep(steps) == false) {
        return new ExpressionResolution(0, false, false, false);
      }

      long name = constantNameToken(source, tokenStarts, tokenLengths, cursor);
      if (sameTokenText(source, tokenStarts, tokenLengths, name, assertedName)) {
        ExpressionValue value = evaluateDeclaration(
          source,
          tokenStarts,
          tokenLengths,
          firstDeclaration,
          memberStart,
          cursor,
          dependencyDepth + 1,
          steps
        );
        return new ExpressionResolution(value.value, true, value.signed, value.valid);
      }

      long next = constantDeclarationEnd(
        source,
        tokenStarts,
        tokenLengths,
        cursor,
        memberStart
      );
      if (cursor < next) {} else {
        return new ExpressionResolution(0, false, false, false);
      }

      cursor = next;
      count += 1;
    }

    return new ExpressionResolution(0, false, false, true);
  }

  private ExpressionValue parsePrimary(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long cursor,
    long end,
    long dependencyDepth,
    borrow mut words steps
  ) {
    if (cursor < end) {} else {
      return invalidExpression(cursor);
    }

    if (consumeStep(steps) == false) {
      return invalidExpression(cursor);
    }

    if (scalarAt(source, tokenStarts, tokenLengths, cursor, PUNCTUATION_OPEN_PAREN)) {
      ExpressionValue nested = parseEquality(
        source,
        tokenStarts,
        tokenLengths,
        firstDeclaration,
        memberStart,
        cursor + 1,
        end,
        dependencyDepth,
        steps
      );
      if (nested.valid == false) {
        return nested;
      }

      if (nested.next < end) {
        if (
          scalarAt(source, tokenStarts, tokenLengths, nested.next, PUNCTUATION_CLOSE_PAREN)
        ) {
          return new ExpressionValue(nested.value, nested.next + 1, nested.signed, true);
        }
      }

      return invalidExpression(nested.next);
    }

    if (scalarAt(source, tokenStarts, tokenLengths, cursor, PUNCTUATION_MINUS)) {
      if (cursor + 1 < end) {
        if (numberToken(source, tokenStarts, cursor + 1)) {
          if (signedNumberValid(source, tokenStarts, tokenLengths, cursor)) {
            return new ExpressionValue(
              parsedSignedNumber(source, tokenStarts, tokenLengths, cursor),
              cursor + 2,
              true,
              true
            );
          }
        }
      }

      return invalidExpression(cursor);
    }

    long hash = tokenHash(source, tokenStarts, tokenLengths, cursor);
    if (hash == TOKEN_TRUE) {
      return new ExpressionValue(1, cursor + 1, false, true);
    }

    if (hash == TOKEN_FALSE) {
      return new ExpressionValue(0, cursor + 1, false, true);
    }

    if (numberToken(source, tokenStarts, cursor)) {
      if (signedNumberValid(source, tokenStarts, tokenLengths, cursor)) {
        return new ExpressionValue(
          parsedSignedNumber(source, tokenStarts, tokenLengths, cursor),
          cursor + 1,
          true,
          true
        );
      }
    }

    ExpressionResolution reference = findAndEvaluate(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      cursor,
      dependencyDepth,
      steps
    );
    if (reference.found) {
      return new ExpressionValue(reference.value, cursor + 1, reference.signed, reference.valid);
    }

    return invalidExpression(cursor);
  }

  private ExpressionValue parseUnary(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long cursor,
    long end,
    long dependencyDepth,
    borrow mut words steps
  ) {
    if (cursor < end) {
      if (scalarAt(source, tokenStarts, tokenLengths, cursor, PUNCTUATION_BANG)) {
        ExpressionValue operand = parseUnary(
          source,
          tokenStarts,
          tokenLengths,
          firstDeclaration,
          memberStart,
          cursor + 1,
          end,
          dependencyDepth,
          steps
        );
        if (operand.valid) {
          if (operand.signed == false) {
            long value = 0;
            if (operand.value == 0) {
              value = 1;
            }

            return new ExpressionValue(value, operand.next, false, true);
          }
        }

        return invalidExpression(operand.next);
      }
    }

    return parsePrimary(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      cursor,
      end,
      dependencyDepth,
      steps
    );
  }

  private ExpressionValue parseMultiplicative(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long cursor,
    long end,
    long dependencyDepth,
    borrow mut words steps
  ) {
    ExpressionValue left = parseUnary(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      cursor,
      end,
      dependencyDepth,
      steps
    );
    boolean scanning = left.valid;
    while (scanning) limit MAX_CONSTANT_EVALUATION_STEPS {
      if (left.next < end) {
        long scalar = utf8Scalar(source, tokenStarts[left.next]);
        boolean operator = scalarAt(
          source,
          tokenStarts,
          tokenLengths,
          left.next,
          PUNCTUATION_STAR
        );
        if (scalar == PUNCTUATION_SLASH) {
          operator = tokenLengths[left.next] == 1;
        }

        if (scalar == PUNCTUATION_PERCENT) {
          operator = tokenLengths[left.next] == 1;
        }

        if (operator) {
          ExpressionValue right = parseUnary(
            source,
            tokenStarts,
            tokenLengths,
            firstDeclaration,
            memberStart,
            left.next + 1,
            end,
            dependencyDepth,
            steps
          );
          if (right.valid) {
            if (left.signed) {
              if (right.signed) {
                if (scalar == PUNCTUATION_STAR) {
                  left = new ExpressionValue(left.value * right.value, right.next, true, true);
                } else {
                  if (right.value == 0) {
                    return invalidExpression(right.next);
                  }

                  if (scalar == PUNCTUATION_SLASH) {
                    left = new ExpressionValue(left.value / right.value, right.next, true, true);
                  } else {
                    left = new ExpressionValue(left.value % right.value, right.next, true, true);
                  }
                }
              } else {
                return invalidExpression(right.next);
              }
            } else {
              return invalidExpression(right.next);
            }
          } else {
            return right;
          }
        } else {
          scanning = false;
        }
      } else {
        scanning = false;
      }
    }

    return left;
  }

  private ExpressionValue parseAdditive(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long cursor,
    long end,
    long dependencyDepth,
    borrow mut words steps
  ) {
    ExpressionValue left = parseMultiplicative(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      cursor,
      end,
      dependencyDepth,
      steps
    );
    boolean scanning = left.valid;
    while (scanning) limit MAX_CONSTANT_EVALUATION_STEPS {
      if (left.next < end) {
        long scalar = utf8Scalar(source, tokenStarts[left.next]);
        boolean operator = scalar == PUNCTUATION_PLUS;
        if (scalar == PUNCTUATION_MINUS) {
          operator = true;
        }

        if (operator) {
          ExpressionValue right = parseMultiplicative(
            source,
            tokenStarts,
            tokenLengths,
            firstDeclaration,
            memberStart,
            left.next + 1,
            end,
            dependencyDepth,
            steps
          );
          if (right.valid) {
            if (left.signed) {
              if (right.signed) {
                long value = left.value + right.value;
                if (scalar == PUNCTUATION_MINUS) {
                  value = left.value - right.value;
                }

                left = new ExpressionValue(value, right.next, true, true);
              } else {
                return invalidExpression(right.next);
              }
            } else {
              return invalidExpression(right.next);
            }
          } else {
            return right;
          }
        } else {
          scanning = false;
        }
      } else {
        scanning = false;
      }
    }

    return left;
  }

  private ExpressionValue parseAnd(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long cursor,
    long end,
    long dependencyDepth,
    borrow mut words steps
  ) {
    ExpressionValue left = parseAdditive(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      cursor,
      end,
      dependencyDepth,
      steps
    );
    while (left.valid) limit MAX_CONSTANT_EVALUATION_STEPS {
      if (left.next < end) {
        if (
          scalarAt(source, tokenStarts, tokenLengths, left.next, PUNCTUATION_AMPERSAND)
        ) {
          ExpressionValue right = parseAdditive(
            source,
            tokenStarts,
            tokenLengths,
            firstDeclaration,
            memberStart,
            left.next + 1,
            end,
            dependencyDepth,
            steps
          );
          if (right.valid) {
            if (left.signed) {
              if (right.signed) {
                left = new ExpressionValue(left.value & right.value, right.next, true, true);
              } else {
                return invalidExpression(right.next);
              }
            } else {
              return invalidExpression(right.next);
            }
          } else {
            return right;
          }
        } else {
          return left;
        }
      } else {
        return left;
      }
    }

    return left;
  }

  private ExpressionValue parseXor(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long cursor,
    long end,
    long dependencyDepth,
    borrow mut words steps
  ) {
    ExpressionValue left = parseAnd(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      cursor,
      end,
      dependencyDepth,
      steps
    );
    while (left.valid) limit MAX_CONSTANT_EVALUATION_STEPS {
      if (left.next < end) {
        if (
          scalarAt(source, tokenStarts, tokenLengths, left.next, PUNCTUATION_CARET)
        ) {
          ExpressionValue right = parseAnd(
            source,
            tokenStarts,
            tokenLengths,
            firstDeclaration,
            memberStart,
            left.next + 1,
            end,
            dependencyDepth,
            steps
          );
          if (right.valid) {
            if (left.signed) {
              if (right.signed) {
                left = new ExpressionValue(left.value ^ right.value, right.next, true, true);
              } else {
                return invalidExpression(right.next);
              }
            } else {
              return invalidExpression(right.next);
            }
          } else {
            return right;
          }
        } else {
          return left;
        }
      } else {
        return left;
      }
    }

    return left;
  }

  private ExpressionValue parseComparison(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long cursor,
    long end,
    long dependencyDepth,
    borrow mut words steps
  ) {
    ExpressionValue left = parseXor(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      cursor,
      end,
      dependencyDepth,
      steps
    );
    while (left.valid) limit MAX_CONSTANT_EVALUATION_STEPS {
      if (left.next < end) {
        if (
          scalarAt(source, tokenStarts, tokenLengths, left.next, PUNCTUATION_LESS_THAN)
        ) {
          ExpressionValue right = parseXor(
            source,
            tokenStarts,
            tokenLengths,
            firstDeclaration,
            memberStart,
            left.next + 1,
            end,
            dependencyDepth,
            steps
          );
          if (right.valid) {
            if (left.signed) {
              if (right.signed) {
                long value = 0;
                if (left.value < right.value) {
                  value = 1;
                }

                left = new ExpressionValue(value, right.next, false, true);
              } else {
                return invalidExpression(right.next);
              }
            } else {
              return invalidExpression(right.next);
            }
          } else {
            return right;
          }
        } else {
          return left;
        }
      } else {
        return left;
      }
    }

    return left;
  }

  private ExpressionValue parseEquality(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long cursor,
    long end,
    long dependencyDepth,
    borrow mut words steps
  ) {
    ExpressionValue left = parseComparison(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      cursor,
      end,
      dependencyDepth,
      steps
    );
    while (left.valid) limit MAX_CONSTANT_EVALUATION_STEPS {
      if (left.next + 1 < end) {
        boolean equality = scalarAt(
          source,
          tokenStarts,
          tokenLengths,
          left.next,
          PUNCTUATION_ASSIGN
        );
        if (equality) {
          equality = scalarAt(
            source,
            tokenStarts,
            tokenLengths,
            left.next + 1,
            PUNCTUATION_ASSIGN
          );
        }

        if (equality) {
          ExpressionValue right = parseComparison(
            source,
            tokenStarts,
            tokenLengths,
            firstDeclaration,
            memberStart,
            left.next + 2,
            end,
            dependencyDepth,
            steps
          );
          if (right.valid) {
            if (left.signed == right.signed) {
              long value = 0;
              if (left.value == right.value) {
                value = 1;
              }

              left = new ExpressionValue(value, right.next, false, true);
            } else {
              return invalidExpression(right.next);
            }
          } else {
            return right;
          }
        } else {
          return left;
        }
      } else {
        return left;
      }
    }

    return left;
  }

  private ExpressionValue evaluateDeclaration(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long declarationStart,
    long dependencyDepth,
    borrow mut words steps
  ) {
    if (MAX_CONSTANT_DEPENDENCY_DEPTH < dependencyDepth) {
      return invalidExpression(declarationStart);
    }

    long declarationEnd = constantDeclarationEnd(
      source,
      tokenStarts,
      tokenLengths,
      declarationStart,
      memberStart
    );
    if (declarationStart < declarationEnd) {} else {
      return invalidExpression(declarationStart);
    }

    long expressionStart = constantExpressionStart(
      source,
      tokenStarts,
      tokenLengths,
      declarationStart
    );
    long expressionEnd = declarationEnd - 1;
    ExpressionValue value = parseEquality(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      expressionStart,
      expressionEnd,
      dependencyDepth,
      steps
    );
    if (value.valid) {
      if (value.next == expressionEnd) {
        boolean declaredSigned = constantTypeSigned(
          source,
          tokenStarts,
          tokenLengths,
          declarationStart
        );
        if (value.signed == declaredSigned) {
          return value;
        }
      }
    }

    return invalidExpression(value.next);
  }

  /// Evaluates one named scalar constant from a complete declaration prefix.
  public ExpressionResolution evaluateConstantExpression(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long assertedName
  ) {
    region evaluation = new region(/* bytes= */ 8, /* allocations= */ 1);
    words steps = allocate(evaluation, 1);
    set(steps, 0, 0);
    ExpressionResolution result = findAndEvaluate(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      assertedName,
      0,
      steps
    );
    drop(steps);
    drop(evaluation);
    return result;
  }
}
