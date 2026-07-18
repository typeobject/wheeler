module examples.compiler.parser;
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

    private long signedNumberWidth(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        long token
    ) {
        if (tokenKinds[token] == 2) {
            return 1;
        }
        if (punctuationAt(source, tokenKinds, tokenStarts, token, 45)) {
            if (tokenKinds[token + 1] == 2) {
                return 2;
            }
        }
        return -1;
    }

    private long minimalEntryStart(
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
                                    long width = signedNumberWidth(
                                        source, tokenKinds, tokenStarts, 8);
                                    if (0 < width) {
                                        if (signedNumberValid(
                                                source,
                                                tokenStarts,
                                                tokenLengths,
                                                8)) {
                                            long semicolon = 8 + width;
                                            if (punctuationAt(
                                                    source,
                                                    tokenKinds,
                                                    tokenStarts,
                                                    semicolon,
                                                    59)) {
                                                return semicolon + 1;
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
        return -1;
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

    private long minimalBodyStart(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long entryStart
    ) {
        if (tokenHash(source, tokenStarts, tokenLengths, entryStart)
                == 96667762) {
            if (tokenHash(
                    source, tokenStarts, tokenLengths, entryStart + 1)
                    == 3625364) {
                if (tokenHash(
                        source, tokenStarts, tokenLengths, entryStart + 2)
                        == 3343801) {
                    if (punctuationAt(
                            source,
                            tokenKinds,
                            tokenStarts,
                            entryStart + 3,
                            40)) {
                        if (punctuationAt(
                                source,
                                tokenKinds,
                                tokenStarts,
                                entryStart + 4,
                                41)) {
                            if (punctuationAt(
                                    source,
                                    tokenKinds,
                                    tokenStarts,
                                    entryStart + 5,
                                    123)) {
                                return entryStart + 6;
                            }
                        }
                    }
                }
            }
        }
        return -1;
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
                    long operandWidth = signedNumberWidth(
                        source,
                        tokenKinds,
                        tokenStarts,
                        statementStart + 2);
                    if (0 < operandWidth) {
                        if (signedNumberValid(
                                source,
                                tokenStarts,
                                tokenLengths,
                                statementStart + 2)) {
                            if (punctuationAt(
                                    source,
                                    tokenKinds,
                                    tokenStarts,
                                    statementStart + 2 + operandWidth,
                                    59)) {
                                return 3 + operandWidth;
                            }
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
                        long updateOperandWidth = signedNumberWidth(
                            source,
                            tokenKinds,
                            tokenStarts,
                            statementStart + 3);
                        if (0 < updateOperandWidth) {
                            if (signedNumberValid(
                                    source,
                                    tokenStarts,
                                    tokenLengths,
                                    statementStart + 3)) {
                                if (punctuationAt(
                                        source,
                                        tokenKinds,
                                        tokenStarts,
                                        statementStart + 3 + updateOperandWidth,
                                        59)) {
                                    return 4 + updateOperandWidth;
                                }
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

    private boolean signedNumberValid(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long token
    ) {
        long magnitudeToken = token;
        if (utf8Scalar(source, tokenStarts[token]) == 45) {
            magnitudeToken += 1;
        }
        long end = tokenStarts[magnitudeToken]
            + tokenLengths[magnitudeToken];
        long magnitude = parseNumber(
            source, tokenStarts[magnitudeToken], end);
        if (magnitude < 0) {
            return false;
        }
        return true;
    }

    private long parsedSignedNumber(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long token
    ) {
        long magnitudeToken = token;
        long sign = 1;
        if (utf8Scalar(source, tokenStarts[token]) == 45) {
            magnitudeToken += 1;
            sign = -1;
        }
        long end = tokenStarts[magnitudeToken]
            + tokenLengths[magnitudeToken];
        long magnitude = parseNumber(
            source, tokenStarts[magnitudeToken], end);
        return sign * magnitude;
    }

    private MinimalProgramResult minimalProgramValue(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long firstStart,
        long secondStart
    ) {
        long initial = parsedSignedNumber(
            source, tokenStarts, tokenLengths, 8);
        long opcode = statementOpcode(source, tokenStarts, firstStart);
        long operandToken = statementOperandToken(
            source, tokenStarts, firstStart);
        long operand = parsedSignedNumber(
            source, tokenStarts, tokenLengths, operandToken);
        long statementCount = 1;
        long secondOpcode = -1;
        long secondOperand = 0;
        if (0 < secondStart) {
            statementCount = 2;
            secondOpcode = statementOpcode(
                source, tokenStarts, secondStart);
            long secondOperandToken = statementOperandToken(
                source, tokenStarts, secondStart);
            secondOperand = parsedSignedNumber(
                source,
                tokenStarts,
                tokenLengths,
                secondOperandToken);
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
        long initial = parsedSignedNumber(
            source, tokenStarts, tokenLengths, 8);
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
            return count < 32;
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
            long entryStart = minimalEntryStart(
                source, tokenKinds, tokenStarts, tokenLengths);
            if (0 < entryStart) {
                long bodyStart = minimalBodyStart(
                    source,
                    tokenKinds,
                    tokenStarts,
                    tokenLengths,
                    entryStart);
                if (0 < bodyStart) {
                    if (punctuationAt(
                            source,
                            tokenKinds,
                            tokenStarts,
                            bodyStart,
                            125)) {
                        if (punctuationAt(
                                source,
                                tokenKinds,
                                tokenStarts,
                                bodyStart + 1,
                                125)) {
                            if (count == bodyStart + 2) {
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
                        bodyStart);
                    if (0 < firstWidth) {
                        long firstEnd = bodyStart + firstWidth;
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
                                        bodyStart,
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
                                            bodyStart,
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

}
