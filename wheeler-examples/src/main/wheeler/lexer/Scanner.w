module examples.lexer.scanner;
classical class Scanner {
    public long tokenKind(long scalar) {
        if (scalar == 10) {
            return 0;
        }
        if (scalar == 32) {
            return 0;
        }
        if (scalar < 48) {
            return 3;
        }
        if (scalar < 58) {
            return 2;
        }
        if (scalar < 65) {
            return 3;
        }
        if (scalar < 91) {
            return 1;
        }
        if (scalar == 95) {
            return 1;
        }
        if (scalar < 97) {
            return 3;
        }
        if (scalar < 123) {
            return 1;
        }
        return 3;
    }

    public long parseNumber(utf8 source, long start, long end) {
        long value = 0;
        long cursor = start;
        while (cursor < end) limit 19 {
            long digit = utf8Scalar(source, cursor) - 48;
            if (value < 922337203685477580) {
                value = value * 10 + digit;
            } else {
                if (value == 922337203685477580) {
                    if (digit < 8) {
                        value = value * 10 + digit;
                    } else {
                        return -1;
                    }
                } else {
                    return -1;
                }
            }
            cursor += utf8Width(source, cursor);
        }
        return value;
    }

    public long commentKind(utf8 source, long cursor, long sourceLength) {
        long next = cursor + utf8Width(source, cursor);
        if (next < sourceLength) {
            long marker = utf8Scalar(source, next);
            if (marker == 47) {
                return 4;
            }
            if (marker == 42) {
                return 5;
            }
        }
        return 0;
    }

    public long asciiLiteralEnd(utf8 source, long cursor, long sourceLength) {
        cursor += utf8Width(source, cursor);
        while (cursor < sourceLength) limit 4096 {
            long scalar = utf8Scalar(source, cursor);
            if (scalar == 34) {
                return cursor + utf8Width(source, cursor);
            }
            if (scalar < 32) {
                return -1;
            }
            if (126 < scalar) {
                return -1;
            }
            cursor += utf8Width(source, cursor);
        }
        return -1;
    }

    public long blockCommentEnd(utf8 source, long cursor, long sourceLength) {
        cursor += utf8Width(source, cursor);
        cursor += utf8Width(source, cursor);
        while (cursor < sourceLength) limit 256 {
            long scalar = utf8Scalar(source, cursor);
            if (scalar == 42) {
                long next = cursor + utf8Width(source, cursor);
                if (next < sourceLength) {
                    if (utf8Scalar(source, next) == 47) {
                        return next + utf8Width(source, next);
                    }
                }
            }
            cursor += utf8Width(source, cursor);
        }
        return -1;
    }
}
