//! Plans canonical string tables for bounded multi-helper libraries.

module wheeler.compiler.library_strings;

import wheeler.compiler.encoding;
import wheeler.compiler.helper_abi;
import wheeler.compiler.ir;

classical class LibraryStrings {
  private const long CLASS_NAME = 0;
  private const long FIRST_HELPER = 1;
  private const long MAX_HELPERS = MAX_SCALAR_HELPERS;
  private const long MAX_STRING_COUNT = MAX_HELPERS + 2;

  /// Defines immutable bounded library string-table plans.
  public record LibraryStringPlan(
    long nameIndex,
    long[23] helperIndices,
    long entryIndex,
    long stringCount,
    long encodedLength,
    long valid
  ) {}

  /// Assigns bounded imported helper groups to their canonical modules.
  public record HelperOwners(
    SourceRange firstModule,
    long firstHelperCount,
    SourceRange secondModule,
    long secondHelperCount,
    SourceRange thirdModule,
    long thirdHelperCount,
    SourceRange fourthModule,
    long fourthHelperCount
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

  private SourceRange candidateModule(
    SourceRange rootModule,
    HelperOwners owners,
    long candidate
  ) {
    long helper = candidate - FIRST_HELPER;
    if (-1 < helper) {
      if (helper < owners.firstHelperCount) {
        return owners.firstModule;
      }

      if (helper < owners.firstHelperCount + owners.secondHelperCount) {
        return owners.secondModule;
      }

      if (
        helper < owners.firstHelperCount + owners.secondHelperCount + owners.thirdHelperCount
      ) {
        return owners.thirdModule;
      }

      if (
        helper < owners.firstHelperCount + owners.secondHelperCount + owners.thirdHelperCount
          + owners.fourthHelperCount
      ) {
        return owners.fourthModule;
      }
    }

    return rootModule;
  }

  private long candidateLength(
    MinimalProgram program,
    SourceRange rootModule,
    HelperOwners owners,
    long candidate
  ) {
    if (candidate == CLASS_NAME) {
      return program.name.length;
    }

    if (candidate == entryCandidate(program)) {
      return 8;
    }

    HelperBody helper = candidateHelper(program, candidate);
    SourceRange moduleName = candidateModule(rootModule, owners, candidate);
    long length = helper.name.length;
    if (0 < moduleName.length) {
      length += moduleName.length + 2;
    }

    return length;
  }

  private long candidateScalar(
    borrow utf8 source,
    MinimalProgram program,
    SourceRange rootModule,
    HelperOwners owners,
    long candidate,
    long index
  ) {
    if (candidate == CLASS_NAME) {
      return utf8Scalar(source, program.name.start + index);
    }

    if (candidate == entryCandidate(program)) {
      return libraryScalar(index);
    }

    SourceRange moduleName = candidateModule(rootModule, owners, candidate);
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
    SourceRange rootModule,
    HelperOwners owners,
    long left,
    long right
  ) {
    long leftLength = candidateLength(program, rootModule, owners, left);
    long rightLength = candidateLength(program, rootModule, owners, right);
    long limit = leftLength;
    if (rightLength < limit) {
      limit = rightLength;
    }

    long index = 0;
    while (index < limit) limit 1024 {
      long difference = candidateScalar(source, program, rootModule, owners, left, index)
        - candidateScalar(
        source,
        program,
        rootModule,
        owners,
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
    SourceRange rootModule,
    HelperOwners owners,
    long candidate,
    long stringCount
  ) {
    long index = 0;
    long other = 0;
    while (other < stringCount) limit MAX_STRING_COUNT {
      if (other == candidate) {} else {
        if (
          compareCandidates(source, program, rootModule, owners, other, candidate) < 0
        ) {
          index += 1;
        }
      }

      other += 1;
    }

    return index;
  }

  /// Computes canonical indices and encoded width for two through twenty-three helpers.
  public LibraryStringPlan planLibraryStrings(
    borrow utf8 source,
    MinimalProgram program,
    SourceRange rootModule,
    HelperOwners owners
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

    long importedHelperCount = owners.firstHelperCount + owners.secondHelperCount
      + owners.thirdHelperCount + owners.fourthHelperCount;
    if (importedHelperCount < program.helperCount + 1) {} else {
      valid = 0;
    }

    if (0 < owners.firstHelperCount) {
      if (0 < owners.firstModule.length) {} else {
        valid = 0;
      }
    }

    if (0 < owners.secondHelperCount) {
      if (0 < owners.secondModule.length) {} else {
        valid = 0;
      }
    }

    if (0 < owners.thirdHelperCount) {
      if (0 < owners.thirdModule.length) {} else {
        valid = 0;
      }
    }

    if (0 < owners.fourthHelperCount) {
      if (0 < owners.fourthModule.length) {} else {
        valid = 0;
      }
    }

    long left = 0;
    while (left < stringCount) limit MAX_STRING_COUNT {
      long right = left + 1;
      while (right < stringCount) limit MAX_STRING_COUNT {
        if (
          compareCandidates(source, program, rootModule, owners, left, right) == 0
        ) {
          valid = 0;
        }

        right += 1;
      }

      left += 1;
    }

    long encodedLength = 4 + stringCount * 4;
    long candidate = 0;
    while (candidate < stringCount) limit MAX_STRING_COUNT {
      encodedLength += candidateLength(program, rootModule, owners, candidate);
      candidate += 1;
    }

    long firstIndex = candidateIndex(
      source,
      program,
      rootModule,
      owners,
      FIRST_HELPER,
      stringCount
    );
    long secondIndex = candidateIndex(
      source,
      program,
      rootModule,
      owners,
      FIRST_HELPER + 1,
      stringCount
    );
    long thirdIndex = 0;
    long fourthIndex = 0;
    long fifthIndex = 0;
    long sixthIndex = 0;
    long seventhIndex = 0;
    long eighthIndex = 0;
    long ninthIndex = 0;
    long tenthIndex = 0;
    long eleventhIndex = 0;
    long twelfthIndex = 0;
    long thirteenthIndex = 0;
    long fourteenthIndex = 0;
    long fifteenthIndex = 0;
    long sixteenthIndex = 0;
    long seventeenthIndex = 0;
    long eighteenthIndex = 0;
    long nineteenthIndex = 0;
    long twentiethIndex = 0;
    long twentyFirstIndex = 0;
    long twentySecondIndex = 0;
    long twentyThirdIndex = 0;
    if (2 < program.helperCount) {
      thirdIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 2,
        stringCount
      );
    }

    if (3 < program.helperCount) {
      fourthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 3,
        stringCount
      );
    }

    if (4 < program.helperCount) {
      fifthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 4,
        stringCount
      );
    }

    if (5 < program.helperCount) {
      sixthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 5,
        stringCount
      );
    }

    if (6 < program.helperCount) {
      seventhIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 6,
        stringCount
      );
    }

    if (7 < program.helperCount) {
      eighthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 7,
        stringCount
      );
    }

    if (8 < program.helperCount) {
      ninthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 8,
        stringCount
      );
    }

    if (9 < program.helperCount) {
      tenthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 9,
        stringCount
      );
    }

    if (10 < program.helperCount) {
      eleventhIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 10,
        stringCount
      );
    }

    if (11 < program.helperCount) {
      twelfthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 11,
        stringCount
      );
    }

    if (12 < program.helperCount) {
      thirteenthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 12,
        stringCount
      );
    }

    if (13 < program.helperCount) {
      fourteenthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 13,
        stringCount
      );
    }

    if (14 < program.helperCount) {
      fifteenthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 14,
        stringCount
      );
    }

    if (15 < program.helperCount) {
      sixteenthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 15,
        stringCount
      );
    }

    if (16 < program.helperCount) {
      seventeenthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 16,
        stringCount
      );
    }

    if (17 < program.helperCount) {
      eighteenthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 17,
        stringCount
      );
    }

    if (18 < program.helperCount) {
      nineteenthIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 18,
        stringCount
      );
    }

    if (19 < program.helperCount) {
      twentiethIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 19,
        stringCount
      );
    }

    if (20 < program.helperCount) {
      twentyFirstIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 20,
        stringCount
      );
    }

    if (21 < program.helperCount) {
      twentySecondIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 21,
        stringCount
      );
    }

    if (22 < program.helperCount) {
      twentyThirdIndex = candidateIndex(
        source,
        program,
        rootModule,
        owners,
        FIRST_HELPER + 22,
        stringCount
      );
    }

    long[23] helperIndices = new long[23](
      firstIndex,
      secondIndex,
      thirdIndex,
      fourthIndex,
      fifthIndex,
      sixthIndex,
      seventhIndex,
      eighthIndex,
      ninthIndex,
      tenthIndex,
      eleventhIndex,
      twelfthIndex,
      thirteenthIndex,
      fourteenthIndex,
      fifteenthIndex,
      sixteenthIndex,
      seventeenthIndex,
      eighteenthIndex,
      nineteenthIndex,
      twentiethIndex,
      twentyFirstIndex,
      twentySecondIndex,
      twentyThirdIndex
    );
    return new LibraryStringPlan(
      candidateIndex(source, program, rootModule, owners, CLASS_NAME, stringCount),
      helperIndices,
      candidateIndex(
        source,
        program,
        rootModule,
        owners,
        entryCandidate(program),
        stringCount
      ),
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
    SourceRange rootModule,
    HelperOwners owners,
    LibraryStringPlan plan
  ) {
    cursor = writeUnsignedLittleEndian(output, cursor, plan.stringCount, 4);
    long stringIndex = 0;
    while (stringIndex < plan.stringCount) limit MAX_STRING_COUNT {
      long candidate = candidateForIndex(program, plan, stringIndex);
      long length = candidateLength(program, rootModule, owners, candidate);
      cursor = writeUnsignedLittleEndian(output, cursor, length, 4);
      long scalar = 0;
      while (scalar < length) limit 1024 {
        setByte(
          output,
          cursor,
          candidateScalar(source, program, rootModule, owners, candidate, scalar)
        );
        cursor += 1;
        scalar += 1;
      }

      stringIndex += 1;
    }

    return cursor;
  }
}
