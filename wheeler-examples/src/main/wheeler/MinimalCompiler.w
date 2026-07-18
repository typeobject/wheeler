module examples.compiler.seed;
import examples.compiler.encoding;
import examples.compiler.parser;
import examples.lexer.scanner;
classical class MinimalCompiler {
    state long finalCursor = 0;
    state long codeStart = 0;

    private MinimalProgram requireMinimalProgram(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths
    ) {
        ScanResult scanned = scan(
            source, tokenKinds, tokenStarts, tokenLengths);
        match (scanned) {
            case ScanResult.Error(ScanDiagnostic diagnostic) {
                assert finalCursor == 1;
                SourceRange scanName = new SourceRange(diagnostic.offset, 0);
                SourceRange scanGlobal = new SourceRange(diagnostic.offset, 0);
                return new MinimalProgram(
                    scanName, scanGlobal, 0, 0, 0, 0, 0, 0, 0);
            }
            case ScanResult.Value(long count) {
                MinimalProgramResult parsed = parseMinimalProgram(
                    source, tokenKinds, tokenStarts, tokenLengths, count);
                match (parsed) {
                    case MinimalProgramResult.Error(long parseOffset) {
                        assert finalCursor == 1;
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
                            0);
                    }
                    case MinimalProgramResult.Value(MinimalProgram program) {
                        return program;
                    }
                }
            }
        }
    }

    private long statementLocalCount(long opcode) {
        if (opcode == 0) {
            return 1;
        }
        if (0 < opcode) {
            return 2;
        }
        return 0;
    }

    private long statementCodeLength(long opcode) {
        if (opcode == 0) {
            return 48;
        }
        if (0 < opcode) {
            return 104;
        }
        return 0;
    }

    private long writeStatement(
        bytes output,
        long cursor,
        long opcode,
        long operand,
        long localBase
    ) {
        cursor = writeInstructionHeader(output, cursor, 1024, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
        cursor = writeSignedLittleEndian(output, cursor, operand, 8);
        if (opcode == 0) {
            cursor = writeInstructionHeader(output, cursor, 1026, 2);
            cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
            return writeUnsignedLittleEndian(
                output, cursor, localBase, 8);
        }
        cursor = writeInstructionHeader(output, cursor, 1025, 2);
        cursor = writeUnsignedLittleEndian(
            output, cursor, localBase + 1, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        cursor = writeInstructionHeader(output, cursor, opcode, 3);
        cursor = writeUnsignedLittleEndian(
            output, cursor, localBase + 1, 8);
        cursor = writeUnsignedLittleEndian(
            output, cursor, localBase + 1, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
        cursor = writeInstructionHeader(output, cursor, 1026, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        return writeUnsignedLittleEndian(
            output, cursor, localBase + 1, 8);
    }

    entry void main(utf8 source, bytes output) {
        region arena = new region(768, 3);
        words tokenKinds = allocate(arena, 32);
        words tokenStarts = allocate(arena, 32);
        words tokenLengths = allocate(arena, 32);
        MinimalProgram program = requireMinimalProgram(
            source, tokenKinds, tokenStarts, tokenLengths);
        long nameLength = program.name.length;
        long globalLength = program.global.length;
        long nameMainOrder = compareAsciiSliceToMain(
            source, program.name.start, nameLength);
        if (nameMainOrder == 0) {
            assert finalCursor == 1;
        }
        long nameIndex = 0;
        long globalIndex = 0;
        long mainIndex = 0;
        if (0 < nameMainOrder) {
            nameIndex = 1;
        }
        if (nameMainOrder < 0) {
            mainIndex = 1;
        }
        long stringCount = 2;
        long stringsLength = 16 + nameLength;
        long typesLength = 16;
        if (program.globalCount == 1) {
            long nameGlobalOrder = compareAsciiSlices(
                source,
                program.name.start,
                nameLength,
                program.global.start,
                globalLength);
            long globalMainOrder = compareAsciiSliceToMain(
                source, program.global.start, globalLength);
            if (nameGlobalOrder == 0) {
                assert finalCursor == 1;
            }
            if (globalMainOrder == 0) {
                assert finalCursor == 1;
            }
            nameIndex = 0;
            globalIndex = 0;
            mainIndex = 0;
            if (0 < nameGlobalOrder) {
                nameIndex += 1;
            }
            if (0 < nameMainOrder) {
                nameIndex += 1;
            }
            if (nameGlobalOrder < 0) {
                globalIndex += 1;
            }
            if (0 < globalMainOrder) {
                globalIndex += 1;
            }
            if (nameMainOrder < 0) {
                mainIndex += 1;
            }
            if (globalMainOrder < 0) {
                mainIndex += 1;
            }
            stringCount = 3;
            stringsLength = 20 + nameLength + globalLength;
            typesLength = 32;
        }
        long manifestOffset = 232;
        long stringsOffset = 256;
        long typesOffset = align8(stringsOffset + stringsLength);
        long variantsOffset = align8(typesOffset + typesLength);
        long functionsOffset = align8(variantsOffset + 4);
        long firstLocalCount = statementLocalCount(program.opcode);
        long localCount = firstLocalCount;
        long codeLength = 8 + statementCodeLength(program.opcode);
        if (program.statementCount == 2) {
            localCount += statementLocalCount(program.secondOpcode);
            codeLength += statementCodeLength(program.secondOpcode);
        }
        long functionsLength = 44 + localCount * 4;
        long codeOffset = align8(functionsOffset + functionsLength);
        long fileLength = align8(codeOffset + codeLength);
        codeStart = codeOffset;

        writeAscii(output, 0, "WHEELBC");
        long cursor = 8;
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, fileLength, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, 6, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 32, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 40, 8);

        cursor = writeDirectoryEntry(
            output, cursor, 1, manifestOffset, 24);
        cursor = writeDirectoryEntry(
            output, cursor, 2, stringsOffset, stringsLength);
        cursor = writeDirectoryEntry(
            output, cursor, 3, typesOffset, typesLength);
        cursor = writeDirectoryEntry(
            output, cursor, 4, variantsOffset, 4);
        cursor = writeDirectoryEntry(
            output, cursor, 5, functionsOffset, functionsLength);
        cursor = writeDirectoryEntry(
            output, cursor, 6, codeOffset, codeLength);

        cursor = writeUnsignedLittleEndian(output, cursor, nameIndex, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 100000, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 1000000, 8);

        cursor = writeUnsignedLittleEndian(output, cursor, stringCount, 4);
        long stringIndex = 0;
        while (stringIndex < stringCount) limit 3 {
            if (stringIndex == nameIndex) {
                cursor = writeUnsignedLittleEndian(
                    output, cursor, nameLength, 4);
                cursor = writeAsciiSlice(
                    output, cursor, source, program.name.start, nameLength);
            }
            if (program.globalCount == 1) {
                if (stringIndex == globalIndex) {
                    cursor = writeUnsignedLittleEndian(
                        output, cursor, globalLength, 4);
                    cursor = writeAsciiSlice(
                        output,
                        cursor,
                        source,
                        program.global.start,
                        globalLength);
                }
            }
            if (stringIndex == mainIndex) {
                cursor = writeUnsignedLittleEndian(output, cursor, 4, 4);
                writeAscii(output, cursor, "main");
                cursor += 4;
            }
            stringIndex += 1;
        }
        cursor = align8(cursor);

        cursor = writeUnsignedLittleEndian(
            output, cursor, program.globalCount, 4);
        if (program.globalCount == 1) {
            cursor = writeUnsignedLittleEndian(
                output, cursor, globalIndex, 4);
            cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
            cursor = writeSignedLittleEndian(
                output, cursor, program.initialValue, 8);
        }
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = align8(cursor);

        cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, mainIndex, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, codeLength, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 4294967295, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, localCount, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        long localType = 0;
        while (localType < localCount) limit 4 {
            cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
            localType += 1;
        }
        cursor = align8(cursor);

        if (0 < program.statementCount) {
            cursor = writeStatement(
                output,
                cursor,
                program.opcode,
                program.operand,
                0);
        }
        if (program.statementCount == 2) {
            cursor = writeStatement(
                output,
                cursor,
                program.secondOpcode,
                program.secondOperand,
                firstLocalCount);
        }
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 8, 4);
        finalCursor = cursor;
        setOutputLength(output, finalCursor);

        drop(tokenLengths);
        drop(tokenStarts);
        drop(tokenKinds);
        drop(arena);
    }
}
