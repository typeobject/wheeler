//! Plans and emits the canonical artifact string table.

module wheeler.compiler.string_table;

import wheeler.compiler.encoding;
import wheeler.compiler.ir;

classical class StringTable {
  private long entrySuffixLength(boolean library) {
    if (library) {
      return 8;
    }

    return 4;
  }

  private long entryScalar(
    borrow utf8 source,
    SourceRange moduleName,
    boolean library,
    long index
  ) {
    if (library == false) {
      if (index < moduleName.length) {
        return utf8Scalar(source, moduleName.start + index);
      }
    }

    long suffix = index;
    if (library == false) {
      suffix -= moduleName.length;
      if (0 < moduleName.length) {
        if (suffix < 2) {
          return 58;
        }

        suffix -= 2;
      }
    }

    if (library) {
      if (suffix == 0) {
        return 36;
      }

      if (suffix == 1) {
        return 108;
      }

      if (suffix == 2) {
        return 105;
      }

      if (suffix == 3) {
        return 98;
      }

      if (suffix == 4) {
        return 114;
      }

      if (suffix == 5) {
        return 97;
      }

      if (suffix == 6) {
        return 114;
      }

      return 121;
    }

    if (suffix == 0) {
      return 109;
    }

    if (suffix == 1) {
      return 97;
    }

    if (suffix == 2) {
      return 105;
    }

    return 110;
  }

  private long compareAsciiSliceToEntry(
    borrow utf8 source,
    long start,
    long length,
    SourceRange moduleName,
    boolean library
  ) {
    long entryLength = entrySuffixLength(library);
    if (library == false) {
      if (0 < moduleName.length) {
        entryLength += moduleName.length + 2;
      }
    }

    long limit = length;
    if (entryLength < limit) {
      limit = entryLength;
    }

    long cursor = 0;
    while (cursor < limit) limit 512 {
      long difference = utf8Scalar(source, start + cursor) - entryScalar(
        source,
        moduleName,
        library,
        cursor
      );
      if (difference == 0) {
        cursor += 1;
      } else {
        return difference;
      }
    }

    return length - entryLength;
  }

  private long helperScalar(
    borrow utf8 source,
    SourceRange moduleName,
    SourceRange helperName,
    long index
  ) {
    if (index < moduleName.length) {
      return utf8Scalar(source, moduleName.start + index);
    }

    long suffix = index - moduleName.length;
    if (0 < moduleName.length) {
      if (suffix < 2) {
        return 58;
      }

      suffix -= 2;
    }

    return utf8Scalar(source, helperName.start + suffix);
  }

  private long compareAsciiSliceToHelper(
    borrow utf8 source,
    long start,
    long length,
    SourceRange moduleName,
    SourceRange helperName
  ) {
    long helperLength = helperName.length;
    if (0 < moduleName.length) {
      helperLength += moduleName.length + 2;
    }

    long limit = length;
    if (helperLength < limit) {
      limit = helperLength;
    }

    long cursor = 0;
    while (cursor < limit) limit 512 {
      long difference = utf8Scalar(source, start + cursor) - helperScalar(
        source,
        moduleName,
        helperName,
        cursor
      );
      if (difference == 0) {
        cursor += 1;
      } else {
        return difference;
      }
    }

    return length - helperLength;
  }

  private long compareHelperToEntry(
    borrow utf8 source,
    SourceRange moduleName,
    SourceRange helperName,
    boolean library
  ) {
    long helperLength = helperName.length;
    long entryLength = entrySuffixLength(library);
    if (0 < moduleName.length) {
      helperLength += moduleName.length + 2;
      if (library == false) {
        entryLength += moduleName.length + 2;
      }
    }

    long limit = helperLength;
    if (entryLength < limit) {
      limit = entryLength;
    }

    long cursor = 0;
    while (cursor < limit) limit 512 {
      long difference = helperScalar(source, moduleName, helperName, cursor) - entryScalar(
        source,
        moduleName,
        library,
        cursor
      );
      if (difference == 0) {
        cursor += 1;
      } else {
        return difference;
      }
    }

    return helperLength - entryLength;
  }

  /// Defines immutable `StringTablePlan` values for this module.
  public record StringTablePlan(
    long nameIndex,
    long globalIndex,
    long helperIndex,
    long proofIndex,
    long mainIndex,
    long stringCount,
    long encodedLength,
    long valid
  ) {}

  private StringTablePlan planNoGlobalHelper(
    borrow utf8 source,
    MinimalProgram program,
    SourceRange moduleName,
    long nameMainOrder,
    long nameLength,
    long helperLength
  ) {
    long nameHelperOrder = compareAsciiSliceToHelper(
      source,
      program.name.start,
      nameLength,
      moduleName,
      helperAt(program, 0).name
    );
    long helperMainOrder = compareHelperToEntry(
      source,
      moduleName,
      helperAt(program, 0).name,
      program.library
    );
    long valid = 1;
    if (nameMainOrder == 0) {
      valid = 0;
    }

    if (nameHelperOrder == 0) {
      valid = 0;
    }

    if (helperMainOrder == 0) {
      valid = 0;
    }

    long nameIndex = 0;
    long helperIndex = 0;
    long mainIndex = 0;
    if (0 < nameMainOrder) {
      nameIndex += 1;
    } else {
      mainIndex += 1;
    }

    if (0 < nameHelperOrder) {
      nameIndex += 1;
    } else {
      helperIndex += 1;
    }

    if (0 < helperMainOrder) {
      helperIndex += 1;
    } else {
      mainIndex += 1;
    }

    long proofIndex = 0;
    long stringCount = 3;
    long proofExtra = 0;
    if (program.proofCount == 1) {
      long proofLength = program.proofName.length;
      long nameProofOrder = compareAsciiSlices(
        source,
        program.name.start,
        nameLength,
        program.proofName.start,
        proofLength
      );
      long helperProofOrder = 0 - compareAsciiSliceToHelper(
        source,
        program.proofName.start,
        proofLength,
        moduleName,
        helperAt(program, 0).name
      );
      long proofMainOrder = compareAsciiSliceToEntry(
        source,
        program.proofName.start,
        proofLength,
        moduleName,
        program.library
      );
      if (nameProofOrder == 0) {
        valid = 0;
      }

      if (helperProofOrder == 0) {
        valid = 0;
      }

      if (proofMainOrder == 0) {
        valid = 0;
      }

      if (0 < nameProofOrder) {
        nameIndex += 1;
      } else {
        proofIndex += 1;
      }

      if (0 < helperProofOrder) {
        helperIndex += 1;
      } else {
        proofIndex += 1;
      }

      if (proofMainOrder < 0) {
        mainIndex += 1;
      } else {
        proofIndex += 1;
      }

      stringCount = 4;
      proofExtra = proofLength + 4;
    }

    long modulePrefixLength = 0;
    if (0 < moduleName.length) {
      modulePrefixLength = moduleName.length + 2;
    }

    long entrySuffixExtra = 0;
    long qualifiedPrefixLength = modulePrefixLength * 2;
    if (program.library) {
      entrySuffixExtra = 4;
      qualifiedPrefixLength = modulePrefixLength;
    }

    return new StringTablePlan(
      nameIndex,
      0,
      helperIndex,
      proofIndex,
      mainIndex,
      stringCount,
      20 + nameLength + helperLength + qualifiedPrefixLength + proofExtra + entrySuffixExtra,
      valid
    );
  }

  /// Computes canonical string offsets and total encoded table length.
  public StringTablePlan planStringTable(
    borrow utf8 source,
    MinimalProgram program,
    SourceRange moduleName
  ) {
    long nameLength = program.name.length;
    long globalLength = program.global.length;
    long helperLength = helperAt(program, 0).name.length;
    long proofLength = program.proofName.length;
    long nameMainOrder = compareAsciiSliceToEntry(
      source,
      program.name.start,
      nameLength,
      moduleName,
      program.library
    );
    long valid = 1;
    if (nameMainOrder == 0) {
      valid = 0;
    }

    long nameIndex = 0;
    long globalIndex = 0;
    long helperIndex = 0;
    long proofIndex = 0;
    long mainIndex = 0;
    if (0 < nameMainOrder) {
      nameIndex = 1;
    }

    if (nameMainOrder < 0) {
      mainIndex = 1;
    }

    long stringCount = 2;
    long entryExtra = 0;
    if (program.library) {
      entryExtra = 4;
    } else {
      if (0 < moduleName.length) {
        entryExtra = moduleName.length + 2;
      }
    }

    long encodedLength = 16 + nameLength + entryExtra;
    if (program.helperCount == 1) {
      if (program.globalCount == 0) {
        return planNoGlobalHelper(
          source,
          program,
          moduleName,
          nameMainOrder,
          nameLength,
          helperLength
        );
      }
    }

    if (program.globalCount == 1) {
      long baseNameGlobalOrder = compareAsciiSlices(
        source,
        program.name.start,
        nameLength,
        program.global.start,
        globalLength
      );
      long baseGlobalMainOrder = compareAsciiSliceToEntry(
        source,
        program.global.start,
        globalLength,
        moduleName,
        program.library
      );
      if (baseNameGlobalOrder == 0) {
        valid = 0;
      }

      if (baseGlobalMainOrder == 0) {
        valid = 0;
      }

      nameIndex = 0;
      globalIndex = 0;
      mainIndex = 0;
      if (0 < baseNameGlobalOrder) {
        nameIndex += 1;
      }

      if (0 < nameMainOrder) {
        nameIndex += 1;
      }

      if (baseNameGlobalOrder < 0) {
        globalIndex += 1;
      }

      if (0 < baseGlobalMainOrder) {
        globalIndex += 1;
      }

      if (nameMainOrder < 0) {
        mainIndex += 1;
      }

      if (baseGlobalMainOrder < 0) {
        mainIndex += 1;
      }

      stringCount = 3;
      encodedLength = 20 + nameLength + globalLength + entryExtra;
    }

    if (program.helperCount == 1) {
      long nameGlobalOrder = compareAsciiSlices(
        source,
        program.name.start,
        nameLength,
        program.global.start,
        globalLength
      );
      long globalMainOrder = compareAsciiSliceToEntry(
        source,
        program.global.start,
        globalLength,
        moduleName,
        program.library
      );
      long nameHelperOrder = compareAsciiSliceToHelper(
        source,
        program.name.start,
        nameLength,
        moduleName,
        helperAt(program, 0).name
      );
      long globalHelperOrder = compareAsciiSliceToHelper(
        source,
        program.global.start,
        globalLength,
        moduleName,
        helperAt(program, 0).name
      );
      long helperMainOrder = compareHelperToEntry(
        source,
        moduleName,
        helperAt(program, 0).name,
        program.library
      );
      if (nameGlobalOrder == 0) {
        valid = 0;
      }

      if (globalMainOrder == 0) {
        valid = 0;
      }

      if (nameHelperOrder == 0) {
        valid = 0;
      }

      if (globalHelperOrder == 0) {
        valid = 0;
      }

      if (helperMainOrder == 0) {
        valid = 0;
      }

      nameIndex = 0;
      globalIndex = 0;
      helperIndex = 0;
      mainIndex = 0;
      if (0 < nameGlobalOrder) {
        nameIndex += 1;
      }

      if (0 < nameMainOrder) {
        nameIndex += 1;
      }

      if (0 < nameHelperOrder) {
        nameIndex += 1;
      }

      if (nameGlobalOrder < 0) {
        globalIndex += 1;
      }

      if (0 < globalMainOrder) {
        globalIndex += 1;
      }

      if (0 < globalHelperOrder) {
        globalIndex += 1;
      }

      if (nameMainOrder < 0) {
        mainIndex += 1;
      }

      if (globalMainOrder < 0) {
        mainIndex += 1;
      }

      if (helperMainOrder < 0) {
        mainIndex += 1;
      }

      if (nameHelperOrder < 0) {
        helperIndex += 1;
      }

      if (globalHelperOrder < 0) {
        helperIndex += 1;
      }

      if (0 < helperMainOrder) {
        helperIndex += 1;
      }

      stringCount = 4;
      encodedLength = 24 + nameLength + globalLength + helperLength + entryExtra;
      if (0 < moduleName.length) {
        encodedLength += moduleName.length + 2;
      }
    }

    if (program.proofCount == 1) {
      long proofNameOrder = compareAsciiSlices(
        source,
        program.name.start,
        nameLength,
        program.proofName.start,
        proofLength
      );
      long proofGlobalOrder = compareAsciiSlices(
        source,
        program.global.start,
        globalLength,
        program.proofName.start,
        proofLength
      );
      long proofHelperOrder = 0 - compareAsciiSliceToHelper(
        source,
        program.proofName.start,
        proofLength,
        moduleName,
        helperAt(program, 0).name
      );
      long proofMainOrder = compareAsciiSliceToEntry(
        source,
        program.proofName.start,
        proofLength,
        moduleName,
        program.library
      );
      if (proofNameOrder == 0) {
        valid = 0;
      }

      if (proofGlobalOrder == 0) {
        valid = 0;
      }

      if (proofHelperOrder == 0) {
        valid = 0;
      }

      if (proofMainOrder == 0) {
        valid = 0;
      }

      if (0 < proofNameOrder) {
        nameIndex += 1;
      } else {
        proofIndex += 1;
      }

      if (0 < proofGlobalOrder) {
        globalIndex += 1;
      } else {
        proofIndex += 1;
      }

      if (0 < proofHelperOrder) {
        helperIndex += 1;
      } else {
        proofIndex += 1;
      }

      if (proofMainOrder < 0) {
        mainIndex += 1;
      } else {
        proofIndex += 1;
      }

      stringCount = 5;
      encodedLength = 28 + nameLength + globalLength + helperLength + proofLength + entryExtra;
      if (0 < moduleName.length) {
        encodedLength += moduleName.length + 2;
      }
    }

    return new StringTablePlan(
      nameIndex,
      globalIndex,
      helperIndex,
      proofIndex,
      mainIndex,
      stringCount,
      encodedLength,
      valid
    );
  }

  /// Writes `stringTable` into caller-owned bounded output.
  public long writeStringTable(
    borrow mut bytes output,
    long cursor,
    borrow utf8 source,
    MinimalProgram program,
    SourceRange moduleName,
    StringTablePlan plan
  ) {
    cursor = writeUnsignedLittleEndian(output, cursor, plan.stringCount, 4);
    long stringIndex = 0;
    while (stringIndex < plan.stringCount) limit 5 {
      if (stringIndex == plan.nameIndex) {
        cursor = writeUnsignedLittleEndian(output, cursor, program.name.length, 4);
        cursor = writeAsciiSlice(
          output,
          cursor,
          source,
          program.name.start,
          program.name.length
        );
      }

      if (program.globalCount == 1) {
        if (stringIndex == plan.globalIndex) {
          cursor = writeUnsignedLittleEndian(output, cursor, program.global.length, 4);
          cursor = writeAsciiSlice(
            output,
            cursor,
            source,
            program.global.start,
            program.global.length
          );
        }
      }

      if (program.helperCount == 1) {
        if (stringIndex == plan.helperIndex) {
          long helperOutputLength = helperAt(program, 0).name.length;
          if (0 < moduleName.length) {
            helperOutputLength += moduleName.length + 2;
          }

          cursor = writeUnsignedLittleEndian(output, cursor, helperOutputLength, 4);
          if (0 < moduleName.length) {
            cursor = writeAsciiSlice(
              output,
              cursor,
              source,
              moduleName.start,
              moduleName.length
            );
            setByte(output, cursor, 58);
            setByte(output, cursor + 1, 58);
            cursor += 2;
          }

          cursor = writeAsciiSlice(
            output,
            cursor,
            source,
            helperAt(program, 0).name.start,
            helperAt(program, 0).name.length
          );
        }
      }

      if (program.proofCount == 1) {
        if (stringIndex == plan.proofIndex) {
          cursor = writeUnsignedLittleEndian(output, cursor, program.proofName.length, 4);
          cursor = writeAsciiSlice(
            output,
            cursor,
            source,
            program.proofName.start,
            program.proofName.length
          );
        }
      }

      if (stringIndex == plan.mainIndex) {
        long entryLength = entrySuffixLength(program.library);
        if (program.library == false) {
          if (0 < moduleName.length) {
            entryLength += moduleName.length + 2;
          }
        }

        cursor = writeUnsignedLittleEndian(output, cursor, entryLength, 4);
        if (0 < moduleName.length) {
          if (program.library == false) {
            cursor = writeAsciiSlice(
              output,
              cursor,
              source,
              moduleName.start,
              moduleName.length
            );
            setByte(output, cursor, 58);
            setByte(output, cursor + 1, 58);
            cursor += 2;
          }
        }

        if (program.library) {
          writeAscii(output, cursor, "$library");
          cursor += 8;
        } else {
          writeAscii(output, cursor, "main");
          cursor += 4;
        }
      }

      stringIndex += 1;
    }

    return cursor;
  }
}
