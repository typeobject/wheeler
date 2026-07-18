//! Decodes strict bounded UTF-8 for the Wheeler-written interpreter.
module wheeler.runtime.utf8_interpreter;
import wheeler.compiler.opcodes;
classical class Utf8Interpreter {
    private boolean byteBetween(long value, long low, long high) {
        if (value < low) {
            return false;
        }
        return value < high + 1;
    }

    /// Returns the checked UTF-8 scalar width at one byte offset.
    public long utf8WidthAt(words starts, words lengths, words data, long handle, long index) {
        if (index < 0) {
            return 0;
        }
        long storage = handle - 1;
        long length = lengths[storage];
        if (index < length) {} else {
            return 0;
        }
        long first = data[starts[storage] + index];
        if (first < 128) {
            return 1;
        }
        if (byteBetween(first, 194, 223)) {
            if (index + 1 < length) {
                if (byteBetween(data[starts[storage] + index + 1], 128, 191)) {
                    return 2;
                }
            }
            return 0;
        }
        if (byteBetween(first, 224, 239)) {
            if (index + 2 < length) {
                long second = data[starts[storage] + index + 1];
                long third = data[starts[storage] + index + 2];
                if (byteBetween(second, 128, 191)) {
                    if (byteBetween(third, 128, 191)) {
                        if (first == 224) {
                            if (second < 160) {
                                return 0;
                            }
                        }
                        if (first == 237) {
                            if (159 < second) {
                                return 0;
                            }
                        }
                        return 3;
                    }
                }
            }
            return 0;
        }
        if (byteBetween(first, 240, 244)) {
            if (index + 3 < length) {
                long fourSecond = data[starts[storage] + index + 1];
                long fourThird = data[starts[storage] + index + 2];
                long fourth = data[starts[storage] + index + 3];
                if (byteBetween(fourSecond, 128, 191)) {
                    if (byteBetween(fourThird, 128, 191)) {
                        if (byteBetween(fourth, 128, 191)) {
                            if (first == 240) {
                                if (fourSecond < 144) {
                                    return 0;
                                }
                            }
                            if (first == 244) {
                                if (143 < fourSecond) {
                                    return 0;
                                }
                            }
                            return 4;
                        }
                    }
                }
            }
        }
        return 0;
    }

    /// Decodes the UTF-8 scalar at one checked byte offset.
    public long utf8ScalarAt(words starts, words lengths, words data, long handle, long index) {
        long width = utf8WidthAt(starts, lengths, data, handle, index);
        long storage = handle - 1;
        long first = data[starts[storage] + index];
        if (width == 1) {
            return first;
        }
        long second = data[starts[storage] + index + 1];
        if (width == 2) {
            return(first & 31) * 64 + (second & 63);
        }
        long third = data[starts[storage] + index + 2];
        if (width == 3) {
            return(first & 15) * 4096 + (second & 63) * 64 + (third & 63);
        }
        long fourth = data[starts[storage] + index + 3];
        if (width == 4) {
            return(first & 7) * 262144 + (second & 63) * 4096 + (third & 63) * 64 + (fourth & 63);
        }
        return -1;
    }

    /// Counts Unicode scalars in one validated UTF-8 buffer.
    public long utf8ScalarCount(words starts, words lengths, words data, long handle) {
        long cursor = 0;
        long count = 0;
        while (cursor < lengths[handle - 1]) limit INTERPRETER_STORAGE_WORDS {
            long width = utf8WidthAt(starts, lengths, data, handle, cursor);
            if (width < 1) {
                return -1;
            }
            cursor += width;
            count += 1;
        }
        return count;
    }
}
