//! Resolves bounded unqualified void calls against prior typed locals.

module wheeler.compiler.void_call_resolution;

import wheeler.compiler.local_resolution;
import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_source_kinds;

classical class VoidCallResolution {
  /// Carries one resolved void-call identity and whether this owner applies.
  public record ResolvedVoidCall(long opcode, boolean applies) {}

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
    if (voidCallSourceStatement(sourceOpcode)) {} else {
      return new ResolvedVoidCall(-1, false);
    }

    if (sourceOpcode == STATEMENT_CALL_VOID_ZERO_NAMED) {
      return new ResolvedVoidCall(STATEMENT_CALL_VOID_ZERO, true);
    }

    long firstSource = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 2,
      true
    );
    if (-1 < firstSource) {} else {
      return new ResolvedVoidCall(-1, true);
    }

    if (sourceOpcode == STATEMENT_CALL_VOID_ONE_NAMED) {
      return new ResolvedVoidCall(STATEMENT_CALL_VOID_ONE, true);
    }

    long secondSource = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 4,
      true
    );
    if (-1 < secondSource) {} else {
      return new ResolvedVoidCall(-1, true);
    }

    if (sourceOpcode == STATEMENT_CALL_VOID_TWO_NAMED) {
      return new ResolvedVoidCall(STATEMENT_CALL_VOID_TWO, true);
    }

    long thirdSource = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 6,
      true
    );
    if (-1 < thirdSource) {
      if (thirdSource < VOID_CALL_LOCAL_SOURCE_COUNT) {
        return new ResolvedVoidCall(STATEMENT_CALL_VOID_THREE_BASE + thirdSource, true);
      }
    }

    return new ResolvedVoidCall(-1, true);
  }
}
