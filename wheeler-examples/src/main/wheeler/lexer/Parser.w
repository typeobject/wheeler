module examples.lexer.parser;
import examples.lexer.scanner;
classical class Parser {
    public record SourceRange(long start, long length) {}

    public variant MinimalClassResult {
        case Value(SourceRange name);
        case Error(long offset);
    }

    public variant DeclarationResult {
        case Value(long value);
        case Error(long offset);
    }

    private long tokenHash(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long token
    ) {
        long cursor = tokenStarts[token];
        long end = cursor + tokenLengths[token];
        long hash = 0;
        while (cursor < end) limit 16 {
            hash = hash * 31 + utf8Scalar(source, cursor);
            cursor += utf8Width(source, cursor);
        }
        return hash;
    }

    public MinimalClassResult parseMinimalClass(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long count
    ) {
        if (count == 12) {
            if (tokenHash(source, tokenStarts, tokenLengths, 0)
                    == 87497064671293) {
                if (tokenHash(source, tokenStarts, tokenLengths, 1) == 94742904) {
                    if (tokenKinds[2] == 1) {
                        if (utf8Scalar(source, tokenStarts[3]) == 123) {
                            if (tokenHash(source, tokenStarts, tokenLengths, 4)
                                    == 96667762) {
                                if (tokenHash(source, tokenStarts, tokenLengths, 5)
                                        == 3625364) {
                                    if (tokenHash(source, tokenStarts, tokenLengths, 6)
                                            == 3343801) {
                                        if (utf8Scalar(source, tokenStarts[7]) == 40) {
                                            if (utf8Scalar(source, tokenStarts[8]) == 41) {
                                                if (utf8Scalar(
                                                        source, tokenStarts[9]) == 123) {
                                                    if (utf8Scalar(
                                                            source, tokenStarts[10]) == 125) {
                                                        if (utf8Scalar(
                                                                source,
                                                                tokenStarts[11]) == 125) {
                                                            SourceRange name = new SourceRange(
                                                                tokenStarts[2],
                                                                tokenLengths[2]);
                                                            return new MinimalClassResult.Value(
                                                                name);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return new MinimalClassResult.Error(0);
    }

    private boolean isLongKeyword(
        utf8 source,
        words tokenStarts,
        words tokenLengths
    ) {
        if (tokenLengths[0] == 4) {
            long start = tokenStarts[0];
            if (utf8Scalar(source, start) == 108) {
                if (utf8Scalar(source, start + 1) == 111) {
                    if (utf8Scalar(source, start + 2) == 110) {
                        return utf8Scalar(source, start + 3) == 103;
                    }
                }
            }
        }
        return false;
    }

    public DeclarationResult parseDeclaration(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long count
    ) {
        if (count == 6) {
            if (isLongKeyword(source, tokenStarts, tokenLengths)) {
                if (tokenKinds[1] == 1) {
                    if (tokenKinds[2] == 3) {
                        if (utf8Scalar(source, tokenStarts[2]) == 61) {
                            if (tokenKinds[3] == 2) {
                                if (tokenKinds[4] == 3) {
                                    if (utf8Scalar(source, tokenStarts[4]) == 59) {
                                        if (3 < tokenKinds[5]) {
                                            if (tokenKinds[5] < 6) {
                                                long end = tokenStarts[3]
                                                    + tokenLengths[3];
                                                long value = parseNumber(
                                                    source, tokenStarts[3], end);
                                                if (value < 0) {
                                                    return new DeclarationResult.Error(
                                                        tokenStarts[3]);
                                                }
                                                return new DeclarationResult.Value(value);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return new DeclarationResult.Error(0);
    }
}
