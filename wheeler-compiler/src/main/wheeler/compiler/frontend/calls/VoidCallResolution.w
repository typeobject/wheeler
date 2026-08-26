//! Resolves bounded unqualified void calls against prior typed locals.

module wheeler.compiler.void_call_resolution;

import wheeler.compiler.local_resolution;
import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_source_forms;
import wheeler.compiler.void_call_source_kinds;

classical class VoidCallResolution {
  private const long FIRST_PACKED_VOID_SOURCES = 4;

  /// Carries one resolved void-call identity and whether this owner applies.
  public record ResolvedVoidCall(long opcode, boolean applies) {}

  private long resolveVoidCallSource(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long argument
  ) {
    return resolvePriorScalarDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 2 + argument * 2
    );
  }

  private long fixedVoidCallOpcode(long arity) {
    if (arity == 0) {
      return STATEMENT_CALL_VOID_ZERO;
    }

    if (arity == 1) {
      return STATEMENT_CALL_VOID_ONE;
    }

    if (arity == 2) {
      return STATEMENT_CALL_VOID_TWO;
    }

    if (arity == 4) {
      return STATEMENT_CALL_VOID_FOUR;
    }

    if (arity == 5) {
      return STATEMENT_CALL_VOID_FIVE;
    }

    if (arity == 6) {
      return STATEMENT_CALL_VOID_SIX;
    }

    if (arity == MAX_VOID_CALL_ARGUMENTS) {
      return STATEMENT_CALL_VOID_SEVEN;
    }

    return -1;
  }

  /// Resolves one source void call without consuming unrelated statements.
  public ResolvedVoidCall resolveVoidCall(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long sourceOpcode
  ) {
    long arity = voidCallSourceArity(sourceOpcode);
    if (arity < 0) {
      return new ResolvedVoidCall(-1, false);
    }

    long argument = 0;
    long thirdSource = -1;
    while (argument < arity) limit MAX_VOID_CALL_ARGUMENTS {
      long selected = resolveVoidCallSource(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart,
        argument
      );
      if (-1 < selected) {} else {
        return new ResolvedVoidCall(-1, true);
      }

      if (argument == 2) {
        thirdSource = selected;
      }

      argument += 1;
    }

    if (arity == 3) {
      if (thirdSource < VOID_CALL_LOCAL_SOURCE_COUNT) {
        return new ResolvedVoidCall(STATEMENT_CALL_VOID_THREE_BASE + thirdSource, true);
      }

      return new ResolvedVoidCall(-1, true);
    }

    return new ResolvedVoidCall(fixedVoidCallOpcode(arity), true);
  }

  private long packVoidCallSources(
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
    while (argument < limit) limit MAX_VOID_CALL_ARGUMENTS {
      long selected = resolveVoidCallSource(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart,
        argument
      );
      if (-1 < selected) {} else {
        return -1;
      }

      packed += selected * scale;
      scale = scale * VOID_CALL_LOCAL_SOURCE_COUNT;
      argument += 1;
    }

    return packed;
  }

  /// Packs the first four sources of one wide void call.
  public long resolveVoidCallFirstSources(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long opcode
  ) {
    long arity = voidCallArity(opcode);
    if (3 < arity) {} else {
      return -1;
    }

    return packVoidCallSources(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart,
      0,
      FIRST_PACKED_VOID_SOURCES
    );
  }

  /// Packs the trailing sources of one wide void call.
  public long resolveVoidCallLastSources(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long opcode
  ) {
    long arity = voidCallArity(opcode);
    if (3 < arity) {} else {
      return -1;
    }

    return packVoidCallSources(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart,
      FIRST_PACKED_VOID_SOURCES,
      arity
    );
  }
}
