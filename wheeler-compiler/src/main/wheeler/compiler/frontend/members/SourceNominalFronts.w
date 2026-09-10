//! Locates record, variant, and enum fronts without resolving their nominal references.

module wheeler.compiler.source_nominal_fronts;

import wheeler.compiler.closure.source_aggregate_syntax;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_front_windows;
import wheeler.compiler.source_scalars;
import wheeler.compiler.source_type_syntax;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class SourceNominalFronts {
  private long fieldCount(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long open,
    long close
  ) {
    long cursor = open + 1;
    long fields = 0;
    while (cursor < close) limit MAX_COMPILER_TOKENS {
      SourceTypeFront type = sourceTypeFront(
        source,
        kinds,
        starts,
        lengths,
        close,
        cursor,
        false
      );
      if (type.valid == false) {
        return -1;
      }

      long name = type.nextToken;
      if (close - 1 < name) {
        return -1;
      }

      if (kinds[name] != 1) {
        return -1;
      }

      long token = cursor;
      while (token < name) limit MAX_COMPILER_TOKENS {
        if (punctuationAt(source, kinds, starts, token, PUNCTUATION_OPEN_SQUARE)) {
          if (token != cursor + 1) {
            return -1;
          }

          if (name < token + 3) {
            return -1;
          }

          if (type.baseType == TYPE_SIGNED) {} else {
            if (type.baseType == TYPE_BOOLEAN) {} else {
              if (type.baseType != TYPE_DONE) {
                return -1;
              }
            }
          }
        }

        token += 1;
      }

      long prior = open + 1;
      while (prior < cursor) limit MAX_COMPILER_TOKENS {
        if (punctuationAt(source, kinds, starts, prior, PUNCTUATION_COMMA)) {
          if (sameTokenText(source, starts, lengths, prior - 1, name)) {
            return -1;
          }
        }

        prior += 1;
      }

      fields += 1;
      cursor = name + 1;
      if (cursor < close) {
        if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_COMMA) == false) {
          return -1;
        }

        cursor += 1;
        if (cursor == close) {
          return -1;
        }
      }
    }

    return fields;
  }

  private long caseEnd(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long start,
    boolean enumeration
  ) {
    if (count < start + 3) {
      return -1;
    }

    if (sourceTokenCode(source, starts, lengths, start) != TOKEN_CASE) {
      return -1;
    }

    if (kinds[start + 1] != 1) {
      return -1;
    }

    long end = start + 2;
    if (enumeration == false) {
      if (punctuationAt(source, kinds, starts, end, PUNCTUATION_OPEN_PAREN) == false) {
        return -1;
      }

      long close = closingToken(
        source,
        kinds,
        starts,
        end,
        count,
        PUNCTUATION_OPEN_PAREN,
        PUNCTUATION_CLOSE_PAREN
      );
      if (close < 0) {
        return -1;
      }

      if (fieldCount(source, kinds, starts, lengths, end, close) < 0) {
        return -1;
      }

      end = close + 1;
    }

    if (count < end + 1) {
      return -1;
    }

    if (punctuationAt(source, kinds, starts, end, PUNCTUATION_SEMICOLON) == false) {
      return -1;
    }

    return end + 1;
  }

  /// Consumes one nominal front at a scanner-owned, visibility-free member start.
  /// Field types and cross-declaration name uniqueness still require the binding products.
  public long sourceNominalMemberEnd(
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

    if (count < start + 4) {
      return -1;
    }

    if (kinds[start + 1] != 1) {
      return -1;
    }

    long code = sourceTokenCode(source, starts, lengths, start);
    long nameCode = sourceTokenCode(source, starts, lengths, start + 1);
    if (code != TOKEN_ENUM) {
      if (nameCode == TOKEN_SLOT) {
        return -1;
      }

      if (-1 < primitiveType(nameCode)) {
        return -1;
      }
    }

    if (code == TOKEN_RECORD) {
      long first = utf8Scalar(source, starts[start + 1]);
      if (first < 65) {
        return -1;
      }

      if (90 < first) {
        return -1;
      }

      if (
        punctuationAt(source, kinds, starts, start + 2, PUNCTUATION_OPEN_PAREN) == false
      ) {
        return -1;
      }

      long closeFields = closingToken(
        source,
        kinds,
        starts,
        start + 2,
        count,
        PUNCTUATION_OPEN_PAREN,
        PUNCTUATION_CLOSE_PAREN
      );
      if (closeFields < 0) {
        return -1;
      }

      if (fieldCount(source, kinds, starts, lengths, start + 2, closeFields) < 1) {
        return -1;
      }

      if (count < closeFields + 3) {
        return -1;
      }

      if (
        punctuationAt(source, kinds, starts, closeFields + 1, PUNCTUATION_OPEN_BRACE) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(source, kinds, starts, closeFields + 2, PUNCTUATION_CLOSE_BRACE) == false
      ) {
        return -1;
      }

      return closeFields + 3;
    }

    boolean enumeration = code == TOKEN_ENUM;
    if (enumeration == false) {
      if (code != TOKEN_VARIANT) {
        return -1;
      }
    }

    if (
      punctuationAt(source, kinds, starts, start + 2, PUNCTUATION_OPEN_BRACE) == false
    ) {
      return -1;
    }

    long cursor = start + 3;
    long cases = 0;
    while (cursor < count) limit MAX_COMPILER_TOKENS {
      if (punctuationAt(source, kinds, starts, cursor, PUNCTUATION_CLOSE_BRACE)) {
        if (cases == 0) {
          return -1;
        }

        return cursor + 1;
      }

      long next = caseEnd(source, kinds, starts, lengths, count, cursor, enumeration);
      if (next < 0) {
        return -1;
      }

      long prior = start + 3;
      while (prior < cursor) limit MAX_COMPILER_TOKENS {
        if (sameTokenText(source, starts, lengths, prior + 1, cursor + 1)) {
          return -1;
        }

        prior = caseEnd(source, kinds, starts, lengths, count, prior, enumeration);
        if (prior < 0) {
          return -1;
        }
      }

      cases += 1;
      cursor = next;
    }

    return -1;
  }
}
