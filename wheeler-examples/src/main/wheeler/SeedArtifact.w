module examples.compiler.seed;
import examples.compiler.encoding;
classical class SeedArtifact {
    state long finalCursor = 0;

    entry void main(utf8 className, bytes output) {
        if (asciiIdentifierValid(className)) {
            finalCursor = 0;
        } else {
            assert finalCursor == 1;
        }
        long nameLength = bufferLength(className);
        long manifestOffset = 232;
        long stringsOffset = 256;
        long stringsLength = 16 + nameLength;
        long typesOffset = align8(stringsOffset + stringsLength);
        long variantsOffset = align8(typesOffset + 16);
        long functionsOffset = align8(variantsOffset + 4);
        long codeOffset = align8(functionsOffset + 44);
        long fileLength = align8(codeOffset + 8);

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
            output, cursor, 3, typesOffset, 16);
        cursor = writeDirectoryEntry(
            output, cursor, 4, variantsOffset, 4);
        cursor = writeDirectoryEntry(
            output, cursor, 5, functionsOffset, 44);
        cursor = writeDirectoryEntry(
            output, cursor, 6, codeOffset, 8);

        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 100000, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 1000000, 8);

        cursor = writeUnsignedLittleEndian(output, cursor, 2, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, nameLength, 4);
        cursor = writeAsciiInput(output, cursor, className);
        cursor = writeUnsignedLittleEndian(output, cursor, 4, 4);
        writeAscii(output, cursor, "main");
        cursor += 4;
        cursor = align8(cursor);

        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = align8(cursor);

        cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 8, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 4294967295, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = align8(cursor);

        cursor = writeUnsignedLittleEndian(output, cursor, 1, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 8, 4);
        finalCursor = cursor;
        setOutputLength(output, finalCursor);
    }
}
