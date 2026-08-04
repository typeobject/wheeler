//! Plans the canonical string table for a bounded two-helper library.

module wheeler.compiler.library_strings;

import wheeler.compiler.encoding;
import wheeler.compiler.ir;

classical class LibraryStrings {
  private const long CLASS_NAME = 0;
  private const long FIRST_HELPER = 1;
  private const long SECOND_HELPER = 2;
  private const long LIBRARY_ENTRY = 3;
  private const long STRING_COUNT = 4;

  /// Defines immutable two-helper string-table plans.
  public record TwoHelperStringPlan(
    long nameIndex,
    long firstHelperIndex,
    long secondHelperIndex,
    long entryIndex,
    long encodedLength,
    long valid
  ) {}

  private long libraryScalar(long index) {
    if (index == 0) {
      return 36;
    }

    if (index == 1) {
      return 108;
    }

    if (index == 2) {
      return 105;
    }

    if (index == 3) {
      return 98;
    }

    if (index == 4) {
      return 114;
    }

    if (index == 5) {
      return 97;
    }

    if (index == 6) {
      return 114;
    }

    return 121;
  }

  private SourceRange helperName(MinimalProgram program, long candidate) {
    if (candidate == FIRST_HELPER) {
      return program.helperName;
    }

    return program.secondHelperName;
  }

  private long candidateLength(MinimalProgram program, SourceRange moduleName, long candidate) {
    if (candidate == CLASS_NAME) {
      return program.name.length;
    }

    if (candidate == LIBRARY_ENTRY) {
      return 8;
    }

    SourceRange helper = helperName(program, candidate);
    long length = helper.length;
    if (0 < moduleName.length) {
      length += moduleName.length + 2;
    }

    return length;
  }

  private long candidateScalar(
    borrow utf8 source,
    MinimalProgram program,
    SourceRange moduleName,
    long candidate,
    long index
  ) {
    if (candidate == CLASS_NAME) {
      return utf8Scalar(source, program.name.start + index);
    }

    if (candidate == LIBRARY_ENTRY) {
      return libraryScalar(index);
    }

    if (index < moduleName.length) {
      return utf8Scalar(source, moduleName.start + index);
    }

    long helperIndex = index;
    if (0 < moduleName.length) {
      helperIndex -= moduleName.length;
      if (helperIndex < 2) {
        return 58;
      }

      helperIndex -= 2;
    }

    SourceRange helper = helperName(program, candidate);
    return utf8Scalar(source, helper.start + helperIndex);
  }

  private long compareCandidates(
    borrow utf8 source,
    MinimalProgram program,
    SourceRange moduleName,
    long left,
    long right
  ) {
    long leftLength = candidateLength(program, moduleName, left);
    long rightLength = candidateLength(program, moduleName, right);
    long limit = leftLength;
    if (rightLength < limit) {
      limit = rightLength;
    }

    long index = 0;
    while (index < limit) limit 1024 {
      long difference = candidateScalar(source, program, moduleName, left, index) - candidateScalar(
        source,
        program,
        moduleName,
        right,
        index
      );
      if (difference == 0) {
        index += 1;
      } else {
        return difference;
      }
    }

    return leftLength - rightLength;
  }

  private long candidateIndex(
    borrow utf8 source,
    MinimalProgram program,
    SourceRange moduleName,
    long candidate
  ) {
    long index = 0;
    long other = 0;
    while (other < STRING_COUNT) limit STRING_COUNT {
      if (other == candidate) {} else {
        if (compareCandidates(source, program, moduleName, other, candidate) < 0) {
          index += 1;
        }
      }

      other += 1;
    }

    return index;
  }

  /// Computes canonical indices and encoded width for two helper names and `$library`.
  public TwoHelperStringPlan planTwoHelperStrings(
    borrow utf8 source,
    MinimalProgram program,
    SourceRange moduleName
  ) {
    long valid = 1;
    long left = 0;
    while (left < STRING_COUNT) limit STRING_COUNT {
      long right = left + 1;
      while (right < STRING_COUNT) limit STRING_COUNT {
        if (compareCandidates(source, program, moduleName, left, right) == 0) {
          valid = 0;
        }

        right += 1;
      }

      left += 1;
    }

    long encodedLength = 4 + STRING_COUNT * 4;
    long candidate = 0;
    while (candidate < STRING_COUNT) limit STRING_COUNT {
      encodedLength += candidateLength(program, moduleName, candidate);
      candidate += 1;
    }

    return new TwoHelperStringPlan(
      candidateIndex(source, program, moduleName, CLASS_NAME),
      candidateIndex(source, program, moduleName, FIRST_HELPER),
      candidateIndex(source, program, moduleName, SECOND_HELPER),
      candidateIndex(source, program, moduleName, LIBRARY_ENTRY),
      encodedLength,
      valid
    );
  }

  private long candidateForIndex(TwoHelperStringPlan plan, long stringIndex) {
    if (stringIndex == plan.nameIndex) {
      return CLASS_NAME;
    }

    if (stringIndex == plan.firstHelperIndex) {
      return FIRST_HELPER;
    }

    if (stringIndex == plan.secondHelperIndex) {
      return SECOND_HELPER;
    }

    return LIBRARY_ENTRY;
  }

  /// Writes one planned canonical two-helper string table.
  public long writeTwoHelperStrings(
    borrow mut bytes output,
    long cursor,
    borrow utf8 source,
    MinimalProgram program,
    SourceRange moduleName,
    TwoHelperStringPlan plan
  ) {
    cursor = writeUnsignedLittleEndian(output, cursor, STRING_COUNT, 4);
    long stringIndex = 0;
    while (stringIndex < STRING_COUNT) limit STRING_COUNT {
      long candidate = candidateForIndex(plan, stringIndex);
      long length = candidateLength(program, moduleName, candidate);
      cursor = writeUnsignedLittleEndian(output, cursor, length, 4);
      long scalar = 0;
      while (scalar < length) limit 1024 {
        setByte(
          output,
          cursor,
          candidateScalar(source, program, moduleName, candidate, scalar)
        );
        cursor += 1;
        scalar += 1;
      }

      stringIndex += 1;
    }

    return cursor;
  }
}
