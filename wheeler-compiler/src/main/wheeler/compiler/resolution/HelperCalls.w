//! Recognizes bounded helper call statements in the bootstrap source profile.

module wheeler.compiler.helper_calls;

import wheeler.compiler.call_forms;
import wheeler.compiler.ir;
import wheeler.compiler.statement_forms;
import wheeler.compiler.statements;
import wheeler.compiler.tokens;

classical class HelperCalls {
  /// Reports whether one statement is a zero-argument call to the named helper.
  public boolean callValid(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken,
    long callStart
  ) {
    if (sameTokenText(source, tokenStarts, tokenLengths, nameToken, callStart)) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, callStart + 1, PUNCTUATION_OPEN_PAREN)
      ) {
        if (
          punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            callStart + 2,
            PUNCTUATION_CLOSE_PAREN
          )
        ) {
          return punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            callStart + 3,
            PUNCTUATION_SEMICOLON
          );
        }
      }
    }

    return false;
  }

  /// Reports whether one scalar result call names the sole bounded helper.
  public boolean resultCallNamesHelper(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken,
    long callStart
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, callStart);
    if (scalarResultCallStatement(opcode)) {
      return sameTokenText(source, tokenStarts, tokenLengths, nameToken, callStart + 3);
    }

    return false;
  }

  /// Checks one resolved scalar call against the helper parameter and result types.
  public boolean resolvedResultCallValid(long opcode, long helperKind) {
    if (helperKind == HELPER_SIGNED) {
      return opcode == STATEMENT_LOCAL_CALL_NAMED;
    }

    if (helperKind == HELPER_REVERSIBLE_SIGNED) {
      return opcode == STATEMENT_LOCAL_CALL_NAMED;
    }

    if (helperKind == HELPER_BOOLEAN) {
      return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED;
    }

    if (helperKind == HELPER_BOOLEAN_ONE) {
      return oneArgumentBooleanCall(opcode);
    }

    if (helperKind == HELPER_BOOLEAN_TWO) {
      return twoArgumentBooleanCall(opcode);
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_ONE) {
      return oneArgumentBooleanSignedCall(opcode);
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_TWO) {
      return twoArgumentBooleanSignedCall(opcode);
    }

    if (helperKind == HELPER_SIGNED_ONE) {
      if (opcode == STATEMENT_LOCAL_CALL_ARGUMENT_NAMED) {
        return true;
      }

      return opcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED;
    }

    if (helperKind == HELPER_SIGNED_TWO) {
      return twoArgumentSignedResultCall(opcode);
    }

    return false;
  }
}
