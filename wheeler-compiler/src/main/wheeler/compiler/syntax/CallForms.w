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
import wheeler.compiler.wide_local_calls;

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

    return packedWideLocalCall(opcode);
  }

  /// Checks whether one statement initializes a Boolean local from a helper.
  public boolean booleanResultCallStatement(long opcode) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      return true;
    }

    if (oneArgumentBooleanCall(opcode)) {
      return true;
    }

    if (oneArgumentBooleanSignedCall(opcode)) {
      return true;
    }

    if (twoArgumentBooleanCall(opcode)) {
      return true;
    }

    if (twoArgumentBooleanSignedCall(opcode)) {
      return true;
    }

    return booleanWideLocalCall(opcode);
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
