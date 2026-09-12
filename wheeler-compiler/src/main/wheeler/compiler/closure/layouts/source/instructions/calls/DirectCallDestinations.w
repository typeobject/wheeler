//! Binds root call destinations after counted signature and argument layout validation.

module wheeler.compiler.closure.direct_call_destinations;

import wheeler.compiler.closure.direct_scalar_locations;
import wheeler.compiler.closure.direct_statement_publication;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.source_call_argument_products;
import wheeler.compiler.closure.source_call_layout_products;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.opcodes;
import wheeler.compiler.tokens;

classical class DirectCallDestinations {
  /// Carries a checked call kind and its destination-specific operand.
  public record DirectCallDestination(long kind, long operand, boolean valid) {}

  /// Checks the complete call envelope and binds stores to actual global locations.
  public DirectCallDestination resolveDirectCallDestination(
    borrow utf8 source,
    borrow byteview globalNames,
    long globalCount,
    long globalProductStart,
    borrow mut words globals,
    long token,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementLength,
    long callStart,
    long arity,
    long kind,
    long reversibleCallableCount,
    long owner,
    long ordinal,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts,
    long valueCount,
    borrow mut words valueRows
  ) {
    assert(-1 < owner);
    assert(owner < DIRECT_FUNCTIONS);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(-1 < ordinal);
    assert(ordinal < statementCount);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(bufferLength(statementLocalRows) == MAX_STATEMENTS * 2);
    assert(bufferLength(statementPhysicalStarts) == MAX_STATEMENTS);
    assert(-1 < valueCount);
    assert(valueCount < LOOP_VALUE_COUNT_LIMIT + 1);
    assert(bufferLength(valueRows) == LOOP_VALUE_ROWS);

    long head = sourceCallHeadTokens(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      tokenCount,
      token
    );
    if (head < 0) {
      return new DirectCallDestination(0, 0, false);
    }

    long name = tokenAtStart(callStart, tokenCount, tokenStarts);
    if (name < 0) {
      return new DirectCallDestination(0, 0, false);
    }

    if (
      sourceCallStatementValid(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        tokenCount,
        token,
        statementLength,
        callStart,
        tokenLengths[name],
        arity,
        head
      ) == false
    ) {
      return new DirectCallDestination(0, 0, false);
    }

    if (head == 0) {
      return new DirectCallDestination(kind, 0, kind == CALL_VOID);
    }

    if (head == 1) {
      return new DirectCallDestination(kind, 0, sourceCallForwardsResult(kind));
    }

    if (head == 3) {
      long expected = CALL_VALUE_SIGNED;
      if (sourceTokenCode(source, tokenStarts, tokenLengths, token) == TOKEN_BOOLEAN) {
        expected = CALL_VALUE_BOOLEAN;
      }

      return new DirectCallDestination(kind, 0, kind == expected);
    }

    if (head != 2) {
      return new DirectCallDestination(0, 0, false);
    }

    if (kind != CALL_FORWARD_SIGNED) {
      return new DirectCallDestination(0, 0, false);
    }

    if (reversibleCallableCount != 0) {
      return new DirectCallDestination(0, 0, false);
    }

    DirectScalarLocation destination = resolveDirectScalarLocation(
      source,
      tokenStarts[token],
      tokenLengths[token],
      globalNames,
      globalCount,
      globalProductStart,
      globals,
      owner,
      ordinal,
      statementCount,
      statementRows,
      statementLocalRows,
      statementPhysicalStarts,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (destination.valid == false) {
      return new DirectCallDestination(0, 0, false);
    }

    if (destination.loadOpcode != OPCODE_LOCAL_LOAD_GLOBAL) {
      return new DirectCallDestination(0, 0, false);
    }

    return new DirectCallDestination(CALL_STORE_GLOBAL_SIGNED, destination.operand, true);
  }
}
