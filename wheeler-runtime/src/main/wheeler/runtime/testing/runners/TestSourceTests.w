//! Discovers one parameterless test declaration in a validated root source.

module wheeler.runtime.testing.runners.test_source_tests;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;
import wheeler.runtime.testing.runners.test_source_plan;

classical class TestSourceTests {
  private const long TOKEN_TEST = 3556498;

  /// Reports the discovered declaration count and exact descriptor-name match.
  public record SourceTestDiscovery(long count, boolean matched) {}

  private boolean discoveredNameMatches(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken,
    borrow byteview descriptor,
    long descriptorStart,
    long descriptorLength,
    borrow byteview targetName
  ) {
    long targetLength = bufferLength(targetName);
    long nameLength = tokenLengths[nameToken];
    if (descriptorLength != targetLength + nameLength + 2) {
      return false;
    }

    long offset = 0;
    while (offset < targetLength) limit 255 {
      if (descriptor[descriptorStart + offset] != targetName[offset]) {
        return false;
      }

      offset += 1;
    }

    if (descriptor[descriptorStart + targetLength] != 58) {
      return false;
    }

    if (descriptor[descriptorStart + targetLength + 1] != 58) {
      return false;
    }

    long nameStart = tokenStarts[nameToken];
    offset = 0;
    while (offset < nameLength) limit 255 {
      if (
        descriptor[descriptorStart + targetLength + 2 + offset] != utf8Scalar(
          source,
          nameStart + offset
        )
      ) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  /// Discovers the bounded parameterless test profile after source-plan validation.
  public SourceTestDiscovery discoverRootTest(
    borrow byteview input,
    long planStart,
    long planLength,
    long rootOrdinal,
    borrow byteview descriptor,
    long descriptorStart,
    long descriptorLength,
    borrow byteview targetName
  ) {
    long sourceLength = validatedSourceLength(input, planStart, planLength, rootOrdinal);
    region arena = new region(/* bytes= */ 106496, /* allocations= */ 4);
    bytes sourceBytes = allocateBytes(arena, sourceLength);
    copyValidatedSource(input, planStart, planLength, rootOrdinal, sourceBytes);
    utf8 source = freezeUtf8(sourceBytes);
    words tokenKinds = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(arena, MAX_COMPILER_TOKENS);
    long tokenCount = 0;
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    match (scanned) {
      case ScanResult.Value(long count) {
        tokenCount = count;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        assert(diagnostic.offset < 0);
      }
    }

    long discovered = 0;
    boolean matched = false;
    long token = 0;
    while (token + 4 < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_TEST) {
        if (tokenHash(source, tokenStarts, tokenLengths, token + 1) == TOKEN_VOID) {
          discovered += 1;
          if (
            punctuationAt(source, tokenKinds, tokenStarts, token + 3, PUNCTUATION_OPEN_PAREN)
          ) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                token + 4,
                PUNCTUATION_CLOSE_PAREN
              )
            ) {
              if (
                discoveredNameMatches(
                  source,
                  tokenStarts,
                  tokenLengths,
                  token + 2,
                  descriptor,
                  descriptorStart,
                  descriptorLength,
                  targetName
                )
              ) {
                matched = true;
              }
            }
          }
        }
      }

      token += 1;
    }

    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(source);
    drop(arena);
    return new SourceTestDiscovery(discovered, matched);
  }
}
