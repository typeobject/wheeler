// Bounded immutable UTF-8 scanner with explicit token and comment output.
classical class Utf8Lexer {
    state long tokenCount = 0;
    state long numberStart = 0;
    state long commentStart = 0;
    state long finalCursor = 0;

    long tokenKind(long scalar) {
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

    boolean startsComment(utf8 source, long cursor, long sourceLength) {
        long next = cursor + utf8Width(source, cursor);
        if (next < sourceLength) {
            return utf8Scalar(source, next) == 47;
        }
        return false;
    }

    entry void main() {
        region arena = new region(266, 3);
        bytes raw = allocateBytes(arena, 10);
        setByte(raw, 0, 120);
        setByte(raw, 1, 61);
        setByte(raw, 2, 49);
        setByte(raw, 3, 50);
        setByte(raw, 4, 51);
        setByte(raw, 5, 59);
        setByte(raw, 6, 47);
        setByte(raw, 7, 47);
        setByte(raw, 8, 99);
        setByte(raw, 9, 10);
        utf8 source = freezeUtf8(raw);

        words tokenKinds = allocate(arena, 16);
        words tokenStarts = allocate(arena, 16);
        long sourceLength = bufferLength(source);
        long count = 0;
        long cursor = 0;

        while (cursor < sourceLength) limit 10 {
            long scalar = utf8Scalar(source, cursor);
            long width = utf8Width(source, cursor);
            long kind = tokenKind(scalar);
            if (scalar == 47) {
                boolean comment = startsComment(source, cursor, sourceLength);
                if (comment) {
                    kind = 4;
                }
            }
            if (kind == 0) {
                cursor += width;
            } else {
                set(tokenKinds, count, kind);
                set(tokenStarts, count, cursor);
                count += 1;
                cursor += width;

                if (kind < 3) {
                    boolean scanning = true;
                    while (scanning) limit 10 {
                        if (cursor < sourceLength) {
                            long next = utf8Scalar(source, cursor);
                            long nextKind = tokenKind(next);
                            if (nextKind == kind) {
                                cursor += utf8Width(source, cursor);
                            } else {
                                scanning = false;
                            }
                        } else {
                            scanning = false;
                        }
                    }
                } else {
                    if (kind == 4) {
                        boolean scanningComment = true;
                        while (scanningComment) limit 10 {
                            if (cursor < sourceLength) {
                                long nextComment = utf8Scalar(source, cursor);
                                if (nextComment == 10) {
                                    scanningComment = false;
                                } else {
                                    cursor += utf8Width(source, cursor);
                                }
                            } else {
                                scanningComment = false;
                            }
                        }
                    }
                }
            }
        }

        tokenCount = count;
        numberStart = tokenStarts[2];
        commentStart = tokenStarts[4];
        finalCursor = cursor;
        assert tokenCount == 5;
        assert numberStart == 2;
        assert commentStart == 6;
        assert finalCursor == 10;

        drop(tokenStarts);
        drop(tokenKinds);
        drop(source);
        drop(arena);
    }
}
