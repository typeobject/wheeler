//! Counts and copies canonical module qualifications from retained scanner tokens.

module wheeler.compiler.module_qualifications;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class ModuleQualifications {
  /// Caps one linked source without widening the physical input lease.
  public const long MAX_LINKED_SOURCE_BYTES = 36864;
  /// Caps canonical qualification rewrites in one linked root.
  public const long MAX_LINKED_QUALIFICATIONS = 64;
  /// Names the two-byte canonical module separator.
  public const long QUALIFICATION_SEPARATOR_BYTES = 2;

  /// Retains the admitted module span and its measured canonical qualification count.
  public record ImportedQualification(long start, long length, long count) {}

  /// Carries one admitted name span in the imported source.
  public record QualifiedNameSpan(long start, long length) {}

  /// Retains one root byte window, destination cursor, and complete scanner count.
  public record QualifiedRootWindow(long start, long length, long outputStart, long tokenCount) {}

  /// Compares two admitted ASCII spans without allocating name storage.
  public boolean rangesEqual(
    borrow utf8 leftSource,
    long leftStart,
    long leftLength,
    borrow utf8 rightSource,
    long rightStart,
    long rightLength
  ) {
    if (leftLength == rightLength) {} else {
      return false;
    }

    long cursor = 0;
    while (cursor < leftLength) limit MAX_QUALIFIED_NAME_BYTES {
      if (
        utf8Scalar(leftSource, leftStart + cursor) == utf8Scalar(rightSource, rightStart + cursor)
      ) {} else {
        return false;
      }

      if (utf8Width(leftSource, leftStart + cursor) == 1) {} else {
        return false;
      }

      if (utf8Width(rightSource, rightStart + cursor) == 1) {} else {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  private boolean qualificationWindowValid(
    borrow utf8 importedSource,
    ImportedQualification moduleName,
    borrow utf8 rootSource,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    if (count < 0) {
      return false;
    }

    if (MAX_COMPILER_TOKENS < count) {
      return false;
    }

    if (bufferLength(kinds) < count) {
      return false;
    }

    if (bufferLength(starts) < count) {
      return false;
    }

    if (bufferLength(lengths) < count) {
      return false;
    }

    if (moduleName.start < 0) {
      return false;
    }

    if (moduleName.length < 1) {
      return false;
    }

    if (MAX_QUALIFIED_NAME_BYTES < moduleName.length) {
      return false;
    }

    if (bufferLength(importedSource) - moduleName.start < moduleName.length) {
      return false;
    }

    return bufferLength(rootSource) < MAX_LINKED_SOURCE_BYTES + 1;
  }

  private long qualifiedNameToken(
    borrow utf8 importedSource,
    ImportedQualification moduleName,
    borrow utf8 rootSource,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long first
  ) {
    if (kinds[first] == 1) {} else {
      return -1;
    }

    if (0 < first) {
      if (punctuationAt(rootSource, kinds, starts, first - 1, PUNCTUATION_DOT)) {
        return -1;
      }

      if (punctuationAt(rootSource, kinds, starts, first - 1, PUNCTUATION_COLON)) {
        return -1;
      }
    }

    long start = starts[first];
    if (
      bufferLength(rootSource) - start < moduleName.length + QUALIFICATION_SEPARATOR_BYTES
    ) {
      return -1;
    }

    if (
      rangesEqual(
        importedSource,
        moduleName.start,
        moduleName.length,
        rootSource,
        start,
        moduleName.length
      )
    ) {} else {
      return -1;
    }

    long end = start + moduleName.length;
    long colon = first;
    while (colon < count) limit MAX_QUALIFIED_NAME_TOKENS {
      if (end < starts[colon] + 1) {
        break;
      }

      colon += 1;
    }

    if (colon + 2 < count) {} else {
      return -1;
    }

    if (starts[colon] == end) {} else {
      return -1;
    }

    if (punctuationAt(rootSource, kinds, starts, colon, PUNCTUATION_COLON)) {} else {
      return -1;
    }

    if (starts[colon + 1] == end + 1) {} else {
      return -1;
    }

    if (punctuationAt(rootSource, kinds, starts, colon + 1, PUNCTUATION_COLON)) {} else {
      return -1;
    }

    if (kinds[colon + 2] == 1) {
      return colon + 2;
    }

    return -1;
  }

  /// Counts complete namespace tokens, excluding comments, strings, and name suffixes.
  public long qualificationCount(
    borrow utf8 importedSource,
    long moduleStart,
    long moduleLength,
    borrow utf8 rootSource,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    ImportedQualification moduleName = new ImportedQualification(moduleStart, moduleLength, 0);
    if (
      qualificationWindowValid(
        importedSource,
        moduleName,
        rootSource,
        kinds,
        starts,
        lengths,
        count
      )
    ) {} else {
      return -1;
    }

    long byteCursor = 0;
    while (byteCursor < bufferLength(rootSource)) limit MAX_LINKED_SOURCE_BYTES {
      if (utf8Width(rootSource, byteCursor) == 1) {} else {
        return -1;
      }

      byteCursor += 1;
    }

    long token = 0;
    long found = 0;
    while (token < count) limit MAX_COMPILER_TOKENS {
      long name = qualifiedNameToken(
        importedSource,
        moduleName,
        rootSource,
        kinds,
        starts,
        lengths,
        count,
        token
      );
      if (-1 < name) {
        found += 1;
        if (MAX_LINKED_QUALIFICATIONS < found) {
          return -1;
        }

        token = name + 1;
      } else {
        token += 1;
      }
    }

    return found;
  }

  /// Rejects qualified private references even when an exact local declaration is shared.
  /// The module count and scanner coordinates must belong to this root source.
  public boolean qualifiedPrivateNameUsed(
    borrow utf8 importedSource,
    ImportedQualification moduleName,
    QualifiedNameSpan nameSpan,
    borrow utf8 rootSource,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    if (
      qualificationWindowValid(
        importedSource,
        moduleName,
        rootSource,
        kinds,
        starts,
        lengths,
        count
      )
    ) {} else {
      return true;
    }

    if (moduleName.count < 0) {
      return true;
    }

    if (MAX_LINKED_QUALIFICATIONS < moduleName.count) {
      return true;
    }

    if (nameSpan.start < 0) {
      return true;
    }

    if (nameSpan.length < 1) {
      return true;
    }

    if (MAX_QUALIFIED_NAME_BYTES < nameSpan.length) {
      return true;
    }

    if (bufferLength(importedSource) - nameSpan.start < nameSpan.length) {
      return true;
    }

    if (moduleName.count == 0) {
      return false;
    }

    long token = 0;
    while (token < count) limit MAX_COMPILER_TOKENS {
      long name = qualifiedNameToken(
        importedSource,
        moduleName,
        rootSource,
        kinds,
        starts,
        lengths,
        count,
        token
      );
      if (-1 < name) {
        if (
          rangesEqual(
            importedSource,
            nameSpan.start,
            nameSpan.length,
            rootSource,
            starts[name],
            lengths[name]
          )
        ) {
          return true;
        }

        token = name + 1;
      } else {
        token += 1;
      }
    }

    return false;
  }

  /// Copies one private staging window using the same qualification matcher as measurement.
  /// Failure may retain a private prefix. The enclosing linker owns publication.
  public long copyLinkedRootAscii(
    borrow utf8 importedSource,
    ImportedQualification moduleName,
    borrow utf8 rootSource,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    QualifiedRootWindow window,
    borrow mut bytes output
  ) {
    if (
      qualificationWindowValid(
        importedSource,
        moduleName,
        rootSource,
        kinds,
        starts,
        lengths,
        window.tokenCount
      )
    ) {} else {
      return -1;
    }

    if (window.start < 0) {
      return -1;
    }

    if (window.length < 0) {
      return -1;
    }

    if (bufferLength(rootSource) - window.start < window.length) {
      return -1;
    }

    if (window.outputStart < 0) {
      return -1;
    }

    if (bufferLength(output) < window.outputStart) {
      return -1;
    }

    long cursor = window.start;
    long end = cursor + window.length;
    long outputCursor = window.outputStart;
    long token = 0;
    while (cursor < end) limit MAX_LINKED_SOURCE_BYTES {
      while (token < window.tokenCount) limit MAX_COMPILER_TOKENS {
        if (cursor < starts[token] + 1) {
          break;
        }

        token += 1;
      }

      long name = -1;
      if (token < window.tokenCount) {
        if (starts[token] == cursor) {
          name = qualifiedNameToken(
            importedSource,
            moduleName,
            rootSource,
            kinds,
            starts,
            lengths,
            window.tokenCount,
            token
          );
        }
      }

      if (-1 < name) {
        long next = cursor + moduleName.length + QUALIFICATION_SEPARATOR_BYTES;
        if (end < next) {
          return -1;
        }

        cursor = next;
        token = name;
      } else {
        if (utf8Width(rootSource, cursor) == 1) {} else {
          return -1;
        }

        setByte(output, outputCursor, utf8Scalar(rootSource, cursor));
        outputCursor += 1;
        cursor += 1;
      }
    }

    return outputCursor;
  }
}
