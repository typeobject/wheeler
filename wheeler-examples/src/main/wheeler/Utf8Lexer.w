// Bounded immutable UTF-8 scanner with explicit token and comment output.
classical class Utf8Lexer {
    variant Assignment {
        case Value(long value);
        case Error(long offset);
    }

    state long tokenCount = 0;
    state long numberStart = 0;
    state long commentStart = 0;
    state long numericValue = 0;
    state long parseError = -1;
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

    long parseNumber(utf8 source, long start, long end) {
        long value = 0;
        long cursor = start;
        while (cursor < end) limit 10 {
            long digit = utf8Scalar(source, cursor) - 48;
            value = value * 10 + digit;
            cursor += utf8Width(source, cursor);
        }
        return value;
    }

    Assignment parseAssignment(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long count
    ) {
        if (count == 5) {
            if (tokenKinds[0] == 1) {
                if (tokenKinds[1] == 3) {
                    if (utf8Scalar(source, tokenStarts[1]) == 61) {
                        if (tokenKinds[2] == 2) {
                            if (tokenKinds[3] == 3) {
                                if (utf8Scalar(source, tokenStarts[3]) == 59) {
                                    if (tokenKinds[4] == 4) {
                                        long end = tokenStarts[2] + tokenLengths[2];
                                        long value = parseNumber(
                                            source, tokenStarts[2], end);
                                        return new Assignment.Value(value);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return new Assignment.Error(0);
    }

    boolean startsComment(utf8 source, long cursor, long sourceLength) {
        long next = cursor + utf8Width(source, cursor);
        if (next < sourceLength) {
            return utf8Scalar(source, next) == 47;
        }
        return false;
    }

    entry void main(utf8 source) {
        region arena = new region(384, 3);
        words tokenKinds = allocate(arena, 16);
        words tokenStarts = allocate(arena, 16);
        words tokenLengths = allocate(arena, 16);
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
                long tokenIndex = count;
                long tokenStart = cursor;
                set(tokenKinds, tokenIndex, kind);
                set(tokenStarts, tokenIndex, tokenStart);
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
                set(tokenLengths, tokenIndex, cursor - tokenStart);
            }
        }

        tokenCount = count;
        numberStart = tokenStarts[2];
        commentStart = tokenStarts[4];
        Assignment parsed = parseAssignment(
            source, tokenKinds, tokenStarts, tokenLengths, tokenCount);
        match (parsed) {
            case Assignment.Value(long value) {
                numericValue = value;
                parseError = 0;
            }
            case Assignment.Error(long offset) {
                numericValue = -1;
                parseError = offset + 1;
            }
        }
        finalCursor = cursor;
        assert tokenCount == 5;
        assert numberStart == 2;
        assert commentStart == 6;
        assert numericValue == 123;
        assert parseError == 0;
        assert finalCursor == 10;

        drop(tokenLengths);
        drop(tokenStarts);
        drop(tokenKinds);
        drop(arena);
    }
}
