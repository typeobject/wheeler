//! Classifies and decodes bounded source token ranges.

module wheeler.compiler.tokens;

import wheeler.lexer.scanner;

classical class Tokens {
  private boolean identifierStart(long scalar) {
    boolean accepted = scalar == 95;
    if (64 < scalar) {
      accepted = scalar < 91;
    }

    if (96 < scalar) {
      accepted = scalar < 123;
    }

    if (scalar == 95) {
      accepted = true;
    }

    return accepted;
  }

  /// Caps compiler token metadata before comment compaction.
  public const long MAX_COMPILER_TOKENS = 1024;

  /// Names the stable token hash for `module`.
  public const long TOKEN_MODULE = 3226183276;
  /// Names the stable token hash for `public`.
  public const long TOKEN_PUBLIC = 3317543529;
  /// Names the stable token hash for `private`.
  public const long TOKEN_PRIVATE = 102764717443;
  /// Names the stable token hash for `classical`.
  public const long TOKEN_CLASSICAL = 87497064671293;
  /// Names the stable token hash for `class`.
  public const long TOKEN_CLASS = 94742904;
  /// Names the stable token hash for `state`.
  public const long TOKEN_STATE = 109757585;
  /// Names the stable token hash for `entry`.
  public const long TOKEN_ENTRY = 96667762;
  /// Names the stable token hash for `void`.
  public const long TOKEN_VOID = 3625364;
  /// Names the stable token hash for `main`.
  public const long TOKEN_MAIN = 3343801;
  /// Names the stable token hash for `rev`.
  public const long TOKEN_REV = 112803;
  /// Names the stable token hash for `reverse`.
  public const long TOKEN_REVERSE = 104179061474;
  /// Names the stable token hash for `theorem`.
  public const long TOKEN_THEOREM = 106024553916;
  /// Names the stable token hash for `proves`.
  public const long TOKEN_PROVES = 3315169751;
  /// Names the stable token hash for `inverse`.
  public const long TOKEN_INVERSE = 96449190704;
  /// Names the stable token hash for `assert`.
  public const long TOKEN_ASSERT = 2886759238;
  /// Names the stable token hash for `if`.
  public const long TOKEN_IF = 3357;
  /// Names the stable token hash for `long`.
  public const long TOKEN_LONG = 3327612;
  /// Names the stable token hash for `boolean`.
  public const long TOKEN_BOOLEAN = 90259024936;
  /// Names the stable token hash for `true`.
  public const long TOKEN_TRUE = 3569038;
  /// Names the stable token hash for `false`.
  public const long TOKEN_FALSE = 97196323;
  /// Names the stable token hash for `return`.
  public const long TOKEN_RETURN = 3360570672;

  /// Names the parser IR code for direct assignment.
  public const long STATEMENT_ASSIGN = 0;
  /// Names the parser IR code for a signed equality assertion.
  public const long STATEMENT_ASSERT_EQ = 768;
  /// Names the parser IR code for a signed local declaration.
  public const long STATEMENT_LOCAL_LONG = 769;
  /// Names the parser IR code for a Boolean literal declaration.
  public const long STATEMENT_LOCAL_BOOLEAN = 770;
  /// Names the parser IR code for a negated Boolean literal declaration.
  public const long STATEMENT_LOCAL_BOOLEAN_NOT = 771;
  /// Names the parser IR code for a Boolean literal assertion.
  public const long STATEMENT_ASSERT_BOOLEAN = 772;
  /// Names the parser IR code for a negated Boolean literal assertion.
  public const long STATEMENT_ASSERT_BOOLEAN_NOT = 773;
  /// Names the parser IR code for an assertion over a prior Boolean local.
  public const long STATEMENT_ASSERT_LOCAL_BOOLEAN = 774;
  /// Names an unresolved equality assertion over a signed name.
  public const long STATEMENT_ASSERT_NAMED_LONG = 775;
  /// Starts resolved signed-local assertion opcodes; the local index is the delta.
  public const long STATEMENT_ASSERT_LOCAL_LONG_BASE = 2048;
  /// Names an unresolved signed declaration initialized from a prior local.
  public const long STATEMENT_LOCAL_LONG_NAMED = 776;
  /// Starts resolved signed-local copy opcodes; the source local is the delta.
  public const long STATEMENT_LOCAL_LONG_COPY_BASE = 2304;
  /// Names an unresolved checked signed-local addition declaration.
  public const long STATEMENT_LOCAL_LONG_ADD_NAMED = 777;
  /// Names an unresolved checked signed-local subtraction declaration.
  public const long STATEMENT_LOCAL_LONG_SUB_NAMED = 778;
  /// Names an unresolved checked signed-local XOR declaration.
  public const long STATEMENT_LOCAL_LONG_XOR_NAMED = 779;
  /// Starts resolved checked signed-local addition declaration opcodes.
  public const long STATEMENT_LOCAL_LONG_ADD_BASE = 2560;
  /// Starts resolved checked signed-local subtraction declaration opcodes.
  public const long STATEMENT_LOCAL_LONG_SUB_BASE = 2816;
  /// Starts resolved checked signed-local XOR declaration opcodes.
  public const long STATEMENT_LOCAL_LONG_XOR_BASE = 3072;
  /// Names an unresolved checked addition of two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_ADD_LOCALS_NAMED = 780;
  /// Names an unresolved checked subtraction of two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_SUB_LOCALS_NAMED = 781;
  /// Names an unresolved checked XOR of two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_XOR_LOCALS_NAMED = 782;
  /// Starts resolved checked addition opcodes for two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_ADD_LOCALS_BASE = 3328;
  /// Starts resolved checked subtraction opcodes for two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE = 3584;
  /// Starts resolved checked XOR opcodes for two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE = 3840;
  /// Names an unresolved Boolean declaration initialized from a prior local.
  public const long STATEMENT_LOCAL_BOOLEAN_NAMED = 783;
  /// Starts resolved Boolean-local copy opcodes.
  public const long STATEMENT_LOCAL_BOOLEAN_COPY_BASE = 4096;
  /// Names an unresolved negated prior-Boolean declaration.
  public const long STATEMENT_LOCAL_BOOLEAN_NOT_NAMED = 784;
  /// Starts resolved negated Boolean-local declaration opcodes.
  public const long STATEMENT_LOCAL_BOOLEAN_NOT_BASE = 4352;
  /// Names an unresolved equality declaration over two prior locals.
  public const long STATEMENT_LOCAL_BOOLEAN_EQ_NAMED = 785;
  /// Starts resolved equality declarations over prior Boolean locals.
  public const long STATEMENT_LOCAL_BOOLEAN_EQ_BASE = 4608;
  /// Starts resolved equality declarations over prior signed locals.
  public const long STATEMENT_LOCAL_LONG_EQ_BASE = 4864;
  /// Names an unresolved less-than declaration over two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_LT_NAMED = 786;
  /// Starts resolved less-than declarations over prior signed locals.
  public const long STATEMENT_LOCAL_LONG_LT_BASE = 5120;
  /// Names unresolved one-arm local conditions guarding global updates.
  public const long STATEMENT_IF_LOCAL_ADD_NAMED = 787;
  /// Names an unresolved one-arm local condition guarding subtraction.
  public const long STATEMENT_IF_LOCAL_SUB_NAMED = 788;
  /// Names an unresolved one-arm local condition guarding XOR.
  public const long STATEMENT_IF_LOCAL_XOR_NAMED = 789;
  /// Starts resolved local conditions guarding global addition.
  public const long STATEMENT_IF_LOCAL_ADD_BASE = 5376;
  /// Starts resolved local conditions guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_SUB_BASE = 5632;
  /// Starts resolved local conditions guarding global XOR.
  public const long STATEMENT_IF_LOCAL_XOR_BASE = 5888;
  /// Names unresolved multiplication, division, and remainder declarations.
  public const long STATEMENT_LOCAL_LONG_MUL_NAMED = 790;
  /// Names an unresolved division declaration with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_DIV_NAMED = 791;
  /// Names an unresolved remainder declaration with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_MOD_NAMED = 792;
  /// Names unresolved two-local multiplication, division, and remainder declarations.
  public const long STATEMENT_LOCAL_LONG_MUL_LOCALS_NAMED = 793;
  /// Names an unresolved division declaration over two prior locals.
  public const long STATEMENT_LOCAL_LONG_DIV_LOCALS_NAMED = 794;
  /// Names an unresolved remainder declaration over two prior locals.
  public const long STATEMENT_LOCAL_LONG_MOD_LOCALS_NAMED = 795;
  /// Starts resolved multiplication declarations with literal right operands.
  public const long STATEMENT_LOCAL_LONG_MUL_BASE = 6144;
  /// Starts resolved division declarations with literal right operands.
  public const long STATEMENT_LOCAL_LONG_DIV_BASE = 6400;
  /// Starts resolved remainder declarations with literal right operands.
  public const long STATEMENT_LOCAL_LONG_MOD_BASE = 6656;
  /// Starts resolved multiplication declarations over two prior locals.
  public const long STATEMENT_LOCAL_LONG_MUL_LOCALS_BASE = 6912;
  /// Starts resolved division declarations over two prior locals.
  public const long STATEMENT_LOCAL_LONG_DIV_LOCALS_BASE = 7168;
  /// Starts resolved remainder declarations over two prior locals.
  public const long STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE = 7424;
  /// Names an unresolved equality assertion over two prior locals.
  public const long STATEMENT_ASSERT_LOCAL_PAIR_NAMED = 796;
  /// Starts resolved equality assertions over prior signed locals.
  public const long STATEMENT_ASSERT_LONG_PAIR_BASE = 7680;
  /// Starts resolved equality assertions over prior Boolean locals.
  public const long STATEMENT_ASSERT_BOOLEAN_PAIR_BASE = 7936;
  /// Names an unresolved less-than assertion over prior signed locals.
  public const long STATEMENT_ASSERT_LONG_LT_NAMED = 797;
  /// Starts resolved less-than assertions over prior signed locals.
  public const long STATEMENT_ASSERT_LONG_LT_BASE = 8192;
  /// Names a negated local condition guarding global addition.
  public const long STATEMENT_IF_NOT_LOCAL_ADD_NAMED = 798;
  /// Names a negated local condition guarding global subtraction.
  public const long STATEMENT_IF_NOT_LOCAL_SUB_NAMED = 799;
  /// Names a negated local condition guarding global XOR.
  public const long STATEMENT_IF_NOT_LOCAL_XOR_NAMED = 800;
  /// Starts resolved negated local conditions guarding global addition.
  public const long STATEMENT_IF_NOT_LOCAL_ADD_BASE = 8448;
  /// Starts resolved negated local conditions guarding global subtraction.
  public const long STATEMENT_IF_NOT_LOCAL_SUB_BASE = 8704;
  /// Starts resolved negated local conditions guarding global XOR.
  public const long STATEMENT_IF_NOT_LOCAL_XOR_BASE = 8960;
  /// Names a local condition guarding global assignment.
  public const long STATEMENT_IF_LOCAL_ASSIGN_NAMED = 801;
  /// Names a negated local condition guarding global assignment.
  public const long STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED = 802;
  /// Starts resolved local conditions guarding global assignment.
  public const long STATEMENT_IF_LOCAL_ASSIGN_BASE = 9216;
  /// Starts resolved negated local conditions guarding global assignment.
  public const long STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE = 9472;
  /// Names a local condition assigning a prior signed local to global state.
  public const long STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED = 803;
  /// Names a negated condition assigning a prior signed local to global state.
  public const long STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED = 804;
  /// Starts resolved local conditions assigning prior signed locals.
  public const long STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE = 9728;
  /// Starts resolved negated conditions assigning prior signed locals.
  public const long STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE = 9984;
  /// Names a global assignment from a prior signed local.
  public const long STATEMENT_ASSIGN_LOCAL_NAMED = 805;
  /// Names checked global addition from a prior signed local.
  public const long STATEMENT_UPDATE_ADD_LOCAL_NAMED = 806;
  /// Names checked global subtraction from a prior signed local.
  public const long STATEMENT_UPDATE_SUB_LOCAL_NAMED = 807;
  /// Names global XOR from a prior signed local.
  public const long STATEMENT_UPDATE_XOR_LOCAL_NAMED = 808;
  /// Names a local condition guarding addition from a prior signed local.
  public const long STATEMENT_IF_LOCAL_ADD_VALUE_NAMED = 809;
  /// Names a local condition guarding subtraction from a prior signed local.
  public const long STATEMENT_IF_LOCAL_SUB_VALUE_NAMED = 810;
  /// Names a local condition guarding XOR from a prior signed local.
  public const long STATEMENT_IF_LOCAL_XOR_VALUE_NAMED = 811;
  /// Names a negated condition guarding addition from a prior signed local.
  public const long STATEMENT_IF_NOT_LOCAL_ADD_VALUE_NAMED = 812;
  /// Names a negated condition guarding subtraction from a prior signed local.
  public const long STATEMENT_IF_NOT_LOCAL_SUB_VALUE_NAMED = 813;
  /// Names a negated condition guarding XOR from a prior signed local.
  public const long STATEMENT_IF_NOT_LOCAL_XOR_VALUE_NAMED = 814;
  /// Starts local conditions guarding addition from prior signed locals.
  public const long STATEMENT_IF_LOCAL_ADD_VALUE_BASE = 10240;
  /// Starts local conditions guarding subtraction from prior signed locals.
  public const long STATEMENT_IF_LOCAL_SUB_VALUE_BASE = 10496;
  /// Starts local conditions guarding XOR from prior signed locals.
  public const long STATEMENT_IF_LOCAL_XOR_VALUE_BASE = 10752;
  /// Starts negated conditions guarding addition from prior signed locals.
  public const long STATEMENT_IF_NOT_LOCAL_ADD_VALUE_BASE = 11008;
  /// Starts negated conditions guarding subtraction from prior signed locals.
  public const long STATEMENT_IF_NOT_LOCAL_SUB_VALUE_BASE = 11264;
  /// Starts negated conditions guarding XOR from prior signed locals.
  public const long STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE = 11520;
  /// Names signed-local equality with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED = 815;
  /// Names signed-local less-than with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED = 816;
  /// Starts resolved signed-local equality with literal right operands.
  public const long STATEMENT_LOCAL_LONG_EQ_LITERAL_BASE = 11776;
  /// Starts resolved signed-local less-than with literal right operands.
  public const long STATEMENT_LOCAL_LONG_LT_LITERAL_BASE = 12032;
  /// Names an equality assertion over two signed literals.
  public const long STATEMENT_ASSERT_LITERAL_EQ = 817;
  /// Names a signed-local equality condition guarding global addition.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_NAMED = 818;
  /// Names a signed-local equality condition guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED = 819;
  /// Names a signed-local equality condition guarding global XOR.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED = 820;
  /// Names a signed-local equality condition guarding global assignment.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED = 821;
  /// Starts resolved equality conditions guarding global addition.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_BASE = 12288;
  /// Starts resolved equality conditions guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_BASE = 12544;
  /// Starts resolved equality conditions guarding global XOR.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_BASE = 12800;
  /// Starts resolved equality conditions guarding global assignment.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_BASE = 13056;
  /// Names a signed-local less-than condition guarding global addition.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED = 822;
  /// Names a signed-local less-than condition guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED = 823;
  /// Names a signed-local less-than condition guarding global XOR.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED = 824;
  /// Names a signed-local less-than condition guarding global assignment.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED = 825;
  /// Starts resolved less-than conditions guarding global addition.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE = 13312;
  /// Starts resolved less-than conditions guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_SUB_BASE = 13568;
  /// Starts resolved less-than conditions guarding global XOR.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_XOR_BASE = 13824;
  /// Starts resolved less-than conditions guarding global assignment.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE = 14080;
  /// Names a signed local initialized by a zero-argument helper call.
  public const long STATEMENT_LOCAL_CALL_NAMED = 826;
  /// Names a signed literal return from a helper.
  public const long STATEMENT_RETURN_LONG = 827;
  /// Names the parser IR code for checked global addition.
  public const long STATEMENT_UPDATE_ADD = 1040;
  /// Names the parser IR code for checked global subtraction.
  public const long STATEMENT_UPDATE_SUB = 1041;
  /// Names the parser IR code for global XOR.
  public const long STATEMENT_UPDATE_XOR = 1042;

  /// Names the ASCII `!` punctuation scalar.
  public const long PUNCTUATION_BANG = 33;
  /// Names the ASCII `%` punctuation scalar.
  public const long PUNCTUATION_PERCENT = 37;
  /// Names the ASCII `(` punctuation scalar.
  public const long PUNCTUATION_OPEN_PAREN = 40;
  /// Names the ASCII `)` punctuation scalar.
  public const long PUNCTUATION_CLOSE_PAREN = 41;
  /// Names the ASCII `*` punctuation scalar.
  public const long PUNCTUATION_STAR = 42;
  /// Names the ASCII `+` punctuation scalar.
  public const long PUNCTUATION_PLUS = 43;
  /// Names the ASCII `.` punctuation scalar.
  public const long PUNCTUATION_DOT = 46;
  /// Names the ASCII `-` punctuation scalar.
  public const long PUNCTUATION_MINUS = 45;
  /// Names the ASCII `/` punctuation scalar.
  public const long PUNCTUATION_SLASH = 47;
  /// Names the ASCII `;` punctuation scalar.
  public const long PUNCTUATION_SEMICOLON = 59;
  /// Names the ASCII `<` punctuation scalar.
  public const long PUNCTUATION_LESS_THAN = 60;
  /// Names the ASCII `=` punctuation scalar.
  public const long PUNCTUATION_ASSIGN = 61;
  /// Names the ASCII `^` punctuation scalar.
  public const long PUNCTUATION_CARET = 94;
  /// Names the ASCII `{` punctuation scalar.
  public const long PUNCTUATION_OPEN_BRACE = 123;
  /// Names the ASCII `}` punctuation scalar.
  public const long PUNCTUATION_CLOSE_BRACE = 125;

  /// Computes the stable hash of one bounded source token.
  public long tokenHash(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long cursor = tokenStarts[token];
    long end = cursor + tokenLengths[token];
    long hash = 0;
    while (cursor < end) limit 16 {
      hash = hash * 31 + utf8Scalar(source, cursor);
      cursor += utf8Width(source, cursor);
    }

    return hash;
  }

  /// Checks one token against an exact punctuation scalar.
  public boolean punctuationAt(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long token,
    long scalar
  ) {
    if (tokenKinds[token] == 3) {
      return utf8Scalar(source, tokenStarts[token]) == scalar;
    }

    return false;
  }

  /// Checks whether `tokenText` denotes the same canonical value.
  public boolean sameTokenText(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long left,
    long right
  ) {
    if (tokenLengths[left] == tokenLengths[right]) {
      long cursor = 0;
      while (cursor < tokenLengths[left]) limit 256 {
        long leftScalar = utf8Scalar(source, tokenStarts[left] + cursor);
        long rightScalar = utf8Scalar(source, tokenStarts[right] + cursor);
        if (leftScalar < rightScalar) {
          return false;
        }

        if (rightScalar < leftScalar) {
          return false;
        }

        cursor += 1;
      }

      return true;
    }

    return false;
  }

  /// Returns the token width consumed by one signed integer literal.
  public long signedNumberWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long token
  ) {
    if (tokenKinds[token] == 2) {
      return 1;
    }

    if (punctuationAt(source, tokenKinds, tokenStarts, token, PUNCTUATION_MINUS)) {
      if (tokenKinds[token + 1] == 2) {
        return 2;
      }
    }

    return -1;
  }

  /// Maps one statement token to its bounded parser opcode.
  public long statementOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long keyword = tokenHash(source, tokenStarts, tokenLengths, statementStart);
    if (keyword == TOKEN_ASSERT) {
      long assertExpression = statementStart + 2;
      long assertHash = tokenHash(source, tokenStarts, tokenLengths, assertExpression);
      if (assertHash == TOKEN_TRUE) {
        return STATEMENT_ASSERT_BOOLEAN;
      }

      if (assertHash == TOKEN_FALSE) {
        return STATEMENT_ASSERT_BOOLEAN;
      }

      long assertScalar = utf8Scalar(source, tokenStarts[assertExpression]);
      if (assertScalar == PUNCTUATION_BANG) {
        return STATEMENT_ASSERT_BOOLEAN_NOT;
      }

      if (identifierStart(assertScalar) == false) {
        return STATEMENT_ASSERT_LITERAL_EQ;
      }

      if (
        utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_CLOSE_PAREN
      ) {
        return STATEMENT_ASSERT_LOCAL_BOOLEAN;
      }

      if (tokenHash(source, tokenStarts, tokenLengths, 5) == TOKEN_LONG) {
        if (sameTokenText(source, tokenStarts, tokenLengths, 6, assertExpression)) {
          return STATEMENT_ASSERT_EQ;
        }
      }

      if (utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_LESS_THAN) {
        return STATEMENT_ASSERT_LONG_LT_NAMED;
      }

      long assertedRight = utf8Scalar(source, tokenStarts[statementStart + 5]);
      if (identifierStart(assertedRight)) {
        return STATEMENT_ASSERT_LOCAL_PAIR_NAMED;
      }

      return STATEMENT_ASSERT_NAMED_LONG;
    }

    if (keyword == TOKEN_RETURN) {
      return STATEMENT_RETURN_LONG;
    }

    if (keyword == TOKEN_IF) {
      long conditionOperator = utf8Scalar(source, tokenStarts[statementStart + 3]);
      long comparisonLiteralToken = -1;
      boolean lessThanComparison = conditionOperator == PUNCTUATION_LESS_THAN;
      if (lessThanComparison) {
        comparisonLiteralToken = statementStart + 4;
      }

      if (conditionOperator == PUNCTUATION_ASSIGN) {
        long conditionSecondOperator = utf8Scalar(source, tokenStarts[statementStart + 4]);
        if (conditionSecondOperator == PUNCTUATION_ASSIGN) {
          comparisonLiteralToken = statementStart + 5;
        }
      }

      if (-1 < comparisonLiteralToken) {
        long comparisonWidth = 1;
        if (
          utf8Scalar(source, tokenStarts[comparisonLiteralToken]) == PUNCTUATION_MINUS
        ) {
          comparisonWidth = 2;
        }

        long comparisonBodyOperator = utf8Scalar(
          source,
          tokenStarts[comparisonLiteralToken + 3 + comparisonWidth]
        );
        if (comparisonBodyOperator == PUNCTUATION_PLUS) {
          if (lessThanComparison) {
            return STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED;
          }

          return STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_NAMED;
        }

        if (comparisonBodyOperator == PUNCTUATION_MINUS) {
          if (lessThanComparison) {
            return STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED;
          }

          return STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED;
        }

        if (comparisonBodyOperator == PUNCTUATION_CARET) {
          if (lessThanComparison) {
            return STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED;
          }

          return STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED;
        }

        if (comparisonBodyOperator == PUNCTUATION_ASSIGN) {
          if (lessThanComparison) {
            return STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED;
          }

          return STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED;
        }

        return -1;
      }

      boolean negatedCondition = utf8Scalar(source, tokenStarts[statementStart + 2])
        == PUNCTUATION_BANG;
      long operatorToken = statementStart + 6;
      if (negatedCondition) {
        operatorToken += 1;
      }

      long conditionalOperator = utf8Scalar(source, tokenStarts[operatorToken]);
      long conditionalUpdateScalar = utf8Scalar(source, tokenStarts[operatorToken + 2]);
      boolean conditionalUpdateNamed = identifierStart(conditionalUpdateScalar);
      if (conditionalOperator == PUNCTUATION_PLUS) {
        if (negatedCondition) {
          if (conditionalUpdateNamed) {
            return STATEMENT_IF_NOT_LOCAL_ADD_VALUE_NAMED;
          }

          return STATEMENT_IF_NOT_LOCAL_ADD_NAMED;
        }

        if (conditionalUpdateNamed) {
          return STATEMENT_IF_LOCAL_ADD_VALUE_NAMED;
        }

        return STATEMENT_IF_LOCAL_ADD_NAMED;
      }

      if (conditionalOperator == PUNCTUATION_MINUS) {
        if (negatedCondition) {
          if (conditionalUpdateNamed) {
            return STATEMENT_IF_NOT_LOCAL_SUB_VALUE_NAMED;
          }

          return STATEMENT_IF_NOT_LOCAL_SUB_NAMED;
        }

        if (conditionalUpdateNamed) {
          return STATEMENT_IF_LOCAL_SUB_VALUE_NAMED;
        }

        return STATEMENT_IF_LOCAL_SUB_NAMED;
      }

      if (conditionalOperator == PUNCTUATION_CARET) {
        if (negatedCondition) {
          if (conditionalUpdateNamed) {
            return STATEMENT_IF_NOT_LOCAL_XOR_VALUE_NAMED;
          }

          return STATEMENT_IF_NOT_LOCAL_XOR_NAMED;
        }

        if (conditionalUpdateNamed) {
          return STATEMENT_IF_LOCAL_XOR_VALUE_NAMED;
        }

        return STATEMENT_IF_LOCAL_XOR_NAMED;
      }

      if (conditionalOperator == PUNCTUATION_ASSIGN) {
        long conditionalRightScalar = utf8Scalar(source, tokenStarts[operatorToken + 1]);
        if (identifierStart(conditionalRightScalar)) {
          if (negatedCondition) {
            return STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED;
          }

          return STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED;
        }

        if (negatedCondition) {
          return STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED;
        }

        return STATEMENT_IF_LOCAL_ASSIGN_NAMED;
      }

      return -1;
    }

    if (keyword == TOKEN_LONG) {
      long initializer = utf8Scalar(source, tokenStarts[statementStart + 3]);
      if (identifierStart(initializer)) {
        long initializerOperator = utf8Scalar(source, tokenStarts[statementStart + 4]);
        if (initializerOperator == PUNCTUATION_OPEN_PAREN) {
          return STATEMENT_LOCAL_CALL_NAMED;
        }

        long rightScalar = utf8Scalar(source, tokenStarts[statementStart + 5]);
        boolean rightNamed = identifierStart(rightScalar);
        if (initializerOperator == PUNCTUATION_PLUS) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_ADD_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_ADD_NAMED;
        }

        if (initializerOperator == PUNCTUATION_MINUS) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_SUB_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_SUB_NAMED;
        }

        if (initializerOperator == PUNCTUATION_CARET) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_XOR_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_XOR_NAMED;
        }

        if (initializerOperator == PUNCTUATION_STAR) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_MUL_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_MUL_NAMED;
        }

        if (initializerOperator == PUNCTUATION_SLASH) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_DIV_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_DIV_NAMED;
        }

        if (initializerOperator == PUNCTUATION_PERCENT) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_MOD_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_MOD_NAMED;
        }

        return STATEMENT_LOCAL_LONG_NAMED;
      }

      return STATEMENT_LOCAL_LONG;
    }

    if (keyword == TOKEN_BOOLEAN) {
      if (utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_BANG) {
        long negated = tokenHash(source, tokenStarts, tokenLengths, statementStart + 4);
        if (negated == TOKEN_TRUE) {
          return STATEMENT_LOCAL_BOOLEAN_NOT;
        }

        if (negated == TOKEN_FALSE) {
          return STATEMENT_LOCAL_BOOLEAN_NOT;
        }

        return STATEMENT_LOCAL_BOOLEAN_NOT_NAMED;
      }

      long booleanInitializer = tokenHash(source, tokenStarts, tokenLengths, statementStart + 3);
      if (booleanInitializer == TOKEN_TRUE) {
        return STATEMENT_LOCAL_BOOLEAN;
      }

      if (booleanInitializer == TOKEN_FALSE) {
        return STATEMENT_LOCAL_BOOLEAN;
      }

      long equality = utf8Scalar(source, tokenStarts[statementStart + 4]);
      if (equality == PUNCTUATION_ASSIGN) {
        if (utf8Scalar(source, tokenStarts[statementStart + 5]) == PUNCTUATION_ASSIGN) {
          long equalityRight = utf8Scalar(source, tokenStarts[statementStart + 6]);
          if (identifierStart(equalityRight)) {
            return STATEMENT_LOCAL_BOOLEAN_EQ_NAMED;
          }

          return STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED;
        }
      }

      if (equality == PUNCTUATION_LESS_THAN) {
        long lessThanRight = utf8Scalar(source, tokenStarts[statementStart + 5]);
        if (identifierStart(lessThanRight)) {
          return STATEMENT_LOCAL_LONG_LT_NAMED;
        }

        return STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED;
      }

      return STATEMENT_LOCAL_BOOLEAN_NAMED;
    }

    long operator = utf8Scalar(source, tokenStarts[statementStart + 1]);
    if (operator == PUNCTUATION_ASSIGN) {
      long assignedScalar = utf8Scalar(source, tokenStarts[statementStart + 2]);
      if (identifierStart(assignedScalar)) {
        return STATEMENT_ASSIGN_LOCAL_NAMED;
      }

      return STATEMENT_ASSIGN;
    }

    long updateScalar = utf8Scalar(source, tokenStarts[statementStart + 3]);
    boolean localUpdate = identifierStart(updateScalar);
    if (operator == PUNCTUATION_PLUS) {
      if (localUpdate) {
        return STATEMENT_UPDATE_ADD_LOCAL_NAMED;
      }

      return STATEMENT_UPDATE_ADD;
    }

    if (operator == PUNCTUATION_MINUS) {
      if (localUpdate) {
        return STATEMENT_UPDATE_SUB_LOCAL_NAMED;
      }

      return STATEMENT_UPDATE_SUB;
    }

    if (operator == PUNCTUATION_CARET) {
      if (localUpdate) {
        return STATEMENT_UPDATE_XOR_LOCAL_NAMED;
      }

      return STATEMENT_UPDATE_XOR;
    }

    return -1;
  }

  /// Validates and sizes one bounded helper value statement.
  public long helperValueStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long statementKind
  ) {
    if (statementKind == STATEMENT_RETURN_LONG) {
      long returnWidth = signedNumberWidth(source, tokenKinds, tokenStarts, statementStart + 1);
      if (returnWidth < 1) {
        return -1;
      }

      if (
        signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 1) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 1 + returnWidth,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return returnWidth + 2;
      }

      return -1;
    }

    if (statementKind == STATEMENT_LOCAL_CALL_NAMED) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
          == false
      ) {
        return -1;
      }

      if (tokenKinds[statementStart + 3] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_OPEN_PAREN
        ) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 5,
          PUNCTUATION_CLOSE_PAREN
        ) == false
      ) {
        return -1;
      }

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

    return -1;
  }

  /// Validates and sizes one equality assertion over two signed literals.
  public long literalEqualityStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 1,
        PUNCTUATION_OPEN_PAREN
      ) == false
    ) {
      return -1;
    }

    long leftWidth = signedNumberWidth(source, tokenKinds, tokenStarts, statementStart + 2);
    if (leftWidth < 1) {
      return -1;
    }

    if (
      signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 2) == false
    ) {
      return -1;
    }

    long equalityStart = statementStart + 2 + leftWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, equalityStart, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, equalityStart + 1, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    long rightStart = equalityStart + 2;
    long rightWidth = signedNumberWidth(source, tokenKinds, tokenStarts, rightStart);
    if (rightWidth < 1) {
      return -1;
    }

    if (signedNumberValid(source, tokenStarts, tokenLengths, rightStart) == false) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        rightStart + rightWidth,
        PUNCTUATION_CLOSE_PAREN
      ) == false
    ) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        rightStart + rightWidth + 1,
        PUNCTUATION_SEMICOLON
      )
    ) {
      return rightStart + rightWidth + 2 - statementStart;
    }

    return -1;
  }

  /// Checks one signed integer token for canonical syntax.
  public boolean signedNumberValid(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long magnitudeToken = token;
    if (utf8Scalar(source, tokenStarts[token]) == PUNCTUATION_MINUS) {
      magnitudeToken += 1;
    }

    long end = tokenStarts[magnitudeToken] + tokenLengths[magnitudeToken];
    long magnitude = parseNumber(source, tokenStarts[magnitudeToken], end);
    if (magnitude < 0) {
      return false;
    }

    return true;
  }

  /// Decodes one signed integer token after canonical syntax validation.
  public long parsedSignedNumber(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long magnitudeToken = token;
    long sign = 1;
    if (utf8Scalar(source, tokenStarts[token]) == PUNCTUATION_MINUS) {
      magnitudeToken += 1;
      sign = -1;
    }

    long end = tokenStarts[magnitudeToken] + tokenLengths[magnitudeToken];
    long magnitude = parseNumber(source, tokenStarts[magnitudeToken], end);
    return sign * magnitude;
  }
}
