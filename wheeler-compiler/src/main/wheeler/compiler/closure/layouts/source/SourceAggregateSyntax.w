//! Shares bounded aggregate declaration and type parsing rules.

module wheeler.compiler.closure.source_aggregate_syntax;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.tokens;

classical class SourceAggregateSyntax {
  private const long MAX_AGGREGATES = 64;
  private const long MAX_CASES = 128;
  private const long MAX_MEMBERS = 256;

  /// Reports the next member row after one bounded parameter sequence.
  public record ParsedMembers(long nextMember, boolean valid) {}

  /// Describes one parsed fixed-array or slice spelling.
  public record StructuralType(
    long kind,
    long element,
    long length,
    boolean applies,
    boolean valid
  ) {}

  /// Checks one scanner token for exact punctuation.
  public boolean punctuation(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long token,
    long expected
  ) {
    if (tokenKinds[token] != 3) {
      return false;
    }

    return utf8Scalar(source, tokenStarts[token]) == expected;
  }

  /// Computes the bounded bootstrap hash of one exact source range.
  public long rangeHash(borrow utf8 source, long start, long length) {
    long cursor = start;
    long end = start + length;
    long hash = 0;
    while (cursor < end) limit 256 {
      hash = (hash & TOKEN_HASH_INPUT_MASK) * 31 + utf8Scalar(source, cursor);
      cursor += utf8Width(source, cursor);
    }

    return hash;
  }

  /// Compares two exact UTF-8 source ranges.
  public boolean sameRange(
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

      offset += utf8Width(source, leftStart + offset);
    }

    return true;
  }

  /// Finds one aggregate name in an existing source-local prefix.
  public boolean duplicateAggregateName(
    borrow utf8 source,
    long nameStart,
    long nameLength,
    long aggregateCount,
    borrow mut words aggregateRows
  ) {
    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      if (
        sameRange(
          source,
          nameStart,
          nameLength,
          aggregateRows[64 + aggregate],
          aggregateRows[128 + aggregate]
        )
      ) {
        return true;
      }

      aggregate += 1;
    }

    return false;
  }

  /// Finds one case name in an existing variant case window.
  public boolean duplicateCaseName(
    borrow utf8 source,
    long nameStart,
    long nameLength,
    long firstCase,
    long caseCount,
    borrow mut words caseRows
  ) {
    long nextCase = firstCase;
    while (nextCase < firstCase + caseCount) limit MAX_CASES {
      if (
        sameRange(
          source,
          nameStart,
          nameLength,
          caseRows[128 + nextCase],
          caseRows[256 + nextCase]
        )
      ) {
        return true;
      }

      nextCase += 1;
    }

    return false;
  }

  /// Parses one bounded record or variant-case member sequence.
  public ParsedMembers parseMembers(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long open,
    long close,
    long aggregateOwner,
    long caseOwner,
    long memberCount,
    borrow mut words memberRows
  ) {
    long firstMember = memberCount;
    long segmentStart = open + 1;
    long memberCursor = segmentStart;
    boolean valid = true;
    while (valid) limit MAX_COMPILER_TOKENS {
      boolean delimiter = memberCursor == close;
      if (delimiter == false) {
        delimiter = punctuation(source, tokenKinds, tokenStarts, memberCursor, 44);
      }

      if (delimiter) {
        if (segmentStart < memberCursor) {
          if (MAX_MEMBERS < memberCount + 1) {
            valid = false;
          } else {
            long memberNameToken = memberCursor - 1;
            if (segmentStart < memberNameToken) {} else {
              valid = false;
            }

            if (tokenKinds[memberNameToken] != 1) {
              valid = false;
            }

            if (valid) {
              long memberNameStart = tokenStarts[memberNameToken];
              long memberNameLength = tokenLengths[memberNameToken];
              long priorMember = firstMember;
              while (priorMember < memberCount) limit MAX_MEMBERS {
                if (
                  sameRange(
                    source,
                    memberNameStart,
                    memberNameLength,
                    memberRows[512 + priorMember],
                    memberRows[768 + priorMember]
                  )
                ) {
                  valid = false;
                }

                priorMember += 1;
              }

              if (valid) {
                long typeEndToken = memberNameToken - 1;
                long typeStart = tokenStarts[segmentStart];
                long typeEnd = tokenStarts[typeEndToken] + tokenLengths[typeEndToken];
                set(memberRows, memberCount, aggregateOwner);
                set(memberRows, 256 + memberCount, caseOwner);
                set(memberRows, 512 + memberCount, memberNameStart);
                set(memberRows, 768 + memberCount, memberNameLength);
                set(memberRows, 1024 + memberCount, typeStart);
                set(memberRows, 1280 + memberCount, typeEnd - typeStart);
                memberCount += 1;
              }
            }
          }
        } else {
          if (memberCursor != close) {
            valid = false;
          }
        }

        segmentStart = memberCursor + 1;
      }

      if (memberCursor == close) {
        break;
      }

      memberCursor += 1;
    }

    return new ParsedMembers(memberCount, valid);
  }

  /// Finds the closing token paired with one opening token.
  public long closingToken(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long open,
    long tokenCount,
    long opening,
    long closing
  ) {
    long depth = 1;
    long cursor = open + 1;
    while (cursor < tokenCount) limit MAX_COMPILER_TOKENS {
      if (punctuation(source, tokenKinds, tokenStarts, cursor, opening)) {
        depth += 1;
      }

      if (punctuation(source, tokenKinds, tokenStarts, cursor, closing)) {
        depth -= 1;
        if (depth == 0) {
          return cursor;
        }
      }

      cursor += 1;
    }

    return -1;
  }

  /// Includes a declaration visibility modifier in its source range.
  public long declarationStart(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declaration
  ) {
    if (0 < declaration) {
      long modifier = tokenHash(source, tokenStarts, tokenLengths, declaration - 1);
      if (modifier == TOKEN_PUBLIC) {
        return tokenStarts[declaration - 1];
      }

      if (modifier == TOKEN_PRIVATE) {
        return tokenStarts[declaration - 1];
      }
    }

    return tokenStarts[declaration];
  }

  /// Decodes public or private aggregate visibility.
  public long declarationVisibility(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declaration
  ) {
    if (0 < declaration) {
      long modifier = tokenHash(source, tokenStarts, tokenLengths, declaration - 1);
      if (modifier == TOKEN_PUBLIC) {
        return 1;
      }

      if (modifier == TOKEN_PRIVATE) {
        return 0;
      }
    }

    return 0;
  }

  /// Parses one scalar fixed-array or slice type range.
  public StructuralType structuralType(borrow utf8 source, long start, long length) {
    long open = -1;
    long offset = 0;
    while (offset < length) limit 256 {
      if (utf8Scalar(source, start + offset) == 91) {
        if (-1 < open) {
          return new StructuralType(0, 0, 0, true, false);
        }

        open = offset;
      }

      offset += utf8Width(source, start + offset);
    }

    if (open < 0) {
      return new StructuralType(0, 0, 0, false, true);
    }

    if (length < open + 2) {
      return new StructuralType(0, 0, 0, true, false);
    }

    if (utf8Scalar(source, start + length - 1) != 93) {
      return new StructuralType(0, 0, 0, true, false);
    }

    long element = primitiveType(rangeHash(source, start, open));
    if (element == 1) {} else {
      if (element == 2) {} else {
        if (element == 14) {} else {
          return new StructuralType(0, 0, 0, true, false);
        }
      }
    }

    if (open + 1 == length - 1) {
      return new StructuralType(3, element, 0, true, true);
    }

    long arrayLength = 0;
    long digit = open + 1;
    while (digit < length - 1) limit 20 {
      long scalar = utf8Scalar(source, start + digit);
      if (scalar < 48) {
        return new StructuralType(0, 0, 0, true, false);
      }

      if (57 < scalar) {
        return new StructuralType(0, 0, 0, true, false);
      }

      arrayLength = arrayLength * 10 + scalar - 48;
      if (64 < arrayLength) {
        return new StructuralType(0, 0, 0, true, false);
      }

      digit += 1;
    }

    if (arrayLength < 1) {
      return new StructuralType(0, 0, 0, true, false);
    }

    return new StructuralType(2, element, arrayLength, true, true);
  }

  /// Maps one exact primitive type hash to its bytecode code.
  public long primitiveType(long typeHash) {
    if (typeHash == 3327612) {
      return 1;
    }

    if (typeHash == 90259024936) {
      return 2;
    }

    if (typeHash == 3360171764) {
      return 3;
    }

    if (typeHash == 113318569) {
      return 4;
    }

    if (typeHash == 94224491) {
      return 5;
    }

    if (typeHash == 99132996960) {
      return 6;
    }

    if (typeHash == 3600241) {
      return 7;
    }

    if (typeHash == 11018295213) {
      return 13;
    }

    if (typeHash == 2135970) {
      return 14;
    }

    return -1;
  }

}
