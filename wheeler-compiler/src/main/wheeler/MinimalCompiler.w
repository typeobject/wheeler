//! Compiles the bounded bootstrap source profile to canonical `.wbc`.

module wheeler.compiler.driver;

import wheeler.compiler.codegen;
import wheeler.compiler.encoding;
import wheeler.compiler.ir;
import wheeler.compiler.opcodes;
import wheeler.compiler.parser;
import wheeler.compiler.statements;
import wheeler.compiler.string_table;
import wheeler.compiler.verifier;
import wheeler.lexer.scanner;

classical class MinimalCompiler {
  state long finalCursor = 0;
  state long codeStart = 0;
  state long verification = 0;

  private long compactCompilerTokens(
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count
  ) {
    long readCursor = 0;
    long writeCursor = 0;
    while (readCursor < count) limit 128 {
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
    borrow mut words tokenLengths
  ) {
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    match (scanned) {
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        assert(finalCursor == 1);
        SourceRange scanName = new SourceRange(diagnostic.offset, 0);
        SourceRange scanGlobal = new SourceRange(diagnostic.offset, 0);
        return new MinimalProgram(
          scanName,
          scanGlobal,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          scanGlobal,
          0,
          -1,
          0,
          0,
          scanGlobal,
          0,
          0,
          0,
          0,
          -1,
          0,
          -1,
          0,
          -1,
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
          semanticCount
        );
        match (parsed) {
          case MinimalProgramResult.Error(long parseOffset) {
            assert(finalCursor == 1);
            SourceRange parseName = new SourceRange(parseOffset, 0);
            SourceRange parseGlobal = new SourceRange(parseOffset, 0);
            return new MinimalProgram(
              parseName,
              parseGlobal,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              parseGlobal,
              0,
              -1,
              0,
              0,
              parseGlobal,
              0,
              0,
              0,
              0,
              -1,
              0,
              -1,
              0,
              -1,
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

  /// Runs the bounded `MinimalCompiler` fixture.
  ///
  /// - Effects: Mutates declared state and caller-owned byte output.
  entry void main(borrow utf8 source, borrow mut bytes output) {
    region arena = new region(3072, 3);
    words tokenKinds = allocate(arena, 128);
    words tokenStarts = allocate(arena, 128);
    words tokenLengths = allocate(arena, 128);
    MinimalProgram program = requireMinimalProgram(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths
    );
    StringTablePlan strings = planStringTable(source, program);
    if (strings.valid == 0) {
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
    long firstLocalCount = statementLocalCount(program.opcode);
    long secondLocalCount = statementLocalCount(program.secondOpcode);
    long thirdLocalCount = statementLocalCount(program.thirdOpcode);
    long localCount = firstLocalCount;
    long codeLength = 8 + statementCodeLength(program.opcode);
    if (1 < program.statementCount) {
      localCount += secondLocalCount;
      codeLength += statementCodeLength(program.secondOpcode);
    }

    if (2 < program.statementCount) {
      localCount += thirdLocalCount;
      codeLength += statementCodeLength(program.thirdOpcode);
    }

    if (3 < program.statementCount) {
      localCount += statementLocalCount(program.fourthOpcode);
      codeLength += statementCodeLength(program.fourthOpcode);
    }

    long entryLocalCount = localCount;
    long entryStatementLength = codeLength - 8;
    long functionsLength = 44 + localCount * 4;
    long helperLocalCount = statementLocalCount(program.helperOpcode);
    long helperForwardLength = statementCodeLength(program.helperOpcode) + 8;
    if (1 < program.helperStatementCount) {
      helperLocalCount += statementLocalCount(program.helperSecondOpcode);
      helperForwardLength += statementCodeLength(program.helperSecondOpcode);
    }

    if (2 < program.helperStatementCount) {
      helperLocalCount += statementLocalCount(program.helperThirdOpcode);
      helperForwardLength += statementCodeLength(program.helperThirdOpcode);
    }

    if (3 < program.helperStatementCount) {
      helperLocalCount += statementLocalCount(program.helperFourthOpcode);
      helperForwardLength += statementCodeLength(program.helperFourthOpcode);
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
        cursor = writeStatementLocalTypes(output, cursor, program.helperOpcode);
        if (1 < program.helperStatementCount) {
          cursor = writeStatementLocalTypes(output, cursor, program.helperSecondOpcode);
        }

        if (2 < program.helperStatementCount) {
          cursor = writeStatementLocalTypes(output, cursor, program.helperThirdOpcode);
        }

        if (3 < program.helperStatementCount) {
          cursor = writeStatementLocalTypes(output, cursor, program.helperFourthOpcode);
        }
      }

      if (0 < program.statementCount) {
        cursor = writeStatementLocalTypes(output, cursor, program.opcode);
      }

      if (1 < program.statementCount) {
        cursor = writeStatementLocalTypes(output, cursor, program.secondOpcode);
      }
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
      if (0 < program.statementCount) {
        cursor = writeStatementLocalTypes(output, cursor, program.opcode);
      }

      if (1 < program.statementCount) {
        cursor = writeStatementLocalTypes(output, cursor, program.secondOpcode);
      }

      if (2 < program.statementCount) {
        cursor = writeStatementLocalTypes(output, cursor, program.thirdOpcode);
      }

      if (3 < program.statementCount) {
        cursor = writeStatementLocalTypes(output, cursor, program.fourthOpcode);
      }
    }

    cursor = align8(cursor);

    if (program.helperCount == 1) {
      if (program.helperReversible == 1) {
        cursor = writeGlobalUpdate(output, cursor, program.helperOpcode, program.helperOperand);
        if (1 < program.helperStatementCount) {
          cursor = writeGlobalUpdate(
            output,
            cursor,
            program.helperSecondOpcode,
            program.helperSecondOperand
          );
        }

        if (2 < program.helperStatementCount) {
          cursor = writeGlobalUpdate(
            output,
            cursor,
            program.helperThirdOpcode,
            program.helperThirdOperand
          );
        }

        if (3 < program.helperStatementCount) {
          cursor = writeGlobalUpdate(
            output,
            cursor,
            program.helperFourthOpcode,
            program.helperFourthOperand
          );
        }

        cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN, 0);
        if (3 < program.helperStatementCount) {
          cursor = writeInverseGlobalUpdate(
            output,
            cursor,
            program.helperFourthOpcode,
            program.helperFourthOperand
          );
        }

        if (2 < program.helperStatementCount) {
          cursor = writeInverseGlobalUpdate(
            output,
            cursor,
            program.helperThirdOpcode,
            program.helperThirdOperand
          );
        }

        if (1 < program.helperStatementCount) {
          cursor = writeInverseGlobalUpdate(
            output,
            cursor,
            program.helperSecondOpcode,
            program.helperSecondOperand
          );
        }

        cursor = writeInverseGlobalUpdate(
          output,
          cursor,
          program.helperOpcode,
          program.helperOperand
        );
        cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN, 0);
      } else {
        long helperFirstLocals = statementLocalCount(program.helperOpcode);
        long helperSecondLocals = statementLocalCount(program.helperSecondOpcode);
        long helperThirdLocals = statementLocalCount(program.helperThirdOpcode);
        cursor = writeStatement(output, cursor, program.helperOpcode, program.helperOperand, 0);
        if (1 < program.helperStatementCount) {
          cursor = writeStatement(
            output,
            cursor,
            program.helperSecondOpcode,
            program.helperSecondOperand,
            helperFirstLocals
          );
        }

        if (2 < program.helperStatementCount) {
          cursor = writeStatement(
            output,
            cursor,
            program.helperThirdOpcode,
            program.helperThirdOperand,
            helperFirstLocals + helperSecondLocals
          );
        }

        if (3 < program.helperStatementCount) {
          cursor = writeStatement(
            output,
            cursor,
            program.helperFourthOpcode,
            program.helperFourthOperand,
            helperFirstLocals + helperSecondLocals + helperThirdLocals
          );
        }

        cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN, 0);
      }

      long helperCall = 0;
      while (helperCall < program.helperCallCount) limit 2 {
        cursor = writeInstructionHeader(output, cursor, OPCODE_CALL, 1);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        helperCall += 1;
      }

      if (program.preReverseStatementCount == 1) {
        cursor = writeStatement(output, cursor, program.opcode, program.operand, 0);
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
          cursor = writeStatement(output, cursor, program.opcode, program.operand, 0);
        }
      }

      if (program.preReverseStatementCount == 1) {
        if (1 < program.statementCount) {
          cursor = writeStatement(
            output,
            cursor,
            program.secondOpcode,
            program.secondOperand,
            firstLocalCount
          );
        }
      }
    } else {
      if (0 < program.statementCount) {
        cursor = writeStatement(output, cursor, program.opcode, program.operand, 0);
      }

      if (1 < program.statementCount) {
        cursor = writeStatement(
          output,
          cursor,
          program.secondOpcode,
          program.secondOperand,
          firstLocalCount
        );
      }

      if (2 < program.statementCount) {
        cursor = writeStatement(
          output,
          cursor,
          program.thirdOpcode,
          program.thirdOperand,
          firstLocalCount + secondLocalCount
        );
      }

      if (3 < program.statementCount) {
        cursor = writeStatement(
          output,
          cursor,
          program.fourthOpcode,
          program.fourthOperand,
          firstLocalCount + secondLocalCount + thirdLocalCount
        );
      }
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

    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(arena);
  }
}
