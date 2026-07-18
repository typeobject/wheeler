module examples.lexer.parser;
import examples.lexer.scanner;
classical class Parser {
    public record SourceRange(long start, long length) {}

    public record MinimalProgram(
        SourceRange name,
        SourceRange global,
        long initialValue,
        long opcode,
        long operand
    ) {}

    public variant MinimalProgramResult {
        case Value(MinimalProgram program);
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

    private boolean punctuationAt(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        long token,
        long scalar
    ) {
        if (tokenKinds[token] == 3) {
            return utf8Scalar(source, tokenStarts[token]) == scalar;
        }
        return false;
    }

    private boolean sameTokenText(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long left,
        long right
    ) {
        if (tokenLengths[left] == tokenLengths[right]) {
            long cursor = 0;
            while (cursor < tokenLengths[left]) limit 256 {
                long leftScalar = utf8Scalar(
                    source, tokenStarts[left] + cursor);
                long rightScalar = utf8Scalar(
                    source, tokenStarts[right] + cursor);
                if (leftScalar < rightScalar) {
                    return false;
                }
                if (rightScalar < leftScalar) {
                    return false;
                }
                cursor += 1;
            }
            return true;
        }
        return false;
    }

    private boolean canonicalMinimalNames(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths
    ) {
        if (tokenKinds[2] == 1) {
            if (tokenLengths[2] < 257) {
                if (tokenKinds[6] == 1) {
                    if (tokenLengths[6] < 257) {
                        if (tokenKinds[16] == 1) {
                            return sameTokenText(
                                source,
                                tokenStarts,
                                tokenLengths,
                                6,
                                16);
                        }
                    }
                }
            }
        }
        return false;
    }

    private boolean minimalHeaderValid(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths
    ) {
        if (tokenHash(source, tokenStarts, tokenLengths, 0)
                == 87497064671293) {
            if (tokenHash(source, tokenStarts, tokenLengths, 1) == 94742904) {
                if (canonicalMinimalNames(
                        source, tokenKinds, tokenStarts, tokenLengths)) {
                    if (punctuationAt(source, tokenKinds, tokenStarts, 3, 123)) {
                        if (tokenHash(source, tokenStarts, tokenLengths, 4)
                                == 109757585) {
                            if (tokenHash(source, tokenStarts, tokenLengths, 5)
                                    == 3327612) {
                                if (punctuationAt(
                                        source, tokenKinds, tokenStarts, 7, 61)) {
                                    if (tokenKinds[8] == 2) {
                                        return punctuationAt(
                                            source,
                                            tokenKinds,
                                            tokenStarts,
                                            9,
                                            59);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return false;
    }

    private long updateOpcode(
        utf8 source,
        words tokenStarts
    ) {
        long operator = utf8Scalar(source, tokenStarts[17]);
        if (operator == 43) {
            return 1040;
        }
        if (operator == 45) {
            return 1041;
        }
        if (operator == 94) {
            return 1042;
        }
        return -1;
    }

    private boolean minimalEntryValid(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths
    ) {
        if (tokenHash(source, tokenStarts, tokenLengths, 10) == 96667762) {
            if (tokenHash(source, tokenStarts, tokenLengths, 11) == 3625364) {
                if (tokenHash(source, tokenStarts, tokenLengths, 12) == 3343801) {
                    if (punctuationAt(
                            source, tokenKinds, tokenStarts, 13, 40)) {
                        if (punctuationAt(
                                source, tokenKinds, tokenStarts, 14, 41)) {
                            if (punctuationAt(
                                    source, tokenKinds, tokenStarts, 15, 123)) {
                                if (0 < updateOpcode(source, tokenStarts)) {
                                    if (punctuationAt(
                                            source, tokenKinds, tokenStarts, 18, 61)) {
                                        if (tokenKinds[19] == 2) {
                                            if (punctuationAt(
                                                    source,
                                                    tokenKinds,
                                                    tokenStarts,
                                                    20,
                                                    59)) {
                                                if (punctuationAt(
                                                        source,
                                                        tokenKinds,
                                                        tokenStarts,
                                                        21,
                                                        125)) {
                                                    return punctuationAt(
                                                        source,
                                                        tokenKinds,
                                                        tokenStarts,
                                                        22,
                                                        125);
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
        return false;
    }

    public MinimalProgramResult parseMinimalProgram(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long count
    ) {
        if (count == 23) {
            if (minimalHeaderValid(
                    source, tokenKinds, tokenStarts, tokenLengths)) {
                if (minimalEntryValid(
                        source, tokenKinds, tokenStarts, tokenLengths)) {
                    long initialEnd = tokenStarts[8] + tokenLengths[8];
                    long initial = parseNumber(
                        source, tokenStarts[8], initialEnd);
                    if (initial < 0) {
                        return new MinimalProgramResult.Error(tokenStarts[8]);
                    }
                    long operandEnd = tokenStarts[19] + tokenLengths[19];
                    long operand = parseNumber(
                        source, tokenStarts[19], operandEnd);
                    if (operand < 0) {
                        return new MinimalProgramResult.Error(tokenStarts[19]);
                    }
                    long opcode = updateOpcode(source, tokenStarts);
                    SourceRange name = new SourceRange(
                        tokenStarts[2], tokenLengths[2]);
                    SourceRange global = new SourceRange(
                        tokenStarts[6], tokenLengths[6]);
                    MinimalProgram program = new MinimalProgram(
                        name, global, initial, opcode, operand);
                    return new MinimalProgramResult.Value(program);
                }
            }
        }
        return new MinimalProgramResult.Error(0);
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
                    if (punctuationAt(
                            source, tokenKinds, tokenStarts, 2, 61)) {
                        if (tokenKinds[3] == 2) {
                            if (punctuationAt(
                                    source, tokenKinds, tokenStarts, 4, 59)) {
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
        return new DeclarationResult.Error(0);
    }
}
