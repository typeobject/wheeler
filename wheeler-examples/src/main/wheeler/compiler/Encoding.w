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

    private boolean asciiIdentifierStart(long scalar) {
        if (scalar == 95) {
            return true;
        }
        if (64 < scalar) {
            if (scalar < 91) {
                return true;
            }
        }
        if (96 < scalar) {
            return scalar < 123;
        }
        return false;
    }

    private boolean asciiIdentifierPart(long scalar) {
        if (asciiIdentifierStart(scalar)) {
            return true;
        }
        if (47 < scalar) {
            return scalar < 58;
        }
        return false;
    }

    public boolean asciiIdentifierValid(utf8 input) {
        long length = bufferLength(input);
        if (length < 1) {
            return false;
        }
        if (256 < length) {
            return false;
        }
        if (utf8Width(input, 0) == 1) {
            if (asciiIdentifierStart(utf8Scalar(input, 0))) {
                long cursor = 1;
                while (cursor < length) limit 256 {
                    if (utf8Width(input, cursor) == 1) {
                        if (asciiIdentifierPart(utf8Scalar(input, cursor))) {
                            cursor += 1;
                        } else {
                            return false;
                        }
                    } else {
                        return false;
                    }
                }
                return true;
            }
        }
        return false;
    }

    public long writeAsciiInput(
        bytes output,
        long offset,
        utf8 input
    ) {
        long length = bufferLength(input);
        long cursor = 0;
        while (cursor < length) limit 256 {
            long width = utf8Width(input, cursor);
            if (width == 1) {
                setByte(output, offset + cursor, utf8Scalar(input, cursor));
                cursor += 1;
            } else {
                return -1;
            }
        }
        return offset + length;
    }

    public long align8(long value) {
        if (value < 0) {
            return -1;
        }
        long remainder = value % 8;
        if (remainder == 0) {
            return value;
        }
        return value + (8 - remainder);
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
