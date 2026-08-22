//! Lowers native-discovered tests into the fixed physical entry profile.

module wheeler.runtime.testing.runners.test_source_lowering;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;
import wheeler.runtime.testing.runners.test_source_plan;

classical class TestSourceLowering {
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

  /// Lowers one selected parameterless declaration and blanks its peers.
  public void copyParameterlessEntrySource(
    borrow byteview input,
    long planStart,
    long planLength,
    long rootOrdinal,
    borrow byteview selectedName,
    long selectedNameStart,
    long selectedNameLength,
    long testCount,
    borrow mut bytes output
  ) {
    long sourceLength = validatedSourceLength(input, planStart, planLength, rootOrdinal);
    long loweredLength = sourceLength + 5 - selectedNameLength;
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
      if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_TEST) {
        if (tokenHash(source, tokenStarts, tokenLengths, token + 1) == TOKEN_VOID) {
          long testStart = tokenStarts[token];
          long nameStart = tokenStarts[token + 2];
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
            inputCursor = testStart + 4;
            writeAscii(output, outputCursor, "entry");
            outputCursor += 5;
            while (inputCursor < nameStart) limit 4096 {
              setByte(output, outputCursor, input[sourceStart + inputCursor]);
              inputCursor += 1;
              outputCursor += 1;
            }

            writeAscii(output, outputCursor, "main");
            outputCursor += 4;
            inputCursor = nameStart + selectedNameLength;
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

    assert(discovered == testCount);
    assert(selected == 1);
    assert(outputCursor == loweredLength);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(source);
    drop(arena);
  }

}
