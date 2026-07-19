//! Scans strict UTF-8 into bounded token metadata.

module wheeler.lexer.scanner;

classical class Scanner {
  /// Defines immutable `ScanDiagnostic` values for this module.
  public record ScanDiagnostic(long code, long offset, long line, long column) {}

  /// Defines the closed `ScanResult` cases exported by this module.
  public variant ScanResult {
    case Value(long count);
    case Error(ScanDiagnostic diagnostic);
  }

  private ScanResult scanError(borrow utf8 source, long code, long offset) {
    long cursor = 0;
    long line = 1;
    long column = 1;
    while (cursor < offset) limit 4096 {
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

  /// Classifies one ASCII or Unicode scalar as a source token kind.
  public long tokenKind(long scalar) {
    if (scalar == 10) {
      return 0;
    }

    if (scalar == 32) {
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

    return false;
  }

  /// Parses `number` from a bounded canonical input.
  public long parseNumber(borrow utf8 source, long start, long end) {
    long value = 0;
    long cursor = start;
    while (cursor < end) limit 19 {
      long digit = utf8Scalar(source, cursor) - 48;
      if (value < 922337203685477580) {
        value = value * 10 + digit;
      } else {
        if (value == 922337203685477580) {
          if (digit < 8) {
            value = value * 10 + digit;
          } else {
            return -1;
          }
        } else {
          return -1;
        }
      }

      cursor += utf8Width(source, cursor);
    }

    return value;
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
    while (cursor < sourceLength) limit 4096 {
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
    while (cursor < sourceLength) limit 4096 {
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
            while (scanning) limit 4096 {
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
              while (scanningComment) limit 4096 {
                if (cursor < sourceLength) {
                  if (utf8Scalar(source, cursor) == 10) {
                    scanningComment = false;
                  } else {
                    cursor += utf8Width(source, cursor);
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
