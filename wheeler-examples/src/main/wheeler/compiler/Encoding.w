module examples.compiler.encoding;
classical class Encoding {
    public long writeUnsignedLittleEndian(
        bytes output,
        long offset,
        long value,
        long width
    ) {
        if (value < 0) {
            return -1;
        }
        if (width < 1) {
            return -1;
        }
        if (8 < width) {
            return -1;
        }
        long cursor = 0;
        while (cursor < width) limit 8 {
            setByte(output, offset + cursor, value % 256);
            value = value / 256;
            cursor += 1;
        }
        if (value == 0) {
            return offset + width;
        }
        return -1;
    }

    public long writeDirectoryEntry(
        bytes output,
        long cursor,
        long sectionType,
        long sectionOffset,
        long sectionLength
    ) {
        cursor = writeUnsignedLittleEndian(output, cursor, sectionType, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 1, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, sectionOffset, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, sectionLength, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, 8, 4);
        return writeUnsignedLittleEndian(output, cursor, 0, 4);
    }
}
