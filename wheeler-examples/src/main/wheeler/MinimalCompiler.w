module examples.compiler.seed;
import examples.compiler.encoding;
import examples.lexer.parser;
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
                return new MinimalProgram(scanName, scanGlobal, 0, 0, 0);
            }
            case ScanResult.Value(long count) {
                MinimalProgramResult parsed = parseMinimalProgram(
                    source, tokenKinds, tokenStarts, tokenLengths, count);
                match (parsed) {
                    case MinimalProgramResult.Error(long parseOffset) {
                        assert finalCursor == 1;
                        SourceRange parseName = new SourceRange(parseOffset, 0);
                        SourceRange parseGlobal = new SourceRange(parseOffset, 0);
                        return new MinimalProgram(parseName, parseGlobal, 0, 0, 0);
                    }
                    case MinimalProgramResult.Value(MinimalProgram program) {
                        return program;
                    }
                }
            }
        }
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
        long nameGlobalOrder = compareAsciiSlices(
            source,
            program.name.start,
            nameLength,
            program.global.start,
            globalLength);
        long nameMainOrder = compareAsciiSliceToMain(
            source, program.name.start, nameLength);
        long globalMainOrder = compareAsciiSliceToMain(
            source, program.global.start, globalLength);
        if (nameGlobalOrder == 0) {
            assert finalCursor == 1;
        }
        if (nameMainOrder == 0) {
            assert finalCursor == 1;
        }
        if (globalMainOrder == 0) {
            assert finalCursor == 1;
        }
        long nameIndex = 0;
        if (0 < nameGlobalOrder) {
            nameIndex += 1;
        }
        if (0 < nameMainOrder) {
            nameIndex += 1;
        }
        long globalIndex = 0;
        if (nameGlobalOrder < 0) {
            globalIndex += 1;
        }
        if (0 < globalMainOrder) {
            globalIndex += 1;
        }
        long mainIndex = 0;
        if (nameMainOrder < 0) {
            mainIndex += 1;
        }
        if (globalMainOrder < 0) {
            mainIndex += 1;
        }
        long manifestOffset = 232;
        long stringsOffset = 256;
        long stringsLength = 20 + nameLength + globalLength;
        long typesOffset = align8(stringsOffset + stringsLength);
        long variantsOffset = align8(typesOffset + 32);
        long functionsOffset = align8(variantsOffset + 4);
        long codeLength = 112;
        long codeOffset = align8(functionsOffset + 52);
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
            output, cursor, 3, typesOffset, 32);
        cursor = writeDirectoryEntry(
            output, cursor, 4, variantsOffset, 4);
        cursor = writeDirectoryEntry(
            output, cursor, 5, functionsOffset, 52);
        cursor = writeDirectoryEntry(
            output, cursor, 6, codeOffset, codeLength);

        cursor = writeUnsignedLittleEndian(output, cursor, nameIndex, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 100000, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 1000000, 8);

        cursor = writeUnsignedLittleEndian(output, cursor, 3, 4);
        long stringIndex = 0;
        while (stringIndex < 3) limit 3 {
            if (stringIndex == nameIndex) {
                cursor = writeUnsignedLittleEndian(
                    output, cursor, nameLength, 4);
                cursor = writeAsciiSlice(
                    output, cursor, source, program.name.start, nameLength);
            }
            if (stringIndex == globalIndex) {
                cursor = writeUnsignedLittleEndian(
                    output, cursor, globalLength, 4);
                cursor = writeAsciiSlice(
                    output, cursor, source, program.global.start, globalLength);
            }
            if (stringIndex == mainIndex) {
                cursor = writeUnsignedLittleEndian(output, cursor, 4, 4);
                writeAscii(output, cursor, "main");
                cursor += 4;
            }
            stringIndex += 1;
        }
        cursor = align8(cursor);

        cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, globalIndex, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
        cursor = writeUnsignedLittleEndian(
            output, cursor, program.initialValue, 8);
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
        cursor = writeUnsignedLittleEndian(output, cursor, 2, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
        cursor = align8(cursor);

        cursor = writeInstructionHeader(output, cursor, 1024, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, program.operand, 8);
        cursor = writeInstructionHeader(output, cursor, 1025, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        cursor = writeInstructionHeader(output, cursor, program.opcode, 3);
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        cursor = writeInstructionHeader(output, cursor, 1026, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 8);
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
