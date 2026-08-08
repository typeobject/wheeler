//! Parses canonical callable result, effect, parameter-type, and loan products.

module wheeler.compiler.closure.callable_signature_products;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class CallableSignatureProducts {
  /// Caps one callable signature at sixty-four parameters.
  public const long MAX_CALLABLE_PARAMETERS = 64;
  /// Caps all parameter products in one closure.
  public const long MAX_CLOSURE_PARAMETERS = 16384;
  private const long TOKEN_COHERENT = 2825335909666;
  private const long TOKEN_TEST = 3556498;

  /// Counts parameters in one structurally validated callable header.
  public long parameterCount(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long open,
    long close
  ) {
    if (open + 1 == close) {
      return 0;
    }

    long count = 1;
    long depth = 1;
    long cursor = open + 1;
    while (cursor < close) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_PAREN)
      ) {
        depth += 1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_PAREN)
      ) {
        depth -= 1;
      }

      if (depth == 1) {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_COMMA)
        ) {
          count += 1;
        }
      }

      cursor += 1;
    }

    if (count < MAX_CALLABLE_PARAMETERS + 1) {
      return count;
    }

    return -1;
  }

  /// Identifies one result type and its canonical effect mask.
  public record CallableHeader(long resultTypeToken, long effects, boolean valid) {}

  /// Separates visibility and effect modifiers from a callable result type.
  public CallableHeader callableHeader(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declarationStart,
    long nameToken
  ) {
    long cursor = declarationStart;
    long first = tokenHash(source, tokenStarts, tokenLengths, cursor);
    if (first == TOKEN_PUBLIC) {
      cursor += 1;
    } else {
      if (first == TOKEN_PRIVATE) {
        cursor += 1;
      }
    }

    long effects = 0;
    boolean scanning = true;
    while (scanning) limit 4 {
      long modifier = tokenHash(source, tokenStarts, tokenLengths, cursor);
      if (modifier == TOKEN_ENTRY) {
        effects += 1;
        cursor += 1;
      } else {
        if (modifier == TOKEN_REV) {
          effects += 2;
          cursor += 1;
        } else {
          if (modifier == TOKEN_COHERENT) {
            effects += 4;
            cursor += 1;
          } else {
            if (modifier == TOKEN_TEST) {
              effects += 8;
              cursor += 1;
            } else {
              scanning = false;
            }
          }
        }
      }
    }

    if (cursor < nameToken) {
      return new CallableHeader(cursor, effects, true);
    }

    return new CallableHeader(0, 0, false);
  }

  /// Publishes canonical parameter type ranges and owner or loan modes.
  public long writeParameterProducts(
    borrow utf8 source,
    long archiveSourceStart,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long open,
    long close,
    long expectedCount,
    long firstParameter,
    borrow mut words parameterTypeStarts,
    borrow mut words parameterTypeLengths,
    borrow mut words parameterModes
  ) {
    long cursor = open + 1;
    long written = 0;
    while (cursor < close) limit MAX_CALLABLE_PARAMETERS {
      long segmentStart = cursor;
      while (cursor < close) limit MAX_COMPILER_TOKENS {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_COMMA)
        ) {
          break;
        }

        cursor += 1;
      }

      long nameToken = cursor - 1;
      if (segmentStart < nameToken) {} else {
        return -1;
      }

      long typeToken = segmentStart;
      long mode = 0;
      if (tokenHash(source, tokenStarts, tokenLengths, typeToken) == TOKEN_BORROW) {
        mode = 1;
        typeToken += 1;
        if (typeToken < nameToken) {} else {
          return -1;
        }

        if (tokenHash(source, tokenStarts, tokenLengths, typeToken) == TOKEN_MUT) {
          mode = 2;
          typeToken += 1;
        }
      }

      if (typeToken < nameToken) {} else {
        return -1;
      }

      long parameter = firstParameter + written;
      if (parameter < MAX_CLOSURE_PARAMETERS) {} else {
        return -1;
      }

      long finalTypeToken = nameToken - 1;
      long typeStart = tokenStarts[typeToken];
      long typeEnd = tokenStarts[finalTypeToken] + tokenLengths[finalTypeToken];
      set(parameterTypeStarts, parameter, archiveSourceStart + typeStart);
      set(parameterTypeLengths, parameter, typeEnd - typeStart);
      set(parameterModes, parameter, mode);
      written += 1;
      cursor += 1;
    }

    if (written == expectedCount) {
      return firstParameter + written;
    }

    return -1;
  }

}
