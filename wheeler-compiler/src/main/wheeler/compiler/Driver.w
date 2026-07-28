//! Implements the bounded bootstrap compiler as one importable library module.

module wheeler.compiler.driver;

import wheeler.compiler.codegen;
import wheeler.compiler.encoding;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.opcodes;
import wheeler.compiler.parser;
import wheeler.compiler.string_table;
import wheeler.compiler.tokens;
import wheeler.compiler.verifier;
import wheeler.lexer.scanner;

classical class CompilerDriver {
  /// Carries the exact bounds of one verified compiler artifact.
  public record Compilation(long length, long codeStart) {}

  private long compactCompilerTokens(
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count
  ) {
    long readCursor = 0;
    long writeCursor = 0;
    while (readCursor < count) limit 1024 {
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

  private long moduleBodyStart(
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

    long cursor = 1;
    long nameStart = 0;
    long nameEnd = 0;
    boolean expectName = true;
    while (cursor < count) limit 64 {
      if (expectName) {
        if (tokenKinds[cursor] == 1) {
          if (nameStart == 0) {
            nameStart = tokenStarts[cursor];
          } else {
            if (tokenStarts[cursor] == nameEnd + 1) {} else {
              return -1;
            }
          }

          nameEnd = tokenStarts[cursor] + tokenLengths[cursor];
          expectName = false;
          cursor += 1;
        } else {
          return -1;
        }
      } else {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_SEMICOLON)
        ) {
          cursor += 1;
          if (cursor < count) {
            if (
              tokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_CLASSICAL
            ) {
              set(moduleRange, 0, nameStart);
              set(moduleRange, 1, nameEnd - nameStart);
              return cursor;
            }
          }

          return -1;
        }

        if (punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_DOT)) {
          if (tokenStarts[cursor] == nameEnd) {} else {
            return -1;
          }

          expectName = true;
          cursor += 1;
        } else {
          return -1;
        }
      }
    }

    return -1;
  }

  private long discardLeadingTokens(
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long bodyStart,
    long count
  ) {
    long readCursor = bodyStart;
    long writeCursor = 0;
    while (readCursor < count) limit 512 {
      set(tokenKinds, writeCursor, tokenKinds[readCursor]);
      set(tokenStarts, writeCursor, tokenStarts[readCursor]);
      set(tokenLengths, writeCursor, tokenLengths[readCursor]);
      readCursor += 1;
      writeCursor += 1;
    }

    return writeCursor;
  }

  private MinimalProgram requireMinimalProgram(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    borrow mut words moduleRange
  ) {
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    match (scanned) {
      case ScanResult.Error(ScanDiagnostic scanDiagnostic) {
        assert(0 == 1);
        SourceRange scanName = new SourceRange(scanDiagnostic.offset, 0);
        SourceRange scanGlobal = new SourceRange(scanDiagnostic.offset, 0);
        return new MinimalProgram(
          scanName,
          scanGlobal,
          0,
          0,
          0,
          emptyStatementOpcodes(),
          emptyStatementOperands(),
          emptyStatementOperands(),
          scanGlobal,
          0,
          emptyStatementOpcodes(),
          emptyStatementOperands(),
          emptyStatementOperands(),
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
        long bodyStart = moduleBodyStart(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          moduleRange,
          semanticCount
        );
        if (bodyStart < 0) {
          assert(0 == 1);
        }

        semanticCount = discardLeadingTokens(
          tokenKinds,
          tokenStarts,
          tokenLengths,
          bodyStart,
          semanticCount
        );
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
            assert(0 == 1);
            SourceRange parseName = new SourceRange(parseOffset, 0);
            SourceRange parseGlobal = new SourceRange(parseOffset, 0);
            return new MinimalProgram(
              parseName,
              parseGlobal,
              0,
              0,
              0,
              emptyStatementOpcodes(),
              emptyStatementOperands(),
              emptyStatementOperands(),
              parseGlobal,
              0,
              emptyStatementOpcodes(),
              emptyStatementOperands(),
              emptyStatementOperands(),
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
    long[64] opcodes,
    long count
  ) {
    long index = 0;
    while (index < count) limit MAX_MINIMAL_STATEMENTS {
      cursor = writeStatementLocalTypes(output, cursor, opcodes[index]);
      index += 1;
    }

    return cursor;
  }

  private long writeSequence(
    borrow mut bytes output,
    long cursor,
    long[64] opcodes,
    long[64] operands,
    long[64] secondaryOperands,
    long count,
    long localBase
  ) {
    long index = 0;
    long instructionBase = 0;
    while (index < count) limit MAX_MINIMAL_STATEMENTS {
      cursor = writeStatement(
        output,
        cursor,
        opcodes[index],
        operands[index],
        secondaryOperands[index],
        localBase,
        instructionBase
      );
      localBase += statementLocalCount(opcodes[index]);
      instructionBase += statementInstructionCount(opcodes[index]);
      index += 1;
    }

    return cursor;
  }

  private long writeReversibleSequence(
    borrow mut bytes output,
    long cursor,
    long[64] opcodes,
    long[64] operands,
    long count,
    boolean inverse
  ) {
    long index = 0;
    if (inverse) {
      index = count;
      while (0 < index) limit MAX_MINIMAL_STATEMENTS {
        index -= 1;
        cursor = writeInverseGlobalUpdate(output, cursor, opcodes[index], operands[index]);
      }

      return cursor;
    }

    while (index < count) limit MAX_MINIMAL_STATEMENTS {
      cursor = writeGlobalUpdate(output, cursor, opcodes[index], operands[index]);
      index += 1;
    }

    return cursor;
  }

  /// Compiles one bounded bootstrap source into caller-owned artifact storage.
  public Compilation compileMinimal(borrow utf8 source, borrow mut bytes output) {
    region arena = new region(25104, 5);
    words tokenKinds = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(arena, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(arena, MAX_COMPILER_TOKENS);
    words statementStarts = allocate(arena, MAX_MINIMAL_STATEMENTS);
    words moduleRange = allocate(arena, 2);
    MinimalProgram program = requireMinimalProgram(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      moduleRange
    );
    SourceRange moduleName = new SourceRange(moduleRange[0], moduleRange[1]);
    StringTablePlan strings = planStringTable(source, program, moduleName);
    if (strings.valid == 0) {
      assert(0 == 1);
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
    while (statementIndex < program.statementCount) limit MAX_MINIMAL_STATEMENTS {
      long statementOpcode = program.statementOpcodes[statementIndex];
      localCount += statementLocalCount(statementOpcode);
      codeLength += statementCodeLength(statementOpcode);
      statementIndex += 1;
    }

    long entryLocalCount = localCount;
    long entryStatementLength = codeLength - 8;
    long functionsLength = 44 + localCount * 4;
    long helperLocalCount = 0;
    long helperParameterCount = 0;
    long helperLocalBase = 0;
    long helperForwardLength = 8;
    long helperStatementIndex = 0;
    while (helperStatementIndex < program.helperStatementCount) limit MAX_MINIMAL_STATEMENTS {
      long helperOpcode = program.helperOpcodes[helperStatementIndex];
      helperLocalCount += statementLocalCount(helperOpcode);
      helperForwardLength += statementCodeLength(helperOpcode);
      helperStatementIndex += 1;
    }

    if (1 < program.helperReversible) {
      helperForwardLength -= 8;
    }

    if (program.helperReversible == 3) {
      helperLocalCount += 1;
      helperParameterCount = 1;
      helperLocalBase = 1;
    }

    if (program.helperReversible == 4) {
      helperLocalCount += 2;
      helperParameterCount = 2;
      helperLocalBase = 2;
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

    long entryTypeOffset = helperLocalCount;
    if (program.helperCount == 1) {
      localCount = helperLocalCount;
      functionsLength = 84 + helperLocalCount * 4 + entryLocalCount * 4;
      if (1 < program.helperReversible) {
        functionsLength += 4;
        entryTypeOffset += 1;
      }

      codeLength = helperForwardLength + helperInverseLength + entryForwardLength;
    }

    long codeOffset = align8(functionsOffset + functionsLength);
    long proofOffset = align8(codeOffset + codeLength);
    long fileLength = align8(codeOffset + codeLength);
    if (program.proofCount == 1) {
      fileLength = align8(proofOffset + 28);
    }

    assert(fileLength < bufferLength(output) + 1);

    writeAscii(output, 0, "WHEELBC");
    long cursor = 8;
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, ENCODING_WIDTH_U16);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U16);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, fileLength, ENCODING_WIDTH_U64);
    cursor = writeUnsignedLittleEndian(output, cursor, sectionCount, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 32, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 40, ENCODING_WIDTH_U64);

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

    cursor = writeUnsignedLittleEndian(output, cursor, nameIndex, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, program.helperCount, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 4000000, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 4000000, ENCODING_WIDTH_U64);

    cursor = writeStringTable(output, cursor, source, program, moduleName, strings);
    cursor = align8(cursor);

    cursor = writeUnsignedLittleEndian(output, cursor, program.globalCount, ENCODING_WIDTH_U32);
    if (program.globalCount == 1) {
      cursor = writeUnsignedLittleEndian(output, cursor, globalIndex, ENCODING_WIDTH_U32);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, ENCODING_WIDTH_U32);
      cursor = writeSignedLittleEndian(output, cursor, program.initialValue, ENCODING_WIDTH_U64);
    }

    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
    cursor = align8(cursor);

    cursor = writeUnsignedLittleEndian(
      output,
      cursor,
      1 + program.helperCount,
      ENCODING_WIDTH_U32
    );
    if (program.helperCount == 1) {
      long helperFlags = program.helperReversible;
      if (1 < program.helperReversible) {
        helperFlags = 4;
      }

      cursor = writeFunctionDescriptor(
        output,
        cursor,
        0,
        helperIndex,
        0,
        helperForwardLength,
        helperFlags,
        helperInverseOffset,
        helperInverseLength,
        helperParameterCount,
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
        0,
        entryLocalCount,
        entryTypeOffset
      );
      if (1 < program.helperReversible) {
        cursor = writeSignedLocalType(output, cursor);
      }

      if (program.helperReversible == 3) {
        cursor = writeSignedLocalType(output, cursor);
      }

      if (program.helperReversible == 4) {
        cursor = writeSignedLocalType(output, cursor);
        cursor = writeSignedLocalType(output, cursor);
      }

      if (program.helperReversible == 1) {} else {
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
        cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN, INSTRUCTION_FORM_NULLARY);
        cursor = writeReversibleSequence(
          output,
          cursor,
          program.helperOpcodes,
          program.helperOperands,
          program.helperStatementCount,
          true
        );
        cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN, INSTRUCTION_FORM_NULLARY);
      } else {
        cursor = writeSequence(
          output,
          cursor,
          program.helperOpcodes,
          program.helperOperands,
          program.helperSecondaryOperands,
          program.helperStatementCount,
          helperLocalBase
        );
        if (1 < program.helperReversible) {} else {
          cursor = writeInstructionHeader(
            output,
            cursor,
            OPCODE_RETURN,
            INSTRUCTION_FORM_NULLARY
          );
        }
      }

      long entryInstructionBase = 0;
      if (1 < program.helperReversible) {
        cursor = writeSequence(
          output,
          cursor,
          program.statementOpcodes,
          program.statementOperands,
          program.statementSecondaryOperands,
          program.statementCount,
          0
        );
      } else {
        long helperCall = 0;
        while (helperCall < program.helperCallCount) limit 2 {
          cursor = writeInstructionHeader(output, cursor, OPCODE_CALL, INSTRUCTION_FORM_UNARY);
          cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U64);
          helperCall += 1;
          entryInstructionBase += 1;
        }

        if (program.preReverseStatementCount == 1) {
          cursor = writeStatement(
            output,
            cursor,
            program.statementOpcodes[0],
            program.statementOperands[0],
            program.statementSecondaryOperands[0],
            0,
            entryInstructionBase
          );
          entryInstructionBase += statementInstructionCount(program.statementOpcodes[0]);
        }

        if (program.helperReversible == 1) {
          long helperUncall = 0;
          while (helperUncall < program.helperCallCount) limit 2 {
            cursor = writeInstructionHeader(
              output,
              cursor,
              OPCODE_UNCALL,
              INSTRUCTION_FORM_UNARY
            );
            cursor = writeUnsignedLittleEndian(
              output,
              cursor,
              /* value= */ 0,
              ENCODING_WIDTH_U64
            );
            helperUncall += 1;
            entryInstructionBase += 1;
          }
        }

        if (program.preReverseStatementCount == 0) {
          if (0 < program.statementCount) {
            cursor = writeStatement(
              output,
              cursor,
              program.statementOpcodes[0],
              program.statementOperands[0],
              program.statementSecondaryOperands[0],
              0,
              entryInstructionBase
            );
            entryInstructionBase += statementInstructionCount(program.statementOpcodes[0]);
          }
        }

        if (program.preReverseStatementCount == 1) {
          if (1 < program.statementCount) {
            cursor = writeStatement(
              output,
              cursor,
              program.statementOpcodes[1],
              program.statementOperands[1],
              program.statementSecondaryOperands[1],
              statementLocalCount(program.statementOpcodes[0]),
              entryInstructionBase
            );
            entryInstructionBase += statementInstructionCount(program.statementOpcodes[1]);
          }
        }
      }
    } else {
      cursor = writeSequence(
        output,
        cursor,
        program.statementOpcodes,
        program.statementOperands,
        program.statementSecondaryOperands,
        program.statementCount,
        0
      );
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_HALT, INSTRUCTION_FORM_NULLARY);
    if (program.proofCount == 1) {
      cursor = align8(cursor);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, ENCODING_WIDTH_U32);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
      cursor = writeUnsignedLittleEndian(output, cursor, proofIndex, ENCODING_WIDTH_U32);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, ENCODING_WIDTH_U32);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, ENCODING_WIDTH_U32);
      cursor = writeSignedLittleEndian(output, cursor, /* value= */ -1, ENCODING_WIDTH_U64);
      cursor = align8(cursor);
    }

    long finalCursor = cursor;
    long verification = verifyArtifact(output, finalCursor);
    assert(verification == 1);

    drop(moduleRange);
    drop(statementStarts);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(arena);
    return new Compilation(finalCursor, codeOffset);
  }
}
