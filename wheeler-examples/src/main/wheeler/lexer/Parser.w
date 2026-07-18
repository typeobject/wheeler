module examples.lexer.parser;
import examples.lexer.scanner;
classical class Parser {
    public variant AssignmentResult {
        case Value(long value);
        case Error(long offset);
    }

    public AssignmentResult parseAssignment(
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
                                    if (3 < tokenKinds[4]) {
                                        if (tokenKinds[4] < 6) {
                                            long end = tokenStarts[2] + tokenLengths[2];
                                            long value = parseNumber(
                                                source, tokenStarts[2], end);
                                            if (value < 0) {
                                                return new AssignmentResult.Error(
                                                    tokenStarts[2]);
                                            }
                                            return new AssignmentResult.Value(value);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return new AssignmentResult.Error(0);
    }
}
