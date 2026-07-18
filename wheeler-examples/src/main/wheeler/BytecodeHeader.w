module examples.compiler.header;
import examples.compiler.encoding;
classical class BytecodeHeader {
    state long finalCursor = 0;

    entry void main(bytes output) {
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
        cursor = writeUnsignedLittleEndian(output, cursor, 40, 8);
        finalCursor = cursor;
        assert finalCursor == 24;
    }
}
