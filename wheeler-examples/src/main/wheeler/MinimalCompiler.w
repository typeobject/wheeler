module examples.compiler.seed;
import examples.compiler.encoding;
import examples.compiler.ir;
import examples.compiler.parser;
import examples.compiler.verifier;
import examples.lexer.scanner;
classical class MinimalCompiler {
    state long finalCursor = 0;
    state long codeStart = 0;
    state long verification = 0;

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
                    0);
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
                            0,
                            0,
                            0,
                            0,
                            0,
                            parseGlobal,
                            0,
                            -1,
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
        if (opcode == 768) {
            return 0;
        }
        if (opcode == 769) {
            return 2;
        }
        if (opcode == 0) {
            return 1;
        }
        if (0 < opcode) {
            return 2;
        }
        return 0;
    }

    private long statementCodeLength(long opcode) {
        if (opcode == 768) {
            return 24;
        }
        if (opcode == 769) {
            return 48;
        }
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
        if (opcode == 768) {
            cursor = writeInstructionHeader(output, cursor, 768, 2);
            cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
            return writeSignedLittleEndian(output, cursor, operand, 8);
        }
        cursor = writeInstructionHeader(output, cursor, 1024, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
        cursor = writeSignedLittleEndian(output, cursor, operand, 8);
        if (opcode == 769) {
            cursor = writeInstructionHeader(output, cursor, 1027, 2);
            cursor = writeUnsignedLittleEndian(
                output, cursor, localBase + 1, 8);
            return writeUnsignedLittleEndian(
                output, cursor, localBase, 8);
        }
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

    private long writeFunctionDescriptor(
        bytes output,
        long cursor,
        long id,
        long name,
        long forwardOffset,
        long forwardLength,
        long flags,
        long inverseOffset,
        long inverseLength,
        long localCount,
        long typeOffset
    ) {
        cursor = writeUnsignedLittleEndian(output, cursor, id, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, name, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, flags, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, forwardOffset, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, forwardLength, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, inverseOffset, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, inverseLength, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, localCount, 4);
        return writeUnsignedLittleEndian(output, cursor, typeOffset, 4);
    }

    entry void main(utf8 source, bytes output) {
        region arena = new region(1536, 3);
        words tokenKinds = allocate(arena, 64);
        words tokenStarts = allocate(arena, 64);
        words tokenLengths = allocate(arena, 64);
        MinimalProgram program = requireMinimalProgram(
            source, tokenKinds, tokenStarts, tokenLengths);
        long nameLength = program.name.length;
        long globalLength = program.global.length;
        long helperLength = program.helperName.length;
        long nameMainOrder = compareAsciiSliceToMain(
            source, program.name.start, nameLength);
        if (nameMainOrder == 0) {
            assert finalCursor == 1;
        }
        long nameIndex = 0;
        long globalIndex = 0;
        long helperIndex = 0;
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
            long baseNameGlobalOrder = compareAsciiSlices(
                source,
                program.name.start,
                nameLength,
                program.global.start,
                globalLength);
            long baseGlobalMainOrder = compareAsciiSliceToMain(
                source, program.global.start, globalLength);
            if (baseNameGlobalOrder == 0) {
                assert finalCursor == 1;
            }
            if (baseGlobalMainOrder == 0) {
                assert finalCursor == 1;
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
            stringsLength = 20 + nameLength + globalLength;
            typesLength = 32;
        }
        if (program.helperCount == 1) {
            long nameGlobalOrder = compareAsciiSlices(
                source,
                program.name.start,
                nameLength,
                program.global.start,
                globalLength);
            long globalMainOrder = compareAsciiSliceToMain(
                source, program.global.start, globalLength);
            long nameHelperOrder = compareAsciiSlices(
                source,
                program.name.start,
                nameLength,
                program.helperName.start,
                helperLength);
            long globalHelperOrder = compareAsciiSlices(
                source,
                program.global.start,
                globalLength,
                program.helperName.start,
                helperLength);
            long helperMainOrder = compareAsciiSliceToMain(
                source, program.helperName.start, helperLength);
            if (nameHelperOrder == 0) {
                assert finalCursor == 1;
            }
            if (globalHelperOrder == 0) {
                assert finalCursor == 1;
            }
            if (helperMainOrder == 0) {
                assert finalCursor == 1;
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
            stringsLength = 24 + nameLength + globalLength + helperLength;
        }
        long manifestOffset = 232;
        long stringsOffset = 256;
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
        long functionsLength = 44 + localCount * 4;
        long helperLocalCount = statementLocalCount(program.helperOpcode);
        long helperForwardLength = statementCodeLength(program.helperOpcode) + 8;
        long helperInverseLength = 0;
        long helperInverseOffset = 4294967295;
        long entryForwardLength = 24;
        if (program.helperReversible == 1) {
            helperLocalCount = 0;
            helperForwardLength = 32;
            helperInverseLength = 32;
            helperInverseOffset = helperForwardLength;
            entryForwardLength = 40;
        }
        if (program.helperCount == 1) {
            localCount = helperLocalCount;
            functionsLength = 84 + helperLocalCount * 4;
            codeLength = helperForwardLength
                + helperInverseLength
                + entryForwardLength;
        }
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
        cursor = writeUnsignedLittleEndian(
            output, cursor, program.helperCount, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 100000, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 1000000, 8);

        cursor = writeUnsignedLittleEndian(output, cursor, stringCount, 4);
        long stringIndex = 0;
        while (stringIndex < stringCount) limit 4 {
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
            if (program.helperCount == 1) {
                if (stringIndex == helperIndex) {
                    cursor = writeUnsignedLittleEndian(
                        output, cursor, helperLength, 4);
                    cursor = writeAsciiSlice(
                        output,
                        cursor,
                        source,
                        program.helperName.start,
                        helperLength);
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

        cursor = writeUnsignedLittleEndian(
            output, cursor, 1 + program.helperCount, 4);
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
                0);
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
                helperLocalCount);
            long helperType = 0;
            while (helperType < helperLocalCount) limit 2 {
                cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
                helperType += 1;
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
                0);
            long localType = 0;
            while (localType < localCount) limit 8 {
                cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
                localType += 1;
            }
        }
        cursor = align8(cursor);

        if (program.helperCount == 1) {
            if (program.helperReversible == 1) {
                cursor = writeInstructionHeader(output, cursor, 256, 2);
                cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
                cursor = writeSignedLittleEndian(
                    output, cursor, program.helperOperand, 8);
                cursor = writeInstructionHeader(output, cursor, 2, 0);
                cursor = writeInstructionHeader(output, cursor, 257, 2);
                cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
                cursor = writeSignedLittleEndian(
                    output, cursor, program.helperOperand, 8);
                cursor = writeInstructionHeader(output, cursor, 2, 0);
                cursor = writeInstructionHeader(output, cursor, 512, 1);
                cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
                cursor = writeInstructionHeader(output, cursor, 513, 1);
                cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
            } else {
                cursor = writeStatement(
                    output,
                    cursor,
                    program.helperOpcode,
                    program.helperOperand,
                    0);
                cursor = writeInstructionHeader(output, cursor, 2, 0);
                cursor = writeInstructionHeader(output, cursor, 512, 1);
                cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
            }
        } else {
            if (0 < program.statementCount) {
                cursor = writeStatement(
                    output,
                    cursor,
                    program.opcode,
                    program.operand,
                    0);
            }
            if (1 < program.statementCount) {
                cursor = writeStatement(
                    output,
                    cursor,
                    program.secondOpcode,
                    program.secondOperand,
                    firstLocalCount);
            }
            if (2 < program.statementCount) {
                cursor = writeStatement(
                    output,
                    cursor,
                    program.thirdOpcode,
                    program.thirdOperand,
                    firstLocalCount + secondLocalCount);
            }
            if (3 < program.statementCount) {
                cursor = writeStatement(
                    output,
                    cursor,
                    program.fourthOpcode,
                    program.fourthOperand,
                    firstLocalCount + secondLocalCount + thirdLocalCount);
            }
        }
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 8, 4);
        finalCursor = cursor;
        verification = verifyArtifact(output, finalCursor);
        assert verification == 1;
        setOutputLength(output, finalCursor);

        drop(tokenLengths);
        drop(tokenStarts);
        drop(tokenKinds);
        drop(arena);
    }
}
