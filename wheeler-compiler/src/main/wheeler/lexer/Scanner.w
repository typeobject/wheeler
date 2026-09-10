//! Scans strict UTF-8 into bounded token metadata.

module wheeler.lexer.scanner;

classical class Scanner {
  /// Caps one source or canonical package-metadata input.
  private const long MAX_SCANNER_INPUT_BYTES = 262144;
  private const long HORIZONTAL_TAB = 9;
  private const long LINE_FEED = 10;
  private const long CARRIAGE_RETURN = 13;
  private const long INFORMATION_SEPARATOR_FIRST = 28;
  private const long SPACE = 32;
  private const long OGHAM_SPACE_MARK = 5760;
  private const long EN_QUAD = 8192;
  private const long FIGURE_SPACE = 8199;
  private const long HAIR_SPACE = 8202;
  private const long LINE_SEPARATOR = 8232;
  private const long PARAGRAPH_SEPARATOR = LINE_SEPARATOR + 1;
  private const long MEDIUM_MATHEMATICAL_SPACE = 8287;
  private const long IDEOGRAPHIC_SPACE = 12288;

  /// Defines immutable `ScanDiagnostic` values for this module.
  public record ScanDiagnostic(long code, long offset, long line, long column) {}

  /// Carries a signed integer without reserving any value as an error sentinel.
  public record NumberValue(long value, boolean valid) {}

  /// Defines the closed `ScanResult` cases exported by this module.
  public variant ScanResult {
    case Value(long count);
    case Error(ScanDiagnostic diagnostic);
  }

  private ScanResult scanError(borrow utf8 source, long code, long offset) {
    long cursor = 0;
    long line = 1;
    long column = 1;
    while (cursor < offset) limit MAX_SCANNER_INPUT_BYTES {
      long scalar = utf8Scalar(source, cursor);
      if (scalar == 10) {
        line += 1;
        column = 1;
      } else {
        column += 1;
      }

      cursor += utf8Width(source, cursor);
    }

    ScanDiagnostic diagnostic = new ScanDiagnostic(code, offset, line, column);
    return new ScanResult.Error(diagnostic);
  }

  private boolean sourceWhitespace(long scalar) {
    if (HORIZONTAL_TAB - 1 < scalar) {
      if (scalar < CARRIAGE_RETURN + 1) {
        return true;
      }
    }

    if (INFORMATION_SEPARATOR_FIRST - 1 < scalar) {
      if (scalar < SPACE + 1) {
        return true;
      }
    }

    if (scalar == OGHAM_SPACE_MARK) {
      return true;
    }

    if (EN_QUAD - 1 < scalar) {
      if (scalar < HAIR_SPACE + 1) {
        return scalar != FIGURE_SPACE;
      }
    }

    if (scalar == LINE_SEPARATOR) {
      return true;
    }

    if (scalar == PARAGRAPH_SEPARATOR) {
      return true;
    }

    if (scalar == MEDIUM_MATHEMATICAL_SPACE) {
      return true;
    }

    return scalar == IDEOGRAPHIC_SPACE;
  }

  /// Classifies one scalar using source whitespace, ASCII identifiers, and punctuation.
  /// Nonbreaking spaces are not source whitespace. Quoted and comment content is separate.
  public long tokenKind(long scalar) {
    if (sourceWhitespace(scalar)) {
      return 0;
    }

    if (scalar < 48) {
      return 3;
    }

    if (scalar < 58) {
      return 2;
    }

    if (scalar < 65) {
      return 3;
    }

    if (scalar < 91) {
      return 1;
    }

    if (scalar == 95) {
      return 1;
    }

    if (scalar < 97) {
      return 3;
    }

    if (scalar < 123) {
      return 1;
    }

    return 3;
  }

  private boolean continuesToken(long kind, long nextKind) {
    if (nextKind == kind) {
      return true;
    }

    if (kind == 1) {
      return nextKind == 2;
    }

    if (kind == 2) {
      return nextKind == 1;
    }

    return false;
  }

  private long numberDigit(long scalar) {
    if (47 < scalar) {
      if (scalar < 58) {
        return scalar - 48;
      }
    }

    if (64 < scalar) {
      if (scalar < 71) {
        return scalar - 55;
      }
    }

    if (96 < scalar) {
      if (scalar < 103) {
        return scalar - 87;
      }
    }

    return -1;
  }

  /// Decodes an unsigned token extent under its separately supplied source sign.
  /// The extent must start on a UTF-8 scalar boundary. Digits and separators share 64 steps.
  public NumberValue parseSignedNumber(
    borrow utf8 source,
    long start,
    long end,
    boolean negative
  ) {
    if (start < 0) {
      return new NumberValue(0, false);
    }

    if (start < end) {} else {
      return new NumberValue(0, false);
    }

    if (bufferLength(source) < end) {
      return new NumberValue(0, false);
    }

    long minimum = -9223372036854775807;
    if (negative) {
      minimum -= 1;
    }

    long radix = 10;
    long cursor = start;
    if (cursor + 1 < end) {
      if (utf8Scalar(source, cursor) == 48) {
        long marker = utf8Scalar(source, cursor + 1);
        if (marker == 120) {
          radix = 16;
          cursor += 2;
        } else {
          if (marker == 98) {
            radix = 2;
            cursor += 2;
          }
        }
      }
    }

    long value = 0;
    long digits = 0;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      if (scalar == 95) {
        cursor += utf8Width(source, cursor);
      } else {
        long digit = numberDigit(scalar);
        if (digit < 0) {
          return new NumberValue(0, false);
        }

        if (digit < radix) {} else {
          return new NumberValue(0, false);
        }

        long limitValue = (minimum + digit) / radix;
        if (value < limitValue) {
          return new NumberValue(0, false);
        }

        value = value * radix - digit;
        digits += 1;
        cursor += utf8Width(source, cursor);
      }
    }

    if (digits == 0) {
      return new NumberValue(0, false);
    }

    if (negative == false) {
      value = 0 - value;
    }

    return new NumberValue(value, true);
  }

  /// Decodes a nonnegative integer, or returns minus one outside that domain.
  public long parseNumber(borrow utf8 source, long start, long end) {
    NumberValue number = parseSignedNumber(source, start, end, false);
    if (number.valid) {
      return number.value;
    }

    return -1;
  }

  /// Classifies the comment beginning at one checked source offset.
  public long commentKind(borrow utf8 source, long cursor, long sourceLength) {
    long next = cursor + utf8Width(source, cursor);
    if (next < sourceLength) {
      long marker = utf8Scalar(source, next);
      if (marker == 47) {
        return 4;
      }

      if (marker == 42) {
        return 5;
      }
    }

    return 0;
  }

  /// Returns the closing offset of one bounded ASCII literal.
  public long asciiLiteralEnd(borrow utf8 source, long cursor, long sourceLength) {
    cursor += utf8Width(source, cursor);
    while (cursor < sourceLength) limit MAX_SCANNER_INPUT_BYTES {
      long scalar = utf8Scalar(source, cursor);
      if (scalar == 34) {
        return cursor + utf8Width(source, cursor);
      }

      if (scalar == 92) {
        cursor += utf8Width(source, cursor);
        if (cursor < sourceLength) {
          long escaped = utf8Scalar(source, cursor);
          if (escaped == 34) {
            cursor += utf8Width(source, cursor);
          } else {
            if (escaped == 92) {
              cursor += utf8Width(source, cursor);
            } else {
              return -1;
            }
          }
        } else {
          return -1;
        }
      } else {
        if (scalar < 32) {
          return -1;
        }

        if (126 < scalar) {
          return -1;
        }

        cursor += utf8Width(source, cursor);
      }
    }

    return -1;
  }

  /// Scans strict UTF-8 into caller-owned bounded token metadata.
  public ScanResult scan(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long sourceLength = bufferLength(source);
    long count = 0;
    long cursor = 0;
    while (cursor < sourceLength) limit MAX_SCANNER_INPUT_BYTES {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long kind = tokenKind(scalar);
      if (scalar == 34) {
        kind = 6;
      }

      if (scalar == 47) {
        long detectedComment = commentKind(source, cursor, sourceLength);
        if (3 < detectedComment) {
          kind = detectedComment;
        }
      }

      if (kind == 0) {
        cursor += width;
      } else {
        if (count < bufferLength(tokenKinds)) {
          long tokenIndex = count;
          long tokenStart = cursor;
          set(tokenKinds, tokenIndex, kind);
          set(tokenStarts, tokenIndex, tokenStart);
          count += 1;
          cursor += width;
          if (kind < 3) {
            boolean scanning = true;
            while (scanning) limit MAX_SCANNER_INPUT_BYTES {
              if (cursor < sourceLength) {
                long next = utf8Scalar(source, cursor);
                if (continuesToken(kind, tokenKind(next))) {
                  cursor += utf8Width(source, cursor);
                } else {
                  scanning = false;
                }
              } else {
                scanning = false;
              }
            }
          } else {
            if (kind == 4) {
              boolean scanningComment = true;
              while (scanningComment) limit MAX_SCANNER_INPUT_BYTES {
                if (cursor < sourceLength) {
                  long commentScalar = utf8Scalar(source, cursor);
                  if (commentScalar == LINE_FEED) {
                    scanningComment = false;
                  } else {
                    if (commentScalar == CARRIAGE_RETURN) {
                      scanningComment = false;
                    } else {
                      cursor += utf8Width(source, cursor);
                    }
                  }
                } else {
                  scanningComment = false;
                }
              }
            }

            if (kind == 5) {
              long blockEnd = blockCommentEnd(source, tokenStart, sourceLength);
              if (blockEnd < 0) {
                return scanError(source, 1, tokenStart);
              }

              cursor = blockEnd;
            }

            if (kind == 6) {
              long literalEnd = asciiLiteralEnd(source, tokenStart, sourceLength);
              if (literalEnd < 0) {
                return scanError(source, 2, tokenStart);
              }

              cursor = literalEnd;
            }
          }

          set(tokenLengths, tokenIndex, cursor - tokenStart);
        } else {
          return scanError(source, 3, cursor);
        }
      }
    }

    return new ScanResult.Value(count);
  }

  /// Returns the closing offset of one bounded block comment.
  public long blockCommentEnd(borrow utf8 source, long cursor, long sourceLength) {
    cursor += utf8Width(source, cursor);
    cursor += utf8Width(source, cursor);
    while (cursor < sourceLength) limit 256 {
      long scalar = utf8Scalar(source, cursor);
      if (scalar == 42) {
        long next = cursor + utf8Width(source, cursor);
        if (next < sourceLength) {
          if (utf8Scalar(source, next) == 47) {
            return next + utf8Width(source, next);
          }
        }
      }

      cursor += utf8Width(source, cursor);
    }

    return -1;
  }
}
