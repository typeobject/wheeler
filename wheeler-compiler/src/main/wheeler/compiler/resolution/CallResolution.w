//! Resolves scalar helper-call arguments through locals and class constants.

module wheeler.compiler.call_resolution;

import wheeler.compiler.call_argument_sources;
import wheeler.compiler.call_forms;
import wheeler.compiler.four_argument_calls;
import wheeler.compiler.local_resolution;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.scalar_references;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.three_argument_calls;
import wheeler.compiler.two_argument_call_kinds;

classical class CallResolution {
  /// Classifies one named argument as a prior local or substituted literal.
  public record CallArgument(boolean local, boolean valid) {}

  private CallArgument resolveCallArgument(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long argumentToken,
    boolean expectedSigned
  ) {
    ScalarReference reference = resolveScalarReference(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      argumentToken,
      expectedSigned
    );
    return new CallArgument(reference.local, reference.valid);
  }

  private long oneArgumentOpcode(boolean booleanResult, boolean signedArgument, boolean local) {
    if (booleanResult) {
      if (signedArgument) {
        if (local) {
          return STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_LOCAL_ARGUMENT_NAMED;
        }

        return STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_ARGUMENT_NAMED;
      }

      if (local) {
        return STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED;
      }

      return STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED;
    }

    if (local) {
      return STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED;
    }

    return STATEMENT_LOCAL_CALL_ARGUMENT_NAMED;
  }

  private long resolveOneArgumentCall(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long opcode
  ) {
    if (oneArgumentCallNamed(opcode) == false) {
      return opcode;
    }

    boolean booleanResult = opcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED;
    long argumentToken = statementStart + 5;
    if (booleanResult == false) {
      CallArgument signedArgument = resolveCallArgument(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        argumentToken,
        true
      );
      if (signedArgument.valid) {
        return oneArgumentOpcode(false, true, signedArgument.local);
      }

      return -1;
    }

    CallArgument signedBooleanArgument = resolveCallArgument(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      argumentToken,
      true
    );
    CallArgument booleanArgument = resolveCallArgument(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      argumentToken,
      false
    );
    if (signedBooleanArgument.valid == booleanArgument.valid) {
      return -1;
    }

    if (signedBooleanArgument.valid) {
      return oneArgumentOpcode(true, true, signedBooleanArgument.local);
    }

    return oneArgumentOpcode(true, false, booleanArgument.local);
  }

  private long twoArgumentOpcodeBase(long opcode, boolean signedArguments) {
    if (opcode < STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED + 1) {
      return STATEMENT_LOCAL_CALL_TWO_ARGUMENT_NAMED;
    }

    if (signedArguments) {
      return STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_ARGUMENT_NAMED;
    }

    return STATEMENT_LOCAL_BOOLEAN_CALL_TWO_ARGUMENT_NAMED;
  }

  private long resolvedTwoArgumentOpcode(long base, CallArgument first, CallArgument second) {
    long localForm = 0;
    if (first.local) {
      localForm += 1;
    }

    if (second.local) {
      localForm += 2;
    }

    return base + localForm;
  }

  private boolean twoArgumentsValid(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long opcode,
    boolean expectedSigned
  ) {
    if (twoArgumentCallFirstNamed(opcode)) {
      CallArgument first = resolveCallArgument(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        twoArgumentFirstToken(statementStart),
        expectedSigned
      );
      if (first.valid == false) {
        return false;
      }
    }

    if (twoArgumentCallSecondNamed(opcode)) {
      CallArgument second = resolveCallArgument(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        twoArgumentSecondToken(source, tokenStarts, statementStart),
        expectedSigned
      );
      if (second.valid == false) {
        return false;
      }
    }

    return true;
  }

  private long resolveTwoArgumentCall(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long opcode
  ) {
    boolean firstNamed = twoArgumentCallFirstNamed(opcode);
    boolean secondNamed = twoArgumentCallSecondNamed(opcode);
    if (firstNamed == false) {
      if (secondNamed == false) {
        return opcode;
      }
    }

    boolean signedArguments = twoArgumentBooleanCall(opcode) == false;
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED) {
      boolean signedValid = twoArgumentsValid(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount,
        opcode,
        true
      );
      boolean booleanValid = twoArgumentsValid(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount,
        opcode,
        false
      );
      if (signedValid == booleanValid) {
        return -1;
      }

      signedArguments = signedValid;
    } else {
      if (
        twoArgumentsValid(
          source,
          tokenStarts,
          tokenLengths,
          statementStart,
          previousStarts,
          previousCount,
          opcode,
          signedArguments
        ) == false
      ) {
        return -1;
      }
    }

    CallArgument first = new CallArgument(false, true);
    if (firstNamed) {
      first = resolveCallArgument(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        twoArgumentFirstToken(statementStart),
        signedArguments
      );
    }

    CallArgument second = new CallArgument(false, true);
    if (secondNamed) {
      second = resolveCallArgument(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        twoArgumentSecondToken(source, tokenStarts, statementStart),
        signedArguments
      );
    }

    return resolvedTwoArgumentOpcode(
      twoArgumentOpcodeBase(opcode, signedArguments),
      first,
      second
    );
  }

  private long resolveThreeArgumentCall(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long opcode
  ) {
    if (opcode == STATEMENT_LOCAL_CALL_THREE_LOCALS_NAMED) {} else {
      return opcode;
    }

    long first = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      threeArgumentFirstToken(statementStart),
      true
    );
    long second = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      threeArgumentSecondToken(statementStart),
      true
    );
    long third = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      threeArgumentThirdToken(statementStart),
      true
    );
    if (-1 < first) {
      if (-1 < second) {
        if (-1 < third) {
          return STATEMENT_LOCAL_CALL_THREE_LOCALS_BASE + third;
        }
      }
    }

    return -1;
  }

  private long resolveFourArgumentCall(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long opcode
  ) {
    if (opcode == STATEMENT_LOCAL_CALL_FOUR_LOCALS_NAMED) {} else {
      return opcode;
    }

    long first = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      threeArgumentFirstToken(statementStart),
      true
    );
    long second = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      threeArgumentSecondToken(statementStart),
      true
    );
    long third = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      threeArgumentThirdToken(statementStart),
      true
    );
    long fourth = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      fourArgumentCallFourthToken(statementStart),
      true
    );
    if (-1 < first) {
      if (-1 < second) {
        if (-1 < third) {
          if (-1 < fourth) {
            return STATEMENT_LOCAL_CALL_FOUR_LOCALS_BASE + third * LOCAL_VALUE_CALL_SOURCE_COUNT
              + fourth;
          }
        }
      }
    }

    return -1;
  }

  /// Resolves every named argument in one scalar helper call.
  public long resolveCallOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long opcode
  ) {
    if (oneArgumentCallStatement(opcode)) {
      return resolveOneArgumentCall(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount,
        opcode
      );
    }

    if (fourArgumentCallStatement(opcode)) {
      return resolveFourArgumentCall(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount,
        opcode
      );
    }

    if (threeArgumentCallStatement(opcode)) {
      return resolveThreeArgumentCall(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount,
        opcode
      );
    }

    if (twoArgumentCallStatement(opcode)) {
      return resolveTwoArgumentCall(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount,
        opcode
      );
    }

    return opcode;
  }
}
