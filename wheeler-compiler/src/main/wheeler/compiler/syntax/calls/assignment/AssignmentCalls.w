//! Defines bounded prior-local calls assigned into an existing signed local.

module wheeler.compiler.assignment_calls;

import wheeler.compiler.identifier_starts;
import wheeler.compiler.source_scalars;

classical class AssignmentCalls {
  /// Bounds call-assignment arguments by the scalar forwarding profile.
  public const long MAX_ASSIGNMENT_CALL_ARGUMENTS = 7;
  /// Names one packed prior-local source digit.
  public const long ASSIGNMENT_CALL_SOURCE_RADIX = 256;
  private const long ASSIGNMENT_CALL_TRAILING_SOURCE = 4;
  private const long ASSIGNMENT_CALL_ARGUMENT_CODE_LENGTH = 48;
  private const long ASSIGNMENT_CALL_RESULT_CODE_LENGTH = 64;
  private const long RESOLVED_TARGET_COUNT = 256;
  /// Existing signed local assigned from a zero-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_ZERO_NAMED = 926;
  /// Existing signed local assigned from a one-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_ONE_NAMED = 927;
  /// Existing signed local assigned from a two-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_TWO_NAMED = 928;
  /// Existing signed local assigned from a three-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_THREE_NAMED = 929;
  /// Existing signed local assigned from a four-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_FOUR_NAMED = 930;
  /// Existing signed local assigned from a five-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_FIVE_NAMED = 931;
  /// Existing signed local assigned from a six-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_SIX_NAMED = 932;
  /// Existing signed local assigned from a seven-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_SEVEN_NAMED = 933;
  /// Resolved zero-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_ZERO_BASE = 40000;
  /// Resolved one-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_ONE_BASE = 40256;
  /// Resolved two-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_TWO_BASE = 40512;
  /// Resolved three-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_THREE_BASE = 40768;
  /// Resolved four-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_FOUR_BASE = 41024;
  /// Resolved five-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_FIVE_BASE = 41280;
  /// Resolved six-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_SIX_BASE = 41536;
  /// Resolved seven-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_SEVEN_BASE = 41792;
  private const long ASSIGNMENT_CALL_END = 42048;

  private long sourceKind(long arity) {
    if (arity == 0) {
      return STATEMENT_ASSIGN_CALL_ZERO_NAMED;
    }

    if (arity == 1) {
      return STATEMENT_ASSIGN_CALL_ONE_NAMED;
    }

    if (arity == 2) {
      return STATEMENT_ASSIGN_CALL_TWO_NAMED;
    }

    if (arity == 3) {
      return STATEMENT_ASSIGN_CALL_THREE_NAMED;
    }

    if (arity == 4) {
      return STATEMENT_ASSIGN_CALL_FOUR_NAMED;
    }

    if (arity == 5) {
      return STATEMENT_ASSIGN_CALL_FIVE_NAMED;
    }

    if (arity == 6) {
      return STATEMENT_ASSIGN_CALL_SIX_NAMED;
    }

    if (arity == MAX_ASSIGNMENT_CALL_ARGUMENTS) {
      return STATEMENT_ASSIGN_CALL_SEVEN_NAMED;
    }

    return -1;
  }

  private long resolvedBase(long arity) {
    if (arity == 0) {
      return STATEMENT_ASSIGN_CALL_ZERO_BASE;
    }

    if (arity == 1) {
      return STATEMENT_ASSIGN_CALL_ONE_BASE;
    }

    if (arity == 2) {
      return STATEMENT_ASSIGN_CALL_TWO_BASE;
    }

    if (arity == 3) {
      return STATEMENT_ASSIGN_CALL_THREE_BASE;
    }

    if (arity == 4) {
      return STATEMENT_ASSIGN_CALL_FOUR_BASE;
    }

    if (arity == 5) {
      return STATEMENT_ASSIGN_CALL_FIVE_BASE;
    }

    if (arity == 6) {
      return STATEMENT_ASSIGN_CALL_SIX_BASE;
    }

    if (arity == MAX_ASSIGNMENT_CALL_ARGUMENTS) {
      return STATEMENT_ASSIGN_CALL_SEVEN_BASE;
    }

    return -1;
  }

  /// Classifies one assignment whose right side starts with a helper call.
  public long namedAssignmentCallKind(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    if (utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_OPEN_PAREN) {} else {
      return -1;
    }

    long arity = 0;
    long cursor = statementStart + 4;
    if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_CLOSE_PAREN) {
      return sourceKind(arity);
    }

    while (arity < MAX_ASSIGNMENT_CALL_ARGUMENTS) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
      if (identifierStart(utf8Scalar(source, tokenStarts[cursor]))) {} else {
        return sourceKind(arity);
      }

      arity += 1;
      cursor += 1;
      if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_COMMA) {
        cursor += 1;
      } else {
        return sourceKind(arity);
      }
    }

    return sourceKind(arity);
  }

  /// Checks whether one identity is an unresolved call assignment.
  public boolean assignmentCallSourceStatement(long opcode) {
    if (opcode < STATEMENT_ASSIGN_CALL_ZERO_NAMED) {
      return false;
    }

    return opcode < STATEMENT_ASSIGN_CALL_SEVEN_NAMED + 1;
  }

  /// Checks whether one identity is a resolved call assignment.
  public boolean assignmentCallStatement(long opcode) {
    if (opcode < STATEMENT_ASSIGN_CALL_ZERO_BASE) {
      return false;
    }

    return opcode < ASSIGNMENT_CALL_END;
  }

  /// Returns the exact call-assignment argument count, or minus one.
  public long assignmentCallArity(long opcode) {
    long arity = 0;
    while (arity < MAX_ASSIGNMENT_CALL_ARGUMENTS + 1) limit 8 {
      if (opcode == sourceKind(arity)) {
        return arity;
      }

      long base = resolvedBase(arity);
      if (base - 1 < opcode) {
        if (opcode < base + RESOLVED_TARGET_COUNT) {
          return arity;
        }
      }

      arity += 1;
    }

    return -1;
  }

  /// Returns one resolved call-assignment identity.
  public long resolvedAssignmentCall(long arity, long target) {
    if (target < 0) {
      return -1;
    }

    if (target < RESOLVED_TARGET_COUNT) {
      long base = resolvedBase(arity);
      return base + target;
    }

    return -1;
  }

  /// Returns the existing signed-local target of one resolved call assignment.
  public long assignmentCallTarget(long opcode) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    long base = resolvedBase(arity);
    return opcode - base;
  }

  /// Returns one argument token in a call assignment.
  public long assignmentCallArgumentToken(long statementStart, long argument) {
    return statementStart + 4 + argument * 2;
  }

  /// Validates and measures one exact call-assignment source statement.
  public long assignmentCallWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long opcode
  ) {
    if (tokenKinds[statementStart] == 1) {} else {
      return -1;
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 1]) == PUNCTUATION_ASSIGN) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 2] == 1) {} else {
      return -1;
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_OPEN_PAREN) {} else {
      return -1;
    }

    long arity = assignmentCallArity(opcode);
    long argument = 0;
    long cursor = statementStart + 4;
    while (argument < arity) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
      if (tokenKinds[cursor] == 1) {} else {
        return -1;
      }

      cursor += 1;
      argument += 1;
      if (argument < arity) {
        if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_COMMA) {} else {
          return -1;
        }

        cursor += 1;
      }
    }

    if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_CLOSE_PAREN) {} else {
      return -1;
    }

    if (utf8Scalar(source, tokenStarts[cursor + 1]) == PUNCTUATION_SEMICOLON) {
      return cursor - statementStart + 2;
    }

    return -1;
  }

  private long packedSource(long packed, long source, long first) {
    long selected = first;
    while (selected < source) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
      packed = packed / ASSIGNMENT_CALL_SOURCE_RADIX;
      selected += 1;
    }

    return packed % ASSIGNMENT_CALL_SOURCE_RADIX;
  }

  /// Decodes one source from the two bounded packed operands.
  public long assignmentCallSource(
    long opcode,
    long operand,
    long secondaryOperand,
    long source
  ) {
    long arity = assignmentCallArity(opcode);
    if (source < 0) {
      return -1;
    }

    if (source < arity) {} else {
      return -1;
    }

    long firstSource = 0;
    if (source < ASSIGNMENT_CALL_TRAILING_SOURCE) {
      return packedSource(operand, source, firstSource);
    }

    long trailingSource = ASSIGNMENT_CALL_TRAILING_SOURCE;
    return packedSource(secondaryOperand, source, trailingSource);
  }

  /// Returns the temporary local width for one call assignment.
  public long assignmentCallLocalCount(long opcode) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    return arity * 2 + 1;
  }

  /// Returns the instruction count for one call assignment.
  public long assignmentCallInstructionCount(long opcode) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    return arity * 2 + 2;
  }

  /// Returns the encoded instruction width for one call assignment.
  public long assignmentCallCodeLength(long opcode) {
    long instructions = assignmentCallInstructionCount(opcode);
    if (instructions < 0) {
      return -1;
    }

    long arity = assignmentCallArity(opcode);
    return arity * ASSIGNMENT_CALL_ARGUMENT_CODE_LENGTH + ASSIGNMENT_CALL_RESULT_CODE_LENGTH;
  }
}
