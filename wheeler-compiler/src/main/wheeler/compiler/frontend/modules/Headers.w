//! Parses bounded module and direct-import headers for native compilation.

module wheeler.compiler.module_headers;

import wheeler.compiler.tokens;

classical class ModuleHeaders {
  private long qualifiedNameEnd(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long start,
    long count
  ) {
    long cursor = start;
    long nameEnd = 0;
    boolean expectName = true;
    while (cursor < count) limit MAX_QUALIFIED_NAME_TOKENS {
      if (expectName) {
        if (tokenKinds[cursor] == 1) {
          if (start < cursor) {
            if (tokenStarts[cursor] == nameEnd + 1) {} else {
              return -1;
            }
          }

          nameEnd = tokenStarts[cursor] + tokenLengths[cursor];
          expectName = false;
        } else {
          return -1;
        }
      } else {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_SEMICOLON)
        ) {
          return cursor;
        }

        if (punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_DOT)) {
          if (tokenStarts[cursor] == nameEnd) {} else {
            return -1;
          }

          expectName = true;
        } else {
          return -1;
        }
      }

      cursor += 1;
    }

    return -1;
  }

  private long compareSourceRanges(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long left = 0;
    long right = 0;
    while (left < leftLength) limit MAX_QUALIFIED_NAME_BYTES {
      if (rightLength < right + 1) {
        return 1;
      }

      long leftScalar = utf8Scalar(source, leftStart + left);
      long rightScalar = utf8Scalar(source, rightStart + right);
      if (leftScalar < rightScalar) {
        return -1;
      }

      if (rightScalar < leftScalar) {
        return 1;
      }

      left += utf8Width(source, leftStart + left);
      right += utf8Width(source, rightStart + right);
    }

    if (right < rightLength) {
      return -1;
    }

    return 0;
  }

  /// Returns the first class token after a valid bounded source header.
  public long moduleBodyStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words moduleRange,
    long count
  ) {
    set(moduleRange, 0, 0);
    set(moduleRange, 1, 0);
    if (count == 0) {
      return -1;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, 0) == TOKEN_CLASSICAL) {
      return 0;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, 0) == TOKEN_MODULE) {} else {
      return -1;
    }

    long nameEnd = qualifiedNameEnd(source, tokenKinds, tokenStarts, tokenLengths, 1, count);
    if (nameEnd < 0) {
      return -1;
    }

    set(moduleRange, 0, tokenStarts[1]);
    set(moduleRange, 1, tokenStarts[nameEnd] - tokenStarts[1]);
    long cursor = nameEnd + 1;
    long previousStart = 0;
    long previousLength = 0;
    long importCount = 0;
    while (importCount < MAX_MODULE_IMPORTS) limit MAX_MODULE_IMPORTS {
      if (cursor < count) {} else {
        return -1;
      }

      if (tokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_IMPORT) {} else {
        break;
      }

      long importEnd = qualifiedNameEnd(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        cursor + 1,
        count
      );
      if (importEnd < 0) {
        return -1;
      }

      long importStart = tokenStarts[cursor + 1];
      long importLength = tokenStarts[importEnd] - importStart;
      if (0 < importCount) {
        if (
          compareSourceRanges(source, previousStart, previousLength, importStart, importLength) < 0
        ) {} else {
          return -1;
        }
      }

      previousStart = importStart;
      previousLength = importLength;
      cursor = importEnd + 1;
      importCount += 1;
    }

    if (cursor < count) {
      if (tokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_IMPORT) {
        return -1;
      }

      if (tokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_CLASSICAL) {
        return cursor;
      }
    }

    return -1;
  }
}
