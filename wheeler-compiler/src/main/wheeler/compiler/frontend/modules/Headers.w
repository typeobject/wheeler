//! Parses bounded module and direct-import headers for native compilation.

module wheeler.compiler.module_headers;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class ModuleHeaders {
  private const long HEADER_DEPENDENCY_ARENA_BYTES = 196640;

  /// Carries exact direct-import membership for two validated module headers.
  public record HeaderDependency(
    long importCount,
    long candidateImportRank,
    boolean importsCandidate,
    boolean valid
  ) {}

  private long qualifiedNameEnd(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long start,
    long count
  ) {
    long cursor = start;
    long nameEnd = 0;
    boolean expectName = true;
    while (cursor < count) limit MAX_QUALIFIED_NAME_TOKENS {
      if (expectName) {
        if (tokenKinds[cursor] == 1) {
          if (start < cursor) {
            if (tokenStarts[cursor] == nameEnd + 1) {} else {
              return -1;
            }
          }

          nameEnd = tokenStarts[cursor] + tokenLengths[cursor];
          expectName = false;
        } else {
          return -1;
        }
      } else {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_SEMICOLON)
        ) {
          return cursor;
        }

        if (punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_DOT)) {
          if (tokenStarts[cursor] == nameEnd) {} else {
            return -1;
          }

          expectName = true;
        } else {
          return -1;
        }
      }

      cursor += 1;
    }

    return -1;
  }

  private long compareSourceRanges(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long left = 0;
    long right = 0;
    while (left < leftLength) limit MAX_QUALIFIED_NAME_BYTES {
      if (rightLength < right + 1) {
        return 1;
      }

      long leftScalar = utf8Scalar(source, leftStart + left);
      long rightScalar = utf8Scalar(source, rightStart + right);
      if (leftScalar < rightScalar) {
        return -1;
      }

      if (rightScalar < leftScalar) {
        return 1;
      }

      left += utf8Width(source, leftStart + left);
      right += utf8Width(source, rightStart + right);
    }

    if (right < rightLength) {
      return -1;
    }

    return 0;
  }

  private long compareCrossSourceRanges(
    borrow utf8 leftSource,
    long leftStart,
    long leftLength,
    borrow utf8 rightSource,
    long rightStart,
    long rightLength
  ) {
    long left = 0;
    long right = 0;
    while (left < leftLength) limit MAX_QUALIFIED_NAME_BYTES {
      if (rightLength < right + 1) {
        return 1;
      }

      long leftScalar = utf8Scalar(leftSource, leftStart + left);
      long rightScalar = utf8Scalar(rightSource, rightStart + right);
      if (leftScalar < rightScalar) {
        return -1;
      }

      if (rightScalar < leftScalar) {
        return 1;
      }

      left += utf8Width(leftSource, leftStart + left);
      right += utf8Width(rightSource, rightStart + right);
    }

    if (right < rightLength) {
      return -1;
    }

    return 0;
  }

  private long compactHeaderTokens(
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count
  ) {
    long readCursor = 0;
    long writeCursor = 0;
    while (readCursor < count) limit MAX_COMPILER_TOKENS {
      long kind = tokenKinds[readCursor];
      if (kind == 4) {} else {
        if (kind == 5) {} else {
          set(tokenKinds, writeCursor, kind);
          set(tokenStarts, writeCursor, tokenStarts[readCursor]);
          set(tokenLengths, writeCursor, tokenLengths[readCursor]);
          writeCursor += 1;
        }
      }

      readCursor += 1;
    }

    return writeCursor;
  }

  private long scanHeaderTokens(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    match (scanned) {
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        long ignoredOffset = diagnostic.offset;
        return -1;
      }
      case ScanResult.Value(long count) {
        return compactHeaderTokens(tokenKinds, tokenStarts, tokenLengths, count);
      }
    }
  }

  /// Returns the first class token after a valid bounded source header.
  public long moduleBodyStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words moduleRange,
    long count
  ) {
    set(moduleRange, 0, 0);
    set(moduleRange, 1, 0);
    if (count == 0) {
      return -1;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, 0) == TOKEN_CLASSICAL) {
      return 0;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, 0) == TOKEN_MODULE) {} else {
      return -1;
    }

    long nameEnd = qualifiedNameEnd(source, tokenKinds, tokenStarts, tokenLengths, 1, count);
    if (nameEnd < 0) {
      return -1;
    }

    set(moduleRange, 0, tokenStarts[1]);
    set(moduleRange, 1, tokenStarts[nameEnd] - tokenStarts[1]);
    long cursor = nameEnd + 1;
    long previousStart = 0;
    long previousLength = 0;
    long importCount = 0;
    while (importCount < MAX_MODULE_IMPORTS) limit MAX_MODULE_IMPORTS {
      if (cursor < count) {} else {
        return -1;
      }

      if (tokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_IMPORT) {} else {
        break;
      }

      long importEnd = qualifiedNameEnd(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        cursor + 1,
        count
      );
      if (importEnd < 0) {
        return -1;
      }

      long importStart = tokenStarts[cursor + 1];
      long importLength = tokenStarts[importEnd] - importStart;
      if (0 < importCount) {
        if (
          compareSourceRanges(source, previousStart, previousLength, importStart, importLength) < 0
        ) {} else {
          return -1;
        }
      }

      previousStart = importStart;
      previousLength = importLength;
      cursor = importEnd + 1;
      importCount += 1;
    }

    if (cursor < count) {
      if (tokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_IMPORT) {
        return -1;
      }

      if (tokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_CLASSICAL) {
        return cursor;
      }
    }

    return -1;
  }

  /// Checks whether one validated module directly imports another exact module name.
  public HeaderDependency moduleDependency(
    borrow utf8 candidateSource,
    borrow utf8 dependentSource
  ) {
    region arena = new region(/* bytes= */ HEADER_DEPENDENCY_ARENA_BYTES, /* allocations= */ 8);
    words candidateKinds = allocate(arena, MAX_COMPILER_TOKENS);
    words candidateStarts = allocate(arena, MAX_COMPILER_TOKENS);
    words candidateLengths = allocate(arena, MAX_COMPILER_TOKENS);
    words candidateRange = allocate(arena, 2);
    words dependentKinds = allocate(arena, MAX_COMPILER_TOKENS);
    words dependentStarts = allocate(arena, MAX_COMPILER_TOKENS);
    words dependentLengths = allocate(arena, MAX_COMPILER_TOKENS);
    words dependentRange = allocate(arena, 2);
    long candidateCount = scanHeaderTokens(
      candidateSource,
      candidateKinds,
      candidateStarts,
      candidateLengths
    );
    long dependentCount = scanHeaderTokens(
      dependentSource,
      dependentKinds,
      dependentStarts,
      dependentLengths
    );
    boolean valid = 0 < candidateCount;
    if (valid) {
      valid = 0 < dependentCount;
    }

    if (valid) {
      valid = 0 < moduleBodyStart(
        candidateSource,
        candidateKinds,
        candidateStarts,
        candidateLengths,
        candidateRange,
        candidateCount
      );
    }

    long dependentBody = -1;
    if (valid) {
      dependentBody = moduleBodyStart(
        dependentSource,
        dependentKinds,
        dependentStarts,
        dependentLengths,
        dependentRange,
        dependentCount
      );
      valid = 0 < dependentBody;
    }

    long importCount = 0;
    long candidateImportRank = -1;
    boolean importsCandidate = false;
    if (valid) {
      long moduleEnd = qualifiedNameEnd(
        dependentSource,
        dependentKinds,
        dependentStarts,
        dependentLengths,
        1,
        dependentCount
      );
      long cursor = moduleEnd + 1;
      while (cursor < dependentBody) limit MAX_MODULE_IMPORTS {
        if (
          tokenHash(dependentSource, dependentStarts, dependentLengths, cursor) == TOKEN_IMPORT
        ) {
          long importEnd = qualifiedNameEnd(
            dependentSource,
            dependentKinds,
            dependentStarts,
            dependentLengths,
            cursor + 1,
            dependentCount
          );
          long importStart = dependentStarts[cursor + 1];
          long importLength = dependentStarts[importEnd] - importStart;
          if (
            compareCrossSourceRanges(
              candidateSource,
              candidateRange[0],
              candidateRange[1],
              dependentSource,
              importStart,
              importLength
            ) == 0
          ) {
            candidateImportRank = importCount;
            importsCandidate = true;
          }

          importCount += 1;
          cursor = importEnd + 1;
        } else {
          valid = false;
          cursor = dependentBody;
        }
      }
    }

    drop(dependentRange);
    drop(dependentLengths);
    drop(dependentStarts);
    drop(dependentKinds);
    drop(candidateRange);
    drop(candidateLengths);
    drop(candidateStarts);
    drop(candidateKinds);
    drop(arena);
    return new HeaderDependency(importCount, candidateImportRank, importsCandidate, valid);
  }
}
