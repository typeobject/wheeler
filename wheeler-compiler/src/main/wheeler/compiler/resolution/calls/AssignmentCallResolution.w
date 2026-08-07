//! Resolves bounded helper calls assigned into existing signed locals.

module wheeler.compiler.assignment_call_resolution;

import wheeler.compiler.assignment_call_identities;
import wheeler.compiler.assignment_call_kinds;
import wheeler.compiler.assignment_call_syntax;
import wheeler.compiler.local_resolution;

classical class AssignmentCallResolution {
  private const long FIRST_PACKED_SOURCE_COUNT = 4;

  private long resolveSource(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long argument
  ) {
    return resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      assignmentCallArgumentToken(statementStart, argument),
      true
    );
  }

  /// Resolves one call-assignment target and validates every source.
  public long resolveAssignmentCallOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long opcode
  ) {
    if (assignmentCallSourceStatement(opcode)) {} else {
      return opcode;
    }

    long target = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart,
      true
    );
    if (target < 0) {
      return -1;
    }

    long arity = assignmentCallArity(opcode);
    long argument = 0;
    while (argument < arity) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
      if (
        -1 < resolveSource(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          statementStart,
          argument
        )
      ) {} else {
        return -1;
      }

      argument += 1;
    }

    return resolvedAssignmentCall(arity, target);
  }

  private long packSources(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long first,
    long limit
  ) {
    long packed = 0;
    long scale = 1;
    long argument = first;
    while (argument < limit) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
      long selected = resolveSource(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart,
        argument
      );
      if (selected < 0) {
        return -1;
      }

      packed += selected * scale;
      scale = scale * ASSIGNMENT_CALL_SOURCE_RADIX;
      argument += 1;
    }

    return packed;
  }

  /// Packs the first four prior-local call sources.
  public long resolveAssignmentCallFirstSources(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long opcode
  ) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    long limit = arity;
    if (FIRST_PACKED_SOURCE_COUNT < limit) {
      limit = FIRST_PACKED_SOURCE_COUNT;
    }

    return packSources(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart,
      0,
      limit
    );
  }

  /// Packs the remaining prior-local call sources.
  public long resolveAssignmentCallLastSources(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long opcode
  ) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    if (arity < FIRST_PACKED_SOURCE_COUNT + 1) {
      return 0;
    }

    return packSources(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart,
      FIRST_PACKED_SOURCE_COUNT,
      arity
    );
  }
}
