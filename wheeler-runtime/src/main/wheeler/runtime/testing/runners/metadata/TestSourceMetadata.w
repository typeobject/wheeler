//! Parses bounded native test tags and execution limits.

module wheeler.runtime.testing.runners.test_source_metadata;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.runtime.testing.runners.test_source_tokens;

classical class TestSourceMetadata {
  private const long MAX_DECLARED_LIMIT = 4000000;
  private const long MAX_TAG_BYTES = 128;
  private const long MAX_TAGS = 64;
  private const long TOKEN_HISTORY = 95416214676;
  private const long TOKEN_LIMITS = 3192269848;
  private const long TOKEN_STEPS = 109761319;
  private const long TOKEN_TAGS = 3552281;

  /// Reports validated metadata, selection, and the effective step bound.
  public record SourceTestMetadata(boolean supported, boolean selected, long stepLimit) {}

  private boolean sameTag(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long leftStart,
    long leftEnd,
    long rightStart,
    long rightEnd
  ) {
    if (leftEnd - leftStart != rightEnd - rightStart) {
      return false;
    }

    long left = leftStart;
    long right = rightStart;
    while (left < leftEnd + 1) limit MAX_COMPILER_TOKENS {
      if (sameTokenText(source, tokenStarts, tokenLengths, left, right) == false) {
        return false;
      }

      left += 1;
      right += 1;
    }

    return true;
  }

  private boolean sourceTagMatches(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long sourceStart,
    long sourceEnd,
    borrow byteview input,
    long selectedStart,
    long selectedLength
  ) {
    long selectedOffset = 0;
    long token = sourceStart;
    while (token < sourceEnd + 1) limit MAX_COMPILER_TOKENS {
      long tokenOffset = 0;
      while (tokenOffset < tokenLengths[token]) limit MAX_TAG_BYTES {
        if (selectedLength < selectedOffset + 1) {
          return false;
        }

        if (
          utf8Scalar(source, tokenStarts[token] + tokenOffset) != input[selectedStart
            + selectedOffset]
        ) {
          return false;
        }

        selectedOffset += 1;
        tokenOffset += 1;
      }

      token += 1;
    }

    return selectedOffset == selectedLength;
  }

  private void markSelectedTag(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long sourceStart,
    long sourceEnd,
    borrow byteview input,
    long selectionStart,
    long selectionCount,
    borrow mut words knownTags,
    borrow mut words declarationMatches
  ) {
    long cursor = selectionStart;
    long selected = 0;
    while (selected < selectionCount) limit MAX_TAGS {
      long length = input[cursor];
      long start = cursor + 1;
      if (
        sourceTagMatches(
          source,
          tokenStarts,
          tokenLengths,
          sourceStart,
          sourceEnd,
          input,
          start,
          length
        )
      ) {
        set(knownTags, selected, 1);
        set(declarationMatches, selected, 1);
      }

      cursor = start + length;
      selected += 1;
    }
  }

  private SourceTestMetadata limitsMetadata(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long tokenCount,
    long start,
    boolean selected
  ) {
    if (start < tokenCount) {} else {
      return new SourceTestMetadata(false, false, 0);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start, PUNCTUATION_OPEN_BRACE)
    ) {
      return new SourceTestMetadata(true, selected, MAX_INTERPRETED_STEPS);
    }

    if (
      boundedSourceTokenHash(source, tokenStarts, tokenLengths, start) != TOKEN_LIMITS
    ) {
      return new SourceTestMetadata(false, false, 0);
    }

    if (start + 10 < tokenCount) {} else {
      return new SourceTestMetadata(false, false, 0);
    }

    boolean valid = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      start + 1,
      PUNCTUATION_OPEN_PAREN
    );
    if (
      boundedSourceTokenHash(source, tokenStarts, tokenLengths, start + 2) != TOKEN_STEPS
    ) {
      valid = false;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 3, PUNCTUATION_ASSIGN) == false
    ) {
      valid = false;
    }

    if (signedNumberWidth(source, tokenKinds, tokenStarts, start + 4) != 1) {
      return new SourceTestMetadata(false, false, 0);
    }

    if (signedNumberValid(source, tokenStarts, tokenLengths, start + 4) == false) {
      return new SourceTestMetadata(false, false, 0);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 5, PUNCTUATION_COMMA) == false
    ) {
      valid = false;
    }

    if (
      boundedSourceTokenHash(source, tokenStarts, tokenLengths, start + 6) != TOKEN_HISTORY
    ) {
      valid = false;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 7, PUNCTUATION_ASSIGN) == false
    ) {
      valid = false;
    }

    if (signedNumberWidth(source, tokenKinds, tokenStarts, start + 8) != 1) {
      return new SourceTestMetadata(false, false, 0);
    }

    if (signedNumberValid(source, tokenStarts, tokenLengths, start + 8) == false) {
      return new SourceTestMetadata(false, false, 0);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 9, PUNCTUATION_CLOSE_PAREN) == false
    ) {
      valid = false;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 10, PUNCTUATION_OPEN_BRACE) == false
    ) {
      valid = false;
    }

    if (valid == false) {
      return new SourceTestMetadata(false, false, 0);
    }

    long steps = parsedSignedNumber(source, tokenStarts, tokenLengths, start + 4);
    long history = parsedSignedNumber(source, tokenStarts, tokenLengths, start + 8);
    if (steps < 1) {
      return new SourceTestMetadata(false, false, 0);
    }

    if (MAX_DECLARED_LIMIT < steps) {
      return new SourceTestMetadata(false, false, 0);
    }

    if (history < 1) {
      return new SourceTestMetadata(false, false, 0);
    }

    if (MAX_DECLARED_LIMIT < history) {
      return new SourceTestMetadata(false, false, 0);
    }

    if (MAX_INTERPRETED_STEPS < steps) {
      steps = MAX_INTERPRETED_STEPS;
    }

    return new SourceTestMetadata(true, selected, steps);
  }

  /// Parses optional tags, optional limits, and the opening body brace.
  public SourceTestMetadata validatedTestMetadata(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long tokenCount,
    long start,
    borrow byteview input,
    long selectionStart,
    long selectionCount,
    borrow mut words knownTags,
    borrow mut words declarationMatches,
    borrow mut words metadataTagStarts,
    borrow mut words metadataTagEnds
  ) {
    assert(bufferLength(knownTags) == MAX_TAGS);
    assert(bufferLength(declarationMatches) == MAX_TAGS);
    assert(bufferLength(metadataTagStarts) == MAX_TAGS);
    assert(bufferLength(metadataTagEnds) == MAX_TAGS);
    long selected = 0;
    while (selected < selectionCount) limit MAX_TAGS {
      set(declarationMatches, selected, 0);
      selected += 1;
    }

    long cursor = start;
    long tagCount = 0;
    if (cursor < tokenCount) {
      if (
        boundedSourceTokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_TAGS
      ) {
        if (cursor + 3 < tokenCount) {} else {
          return new SourceTestMetadata(false, false, 0);
        }

        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor + 1, PUNCTUATION_OPEN_PAREN)
            == false
        ) {
          return new SourceTestMetadata(false, false, 0);
        }

        cursor += 2;
        boolean scanningTags = true;
        while (scanningTags) limit MAX_TAGS {
          if (tagCount < MAX_TAGS) {} else {
            return new SourceTestMetadata(false, false, 0);
          }

          if (cursor < tokenCount) {} else {
            return new SourceTestMetadata(false, false, 0);
          }

          if (tokenKinds[cursor] != 1) {
            return new SourceTestMetadata(false, false, 0);
          }

          long tagStart = cursor;
          long tagEnd = cursor;
          long tagBytes = tokenLengths[cursor];
          cursor += 1;
          boolean scanningSegments = true;
          while (scanningSegments) limit MAX_COMPILER_TOKENS {
            if (cursor < tokenCount) {
              if (
                punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_DOT)
              ) {
                if (cursor + 1 < tokenCount) {} else {
                  return new SourceTestMetadata(false, false, 0);
                }

                if (tokenKinds[cursor + 1] != 1) {
                  return new SourceTestMetadata(false, false, 0);
                }

                tagBytes += 1 + tokenLengths[cursor + 1];
                tagEnd = cursor + 1;
                cursor += 2;
              } else {
                scanningSegments = false;
              }
            } else {
              scanningSegments = false;
            }
          }

          if (MAX_TAG_BYTES < tagBytes) {
            return new SourceTestMetadata(false, false, 0);
          }

          long prior = 0;
          while (prior < tagCount) limit MAX_TAGS {
            if (
              sameTag(
                source,
                tokenStarts,
                tokenLengths,
                metadataTagStarts[prior],
                metadataTagEnds[prior],
                tagStart,
                tagEnd
              )
            ) {
              return new SourceTestMetadata(false, false, 0);
            }

            prior += 1;
          }

          set(metadataTagStarts, tagCount, tagStart);
          set(metadataTagEnds, tagCount, tagEnd);
          markSelectedTag(
            source,
            tokenStarts,
            tokenLengths,
            tagStart,
            tagEnd,
            input,
            selectionStart,
            selectionCount,
            knownTags,
            declarationMatches
          );
          tagCount += 1;
          if (cursor < tokenCount) {} else {
            return new SourceTestMetadata(false, false, 0);
          }

          if (
            punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_COMMA)
          ) {
            cursor += 1;
          } else {
            if (
              punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_PAREN)
            ) {
              cursor += 1;
              scanningTags = false;
            } else {
              return new SourceTestMetadata(false, false, 0);
            }
          }
        }
      }
    }

    boolean declarationSelected = true;
    selected = 0;
    while (selected < selectionCount) limit MAX_TAGS {
      if (declarationMatches[selected] == 0) {
        declarationSelected = false;
      }

      selected += 1;
    }

    return limitsMetadata(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      tokenCount,
      cursor,
      declarationSelected
    );
  }
}
