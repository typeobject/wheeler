// Bounded UTF-8 scanner over a fixed source buffer with explicit token output.
classical class Utf8Lexer {
    state long tokenCount = 0;
    state long numberStart = 0;
    state long finalCursor = 0;

    long tokenKind(long scalar) {
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

    entry void main() {
        region arena = new region(271, 3);
        bytes source = allocateBytes(arena, 15);
        setByte(source, 0, 108);
        setByte(source, 1, 111);
        setByte(source, 2, 110);
        setByte(source, 3, 103);
        setByte(source, 4, 32);
        setByte(source, 5, 118);
        setByte(source, 6, 97);
        setByte(source, 7, 108);
        setByte(source, 8, 117);
        setByte(source, 9, 101);
        setByte(source, 10, 61);
        setByte(source, 11, 49);
        setByte(source, 12, 50);
        setByte(source, 13, 51);
        setByte(source, 14, 59);

        words tokenKinds = allocate(arena, 16);
        words tokenStarts = allocate(arena, 16);
        long sourceLength = bufferLength(source);
        long count = 0;
        long cursor = 0;

        while (cursor < sourceLength) limit 15 {
            long scalar = utf8Scalar(source, cursor);
            long width = utf8Width(source, cursor);
            long kind = tokenKind(scalar);
            if (kind == 0) {
                cursor += width;
            } else {
                set(tokenKinds, count, kind);
                set(tokenStarts, count, cursor);
                count += 1;
                cursor += width;

                if (kind < 3) {
                    boolean scanning = true;
                    while (scanning) limit 15 {
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
                }
            }
        }

        tokenCount = count;
        numberStart = tokenStarts[3];
        finalCursor = cursor;
        assert tokenCount == 5;
        assert numberStart == 11;
        assert finalCursor == 15;

        drop(tokenStarts);
        drop(tokenKinds);
        drop(source);
        drop(arena);
    }
}
