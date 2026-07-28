//! Recognizes bounded helper call statements in the bootstrap source profile.

module wheeler.compiler.helper_calls;

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

  /// Reports whether one statement calls the named signed-result helper form.
  public boolean resultCallValid(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken,
    long callStart,
    long helperKind
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, callStart);
    boolean expectedCall = opcode == STATEMENT_LOCAL_CALL_NAMED;
    if (helperKind == HELPER_BOOLEAN) {
      expectedCall = opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED;
    }

    if (helperKind == HELPER_BOOLEAN_ONE) {
      expectedCall = oneArgumentBooleanCall(opcode);
    }

    if (helperKind == HELPER_BOOLEAN_TWO) {
      expectedCall = twoArgumentBooleanCall(opcode);
    }

    if (helperKind == HELPER_SIGNED_ONE) {
      expectedCall = opcode == STATEMENT_LOCAL_CALL_ARGUMENT_NAMED;
      if (opcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED) {
        expectedCall = true;
      }
    }

    if (helperKind == HELPER_SIGNED_TWO) {
      expectedCall = twoArgumentCallStatement(opcode);
    }

    if (expectedCall) {
      return sameTokenText(source, tokenStarts, tokenLengths, nameToken, callStart + 3);
    }

    return false;
  }
}
