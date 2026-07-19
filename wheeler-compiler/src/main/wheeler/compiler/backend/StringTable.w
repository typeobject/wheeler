//! Plans and emits the canonical artifact string table.

module wheeler.compiler.string_table;

import wheeler.compiler.encoding;
import wheeler.compiler.ir;

classical class StringTable {
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

  /// Computes canonical string offsets and total encoded table length.
  public StringTablePlan planStringTable(borrow utf8 source, MinimalProgram program) {
    long nameLength = program.name.length;
    long globalLength = program.global.length;
    long helperLength = program.helperName.length;
    long proofLength = program.proofName.length;
    long nameMainOrder = compareAsciiSliceToMain(source, program.name.start, nameLength);
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
    long encodedLength = 16 + nameLength;
    if (program.globalCount == 1) {
      long baseNameGlobalOrder = compareAsciiSlices(
        source,
        program.name.start,
        nameLength,
        program.global.start,
        globalLength
      );
      long baseGlobalMainOrder = compareAsciiSliceToMain(
        source,
        program.global.start,
        globalLength
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
      encodedLength = 20 + nameLength + globalLength;
    }

    if (program.helperCount == 1) {
      long nameGlobalOrder = compareAsciiSlices(
        source,
        program.name.start,
        nameLength,
        program.global.start,
        globalLength
      );
      long globalMainOrder = compareAsciiSliceToMain(source, program.global.start, globalLength);
      long nameHelperOrder = compareAsciiSlices(
        source,
        program.name.start,
        nameLength,
        program.helperName.start,
        helperLength
      );
      long globalHelperOrder = compareAsciiSlices(
        source,
        program.global.start,
        globalLength,
        program.helperName.start,
        helperLength
      );
      long helperMainOrder = compareAsciiSliceToMain(
        source,
        program.helperName.start,
        helperLength
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
      encodedLength = 24 + nameLength + globalLength + helperLength;
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
      long proofHelperOrder = compareAsciiSlices(
        source,
        program.helperName.start,
        helperLength,
        program.proofName.start,
        proofLength
      );
      long proofMainOrder = compareAsciiSliceToMain(source, program.proofName.start, proofLength);
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
      encodedLength = 28 + nameLength + globalLength + helperLength + proofLength;
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
          cursor = writeUnsignedLittleEndian(output, cursor, program.helperName.length, 4);
          cursor = writeAsciiSlice(
            output,
            cursor,
            source,
            program.helperName.start,
            program.helperName.length
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
        cursor = writeUnsignedLittleEndian(output, cursor, 4, 4);
        writeAscii(output, cursor, "main");
        cursor += 4;
      }

      stringIndex += 1;
    }

    return cursor;
  }
}
