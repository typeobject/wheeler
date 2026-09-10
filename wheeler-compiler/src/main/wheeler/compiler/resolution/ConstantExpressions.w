//! Evaluates bounded same-class scalar constant dependency expressions.

module wheeler.compiler.constant_expressions;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.constant_declarations;
import wheeler.compiler.product_constant_lookup;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class ConstantExpressions {
  private const long LEVEL_MULTIPLICATIVE = 0;
  private const long LEVEL_ADDITIVE = LEVEL_MULTIPLICATIVE + 1;
  private const long LEVEL_AND = LEVEL_ADDITIVE + 1;
  private const long LEVEL_XOR = LEVEL_AND + 1;
  private const long LEVEL_COMPARISON = LEVEL_XOR + 1;
  private const long LEVEL_EQUALITY = LEVEL_COMPARISON + 1;
  private const long EVALUATION_COUNTERS = 1;
  private const long NATIVE_WORD_BYTES = 8;
  private const long EVALUATION_BYTES = EVALUATION_COUNTERS * NATIVE_WORD_BYTES;

  /// Caps recursive dependency and expression work for one lookup.
  public const long MAX_CONSTANT_EVALUATION_STEPS = 4096;
  /// Caps a same-class dependency path, including cycle detection.
  public const long MAX_CONSTANT_DEPENDENCY_DEPTH = 64;
  /// Caps the checked `rotateRight32` amount.
  public const long MAX_ROTATE_RIGHT_32_AMOUNT = 31;

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
    borrow byteview importedNames,
    borrow mut words importedRows,
    borrow mut words steps
  ) {
    if (MAX_CONSTANT_DEPENDENCY_DEPTH < dependencyDepth + 1) {
      return new ExpressionResolution(0, false, false, false);
    }

    long cursor = firstDeclaration;
    while (cursor < memberStart) limit MAX_CLASS_CONSTANTS {
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
          importedNames,
          importedRows,
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
    }

    ProductConstantResolution imported = lookupProductConstant(
      source,
      tokenStarts,
      tokenLengths,
      assertedName,
      importedNames,
      importedRows
    );
    return new ExpressionResolution(
      imported.value,
      imported.found,
      imported.signed,
      imported.valid
    );
  }

  private ExpressionValue parseRotateRight32(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long cursor,
    long end,
    long dependencyDepth,
    borrow byteview importedNames,
    borrow mut words importedRows,
    borrow mut words steps
  ) {
    if (cursor + 4 < end) {} else {
      return invalidExpression(cursor);
    }

    if (
      scalarAt(source, tokenStarts, tokenLengths, cursor + 1, PUNCTUATION_OPEN_PAREN)
    ) {} else {
      return invalidExpression(cursor);
    }

    ExpressionValue value = parseBinary(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      cursor + 2,
      end,
      dependencyDepth,
      importedNames,
      importedRows,
      steps,
      LEVEL_EQUALITY
    );
    if (value.valid) {} else {
      return value;
    }

    if (value.signed) {} else {
      return invalidExpression(value.next);
    }

    if (value.next < end) {
      if (scalarAt(source, tokenStarts, tokenLengths, value.next, PUNCTUATION_COMMA)) {} else {
        return invalidExpression(value.next);
      }
    } else {
      return invalidExpression(value.next);
    }

    ExpressionValue amount = parseBinary(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      value.next + 1,
      end,
      dependencyDepth,
      importedNames,
      importedRows,
      steps,
      LEVEL_EQUALITY
    );
    if (amount.valid) {} else {
      return amount;
    }

    if (amount.signed) {} else {
      return invalidExpression(amount.next);
    }

    if (amount.value < 0) {
      return invalidExpression(amount.next);
    }

    if (MAX_ROTATE_RIGHT_32_AMOUNT < amount.value) {
      return invalidExpression(amount.next);
    }

    if (amount.next < end) {
      if (
        scalarAt(source, tokenStarts, tokenLengths, amount.next, PUNCTUATION_CLOSE_PAREN)
      ) {
        return new ExpressionValue(
          rotateRight32(value.value, amount.value),
          amount.next + 1,
          true,
          true
        );
      }
    }

    return invalidExpression(amount.next);
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
    borrow byteview importedNames,
    borrow mut words importedRows,
    borrow mut words steps
  ) {
    if (cursor < end) {} else {
      return invalidExpression(cursor);
    }

    if (consumeStep(steps) == false) {
      return invalidExpression(cursor);
    }

    if (scalarAt(source, tokenStarts, tokenLengths, cursor, PUNCTUATION_OPEN_PAREN)) {
      ExpressionValue nested = parseBinary(
        source,
        tokenStarts,
        tokenLengths,
        firstDeclaration,
        memberStart,
        cursor + 1,
        end,
        dependencyDepth,
        importedNames,
        importedRows,
        steps,
        LEVEL_EQUALITY
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

    if (rotateRight32Token(source, tokenStarts, tokenLengths, cursor)) {
      return parseRotateRight32(
        source,
        tokenStarts,
        tokenLengths,
        firstDeclaration,
        memberStart,
        cursor,
        end,
        dependencyDepth,
        importedNames,
        importedRows,
        steps
      );
    }

    long wordCode = sourceTokenCode(source, tokenStarts, tokenLengths, cursor);
    if (wordCode == TOKEN_TRUE) {
      return new ExpressionValue(1, cursor + 1, false, true);
    }

    if (wordCode == TOKEN_FALSE) {
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

    ProductConstantExpression qualified = lookupQualifiedProductConstant(
      source,
      tokenStarts,
      tokenLengths,
      cursor,
      end,
      importedNames,
      importedRows
    );
    if (qualified.found) {
      return new ExpressionValue(
        qualified.value,
        qualified.next,
        qualified.signed,
        qualified.valid
      );
    }

    ExpressionResolution reference = findAndEvaluate(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      cursor,
      dependencyDepth,
      importedNames,
      importedRows,
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
    borrow byteview importedNames,
    borrow mut words importedRows,
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
          importedNames,
          importedRows,
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
      importedNames,
      importedRows,
      steps
    );
  }

  private long binaryLevel(long scalar) {
    if (scalar == PUNCTUATION_STAR) {
      return LEVEL_MULTIPLICATIVE;
    }

    if (scalar == PUNCTUATION_SLASH) {
      return LEVEL_MULTIPLICATIVE;
    }

    if (scalar == PUNCTUATION_PERCENT) {
      return LEVEL_MULTIPLICATIVE;
    }

    if (scalar == PUNCTUATION_PLUS) {
      return LEVEL_ADDITIVE;
    }

    if (scalar == PUNCTUATION_MINUS) {
      return LEVEL_ADDITIVE;
    }

    if (scalar == PUNCTUATION_AMPERSAND) {
      return LEVEL_AND;
    }

    if (scalar == PUNCTUATION_CARET) {
      return LEVEL_XOR;
    }

    if (scalar == PUNCTUATION_LESS_THAN) {
      return LEVEL_COMPARISON;
    }

    if (scalar == PUNCTUATION_ASSIGN) {
      return LEVEL_EQUALITY;
    }

    return -1;
  }

  private ExpressionValue applyBinary(long scalar, ExpressionValue left, ExpressionValue right) {
    if (left.signed != right.signed) {
      return invalidExpression(right.next);
    }

    if (scalar == PUNCTUATION_ASSIGN) {
      long equal = 0;
      if (left.value == right.value) {
        equal = 1;
      }

      return new ExpressionValue(equal, right.next, false, true);
    }

    if (left.signed == false) {
      return invalidExpression(right.next);
    }

    long value = 0;
    if (scalar == PUNCTUATION_LESS_THAN) {
      if (left.value < right.value) {
        value = 1;
      }

      return new ExpressionValue(value, right.next, false, true);
    }

    if (scalar == PUNCTUATION_STAR) {
      return new ExpressionValue(left.value * right.value, right.next, true, true);
    }

    if (scalar == PUNCTUATION_PLUS) {
      return new ExpressionValue(left.value + right.value, right.next, true, true);
    }

    if (scalar == PUNCTUATION_MINUS) {
      return new ExpressionValue(left.value - right.value, right.next, true, true);
    }

    if (scalar == PUNCTUATION_AMPERSAND) {
      return new ExpressionValue(left.value & right.value, right.next, true, true);
    }

    if (scalar == PUNCTUATION_CARET) {
      return new ExpressionValue(left.value ^ right.value, right.next, true, true);
    }

    if (right.value == 0) {
      return invalidExpression(right.next);
    }

    if (scalar == PUNCTUATION_SLASH) {
      return new ExpressionValue(left.value / right.value, right.next, true, true);
    }

    if (scalar == PUNCTUATION_PERCENT) {
      return new ExpressionValue(left.value % right.value, right.next, true, true);
    }

    return invalidExpression(right.next);
  }

  private ExpressionValue parseBinary(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long cursor,
    long end,
    long dependencyDepth,
    borrow byteview importedNames,
    borrow mut words importedRows,
    borrow mut words steps,
    long level
  ) {
    if (level < LEVEL_MULTIPLICATIVE) {
      return parseUnary(
        source,
        tokenStarts,
        tokenLengths,
        firstDeclaration,
        memberStart,
        cursor,
        end,
        dependencyDepth,
        importedNames,
        importedRows,
        steps
      );
    }

    ExpressionValue left = parseBinary(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      cursor,
      end,
      dependencyDepth,
      importedNames,
      importedRows,
      steps,
      level - 1
    );
    while (left.valid) limit MAX_CONSTANT_EVALUATION_STEPS {
      if (end < left.next + 1) {
        return left;
      }

      if (tokenLengths[left.next] != 1) {
        return left;
      }

      long scalar = utf8Scalar(source, tokenStarts[left.next]);
      if (binaryLevel(scalar) != level) {
        return left;
      }

      long operatorWidth = 1;
      if (level == LEVEL_EQUALITY) {
        if (end < left.next + 2) {
          return left;
        }

        if (
          scalarAt(source, tokenStarts, tokenLengths, left.next + 1, PUNCTUATION_ASSIGN) == false
        ) {
          return left;
        }

        if (tokenStarts[left.next + 1] != tokenStarts[left.next] + operatorWidth) {
          return left;
        }

        operatorWidth += 1;
      }

      ExpressionValue right = parseBinary(
        source,
        tokenStarts,
        tokenLengths,
        firstDeclaration,
        memberStart,
        left.next + operatorWidth,
        end,
        dependencyDepth,
        importedNames,
        importedRows,
        steps,
        level - 1
      );
      if (right.valid == false) {
        return right;
      }

      left = applyBinary(scalar, left, right);
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
    borrow byteview importedNames,
    borrow mut words importedRows,
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
    ExpressionValue value = parseBinary(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      expressionStart,
      expressionEnd,
      dependencyDepth,
      importedNames,
      importedRows,
      steps,
      LEVEL_EQUALITY
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

  /// Evaluates one scalar constant against local declarations and packed import products.
  public ExpressionResolution evaluateConstantExpressionWithProducts(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long assertedName,
    borrow byteview importedNames,
    borrow mut words importedRows
  ) {
    region evaluation = new region(/* bytes= */ EVALUATION_BYTES, /* allocations= */ 1);
    words steps = allocate(evaluation, EVALUATION_COUNTERS);
    set(steps, 0, 0);
    ExpressionResolution result = findAndEvaluate(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      assertedName,
      0,
      importedNames,
      importedRows,
      steps
    );
    drop(steps);
    drop(evaluation);
    return result;
  }

  /// Evaluates exactly one scanner-owned scalar expression against local and counted constants.
  /// Empty local declaration windows select products only, without dependency source.
  /// A valid result consumes the entire expression window, not merely a valid prefix.
  public ExpressionValue evaluateScalarExpressionWithProducts(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long expressionStart,
    long expressionEnd,
    borrow byteview importedNames,
    borrow mut words importedRows
  ) {
    assert(-1 < firstDeclaration);
    assert(-1 < memberStart);
    assert(memberStart < bufferLength(tokenStarts) + 1);
    assert(memberStart < bufferLength(tokenLengths) + 1);
    assert(firstDeclaration < memberStart + 1);
    assert(-1 < expressionStart);
    assert(expressionStart < expressionEnd);
    assert(expressionEnd < bufferLength(tokenStarts) + 1);
    assert(expressionEnd < bufferLength(tokenLengths) + 1);
    region evaluation = new region(/* bytes= */ EVALUATION_BYTES, /* allocations= */ 1);
    words steps = allocate(evaluation, EVALUATION_COUNTERS);
    ExpressionValue parsed = parseBinary(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      expressionStart,
      expressionEnd,
      0,
      importedNames,
      importedRows,
      steps,
      LEVEL_EQUALITY
    );
    boolean valid = parsed.valid;
    if (parsed.next != expressionEnd) {
      valid = false;
    }

    ExpressionValue result = new ExpressionValue(
      parsed.value,
      parsed.next,
      parsed.signed,
      valid
    );
    drop(steps);
    drop(evaluation);
    return result;
  }
}
