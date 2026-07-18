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

    public long writeAsciiSlice(
        bytes output,
        long offset,
        utf8 input,
        long start,
        long length
    ) {
        long cursor = 0;
        while (cursor < length) limit 256 {
            long inputCursor = start + cursor;
            if (utf8Width(input, inputCursor) == 1) {
                setByte(
                    output,
                    offset + cursor,
                    utf8Scalar(input, inputCursor));
                cursor += 1;
            } else {
                return -1;
            }
        }
        return offset + length;
    }

    public long compareAsciiSlices(
        utf8 input,
        long leftStart,
        long leftLength,
        long rightStart,
        long rightLength
    ) {
        long cursor = 0;
        while (cursor < leftLength) limit 256 {
            if (cursor < rightLength) {
                long left = utf8Scalar(input, leftStart + cursor);
                long right = utf8Scalar(input, rightStart + cursor);
                if (left < right) {
                    return -1;
                }
                if (right < left) {
                    return 1;
                }
                cursor += 1;
            } else {
                return 1;
            }
        }
        if (cursor < rightLength) {
            return -1;
        }
        return 0;
    }

    private long mainScalar(long index) {
        if (index == 0) {
            return 109;
        }
        if (index == 1) {
            return 97;
        }
        if (index == 2) {
            return 105;
        }
        return 110;
    }

    public long compareAsciiSliceToMain(
        utf8 input,
        long start,
        long length
    ) {
        long cursor = 0;
        while (cursor < length) limit 256 {
            if (cursor < 4) {
                long left = utf8Scalar(input, start + cursor);
                long right = mainScalar(cursor);
                if (left < right) {
                    return -1;
                }
                if (right < left) {
                    return 1;
                }
                cursor += 1;
            } else {
                return 1;
            }
        }
        if (cursor < 4) {
            return -1;
        }
        return 0;
    }

    public long writeInstructionHeader(
        bytes output,
        long offset,
        long opcode,
        long operandCount
    ) {
        offset = writeUnsignedLittleEndian(output, offset, opcode, 2);
        offset = writeUnsignedLittleEndian(output, offset, operandCount, 2);
        return writeUnsignedLittleEndian(
            output, offset, 8 + operandCount * 8, 4);
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
