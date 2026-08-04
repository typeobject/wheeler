//! Classifies bounded typed helper-call statement forms.

module wheeler.compiler.call_forms;

import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;

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
    long firstWidth = 1;
    if (utf8Scalar(source, tokenStarts[firstToken]) == PUNCTUATION_MINUS) {
      firstWidth = 2;
    }

    return firstToken + firstWidth + 1;
  }

  /// Checks for a signed or Boolean one-argument helper call.
  public boolean oneArgumentCallStatement(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_ARGUMENT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_LOCAL_ARGUMENT_NAMED;
  }

  /// Checks whether one helper call argument names a prior local.
  public boolean oneArgumentCallNamed(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_LOCAL_ARGUMENT_NAMED;
  }

  /// Checks whether one helper call receives and returns a Boolean.
  public boolean oneArgumentBooleanCall(long opcode) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED;
  }

  /// Checks whether one Boolean-result call receives a signed value.
  public boolean oneArgumentBooleanSignedCall(long opcode) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_ARGUMENT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_LOCAL_ARGUMENT_NAMED;
  }

  /// Checks for a signed or Boolean two-argument helper call.
  public boolean twoArgumentCallStatement(long opcode) {
    if (STATEMENT_LOCAL_CALL_TWO_ARGUMENT_NAMED - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED + 1) {
        return true;
      }
    }

    if (STATEMENT_LOCAL_BOOLEAN_CALL_TWO_ARGUMENT_NAMED - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED + 1) {
        return true;
      }
    }

    if (opcode < STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_ARGUMENT_NAMED) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_LOCALS_NAMED + 1;
  }

  /// Checks whether a two-argument call returns a signed value.
  public boolean twoArgumentSignedResultCall(long opcode) {
    if (opcode < STATEMENT_LOCAL_CALL_TWO_ARGUMENT_NAMED) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED + 1;
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

    return twoArgumentCallStatement(opcode);
  }

  /// Checks whether a two-argument helper call receives and returns Booleans.
  public boolean twoArgumentBooleanCall(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_CALL_TWO_ARGUMENT_NAMED) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED + 1;
  }

  /// Checks whether one Boolean-result call receives two signed values.
  public boolean twoArgumentBooleanSignedCall(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_ARGUMENT_NAMED) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_LOCALS_NAMED + 1;
  }

  /// Checks whether the first call argument names a prior local.
  public boolean twoArgumentCallFirstNamed(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_LOCALS_NAMED;
  }

  /// Checks whether the second call argument names a prior local.
  public boolean twoArgumentCallSecondNamed(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_LOCALS_NAMED;
  }
}
