module examples.lexer.parser;
import examples.lexer.scanner;
classical class Parser {
    public record SourceRange(long start, long length) {}

    public record MinimalProgram(
        SourceRange name,
        SourceRange global,
        long globalCount,
        long initialValue,
        long statementCount,
        long opcode,
        long operand,
        long secondOpcode,
        long secondOperand
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
        words tokenKinds,
        words tokenLengths
    ) {
        if (tokenKinds[2] == 1) {
            if (tokenLengths[2] < 257) {
                if (tokenKinds[6] == 1) {
                    return tokenLengths[6] < 257;
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
                if (canonicalMinimalNames(tokenKinds, tokenLengths)) {
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

    private long statementOpcode(
        utf8 source,
        words tokenStarts,
        long statementStart
    ) {
        long operator = utf8Scalar(
            source, tokenStarts[statementStart + 1]);
        if (operator == 61) {
            return 0;
        }
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

    private boolean minimalEntryPrefixValid(
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
                            return punctuationAt(
                                source, tokenKinds, tokenStarts, 15, 123);
                        }
                    }
                }
            }
        }
        return false;
    }

    private long statementWidth(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long statementStart
    ) {
        if (tokenKinds[statementStart] == 1) {
            if (sameTokenText(
                    source,
                    tokenStarts,
                    tokenLengths,
                    6,
                    statementStart)) {
                long opcode = statementOpcode(
                    source, tokenStarts, statementStart);
                if (opcode == 0) {
                    if (tokenKinds[statementStart + 2] == 2) {
                        if (punctuationAt(
                                source,
                                tokenKinds,
                                tokenStarts,
                                statementStart + 3,
                                59)) {
                            return 4;
                        }
                    }
                }
                if (0 < opcode) {
                    if (punctuationAt(
                            source,
                            tokenKinds,
                            tokenStarts,
                            statementStart + 2,
                            61)) {
                        if (tokenKinds[statementStart + 3] == 2) {
                            if (punctuationAt(
                                    source,
                                    tokenKinds,
                                    tokenStarts,
                                    statementStart + 4,
                                    59)) {
                                return 5;
                            }
                        }
                    }
                }
            }
        }
        return -1;
    }

    private long statementOperandToken(
        utf8 source,
        words tokenStarts,
        long statementStart
    ) {
        long opcode = statementOpcode(
            source, tokenStarts, statementStart);
        if (opcode == 0) {
            return statementStart + 2;
        }
        return statementStart + 3;
    }

    private long parsedNumber(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long token
    ) {
        long end = tokenStarts[token] + tokenLengths[token];
        return parseNumber(source, tokenStarts[token], end);
    }

    private MinimalProgramResult minimalProgramValue(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long firstStart,
        long secondStart
    ) {
        long initial = parsedNumber(
            source, tokenStarts, tokenLengths, 8);
        if (initial < 0) {
            return new MinimalProgramResult.Error(tokenStarts[8]);
        }
        long opcode = statementOpcode(source, tokenStarts, firstStart);
        long operandToken = statementOperandToken(
            source, tokenStarts, firstStart);
        long operand = parsedNumber(
            source, tokenStarts, tokenLengths, operandToken);
        if (operand < 0) {
            return new MinimalProgramResult.Error(tokenStarts[operandToken]);
        }
        long statementCount = 1;
        long secondOpcode = -1;
        long secondOperand = 0;
        if (0 < secondStart) {
            statementCount = 2;
            secondOpcode = statementOpcode(
                source, tokenStarts, secondStart);
            long secondOperandToken = statementOperandToken(
                source, tokenStarts, secondStart);
            secondOperand = parsedNumber(
                source,
                tokenStarts,
                tokenLengths,
                secondOperandToken);
            if (secondOperand < 0) {
                return new MinimalProgramResult.Error(
                    tokenStarts[secondOperandToken]);
            }
        }
        SourceRange name = new SourceRange(
            tokenStarts[2], tokenLengths[2]);
        SourceRange global = new SourceRange(
            tokenStarts[6], tokenLengths[6]);
        MinimalProgram program = new MinimalProgram(
            name,
            global,
            1,
            initial,
            statementCount,
            opcode,
            operand,
            secondOpcode,
            secondOperand);
        return new MinimalProgramResult.Value(program);
    }

    private MinimalProgramResult minimalEmptyProgramValue(
        utf8 source,
        words tokenStarts,
        words tokenLengths
    ) {
        long initial = parsedNumber(
            source, tokenStarts, tokenLengths, 8);
        if (initial < 0) {
            return new MinimalProgramResult.Error(tokenStarts[8]);
        }
        SourceRange name = new SourceRange(
            tokenStarts[2], tokenLengths[2]);
        SourceRange global = new SourceRange(
            tokenStarts[6], tokenLengths[6]);
        MinimalProgram program = new MinimalProgram(
            name, global, 1, initial, 0, -1, 0, -1, 0);
        return new MinimalProgramResult.Value(program);
    }

    private MinimalProgramResult minimalNoGlobalProgram(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths
    ) {
        if (tokenHash(source, tokenStarts, tokenLengths, 0)
                == 87497064671293) {
            if (tokenHash(source, tokenStarts, tokenLengths, 1) == 94742904) {
                if (tokenKinds[2] == 1) {
                    if (tokenLengths[2] < 257) {
                        if (punctuationAt(
                                source, tokenKinds, tokenStarts, 3, 123)) {
                            if (tokenHash(
                                    source, tokenStarts, tokenLengths, 4)
                                    == 96667762) {
                                if (tokenHash(
                                        source, tokenStarts, tokenLengths, 5)
                                        == 3625364) {
                                    if (tokenHash(
                                            source, tokenStarts, tokenLengths, 6)
                                            == 3343801) {
                                        if (punctuationAt(
                                                source,
                                                tokenKinds,
                                                tokenStarts,
                                                7,
                                                40)) {
                                            if (punctuationAt(
                                                    source,
                                                    tokenKinds,
                                                    tokenStarts,
                                                    8,
                                                    41)) {
                                                if (punctuationAt(
                                                        source,
                                                        tokenKinds,
                                                        tokenStarts,
                                                        9,
                                                        123)) {
                                                    if (punctuationAt(
                                                            source,
                                                            tokenKinds,
                                                            tokenStarts,
                                                            10,
                                                            125)) {
                                                        if (punctuationAt(
                                                                source,
                                                                tokenKinds,
                                                                tokenStarts,
                                                                11,
                                                                125)) {
                                                            SourceRange name =
                                                                new SourceRange(
                                                                    tokenStarts[2],
                                                                    tokenLengths[2]);
                                                            SourceRange global =
                                                                new SourceRange(0, 0);
                                                            MinimalProgram program =
                                                                new MinimalProgram(
                                                                    name,
                                                                    global,
                                                                    0,
                                                                    0,
                                                                    0,
                                                                    -1,
                                                                    0,
                                                                    -1,
                                                                    0);
                                                            return new MinimalProgramResult.Value(
                                                                program);
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
        return new MinimalProgramResult.Error(0);
    }

    private boolean minimalStateCountSupported(long count) {
        if (17 < count) {
            return count < 29;
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
        if (count == 12) {
            return minimalNoGlobalProgram(
                source, tokenKinds, tokenStarts, tokenLengths);
        }
        if (minimalStateCountSupported(count)) {
            if (minimalHeaderValid(
                    source, tokenKinds, tokenStarts, tokenLengths)) {
                if (minimalEntryPrefixValid(
                        source, tokenKinds, tokenStarts, tokenLengths)) {
                    if (punctuationAt(
                            source, tokenKinds, tokenStarts, 16, 125)) {
                        if (punctuationAt(
                                source, tokenKinds, tokenStarts, 17, 125)) {
                            if (count == 18) {
                                return minimalEmptyProgramValue(
                                    source, tokenStarts, tokenLengths);
                            }
                        }
                    }
                    long firstWidth = statementWidth(
                        source,
                        tokenKinds,
                        tokenStarts,
                        tokenLengths,
                        16);
                    if (0 < firstWidth) {
                        long firstEnd = 16 + firstWidth;
                        if (punctuationAt(
                                source,
                                tokenKinds,
                                tokenStarts,
                                firstEnd,
                                125)) {
                            if (punctuationAt(
                                    source,
                                    tokenKinds,
                                    tokenStarts,
                                    firstEnd + 1,
                                    125)) {
                                if (count == firstEnd + 2) {
                                    return minimalProgramValue(
                                        source,
                                        tokenStarts,
                                        tokenLengths,
                                        16,
                                        -1);
                                }
                            }
                        }
                        long secondWidth = statementWidth(
                            source,
                            tokenKinds,
                            tokenStarts,
                            tokenLengths,
                            firstEnd);
                        if (0 < secondWidth) {
                            long secondEnd = firstEnd + secondWidth;
                            if (punctuationAt(
                                    source,
                                    tokenKinds,
                                    tokenStarts,
                                    secondEnd,
                                    125)) {
                                if (punctuationAt(
                                        source,
                                        tokenKinds,
                                        tokenStarts,
                                        secondEnd + 1,
                                        125)) {
                                    if (count == secondEnd + 2) {
                                        return minimalProgramValue(
                                            source,
                                            tokenStarts,
                                            tokenLengths,
                                            16,
                                            firstEnd);
                                    }
                                }
                            }
                        }
                    }
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
