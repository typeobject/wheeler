//! Compiles the bounded bootstrap source profile to canonical `.wbc`.

module wheeler.compiler.driver;

import wheeler.compiler.codegen;
import wheeler.compiler.encoding;
import wheeler.compiler.ir;
import wheeler.compiler.opcodes;
import wheeler.compiler.parser;
import wheeler.compiler.statements;
import wheeler.compiler.string_table;
import wheeler.compiler.tokens;
import wheeler.compiler.verifier;
import wheeler.lexer.scanner;

classical class MinimalCompiler {
  /// Names a scanner rejection in `diagnosticStage`.
  public const long DIAGNOSTIC_SCAN = 1;
  /// Names a parser rejection in `diagnosticStage`.
  public const long DIAGNOSTIC_PARSE = 2;
  /// Names a string-table rejection in `diagnosticStage`.
  public const long DIAGNOSTIC_STRING_TABLE = 3;

  state long finalCursor = 0;
  state long codeStart = 0;
  state long verification = 0;
  state long diagnosticStage = 0;

  private long compactCompilerTokens(
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count
  ) {
    long readCursor = 0;
    long writeCursor = 0;
    while (readCursor < count) limit 812 {
      long kind = tokenKinds[readCursor];
      boolean emit = true;
      if (kind == 4) {
        emit = false;
      }

      if (kind == 5) {
        emit = false;
      }

      if (emit) {
        set(tokenKinds, writeCursor, kind);
        set(tokenStarts, writeCursor, tokenStarts[readCursor]);
        set(tokenLengths, writeCursor, tokenLengths[readCursor]);
        writeCursor += 1;
      }

      readCursor += 1;
    }

    return writeCursor;
  }

  private MinimalProgram requireMinimalProgram(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts
  ) {
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    match (scanned) {
      case ScanResult.Error(ScanDiagnostic scanDiagnostic) {
        diagnosticStage = DIAGNOSTIC_SCAN;
        assert(finalCursor == 1);
        SourceRange scanName = new SourceRange(scanDiagnostic.offset, 0);
        SourceRange scanGlobal = new SourceRange(scanDiagnostic.offset, 0);
        return new MinimalProgram(
          scanName,
          scanGlobal,
          0,
          0,
          0,
          new long[16](-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),
          new long[16](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
          scanGlobal,
          0,
          new long[16](-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),
          new long[16](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
          0,
          scanGlobal,
          0,
          0,
          0,
          0
        );
      }
      case ScanResult.Value(long count) {
        long semanticCount = compactCompilerTokens(tokenKinds, tokenStarts, tokenLengths, count);
        MinimalProgramResult parsed = parseMinimalProgram(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          statementStarts,
          semanticCount
        );
        match (parsed) {
          case MinimalProgramResult.Error(long parseOffset) {
            diagnosticStage = DIAGNOSTIC_PARSE;
            assert(finalCursor == 1);
            SourceRange parseName = new SourceRange(parseOffset, 0);
            SourceRange parseGlobal = new SourceRange(parseOffset, 0);
            return new MinimalProgram(
              parseName,
              parseGlobal,
              0,
              0,
              0,
              new long[16](-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),
              new long[16](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
              parseGlobal,
              0,
              new long[16](-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),
              new long[16](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
              0,
              parseGlobal,
              0,
              0,
              0,
              0
            );
          }
          case MinimalProgramResult.Value(MinimalProgram program) {
            return program;
          }
        }
      }
    }
  }

  private long writeSequenceLocalTypes(
    borrow mut bytes output,
    long cursor,
    long[16] opcodes,
    long count
  ) {
    long index = 0;
    while (index < count) limit 16 {
      cursor = writeStatementLocalTypes(output, cursor, opcodes[index]);
      index += 1;
    }

    return cursor;
  }

  private long writeSequence(
    borrow mut bytes output,
    long cursor,
    long[16] opcodes,
    long[16] operands,
    long count
  ) {
    long index = 0;
    long localBase = 0;
    while (index < count) limit 16 {
      cursor = writeStatement(output, cursor, opcodes[index], operands[index], localBase);
      localBase += statementLocalCount(opcodes[index]);
      index += 1;
    }

    return cursor;
  }

  private long writeReversibleSequence(
    borrow mut bytes output,
    long cursor,
    long[16] opcodes,
    long[16] operands,
    long count,
    boolean inverse
  ) {
    long index = 0;
    if (inverse) {
      index = count;
      while (0 < index) limit 16 {
        index -= 1;
        cursor = writeInverseGlobalUpdate(output, cursor, opcodes[index], operands[index]);
      }

      return cursor;
    }

    while (index < count) limit 16 {
      cursor = writeGlobalUpdate(output, cursor, opcodes[index], operands[index]);
      index += 1;
    }

    return cursor;
  }

  /// Runs the bounded `MinimalCompiler` fixture.
  ///
  /// - Effects: Mutates declared state and caller-owned byte output.
  entry void main(borrow utf8 source, borrow mut bytes output) {
    region arena = new region(12416, 4);
    words tokenKinds = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(arena, MAX_COMPILER_TOKENS);
    words statementStarts = allocate(arena, 16);
    MinimalProgram program = requireMinimalProgram(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts
    );
    StringTablePlan strings = planStringTable(source, program);
    if (strings.valid == 0) {
      diagnosticStage = DIAGNOSTIC_STRING_TABLE;
      assert(finalCursor == 1);
    }

    long nameIndex = strings.nameIndex;
    long globalIndex = strings.globalIndex;
    long helperIndex = strings.helperIndex;
    long proofIndex = strings.proofIndex;
    long mainIndex = strings.mainIndex;
    long stringsLength = strings.encodedLength;
    long typesLength = 16;
    if (program.globalCount == 1) {
      typesLength = 32;
    }

    long sectionCount = 6 + program.proofCount;
    long manifestOffset = align8(40 + sectionCount * 32);
    long stringsOffset = align8(manifestOffset + 24);
    long typesOffset = align8(stringsOffset + stringsLength);
    long variantsOffset = align8(typesOffset + typesLength);
    long functionsOffset = align8(variantsOffset + 4);
    long localCount = 0;
    long codeLength = 8;
    long statementIndex = 0;
    while (statementIndex < program.statementCount) limit 16 {
      long statementOpcode = program.statementOpcodes[statementIndex];
      localCount += statementLocalCount(statementOpcode);
      codeLength += statementCodeLength(statementOpcode);
      statementIndex += 1;
    }

    long entryLocalCount = localCount;
    long entryStatementLength = codeLength - 8;
    long functionsLength = 44 + localCount * 4;
    long helperLocalCount = 0;
    long helperForwardLength = 8;
    long helperStatementIndex = 0;
    while (helperStatementIndex < program.helperStatementCount) limit 16 {
      long helperOpcode = program.helperOpcodes[helperStatementIndex];
      helperLocalCount += statementLocalCount(helperOpcode);
      helperForwardLength += statementCodeLength(helperOpcode);
      helperStatementIndex += 1;
    }

    long helperInverseLength = 0;
    long helperInverseOffset = 4294967295;
    long entryForwardLength = 8 + program.helperCallCount * 16 + entryStatementLength;
    if (program.helperReversible == 1) {
      helperLocalCount = 0;
      helperForwardLength = 8 + program.helperStatementCount * 24;
      helperInverseLength = helperForwardLength;
      helperInverseOffset = helperForwardLength;
      entryForwardLength = 8 + program.helperCallCount * 32 + entryStatementLength;
    }

    if (program.helperCount == 1) {
      localCount = helperLocalCount;
      functionsLength = 84 + helperLocalCount * 4 + entryLocalCount * 4;
      codeLength = helperForwardLength + helperInverseLength + entryForwardLength;
    }

    long codeOffset = align8(functionsOffset + functionsLength);
    long proofOffset = align8(codeOffset + codeLength);
    long fileLength = align8(codeOffset + codeLength);
    if (program.proofCount == 1) {
      fileLength = align8(proofOffset + 28);
    }

    assert(fileLength < bufferLength(output) + 1);
    codeStart = codeOffset;

    writeAscii(output, 0, "WHEELBC");
    long cursor = 8;
    cursor = writeUnsignedLittleEndian(output, cursor, 1, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, 0, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, fileLength, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, sectionCount, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, 32, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, 40, 8);

    cursor = writeDirectoryEntry(output, cursor, 1, manifestOffset, 24);
    cursor = writeDirectoryEntry(output, cursor, 2, stringsOffset, stringsLength);
    cursor = writeDirectoryEntry(output, cursor, 3, typesOffset, typesLength);
    cursor = writeDirectoryEntry(output, cursor, 4, variantsOffset, 4);
    cursor = writeDirectoryEntry(output, cursor, 5, functionsOffset, functionsLength);
    cursor = writeDirectoryEntry(output, cursor, 6, codeOffset, codeLength);
    if (program.proofCount == 1) {
      cursor = writeDirectoryEntry(output, cursor, 10, proofOffset, 28);
    }

    cursor = align8(cursor);

    cursor = writeUnsignedLittleEndian(output, cursor, nameIndex, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, program.helperCount, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, 250000, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, 1000000, 8);

    cursor = writeStringTable(output, cursor, source, program, strings);
    cursor = align8(cursor);

    cursor = writeUnsignedLittleEndian(output, cursor, program.globalCount, 4);
    if (program.globalCount == 1) {
      cursor = writeUnsignedLittleEndian(output, cursor, globalIndex, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
      cursor = writeSignedLittleEndian(output, cursor, program.initialValue, 8);
    }

    cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
    cursor = align8(cursor);

    cursor = writeUnsignedLittleEndian(output, cursor, 1 + program.helperCount, 4);
    if (program.helperCount == 1) {
      cursor = writeFunctionDescriptor(
        output,
        cursor,
        0,
        helperIndex,
        0,
        helperForwardLength,
        program.helperReversible,
        helperInverseOffset,
        helperInverseLength,
        helperLocalCount,
        0
      );
      cursor = writeFunctionDescriptor(
        output,
        cursor,
        1,
        mainIndex,
        helperForwardLength + helperInverseLength,
        entryForwardLength,
        0,
        4294967295,
        0,
        entryLocalCount,
        helperLocalCount
      );
      if (program.helperReversible == 0) {
        cursor = writeSequenceLocalTypes(
          output,
          cursor,
          program.helperOpcodes,
          program.helperStatementCount
        );
      }

      cursor = writeSequenceLocalTypes(
        output,
        cursor,
        program.statementOpcodes,
        program.statementCount
      );
    } else {
      cursor = writeFunctionDescriptor(
        output,
        cursor,
        0,
        mainIndex,
        0,
        codeLength,
        0,
        4294967295,
        0,
        localCount,
        0
      );
      cursor = writeSequenceLocalTypes(
        output,
        cursor,
        program.statementOpcodes,
        program.statementCount
      );
    }

    cursor = align8(cursor);

    if (program.helperCount == 1) {
      if (program.helperReversible == 1) {
        cursor = writeReversibleSequence(
          output,
          cursor,
          program.helperOpcodes,
          program.helperOperands,
          program.helperStatementCount,
          false
        );
        cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN, 0);
        cursor = writeReversibleSequence(
          output,
          cursor,
          program.helperOpcodes,
          program.helperOperands,
          program.helperStatementCount,
          true
        );
        cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN, 0);
      } else {
        cursor = writeSequence(
          output,
          cursor,
          program.helperOpcodes,
          program.helperOperands,
          program.helperStatementCount
        );
        cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN, 0);
      }

      long helperCall = 0;
      while (helperCall < program.helperCallCount) limit 2 {
        cursor = writeInstructionHeader(output, cursor, OPCODE_CALL, 1);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        helperCall += 1;
      }

      if (program.preReverseStatementCount == 1) {
        cursor = writeStatement(
          output,
          cursor,
          program.statementOpcodes[0],
          program.statementOperands[0],
          0
        );
      }

      if (program.helperReversible == 1) {
        long helperUncall = 0;
        while (helperUncall < program.helperCallCount) limit 2 {
          cursor = writeInstructionHeader(output, cursor, OPCODE_UNCALL, 1);
          cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
          helperUncall += 1;
        }
      }

      if (program.preReverseStatementCount == 0) {
        if (0 < program.statementCount) {
          cursor = writeStatement(
            output,
            cursor,
            program.statementOpcodes[0],
            program.statementOperands[0],
            0
          );
        }
      }

      if (program.preReverseStatementCount == 1) {
        if (1 < program.statementCount) {
          cursor = writeStatement(
            output,
            cursor,
            program.statementOpcodes[1],
            program.statementOperands[1],
            statementLocalCount(program.statementOpcodes[0])
          );
        }
      }
    } else {
      cursor = writeSequence(
        output,
        cursor,
        program.statementOpcodes,
        program.statementOperands,
        program.statementCount
      );
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_HALT, 0);
    if (program.proofCount == 1) {
      cursor = align8(cursor);
      cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, proofIndex, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
      cursor = writeSignedLittleEndian(output, cursor, -1, 8);
      cursor = align8(cursor);
    }

    finalCursor = cursor;
    verification = verifyArtifact(output, finalCursor);
    assert(verification == 1);
    setOutputLength(output, finalCursor);

    drop(statementStarts);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(arena);
  }
}
