//! Parses bounded entryless libraries with several scalar helpers.

module wheeler.compiler.scalar_helper_libraries;

import wheeler.compiler.body_parser;
import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.class_constants;
import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.early_comparison_forms;
import wheeler.compiler.encoding;
import wheeler.compiler.helper_abi;
import wheeler.compiler.helper_parameter_types;
import wheeler.compiler.helper_signatures;
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
import wheeler.compiler.type_codes;

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

    if (resolvedReturnHelperCall(opcode)) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_LENGTH) {
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

  private boolean intrinsicSourcesValid(
    StatementSequence sequence,
    long[16] parameterTypes,
    long parameterCount
  ) {
    long statement = 0;
    while (statement < sequence.count) limit MAX_MINIMAL_STATEMENTS {
      long opcode = sequence.opcodes[statement];
      boolean bufferLength = opcode == STATEMENT_RETURN_BUFFER_LENGTH;
      if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH) {
        bufferLength = true;
      }

      if (opcode == STATEMENT_LOCAL_BUFFER_GET) {
        long bufferLocal = sequence.operands[statement];
        if (bufferLocal < 0) {
          return false;
        }

        if (bufferLocal < parameterCount) {} else {
          return false;
        }

        long bufferType = parameterTypes[bufferLocal];
        boolean indexableBuffer = bufferType == TYPE_BYTE_VIEW;
        if (bufferType == TYPE_BYTES_BORROW) {
          indexableBuffer = true;
        }

        if (bufferType == TYPE_WORDS_BORROW) {
          indexableBuffer = true;
        }

        if (indexableBuffer == false) {
          return false;
        }

        long bufferIndex = sequence.secondaryOperands[statement];
        if (bufferIndex < 0) {
          return false;
        }

        if (bufferIndex < parameterCount) {
          if (parameterTypes[bufferIndex] == TYPE_SIGNED) {} else {
            return false;
          }
        }
      }

      boolean utf8IndexedRead = opcode == STATEMENT_LOCAL_UTF8_SCALAR;
      if (opcode == STATEMENT_LOCAL_UTF8_WIDTH) {
        utf8IndexedRead = true;
      }

      if (utf8IndexedRead) {
        long utf8Local = sequence.operands[statement];
        if (utf8Local < 0) {
          return false;
        }

        if (utf8Local < parameterCount) {} else {
          return false;
        }

        if (parameterTypes[utf8Local] == TYPE_UTF8_BORROW) {} else {
          return false;
        }

        long indexLocal = sequence.secondaryOperands[statement];
        if (indexLocal < 0) {
          return false;
        }

        if (indexLocal < parameterCount) {
          if (parameterTypes[indexLocal] == TYPE_SIGNED) {} else {
            return false;
          }
        }
      }

      if (bufferLength) {
        long sourceLocal = sequence.operands[statement];
        if (sourceLocal < 0) {
          return false;
        }

        if (sourceLocal < parameterCount) {} else {
          return false;
        }

        long sourceType = parameterTypes[sourceLocal];
        boolean buffer = sourceType == TYPE_UTF8_BORROW;
        if (sourceType == TYPE_BYTE_VIEW) {
          buffer = true;
        }

        if (sourceType == TYPE_BYTES_BORROW) {
          buffer = true;
        }

        if (sourceType == TYPE_WORDS_BORROW) {
          buffer = true;
        }

        if (buffer == false) {
          return false;
        }
      }

      statement += 1;
    }

    return true;
  }

  private boolean scalarSequenceValid(
    StatementSequence sequence,
    long kind,
    long[16] parameterTypes,
    long parameterCount
  ) {
    if (0 < sequence.count) {} else {
      return false;
    }

    if (intrinsicSourcesValid(sequence, parameterTypes, parameterCount)) {} else {
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
        if (earlyOpcode == STATEMENT_LOCAL_LONG) {
          signedPrelude = true;
        }

        if (resolvedLocalLongPair(earlyOpcode)) {
          signedPrelude = true;
        }

        if (earlyOpcode == STATEMENT_LOCAL_BUFFER_LENGTH) {
          signedPrelude = true;
        }

        if (earlyOpcode == STATEMENT_LOCAL_UTF8_SCALAR) {
          signedPrelude = true;
        }

        if (earlyOpcode == STATEMENT_LOCAL_UTF8_WIDTH) {
          signedPrelude = true;
        }

        if (earlyOpcode == STATEMENT_LOCAL_BUFFER_GET) {
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
    if (returnType == TOKEN_LONG) {} else {
      if (returnType == TOKEN_BOOLEAN) {} else {
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
    long parameterCursor = start + 4;
    while (
      punctuationAt(source, tokenKinds, tokenStarts, parameterCursor, PUNCTUATION_CLOSE_PAREN)
        == false
    ) limit MAX_SCALAR_HELPER_PARAMETERS {
      if (0 < parameterCount) {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, parameterCursor, PUNCTUATION_COMMA)
        ) {} else {
          return invalidHelper();
        }

        parameterCursor += 1;
      }

      HelperParameter parsedParameter = parseHelperParameter(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        parameterCursor
      );
      if (parsedParameter.valid) {} else {
        return invalidHelper();
      }

      long parameterName = parsedParameter.nameToken;
      if (classConstantNameExists(source, tokenStarts, tokenLengths, parameterName)) {
        return invalidHelper();
      }

      long priorParameter = 0;
      while (priorParameter < parameterCount) limit MAX_SCALAR_HELPER_PARAMETERS {
        HelperParameter prior = helperParameterAt(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          start,
          priorParameter
        );
        if (prior.valid) {} else {
          return invalidHelper();
        }

        long parameterOrder = compareAsciiSlices(
          source,
          tokenStarts[prior.nameToken],
          tokenLengths[prior.nameToken],
          tokenStarts[parameterName],
          tokenLengths[parameterName]
        );
        if (parameterOrder == 0) {
          return invalidHelper();
        }

        priorParameter += 1;
      }

      parameterCount += 1;
      parameterCursor = parsedParameter.nextToken;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, parameterCursor, PUNCTUATION_CLOSE_PAREN)
    ) {} else {
      return invalidHelper();
    }

    long bodyOpen = parameterCursor + 1;
    long kind = signedScalarHelperKind(parameterCount);
    if (returnType == TOKEN_BOOLEAN) {
      kind = booleanScalarHelperKind(parameterCount);
    }

    if (-1 < kind) {} else {
      return invalidHelper();
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

    region callArena = new region(/* bytes= */ 1536, /* allocations= */ 3);
    words callTargetStartWork = allocate(callArena, MAX_SCALAR_HELPER_CALLS);
    words callTargetLengthWork = allocate(callArena, MAX_SCALAR_HELPER_CALLS);
    words callStatementWork = allocate(callArena, MAX_SCALAR_HELPER_CALLS);
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

      boolean forwardingGuard = sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_HELPER_CALL_NAMED;
      if (forwardingGuard) {
        helperCall = true;
      }

      long targetToken = statementStarts[sourceStatement] + 2;
      if (sourceOpcode == STATEMENT_RETURN_HELPER_CALL_NAMED) {
        helperCall = true;
        targetToken = statementStarts[sourceStatement] + 1;
      }

      if (helperCall) {
        if (callCount < MAX_SCALAR_HELPER_CALLS) {
          set(callTargetStartWork, callCount, tokenStarts[targetToken]);
          set(callTargetLengthWork, callCount, tokenLengths[targetToken]);
          set(callStatementWork, callCount, sourceStatement);
        }

        callCount += 1;
      }

      if (forwardingGuard) {
        long returnTargetToken = statementStarts[sourceStatement] + 9;
        if (callCount < MAX_SCALAR_HELPER_CALLS) {
          set(callTargetStartWork, callCount, tokenStarts[returnTargetToken]);
          set(callTargetLengthWork, callCount, tokenLengths[returnTargetToken]);
          set(callStatementWork, callCount, sourceStatement);
        }

        callCount += 1;
      }

      sourceStatement += 1;
    }

    if (callCount < MAX_SCALAR_HELPER_CALLS + 1) {} else {
      drop(callStatementWork);
      drop(callTargetLengthWork);
      drop(callTargetStartWork);
      drop(callArena);
      return invalidHelper();
    }

    if (0 < parameterCount) {
      long shifted = statements.count;
      while (0 < shifted) limit MAX_MINIMAL_STATEMENTS {
        set(statementStarts, shifted + parameterCount - 1, statementStarts[shifted - 1]);
        shifted -= 1;
      }

      long parameter = 0;
      while (parameter < parameterCount) limit MAX_SCALAR_HELPER_PARAMETERS {
        HelperParameter resolvedParameter = helperParameterAt(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          start,
          parameter
        );
        assert(resolvedParameter.valid);
        set(statementStarts, parameter, 0 - resolvedParameter.nameToken);
        parameter += 1;
      }
    }

    StatementSequence sequence = parseStatementSequence(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      statements.count
    );
    long[16] parameterTypes = parsedHelperParameterTypes(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      start,
      parameterCount
    );
    if (scalarSequenceValid(sequence, kind, parameterTypes, parameterCount)) {} else {
      drop(callStatementWork);
      drop(callTargetLengthWork);
      drop(callTargetStartWork);
      drop(callArena);
      return invalidHelper();
    }

    long[64] callTargetStarts = freezeHelperCallColumn(callTargetStartWork);
    long[64] callTargetLengths = freezeHelperCallColumn(callTargetLengthWork);
    long[64] callStatements = freezeHelperCallColumn(callStatementWork);
    long[64] callFunctions = emptyHelperCallIdentities();
    drop(callStatementWork);
    drop(callTargetLengthWork);
    drop(callTargetStartWork);
    drop(callArena);

    HelperBody body = new HelperBody(
      new SourceRange(tokenStarts[nameToken], tokenLengths[nameToken]),
      sequence.opcodes,
      sequence.operands,
      sequence.secondaryOperands,
      kind,
      parameterCount,
      parameterTypes,
      sequence.count,
      sequence.count - 1,
      callTargetStarts,
      callTargetLengths,
      callStatements,
      callFunctions,
      callCount
    );
    return new ParsedScalarHelper(body, statements.end + 1, true);
  }

}
