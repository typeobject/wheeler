//! Locates scalar and proof member fronts before initializer or theorem evaluation.

module wheeler.compiler.source_scalar_member_fronts;

import wheeler.compiler.closure.source_aggregate_syntax;
import wheeler.compiler.constant_declarations;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_front_windows;
import wheeler.compiler.source_member_names;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class SourceScalarMemberFronts {
  private long quantumRegisterEnd(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long start
  ) {
    if (count < start + 9) {
      return -1;
    }

    if (sourceValueNameValid(source, kinds, starts, lengths, start + 1) == false) {
      return -1;
    }

    if (punctuationAt(source, kinds, starts, start + 2, PUNCTUATION_ASSIGN) == false) {
      return -1;
    }

    if (sourceTokenCode(source, starts, lengths, start + 3) != TOKEN_NEW) {
      return -1;
    }

    if (sourceTokenCode(source, starts, lengths, start + 4) != TOKEN_QREG) {
      return -1;
    }

    if (
      punctuationAt(source, kinds, starts, start + 5, PUNCTUATION_OPEN_PAREN) == false
    ) {
      return -1;
    }

    long close = closingToken(
      source,
      kinds,
      starts,
      start + 5,
      count,
      PUNCTUATION_OPEN_PAREN,
      PUNCTUATION_CLOSE_PAREN
    );
    if (close < start + 7) {
      return -1;
    }

    long end = scalarInitializerEnd(source, starts, lengths, start + 3, count);
    if (end != close + 2) {
      return -1;
    }

    return end;
  }

  private long theoremEnd(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long start
  ) {
    if (count < start + 8) {
      return -1;
    }

    if (kinds[start + 1] != 1) {
      return -1;
    }

    if (sourceTokenCode(source, starts, lengths, start + 2) != TOKEN_PROVES) {
      return -1;
    }

    long rule = sourceTokenCode(source, starts, lengths, start + 3);
    if (
      punctuationAt(source, kinds, starts, start + 4, PUNCTUATION_OPEN_PAREN) == false
    ) {
      return -1;
    }

    if (kinds[start + 5] != 1) {
      return -1;
    }

    long close = closingToken(
      source,
      kinds,
      starts,
      start + 4,
      count,
      PUNCTUATION_OPEN_PAREN,
      PUNCTUATION_CLOSE_PAREN
    );
    if (close < 0) {
      return -1;
    }

    if (count < close + 2) {
      return -1;
    }

    if (
      punctuationAt(source, kinds, starts, close + 1, PUNCTUATION_SEMICOLON) == false
    ) {
      return -1;
    }

    if (rule == TOKEN_INVERSE) {
      if (close != start + 6) {
        return -1;
      }

      return close + 2;
    }

    if (rule == TOKEN_ADJOINT) {
      if (close != start + 6) {
        return -1;
      }

      return close + 2;
    }

    if (close < start + 8) {
      return -1;
    }

    if (punctuationAt(source, kinds, starts, start + 6, PUNCTUATION_COMMA) == false) {
      return -1;
    }

    if (rule == TOKEN_EQUIVALENT) {
      if (close != start + 8) {
        return -1;
      }

      if (kinds[start + 7] != 1) {
        return -1;
      }

      return close + 2;
    }

    if (rule == TOKEN_STEPS) {
      return close + 2;
    }

    return -1;
  }

  /// Consumes a scalar or proof front at a scanner-owned, visibility-free member start.
  /// Constant values, register sizes, proof subjects, and proof bounds still require resolution.
  public long sourceScalarMemberEnd(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long start
  ) {
    if (sourceFrontWindowValid(kinds, starts, lengths, count, start) == false) {
      return -1;
    }

    long code = sourceTokenCode(source, starts, lengths, start);
    if (code == TOKEN_QREG) {
      return quantumRegisterEnd(source, kinds, starts, lengths, count, start);
    }

    if (code == TOKEN_THEOREM) {
      return theoremEnd(source, kinds, starts, lengths, count, start);
    }

    if (count < start + 6) {
      return -1;
    }

    if (sourceValueNameValid(source, kinds, starts, lengths, start + 2) == false) {
      return -1;
    }

    if (code == TOKEN_CONST) {
      return constantDeclarationEnd(source, starts, lengths, start, count);
    }

    if (code != TOKEN_STATE) {
      return -1;
    }

    if (sourceTokenCode(source, starts, lengths, start + 1) != TOKEN_LONG) {
      return -1;
    }

    if (punctuationAt(source, kinds, starts, start + 3, PUNCTUATION_ASSIGN) == false) {
      return -1;
    }

    return scalarInitializerEnd(source, starts, lengths, start + 4, count);
  }
}
