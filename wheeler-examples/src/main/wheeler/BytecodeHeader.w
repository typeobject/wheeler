module examples.compiler.header;
import examples.compiler.encoding;
classical class BytecodeHeader {
    state long finalCursor = 0;

    entry void main(bytes output) {
        long manifestOffset = align8(40 + 6 * 32);
        long stringsOffset = align8(manifestOffset + 24);
        long typesOffset = align8(stringsOffset + 217);
        long variantsOffset = align8(typesOffset + 32);
        long functionsOffset = align8(variantsOffset + 4);
        long codeOffset = align8(functionsOffset + 1632);
        long fileLength = align8(codeOffset + 10544);
        setByte(output, 0, 87);
        setByte(output, 1, 72);
        setByte(output, 2, 69);
        setByte(output, 3, 69);
        setByte(output, 4, 76);
        setByte(output, 5, 66);
        setByte(output, 6, 67);
        setByte(output, 7, 0);
        long cursor = 8;
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, fileLength, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, 6, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 32, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 40, 8);
        cursor = writeDirectoryEntry(output, cursor, 1, manifestOffset, 24);
        cursor = writeDirectoryEntry(output, cursor, 2, stringsOffset, 217);
        cursor = writeDirectoryEntry(output, cursor, 3, typesOffset, 32);
        cursor = writeDirectoryEntry(output, cursor, 4, variantsOffset, 4);
        cursor = writeDirectoryEntry(output, cursor, 5, functionsOffset, 1632);
        cursor = writeDirectoryEntry(output, cursor, 6, codeOffset, 10544);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 3, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 100000, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 1000000, 8);
        finalCursor = cursor;
        assert finalCursor == 256;
    }
}
