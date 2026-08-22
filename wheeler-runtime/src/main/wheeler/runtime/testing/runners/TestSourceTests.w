//! Discovers bounded parameterless test declarations in a validated root source.

module wheeler.runtime.testing.runners.test_source_tests;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;
import wheeler.runtime.testing.runners.test_source_plan;

classical class TestSourceTests {
  private const long MAX_CASES = 64;
  private const long TOKEN_TEST = 3556498;

  /// Reports the discovered declaration count and complete descriptor match.
  public record SourceTestDiscovery(long count, boolean matched) {}

  private long readUnsigned32LittleEndian(borrow byteview input, long offset) {
    return input[offset] + input[offset + 1] * 256 + input[offset + 2] * 65536 + input[offset + 3]
      * 16777216;
  }

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

  private boolean declarationMatchesOneDescriptor(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken,
    borrow byteview descriptors,
    long descriptorStart,
    long caseCount,
    borrow byteview targetName
  ) {
    long cursor = descriptorStart;
    long matched = 0;
    long testcase = 0;
    while (testcase < caseCount) limit MAX_CASES {
      long nameLength = descriptors[cursor];
      long nameStart = cursor + 1;
      if (
        discoveredNameMatches(
          source,
          tokenStarts,
          tokenLengths,
          nameToken,
          descriptors,
          nameStart,
          nameLength,
          targetName
        )
      ) {
        matched += 1;
      }

      long artifactLengthOffset = nameStart + nameLength;
      long artifactLength = readUnsigned32LittleEndian(descriptors, artifactLengthOffset);
      cursor = artifactLengthOffset + 4 + artifactLength;
      testcase += 1;
    }

    return matched == 1;
  }

  private boolean uniqueTestName(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken
  ) {
    long prior = 0;
    while (prior + 2 < nameToken) limit MAX_COMPILER_TOKENS {
      if (tokenHash(source, tokenStarts, tokenLengths, prior) == TOKEN_TEST) {
        if (tokenHash(source, tokenStarts, tokenLengths, prior + 1) == TOKEN_VOID) {
          if (sameTokenText(source, tokenStarts, tokenLengths, prior + 2, nameToken)) {
            return false;
          }
        }
      }

      prior += 1;
    }

    return true;
  }

  /// Discovers and binds the bounded parameterless root-test profile.
  public SourceTestDiscovery discoverRootTests(
    borrow byteview input,
    long planStart,
    long planLength,
    long rootOrdinal,
    long descriptorStart,
    long caseCount,
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
    long matchedDeclarations = 0;
    boolean supported = true;
    long token = 0;
    while (token + 4 < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_TEST) {
        if (tokenHash(source, tokenStarts, tokenLengths, token + 1) == TOKEN_VOID) {
          discovered += 1;
          if (uniqueTestName(source, tokenStarts, tokenLengths, token + 2) == false) {
            supported = false;
          }

          boolean parameterless = punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            token + 3,
            PUNCTUATION_OPEN_PAREN
          );
          if (parameterless) {
            parameterless = punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              token + 4,
              PUNCTUATION_CLOSE_PAREN
            );
          }

          if (parameterless) {
            if (
              declarationMatchesOneDescriptor(
                source,
                tokenStarts,
                tokenLengths,
                token + 2,
                input,
                descriptorStart,
                caseCount,
                targetName
              )
            ) {
              matchedDeclarations += 1;
            }
          } else {
            supported = false;
          }
        }
      }

      token += 1;
    }

    boolean matched = supported;
    if (discovered != caseCount) {
      matched = false;
    }

    if (matchedDeclarations != discovered) {
      matched = false;
    }

    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(source);
    drop(arena);
    return new SourceTestDiscovery(discovered, matched);
  }
}
