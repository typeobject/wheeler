//! Lowers native-discovered tests into the fixed physical entry profile.

module wheeler.runtime.testing.runners.test_source_lowering;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;
import wheeler.runtime.testing.runners.test_source_plan;

classical class TestSourceLowering {
  private const long TOKEN_ENTRY = 96667762;
  private const long TOKEN_TEST = 3556498;

  private boolean tokenMatchesRange(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token,
    borrow byteview value,
    long valueStart,
    long valueLength
  ) {
    if (tokenLengths[token] != valueLength) {
      return false;
    }

    long offset = 0;
    while (offset < valueLength) limit 255 {
      if (
        utf8Scalar(source, tokenStarts[token] + offset) != value[valueStart + offset]
      ) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private long declarationEndByte(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long tokenCount,
    long declaration
  ) {
    long token = declaration + 5;
    long depth = 0;
    boolean started = false;
    while (token < tokenCount) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, token, PUNCTUATION_OPEN_BRACE)
      ) {
        depth += 1;
        started = true;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, token, PUNCTUATION_CLOSE_BRACE)
      ) {
        assert(0 < depth);
        depth -= 1;
        if (started) {
          if (depth == 0) {
            return tokenStarts[token] + tokenLengths[token];
          }
        }
      }

      token += 1;
    }

    return -1;
  }

  private long bodyOpenToken(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long tokenCount,
    long declaration
  ) {
    long token = declaration + 5;
    while (token < tokenCount) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, token, PUNCTUATION_OPEN_BRACE)
      ) {
        return token;
      }

      token += 1;
    }

    return -1;
  }

  private long signedTextLength(long value) {
    long length = 1;
    long remaining = value;
    if (remaining < 0) {
      length += 1;
    } else {
      remaining = 0 - remaining;
    }

    while (remaining < -9) limit 19 {
      remaining = remaining / 10;
      length += 1;
    }

    return length;
  }

  private long writeSignedText(borrow mut bytes output, long cursor, long value) {
    long length = signedTextLength(value);
    long start = cursor;
    long remaining = value;
    if (remaining < 0) {
      setByte(output, cursor, 45);
      cursor += 1;
    } else {
      remaining = 0 - remaining;
    }

    long end = start + length;
    long position = end - 1;
    while (remaining < -9) limit 19 {
      setByte(output, position, 48 - remaining % 10);
      remaining = remaining / 10;
      position -= 1;
    }

    setByte(output, position, 48 - remaining);
    return end;
  }

  private long parameterValueTextLength(long caseKind, long caseValue) {
    if (caseKind == 2) {
      return signedTextLength(caseValue);
    }

    assert(caseKind == 3);
    if (caseValue == 0) {
      return 5;
    }

    assert(caseValue == 1);
    return 4;
  }

  /// Derives one parameterless selected-entry source length.
  public long parameterlessEntrySourceLength(
    borrow byteview input,
    long planStart,
    long planLength,
    long rootOrdinal,
    borrow byteview selectedName,
    long selectedNameStart,
    long selectedNameLength
  ) {
    long sourceLength = validatedSourceLength(input, planStart, planLength, rootOrdinal);
    region arena = new region(/* bytes= */ 106496, /* allocations= */ 4);
    bytes sourceBytes = allocateBytes(arena, sourceLength);
    copyValidatedSource(input, planStart, planLength, rootOrdinal, sourceBytes);
    utf8 source = freezeUtf8(sourceBytes);
    words tokenKinds = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(arena, MAX_COMPILER_TOKENS);
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    long tokenCount = 0;
    match (scanned) {
      case ScanResult.Value(long count) {
        tokenCount = count;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        assert(diagnostic.offset < 0);
      }
    }

    long loweredLength = -1;
    long token = 0;
    while (token + 4 < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_TEST) {
        if (tokenHash(source, tokenStarts, tokenLengths, token + 1) == TOKEN_VOID) {
          if (
            tokenMatchesRange(
              source,
              tokenStarts,
              tokenLengths,
              token + 2,
              selectedName,
              selectedNameStart,
              selectedNameLength
            )
          ) {
            long body = bodyOpenToken(source, tokenKinds, tokenStarts, tokenCount, token);
            assert(-1 < body);
            loweredLength = sourceLength + 19 - (tokenStarts[body] + 1 - tokenStarts[token]);
          }
        }
      }

      token += 1;
    }

    assert(0 < loweredLength);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(source);
    drop(arena);
    return loweredLength;
  }

  /// Derives one parameterized selected-entry source length.
  public long parameterizedEntrySourceLength(
    borrow byteview input,
    long planStart,
    long planLength,
    long rootOrdinal,
    borrow byteview selectedName,
    long selectedNameStart,
    long selectedNameLength,
    long caseKind,
    long caseValue
  ) {
    long sourceLength = validatedSourceLength(input, planStart, planLength, rootOrdinal);
    region arena = new region(/* bytes= */ 106496, /* allocations= */ 4);
    bytes sourceBytes = allocateBytes(arena, sourceLength);
    copyValidatedSource(input, planStart, planLength, rootOrdinal, sourceBytes);
    utf8 source = freezeUtf8(sourceBytes);
    words tokenKinds = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(arena, MAX_COMPILER_TOKENS);
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    long tokenCount = 0;
    match (scanned) {
      case ScanResult.Value(long count) {
        tokenCount = count;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        assert(diagnostic.offset < 0);
      }
    }

    long loweredLength = -1;
    long token = 0;
    while (token + 8 < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_TEST) {
        if (tokenHash(source, tokenStarts, tokenLengths, token + 1) == TOKEN_VOID) {
          if (
            tokenMatchesRange(
              source,
              tokenStarts,
              tokenLengths,
              token + 2,
              selectedName,
              selectedNameStart,
              selectedNameLength
            )
          ) {
            long body = bodyOpenToken(source, tokenKinds, tokenStarts, tokenCount, token);
            assert(-1 < body);
            long generatedLength = 19 + tokenLengths[token + 5] + 4;
            if (caseKind == 2) {
              generatedLength += 5;
            } else {
              generatedLength += 8;
            }

            generatedLength += parameterValueTextLength(caseKind, caseValue);
            loweredLength = sourceLength + generatedLength - (
              tokenStarts[body] + 1 - tokenStarts[token]
            );
          }
        }
      }

      token += 1;
    }

    assert(0 < loweredLength);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(source);
    drop(arena);
    return loweredLength;
  }

  /// Lowers one selected parameterless declaration and blanks its peers.
  public void copyParameterlessEntrySource(
    borrow byteview input,
    long planStart,
    long planLength,
    long rootOrdinal,
    borrow byteview selectedName,
    long selectedNameStart,
    long selectedNameLength,
    borrow mut bytes output
  ) {
    long sourceLength = validatedSourceLength(input, planStart, planLength, rootOrdinal);
    long loweredLength = parameterlessEntrySourceLength(
      input,
      planStart,
      planLength,
      rootOrdinal,
      selectedName,
      selectedNameStart,
      selectedNameLength
    );
    assert(bufferLength(output) == loweredLength);
    region arena = new region(/* bytes= */ 106496, /* allocations= */ 4);
    bytes sourceBytes = allocateBytes(arena, sourceLength);
    copyValidatedSource(input, planStart, planLength, rootOrdinal, sourceBytes);
    utf8 source = freezeUtf8(sourceBytes);
    words tokenKinds = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(arena, MAX_COMPILER_TOKENS);
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    long tokenCount = 0;
    match (scanned) {
      case ScanResult.Value(long count) {
        tokenCount = count;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        assert(diagnostic.offset < 0);
      }
    }

    long sourceStart = validatedSourceStart(input, planStart, planLength, rootOrdinal);
    long inputCursor = 0;
    long outputCursor = 0;
    long discovered = 0;
    long selected = 0;
    long token = 0;
    while (token + 4 < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_ENTRY) {
        if (tokenHash(source, tokenStarts, tokenLengths, token + 1) == TOKEN_VOID) {
          long entryStart = tokenStarts[token];
          while (inputCursor < entryStart) limit 4096 {
            setByte(output, outputCursor, input[sourceStart + inputCursor]);
            inputCursor += 1;
            outputCursor += 1;
          }

          long entryEnd = declarationEndByte(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            tokenCount,
            token
          );
          assert(entryStart < entryEnd);
          inputCursor = entryEnd;
          long entryBlank = entryStart;
          while (entryBlank < entryEnd) limit 4096 {
            setByte(output, outputCursor, 32);
            outputCursor += 1;
            entryBlank += 1;
          }
        }
      }

      if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_TEST) {
        if (tokenHash(source, tokenStarts, tokenLengths, token + 1) == TOKEN_VOID) {
          long testStart = tokenStarts[token];
          while (inputCursor < testStart) limit 4096 {
            setByte(output, outputCursor, input[sourceStart + inputCursor]);
            inputCursor += 1;
            outputCursor += 1;
          }

          boolean selectedDeclaration = tokenMatchesRange(
            source,
            tokenStarts,
            tokenLengths,
            token + 2,
            selectedName,
            selectedNameStart,
            selectedNameLength
          );
          if (selectedDeclaration) {
            long body = bodyOpenToken(source, tokenKinds, tokenStarts, tokenCount, token);
            assert(-1 < body);
            writeAscii(output, outputCursor, "entry void main() {");
            outputCursor += 19;
            inputCursor = tokenStarts[body] + 1;
            selected += 1;
          } else {
            long declarationEnd = declarationEndByte(
              source,
              tokenKinds,
              tokenStarts,
              tokenLengths,
              tokenCount,
              token
            );
            assert(testStart < declarationEnd);
            inputCursor = declarationEnd;
            long blank = testStart;
            while (blank < declarationEnd) limit 4096 {
              setByte(output, outputCursor, 32);
              outputCursor += 1;
              blank += 1;
            }
          }

          discovered += 1;
        }
      }

      token += 1;
    }

    while (inputCursor < sourceLength) limit 4096 {
      setByte(output, outputCursor, input[sourceStart + inputCursor]);
      inputCursor += 1;
      outputCursor += 1;
    }

    assert(0 < discovered);
    assert(selected == 1);
    assert(outputCursor == loweredLength);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(source);
    drop(arena);
  }

  /// Lowers one selected scalar row and blanks every peer declaration.
  public void copyParameterizedEntrySource(
    borrow byteview input,
    long planStart,
    long planLength,
    long rootOrdinal,
    borrow byteview selectedName,
    long selectedNameStart,
    long selectedNameLength,
    long caseKind,
    long caseValue,
    borrow mut bytes output
  ) {
    long sourceLength = validatedSourceLength(input, planStart, planLength, rootOrdinal);
    region arena = new region(/* bytes= */ 106496, /* allocations= */ 4);
    bytes sourceBytes = allocateBytes(arena, sourceLength);
    copyValidatedSource(input, planStart, planLength, rootOrdinal, sourceBytes);
    utf8 source = freezeUtf8(sourceBytes);
    words tokenKinds = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(arena, MAX_COMPILER_TOKENS);
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    long tokenCount = 0;
    match (scanned) {
      case ScanResult.Value(long count) {
        tokenCount = count;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        assert(diagnostic.offset < 0);
      }
    }

    long sourceStart = validatedSourceStart(input, planStart, planLength, rootOrdinal);
    long inputCursor = 0;
    long outputCursor = 0;
    long discovered = 0;
    long selected = 0;
    long token = 0;
    while (token + 8 < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_ENTRY) {
        if (tokenHash(source, tokenStarts, tokenLengths, token + 1) == TOKEN_VOID) {
          long entryStart = tokenStarts[token];
          while (inputCursor < entryStart) limit 4096 {
            setByte(output, outputCursor, input[sourceStart + inputCursor]);
            inputCursor += 1;
            outputCursor += 1;
          }

          long entryEnd = declarationEndByte(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            tokenCount,
            token
          );
          assert(entryStart < entryEnd);
          inputCursor = entryEnd;
          long entryBlank = entryStart;
          while (entryBlank < entryEnd) limit 4096 {
            setByte(output, outputCursor, 32);
            outputCursor += 1;
            entryBlank += 1;
          }
        }
      }

      if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_TEST) {
        if (tokenHash(source, tokenStarts, tokenLengths, token + 1) == TOKEN_VOID) {
          long testStart = tokenStarts[token];
          while (inputCursor < testStart) limit 4096 {
            setByte(output, outputCursor, input[sourceStart + inputCursor]);
            inputCursor += 1;
            outputCursor += 1;
          }

          boolean selectedDeclaration = tokenMatchesRange(
            source,
            tokenStarts,
            tokenLengths,
            token + 2,
            selectedName,
            selectedNameStart,
            selectedNameLength
          );
          if (selectedDeclaration) {
            long body = bodyOpenToken(source, tokenKinds, tokenStarts, tokenCount, token);
            assert(-1 < body);
            writeAscii(output, outputCursor, "entry void main() {");
            outputCursor += 19;
            if (caseKind == 2) {
              writeAscii(output, outputCursor, "long ");
              outputCursor += 5;
            } else {
              assert(caseKind == 3);
              writeAscii(output, outputCursor, "boolean ");
              outputCursor += 8;
            }

            long parameterToken = token + 5;
            long parameterOffset = 0;
            while (parameterOffset < tokenLengths[parameterToken]) limit 255 {
              setByte(
                output,
                outputCursor,
                input[sourceStart + tokenStarts[parameterToken] + parameterOffset]
              );
              outputCursor += 1;
              parameterOffset += 1;
            }

            writeAscii(output, outputCursor, " = ");
            outputCursor += 3;
            if (caseKind == 2) {
              outputCursor = writeSignedText(output, outputCursor, caseValue);
            } else {
              if (caseValue == 0) {
                writeAscii(output, outputCursor, "false");
                outputCursor += 5;
              } else {
                assert(caseValue == 1);
                writeAscii(output, outputCursor, "true");
                outputCursor += 4;
              }
            }

            setByte(output, outputCursor, 59);
            outputCursor += 1;
            inputCursor = tokenStarts[body] + 1;
            selected += 1;
          } else {
            long declarationEnd = declarationEndByte(
              source,
              tokenKinds,
              tokenStarts,
              tokenLengths,
              tokenCount,
              token
            );
            assert(testStart < declarationEnd);
            inputCursor = declarationEnd;
            long blank = testStart;
            while (blank < declarationEnd) limit 4096 {
              setByte(output, outputCursor, 32);
              outputCursor += 1;
              blank += 1;
            }
          }

          discovered += 1;
        }
      }

      token += 1;
    }

    while (inputCursor < sourceLength) limit 4096 {
      setByte(output, outputCursor, input[sourceStart + inputCursor]);
      inputCursor += 1;
      outputCursor += 1;
    }

    assert(0 < discovered);
    assert(selected == 1);
    assert(outputCursor == bufferLength(output));
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(source);
    drop(arena);
  }
}
