//! Builds and validates bounded helper and entry statement sequences.

module wheeler.compiler.helper_programs;

import wheeler.compiler.call_forms;
import wheeler.compiler.class_layouts;
import wheeler.compiler.helper_calls;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.scalar_opcodes;
import wheeler.compiler.sequences;
import wheeler.compiler.statement_forms;
import wheeler.compiler.tokens;

classical class HelperPrograms {
  private const long LOGICAL_ASSERTION_LOCALS = 3;

  private boolean signedResultSlotCall(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_ARGUMENT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED;
  }

  private boolean resultStatement(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      return true;
    }

    if (returnComparisonStatement(opcode)) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LONG) {
      return true;
    }

    if (resolvedLocalReturn(opcode)) {
      return true;
    }

    if (returnLocalBinaryStatement(opcode)) {
      return true;
    }

    return returnLocalPairStatement(opcode);
  }

  private boolean signedResultStatement(long opcode) {
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

  private boolean resultSlotSourceDeclared(
    StatementSequence sequence,
    long statement,
    long source
  ) {
    long prior = 0;
    long logicalBase = 0;
    while (prior < statement) limit MAX_MINIMAL_STATEMENTS {
      long opcode = sequence.opcodes[prior];
      if (signedResultSlotCall(opcode)) {
        long callLocals = statementLocalCount(opcode);
        if (source == logicalBase + callLocals - 1) {
          return true;
        }

        logicalBase += callLocals;
      } else {
        logicalBase += LOGICAL_ASSERTION_LOCALS;
      }

      prior += 1;
    }

    return false;
  }

  private boolean resultSlotEntryValid(StatementSequence sequence) {
    long statement = 0;
    long callCount = 0;
    while (statement < sequence.count) limit MAX_MINIMAL_STATEMENTS {
      long opcode = sequence.opcodes[statement];
      if (signedResultSlotCall(opcode)) {
        if (oneArgumentCallNamed(opcode)) {
          if (
            resultSlotSourceDeclared(sequence, statement, sequence.operands[statement])
          ) {} else {
            return false;
          }
        }

        callCount += 1;
      } else {
        if (resolvedLocalLongAssertion(opcode)) {
          long source = opcode - STATEMENT_ASSERT_LOCAL_LONG_BASE;
          if (resultSlotSourceDeclared(sequence, statement, source)) {} else {
            return false;
          }
        } else {
          if (resolvedLocalPairAssertionSigned(opcode)) {} else {
            return false;
          }

          long left = resolvedLocalPairAssertionSource(opcode);
          long right = sequence.operands[statement];
          if (resultSlotSourceDeclared(sequence, statement, left)) {} else {
            return false;
          }

          if (resultSlotSourceDeclared(sequence, statement, right)) {} else {
            return false;
          }
        }
      }

      statement += 1;
    }

    return 0 < callCount;
  }

  private boolean entryCallsMatchHelper(StatementSequence sequence, long helperKind) {
    long statement = 0;
    while (statement < sequence.count) limit MAX_MINIMAL_STATEMENTS {
      long opcode = sequence.opcodes[statement];
      if (scalarResultCallStatement(opcode)) {
        if (resolvedResultCallValid(opcode, helperKind) == false) {
          return false;
        }
      }

      statement += 1;
    }

    return true;
  }

  /// Builds one typed helper and entry program after bounded structural parsing.
  public MinimalProgramResult helperProgram(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    ClassLayout layout,
    long nameToken,
    long helperKind,
    long proofToken,
    long proofCount,
    long entryStatement,
    long helperCallCount,
    long preReverseStatement,
    long resultEntryCount,
    borrow mut words helperStarts,
    long helperStatementCount
  ) {
    SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
    SourceRange global = new SourceRange(0, 0);
    if (layout.globalCount == 1) {
      global = new SourceRange(
        tokenStarts[layout.globalNameToken],
        tokenLengths[layout.globalNameToken]
      );
    }

    SourceRange helper = new SourceRange(tokenStarts[nameToken], tokenLengths[nameToken]);
    SourceRange proof = new SourceRange(0, 0);
    if (proofCount == 1) {
      proof = new SourceRange(tokenStarts[proofToken], tokenLengths[proofToken]);
    }

    long parameterCount = parameterCountForHelper(helperKind);

    if (0 < parameterCount) {
      long shifted = helperStatementCount;
      while (0 < shifted) limit MAX_MINIMAL_STATEMENTS {
        set(helperStarts, shifted + parameterCount - 1, helperStarts[shifted - 1]);
        shifted -= 1;
      }

      long firstParameterMarker = 0 - (nameToken + 3);
      boolean booleanParameters = booleanParameterHelper(helperKind);

      if (booleanParameters) {
        firstParameterMarker -= BOOLEAN_PARAMETER_TOKEN_BIAS;
      }

      set(helperStarts, 0, firstParameterMarker);
      if (parameterCount == 2) {
        long secondParameterMarker = 0 - (nameToken + 6);
        if (booleanParameters) {
          secondParameterMarker -= BOOLEAN_PARAMETER_TOKEN_BIAS;
        }

        set(helperStarts, 1, secondParameterMarker);
      }
    }

    StatementSequence helperSequence = parseStatementSequence(
      source,
      tokenStarts,
      tokenLengths,
      helperStarts,
      helperStatementCount
    );
    if (helperSequence.valid == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (helperKind == HELPER_SIGNED) {
      if (0 < helperSequence.count) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long resultIndex = helperSequence.count - 1;
      long resultOpcode = helperSequence.opcodes[resultIndex];
      if (signedResultStatement(resultOpcode) == false) {
        return new MinimalProgramResult.Error(0);
      }

      long preludeStatement = 0;
      while (preludeStatement < resultIndex) limit MAX_MINIMAL_STATEMENTS {
        if (resultStatement(helperSequence.opcodes[preludeStatement])) {
          return new MinimalProgramResult.Error(0);
        }

        preludeStatement += 1;
      }
    }

    boolean booleanHelper = booleanResultHelper(helperKind);

    if (booleanHelper) {
      if (0 < helperSequence.count) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long booleanResultIndex = helperSequence.count - 1;
      long booleanResultOpcode = helperSequence.opcodes[booleanResultIndex];
      boolean supportedBooleanResult = booleanResultOpcode == STATEMENT_RETURN_BOOLEAN;
      if (booleanResultOpcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
        supportedBooleanResult = true;
      }

      if (returnComparisonStatement(booleanResultOpcode)) {
        supportedBooleanResult = true;
      }

      if (resolvedLocalReturn(booleanResultOpcode)) {
        if (resolvedSignedLocalReturn(booleanResultOpcode) == false) {
          supportedBooleanResult = true;
        }
      }

      if (supportedBooleanResult == false) {
        return new MinimalProgramResult.Error(0);
      }

      long booleanPreludeStatement = 0;
      while (booleanPreludeStatement < booleanResultIndex) limit MAX_MINIMAL_STATEMENTS {
        if (resultStatement(helperSequence.opcodes[booleanPreludeStatement])) {
          return new MinimalProgramResult.Error(0);
        }

        booleanPreludeStatement += 1;
      }
    }

    if (helperKind == HELPER_SIGNED_ONE) {
      if (0 < helperSequence.count) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long parameterResultIndex = helperSequence.count - 1;
      if (signedResultStatement(helperSequence.opcodes[parameterResultIndex])) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long parameterPreludeStatement = 0;
      while (parameterPreludeStatement < parameterResultIndex) limit MAX_MINIMAL_STATEMENTS {
        if (resultStatement(helperSequence.opcodes[parameterPreludeStatement])) {
          return new MinimalProgramResult.Error(0);
        }

        parameterPreludeStatement += 1;
      }
    }

    if (helperKind == HELPER_SIGNED_TWO) {
      if (0 < helperSequence.count) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long pairResultIndex = helperSequence.count - 1;
      if (helperSequence.count == 1) {
        boolean supportedPairReturn = returnLocalPairStatement(
          helperSequence.opcodes[pairResultIndex]
        );
        if (returnLocalBinaryStatement(helperSequence.opcodes[pairResultIndex])) {
          supportedPairReturn = true;
        }

        if (supportedPairReturn == false) {
          return new MinimalProgramResult.Error(0);
        }
      } else {
        if (resolvedSignedLocalReturn(helperSequence.opcodes[pairResultIndex])) {} else {
          return new MinimalProgramResult.Error(0);
        }
      }

      long pairPreludeStatement = 0;
      while (pairPreludeStatement < pairResultIndex) limit MAX_MINIMAL_STATEMENTS {
        if (resultStatement(helperSequence.opcodes[pairPreludeStatement])) {
          return new MinimalProgramResult.Error(0);
        }

        pairPreludeStatement += 1;
      }
    }

    if (helperKind < HELPER_SIGNED) {
      long helperStatement = 0;
      while (helperStatement < helperSequence.count) limit MAX_MINIMAL_STATEMENTS {
        if (resultStatement(helperSequence.opcodes[helperStatement])) {
          return new MinimalProgramResult.Error(0);
        }

        helperStatement += 1;
      }
    }

    if (helperKind == HELPER_REVERSIBLE) {
      if (reversibleSequenceValid(helperSequence) == false) {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (resultSlotHelper(helperKind)) {
      if (helperSequence.count == 1) {} else {
        return new MinimalProgramResult.Error(0);
      }

      if (helperSequence.opcodes[0] == STATEMENT_RETURN_LONG) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    long entryCount = 0;
    long preReverseCount = 0;
    if (0 < resultEntryCount) {
      while (entryCount < resultEntryCount) limit MAX_MINIMAL_STATEMENTS {
        set(helperStarts, entryCount, helperStarts[MAX_HELPER_RESOLUTION_STARTS + entryCount]);
        entryCount += 1;
      }
    } else {
      if (-1 < preReverseStatement) {
        set(helperStarts, entryCount, preReverseStatement);
        entryCount += 1;
        if (helperKind == HELPER_REVERSIBLE) {
          preReverseCount = 1;
        }
      }

      if (-1 < entryStatement) {
        set(helperStarts, entryCount, entryStatement);
        entryCount += 1;
      }
    }

    StatementSequence entrySequence = parseStatementSequence(
      source,
      tokenStarts,
      tokenLengths,
      helperStarts,
      entryCount
    );
    if (entrySequence.valid == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (HELPER_REVERSIBLE < helperKind) {
      if (entryCallsMatchHelper(entrySequence, helperKind) == false) {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (resultSlotHelper(helperKind)) {
      if (resultSlotEntryValid(entrySequence)) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    MinimalProgram program = new MinimalProgram(
      name,
      global,
      layout.globalCount,
      layout.initialValue,
      entrySequence.count,
      entrySequence.opcodes,
      entrySequence.operands,
      entrySequence.secondaryOperands,
      helper,
      1,
      helperSequence.opcodes,
      helperSequence.operands,
      helperSequence.secondaryOperands,
      helperKind,
      proof,
      proofCount,
      helperCallCount,
      preReverseCount,
      helperSequence.count
    );
    return new MinimalProgramResult.Value(program);
  }

}
