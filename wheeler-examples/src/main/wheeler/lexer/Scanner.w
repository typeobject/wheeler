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
        while (cursor < end) limit 10 {
            long digit = utf8Scalar(source, cursor) - 48;
            value = value * 10 + digit;
            cursor += utf8Width(source, cursor);
        }
        return value;
    }

    public boolean startsComment(utf8 source, long cursor, long sourceLength) {
        long next = cursor + utf8Width(source, cursor);
        if (next < sourceLength) {
            return utf8Scalar(source, next) == 47;
        }
        return false;
    }
}
