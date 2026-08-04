//! Plans canonical string tables for bounded multi-helper libraries.

module wheeler.compiler.library_strings;

import wheeler.compiler.encoding;
import wheeler.compiler.ir;

classical class LibraryStrings {
  private const long CLASS_NAME = 0;
  private const long FIRST_HELPER = 1;
  private const long MAX_HELPERS = 4;
  private const long MAX_STRING_COUNT = MAX_HELPERS + 2;

  /// Defines immutable bounded library string-table plans.
  public record LibraryStringPlan(
    long nameIndex,
    long[4] helperIndices,
    long entryIndex,
    long stringCount,
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

  private long entryCandidate(MinimalProgram program) {
    return program.helperCount + 1;
  }

  private HelperBody candidateHelper(MinimalProgram program, long candidate) {
    return helperAt(program, candidate - FIRST_HELPER);
  }

  private long candidateLength(MinimalProgram program, SourceRange moduleName, long candidate) {
    if (candidate == CLASS_NAME) {
      return program.name.length;
    }

    if (candidate == entryCandidate(program)) {
      return 8;
    }

    HelperBody helper = candidateHelper(program, candidate);
    long length = helper.name.length;
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

    if (candidate == entryCandidate(program)) {
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

    HelperBody helper = candidateHelper(program, candidate);
    return utf8Scalar(source, helper.name.start + helperIndex);
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
    long candidate,
    long stringCount
  ) {
    long index = 0;
    long other = 0;
    while (other < stringCount) limit MAX_STRING_COUNT {
      if (other == candidate) {} else {
        if (compareCandidates(source, program, moduleName, other, candidate) < 0) {
          index += 1;
        }
      }

      other += 1;
    }

    return index;
  }

  /// Computes canonical indices and encoded width for two through four helpers.
  public LibraryStringPlan planLibraryStrings(
    borrow utf8 source,
    MinimalProgram program,
    SourceRange moduleName
  ) {
    long stringCount = program.helperCount + 2;
    long valid = 1;
    if (2 < program.helperCount) {} else {
      if (program.helperCount == 2) {} else {
        valid = 0;
      }
    }

    if (program.helperCount < MAX_HELPERS + 1) {} else {
      valid = 0;
    }

    long left = 0;
    while (left < stringCount) limit MAX_STRING_COUNT {
      long right = left + 1;
      while (right < stringCount) limit MAX_STRING_COUNT {
        if (compareCandidates(source, program, moduleName, left, right) == 0) {
          valid = 0;
        }

        right += 1;
      }

      left += 1;
    }

    long encodedLength = 4 + stringCount * 4;
    long candidate = 0;
    while (candidate < stringCount) limit MAX_STRING_COUNT {
      encodedLength += candidateLength(program, moduleName, candidate);
      candidate += 1;
    }

    long firstIndex = candidateIndex(source, program, moduleName, FIRST_HELPER, stringCount);
    long secondIndex = candidateIndex(
      source,
      program,
      moduleName,
      FIRST_HELPER + 1,
      stringCount
    );
    long thirdIndex = 0;
    long fourthIndex = 0;
    if (2 < program.helperCount) {
      thirdIndex = candidateIndex(source, program, moduleName, FIRST_HELPER + 2, stringCount);
    }

    if (3 < program.helperCount) {
      fourthIndex = candidateIndex(source, program, moduleName, FIRST_HELPER + 3, stringCount);
    }

    long[4] helperIndices = new long[4](firstIndex, secondIndex, thirdIndex, fourthIndex);
    return new LibraryStringPlan(
      candidateIndex(source, program, moduleName, CLASS_NAME, stringCount),
      helperIndices,
      candidateIndex(source, program, moduleName, entryCandidate(program), stringCount),
      stringCount,
      encodedLength,
      valid
    );
  }

  private long candidateForIndex(
    MinimalProgram program,
    LibraryStringPlan plan,
    long stringIndex
  ) {
    if (stringIndex == plan.nameIndex) {
      return CLASS_NAME;
    }

    long helper = 0;
    while (helper < program.helperCount) limit MAX_HELPERS {
      if (stringIndex == plan.helperIndices[helper]) {
        return helper + FIRST_HELPER;
      }

      helper += 1;
    }

    return entryCandidate(program);
  }

  /// Writes one planned canonical bounded library string table.
  public long writeLibraryStrings(
    borrow mut bytes output,
    long cursor,
    borrow utf8 source,
    MinimalProgram program,
    SourceRange moduleName,
    LibraryStringPlan plan
  ) {
    cursor = writeUnsignedLittleEndian(output, cursor, plan.stringCount, 4);
    long stringIndex = 0;
    while (stringIndex < plan.stringCount) limit MAX_STRING_COUNT {
      long candidate = candidateForIndex(program, plan, stringIndex);
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
