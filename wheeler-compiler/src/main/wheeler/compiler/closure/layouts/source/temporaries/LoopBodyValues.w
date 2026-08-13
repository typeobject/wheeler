//! Resolves loop-body names and scalar types against callable value products.

module wheeler.compiler.closure.loop_body_values;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.tokens;

classical class LoopBodyValues {
  private const long MAX_LOCALS = 256;
  private const long VALUE_COUNT_LIMIT = 1024;
  private const long VALUE_DEFINITION_ORDINAL_ROW = 4096;
  private const long VALUE_LOCAL_ROW = 3072;
  private const long VALUE_NAME_LENGTH_ROW = 2048;
  private const long VALUE_NAME_START_ROW = 1024;

  /// Reports one exact visible callable value.
  public record LoopBodyValue(long local, boolean valid) {}

  private long tokenAtRange(
    long start,
    long length,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long selected = -1;
    long matches = 0;
    long token = 0;
    while (token < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenStarts[token] == start) {
        if (tokenLengths[token] == length) {
          selected = token;
          matches += 1;
        }
      }

      token += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private boolean sameRange(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    if (leftLength != rightLength) {
      return false;
    }

    long offset = 0;
    while (offset < leftLength) limit 256 {
      if (
        utf8Scalar(source, leftStart + offset) != utf8Scalar(source, rightStart + offset)
      ) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  /// Resolves one uniquely visible name before the selected source ordinal.
  public LoopBodyValue resolveLoopBodyValue(
    borrow utf8 source,
    long start,
    long length,
    long owner,
    long ordinal,
    long valueCount,
    borrow mut words valueRows
  ) {
    long selected = -1;
    long matches = 0;
    long value = 0;
    while (value < valueCount) limit VALUE_COUNT_LIMIT {
      if (valueRows[value] == owner) {
        if (valueRows[VALUE_DEFINITION_ORDINAL_ROW + value] < ordinal + 1) {
          if (
            sameRange(
              source,
              start,
              length,
              valueRows[VALUE_NAME_START_ROW + value],
              valueRows[VALUE_NAME_LENGTH_ROW + value]
            )
          ) {
            selected = valueRows[VALUE_LOCAL_ROW + value];
            matches += 1;
          }
        }
      }

      value += 1;
    }

    if (matches != 1) {
      return new LoopBodyValue(0, false);
    }

    if (selected < 0) {
      return new LoopBodyValue(0, false);
    }

    if (MAX_LOCALS - 1 < selected) {
      return new LoopBodyValue(0, false);
    }

    return new LoopBodyValue(selected, true);
  }

  /// Returns the source type token hash for one unique callable local.
  public long loopBodyValueType(
    borrow utf8 source,
    long owner,
    long local,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long selected = -1;
    long matches = 0;
    long value = 0;
    while (value < valueCount) limit VALUE_COUNT_LIMIT {
      if (valueRows[value] == owner) {
        if (valueRows[VALUE_LOCAL_ROW + value] == local) {
          selected = value;
          matches += 1;
        }
      }

      value += 1;
    }

    if (matches != 1) {
      return -1;
    }

    long nameToken = tokenAtRange(
      valueRows[VALUE_NAME_START_ROW + selected],
      valueRows[VALUE_NAME_LENGTH_ROW + selected],
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (nameToken < 1) {
      return -1;
    }

    return tokenHash(source, tokenStarts, tokenLengths, nameToken - 1);
  }
}
