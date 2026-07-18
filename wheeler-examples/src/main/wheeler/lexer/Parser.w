module examples.lexer.parser;
import examples.lexer.scanner;
classical class Parser {
    public variant DeclarationResult {
        case Value(long value);
        case Error(long offset);
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
