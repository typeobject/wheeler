//! Classifies bounded typed helper-call statement forms.

module wheeler.compiler.call_forms;

import wheeler.compiler.four_argument_calls;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.three_argument_calls;
import wheeler.compiler.tokens;
import wheeler.compiler.two_argument_call_kinds;

classical class CallForms {
  /// Returns the first argument token in a two-argument scalar call.
  public long twoArgumentFirstToken(long statementStart) {
    return statementStart + 5;
  }

  /// Returns the second argument token in a two-argument scalar call.
  public long twoArgumentSecondToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    long firstToken = twoArgumentFirstToken(statementStart);
    long firstStart = tokenStarts[firstToken];
    long firstScalar = utf8Scalar(source, firstStart);
    long narrowToken = firstToken + 2;
    long wideToken = firstToken + 3;
    if (firstScalar == PUNCTUATION_MINUS) {
      return wideToken;
    }

    return narrowToken;
  }

  /// Checks for a bounded three- through seven-local call identity.
  public boolean wideLocalCallStatement(long opcode) {
    if (threeArgumentCallStatement(opcode)) {
      return true;
    }

    if (fourArgumentCallStatement(opcode)) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_FIVE_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SIX_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SEVEN_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_FIVE_LOCALS) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SIX_LOCALS) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_CALL_SEVEN_LOCALS;
  }

  /// Checks whether one statement initializes a local from a scalar helper.
  public boolean scalarResultCallStatement(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      return true;
    }

    if (oneArgumentCallStatement(opcode)) {
      return true;
    }

    if (twoArgumentCallStatement(opcode)) {
      return true;
    }

    return wideLocalCallStatement(opcode);
  }

}
