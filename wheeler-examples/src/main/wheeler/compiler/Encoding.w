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
}
