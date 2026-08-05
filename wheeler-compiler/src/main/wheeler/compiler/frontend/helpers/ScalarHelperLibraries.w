//! Parses bounded entryless libraries with several scalar helpers.

module wheeler.compiler.scalar_helper_libraries;

import wheeler.compiler.body_parser;
import wheeler.compiler.class_constants;
import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.early_comparison_forms;
import wheeler.compiler.encoding;
import wheeler.compiler.helper_abi;
import wheeler.compiler.ir;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.named_comparison_kinds;
import wheeler.compiler.named_return_arithmetic_kinds;
import wheeler.compiler.resolved_early_result_kinds;
import wheeler.compiler.resolved_local_returns;
import wheeler.compiler.resolved_long_operations;
import wheeler.compiler.resolved_return_call_kinds;
import wheeler.compiler.scalar_helper_tables;
import wheeler.compiler.sequences;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.tokens;

classical class ScalarHelperLibraries {
  /// Carries one complete scalar helper and the following declaration token.
  public record ParsedScalarHelper(HelperBody body, long nextToken, boolean valid) {}

  /// Returns one invalid helper parse sentinel.
  public ParsedScalarHelper invalidHelper() {
    return new ParsedScalarHelper(emptyHelperBody(), 0, false);
  }

  private boolean signedResult(long opcode) {
    if (opcode == STATEMENT_RETURN_LONG) {
      return true;
    }

    if (resolvedSignedLocalReturn(opcode)) {
      return true;
    }

    if (returnLocalBinaryStatement(opcode)) {
      return true;
    }

    return returnLocalPairStatement(opcode);
  }

  private boolean booleanResult(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      return true;
    }

    if (returnComparisonStatement(opcode)) {
      return true;
    }

    if (resolvedReturnHelperCall(opcode)) {
      return true;
    }

    if (resolvedLocalReturn(opcode)) {
      return resolvedSignedLocalReturn(opcode) == false;
    }

    return false;
  }

  private boolean scalarSequenceValid(StatementSequence sequence, long kind) {
    if (0 < sequence.count) {} else {
      return false;
    }

    long result = sequence.count - 1;
    boolean booleanHelper = booleanHelperKind(kind);

    boolean validResult = signedResult(sequence.opcodes[result]);
    if (booleanHelper) {
      validResult = booleanResult(sequence.opcodes[result]);
    }

    if (validResult) {} else {
      return false;
    }

    long statement = 0;
    while (statement < result) limit MAX_MINIMAL_STATEMENTS {
      long earlyOpcode = sequence.opcodes[statement];
      boolean earlyReturn = resolvedEarlyComparisonReturn(earlyOpcode);
      if (resolvedEarlyHelperReturn(earlyOpcode)) {
        earlyReturn = true;
      }

      if (earlyReturn) {
        boolean signedEarlyReturn = resolvedEarlySignedReturn(earlyOpcode);
        if (booleanHelper) {
          if (signedEarlyReturn) {
            return false;
          }
        } else {
          if (signedEarlyReturn == false) {
            return false;
          }
        }
      } else {
        boolean signedPrelude = resolvedLocalLongBinary(earlyOpcode);
        if (resolvedLocalLongPair(earlyOpcode)) {
          signedPrelude = true;
        }

        if (signedPrelude == false) {
          return false;
        }
      }

      statement += 1;
    }

    return true;
  }

  /// Parses one scalar helper declaration and body.
  public ParsedScalarHelper parseScalarHelper(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    long start
  ) {
    long visibility = tokenHash(source, tokenStarts, tokenLengths, start);
    if (visibility == TOKEN_PUBLIC) {} else {
      if (visibility == TOKEN_PRIVATE) {} else {
        return invalidHelper();
      }
    }

    long returnType = tokenHash(source, tokenStarts, tokenLengths, start + 1);
    long kind = HELPER_SIGNED;
    if (returnType == TOKEN_LONG) {} else {
      if (returnType == TOKEN_BOOLEAN) {
        kind = HELPER_BOOLEAN;
      } else {
        return invalidHelper();
      }
    }

    long nameToken = start + 2;
    if (tokenKinds[nameToken] == 1) {} else {
      return invalidHelper();
    }

    if (tokenLengths[nameToken] < 257) {} else {
      return invalidHelper();
    }

    if (classConstantNameExists(source, tokenStarts, tokenLengths, nameToken)) {
      return invalidHelper();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 3, PUNCTUATION_OPEN_PAREN)
    ) {} else {
      return invalidHelper();
    }

    long parameterCount = 0;
    long firstParameterToken = 0;
    long secondParameterToken = 0;
    long thirdParameterToken = 0;
    long bodyOpen = start + 5;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 4, PUNCTUATION_CLOSE_PAREN)
    ) {} else {
      if (tokenHash(source, tokenStarts, tokenLengths, start + 4) == TOKEN_LONG) {} else {
        return invalidHelper();
      }

      firstParameterToken = start + 5;
      if (tokenKinds[firstParameterToken] == 1) {} else {
        return invalidHelper();
      }

      if (tokenLengths[firstParameterToken] < 257) {} else {
        return invalidHelper();
      }

      if (
        classConstantNameExists(source, tokenStarts, tokenLengths, firstParameterToken)
      ) {
        return invalidHelper();
      }

      parameterCount = 1;
      bodyOpen = start + 7;
      if (
        punctuationAt(source, tokenKinds, tokenStarts, start + 6, PUNCTUATION_COMMA)
      ) {
        if (tokenHash(source, tokenStarts, tokenLengths, start + 7) == TOKEN_LONG) {} else {
          return invalidHelper();
        }

        secondParameterToken = start + 8;
        if (tokenKinds[secondParameterToken] == 1) {} else {
          return invalidHelper();
        }

        if (tokenLengths[secondParameterToken] < 257) {} else {
          return invalidHelper();
        }

        if (
          classConstantNameExists(source, tokenStarts, tokenLengths, secondParameterToken)
        ) {
          return invalidHelper();
        }

        long parameterOrder = compareAsciiSlices(
          source,
          tokenStarts[firstParameterToken],
          tokenLengths[firstParameterToken],
          tokenStarts[secondParameterToken],
          tokenLengths[secondParameterToken]
        );
        if (parameterOrder == 0) {
          return invalidHelper();
        }

        if (
          punctuationAt(source, tokenKinds, tokenStarts, start + 9, PUNCTUATION_COMMA)
        ) {
          if (tokenHash(source, tokenStarts, tokenLengths, start + 10) == TOKEN_LONG) {} else {
            return invalidHelper();
          }

          thirdParameterToken = start + 11;
          if (tokenKinds[thirdParameterToken] == 1) {} else {
            return invalidHelper();
          }

          if (tokenLengths[thirdParameterToken] < 257) {} else {
            return invalidHelper();
          }

          if (
            classConstantNameExists(source, tokenStarts, tokenLengths, thirdParameterToken)
          ) {
            return invalidHelper();
          }

          long firstThirdOrder = compareAsciiSlices(
            source,
            tokenStarts[firstParameterToken],
            tokenLengths[firstParameterToken],
            tokenStarts[thirdParameterToken],
            tokenLengths[thirdParameterToken]
          );
          long secondThirdOrder = compareAsciiSlices(
            source,
            tokenStarts[secondParameterToken],
            tokenLengths[secondParameterToken],
            tokenStarts[thirdParameterToken],
            tokenLengths[thirdParameterToken]
          );
          if (firstThirdOrder == 0) {
            return invalidHelper();
          }

          if (secondThirdOrder == 0) {
            return invalidHelper();
          }

          if (
            punctuationAt(source, tokenKinds, tokenStarts, start + 12, PUNCTUATION_CLOSE_PAREN)
          ) {} else {
            return invalidHelper();
          }

          parameterCount = 3;
          bodyOpen = start + 13;
          if (returnType == TOKEN_LONG) {
            kind = HELPER_SIGNED_THREE;
          } else {
            kind = HELPER_BOOLEAN_SIGNED_THREE;
          }
        } else {
          if (
            punctuationAt(source, tokenKinds, tokenStarts, start + 9, PUNCTUATION_CLOSE_PAREN)
          ) {} else {
            return invalidHelper();
          }

          parameterCount = 2;
          bodyOpen = start + 10;
          if (returnType == TOKEN_LONG) {
            kind = HELPER_SIGNED_TWO;
          } else {
            kind = HELPER_BOOLEAN_SIGNED_TWO;
          }
        }
      } else {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, start + 6, PUNCTUATION_CLOSE_PAREN)
        ) {} else {
          return invalidHelper();
        }

        if (returnType == TOKEN_LONG) {
          kind = HELPER_SIGNED_ONE;
        } else {
          kind = HELPER_BOOLEAN_SIGNED_ONE;
        }
      }
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, bodyOpen, PUNCTUATION_OPEN_BRACE)
    ) {} else {
      return invalidHelper();
    }

    BodyScan statements = scanBody(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      bodyOpen + 1
    );
    if (statements.valid) {} else {
      return invalidHelper();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statements.end, PUNCTUATION_CLOSE_BRACE)
    ) {} else {
      return invalidHelper();
    }

    SourceRange firstCallTarget = new SourceRange(0, 0);
    SourceRange secondCallTarget = new SourceRange(0, 0);
    long firstCallStatement = -1;
    long secondCallStatement = -1;
    long callCount = 0;
    long sourceStatement = 0;
    while (sourceStatement < statements.count) limit MAX_MINIMAL_STATEMENTS {
      long sourceOpcode = statementOpcode(
        source,
        tokenStarts,
        tokenLengths,
        statementStarts[sourceStatement]
      );
      boolean helperCall = sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_TRUE_NAMED;
      if (sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_FALSE_NAMED) {
        helperCall = true;
      }

      if (sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_LONG_NAMED) {
        helperCall = true;
      }

      long targetToken = statementStarts[sourceStatement] + 2;
      if (sourceOpcode == STATEMENT_RETURN_HELPER_CALL_NAMED) {
        helperCall = true;
        targetToken = statementStarts[sourceStatement] + 1;
      }

      if (helperCall) {
        SourceRange target = new SourceRange(
          tokenStarts[targetToken],
          tokenLengths[targetToken]
        );
        if (callCount == 0) {
          firstCallTarget = target;
          firstCallStatement = sourceStatement;
        } else {
          secondCallTarget = target;
          secondCallStatement = sourceStatement;
        }

        callCount += 1;
      }

      sourceStatement += 1;
    }

    if (callCount < 3) {} else {
      return invalidHelper();
    }

    if (0 < parameterCount) {
      long shifted = statements.count;
      while (0 < shifted) limit MAX_MINIMAL_STATEMENTS {
        set(statementStarts, shifted + parameterCount - 1, statementStarts[shifted - 1]);
        shifted -= 1;
      }

      set(statementStarts, 0, 0 - firstParameterToken);
      if (1 < parameterCount) {
        set(statementStarts, 1, 0 - secondParameterToken);
      }

      if (parameterCount == 3) {
        set(statementStarts, 2, 0 - thirdParameterToken);
      }
    }

    StatementSequence sequence = parseStatementSequence(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      statements.count
    );
    if (scalarSequenceValid(sequence, kind)) {} else {
      return invalidHelper();
    }

    HelperBody body = new HelperBody(
      new SourceRange(tokenStarts[nameToken], tokenLengths[nameToken]),
      sequence.opcodes,
      sequence.operands,
      sequence.secondaryOperands,
      kind,
      sequence.count,
      sequence.count - 1,
      firstCallTarget,
      firstCallStatement,
      -1,
      secondCallTarget,
      secondCallStatement,
      -1
    );
    return new ParsedScalarHelper(body, statements.end + 1, true);
  }

}
