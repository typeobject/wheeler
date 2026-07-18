module examples.lexer.parser;
import examples.lexer.scanner;
classical class Parser {
    public record SourceRange(long start, long length) {}

    public record MinimalProgram(
        SourceRange name,
        SourceRange global,
        long globalCount,
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

    private boolean minimalBodyNameValid(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths
    ) {
        if (tokenKinds[16] == 1) {
            return sameTokenText(
                source, tokenStarts, tokenLengths, 6, 16);
        }
        return false;
    }

    private boolean minimalEmptyValid(
        utf8 source,
        words tokenKinds,
        words tokenStarts
    ) {
        if (punctuationAt(source, tokenKinds, tokenStarts, 16, 125)) {
            return punctuationAt(
                source, tokenKinds, tokenStarts, 17, 125);
        }
        return false;
    }

    private boolean minimalAssignmentValid(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths
    ) {
        if (minimalBodyNameValid(
                source, tokenKinds, tokenStarts, tokenLengths)) {
            if (punctuationAt(source, tokenKinds, tokenStarts, 17, 61)) {
                if (tokenKinds[18] == 2) {
                    if (punctuationAt(
                            source, tokenKinds, tokenStarts, 19, 59)) {
                        if (punctuationAt(
                                source, tokenKinds, tokenStarts, 20, 125)) {
                            return punctuationAt(
                                source, tokenKinds, tokenStarts, 21, 125);
                        }
                    }
                }
            }
        }
        return false;
    }

    private boolean minimalUpdateValid(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths
    ) {
        if (minimalBodyNameValid(
                source, tokenKinds, tokenStarts, tokenLengths)) {
            if (0 < updateOpcode(source, tokenStarts)) {
                if (punctuationAt(
                        source, tokenKinds, tokenStarts, 18, 61)) {
                    if (tokenKinds[19] == 2) {
                        if (punctuationAt(
                                source, tokenKinds, tokenStarts, 20, 59)) {
                            if (punctuationAt(
                                    source, tokenKinds, tokenStarts, 21, 125)) {
                                return punctuationAt(
                                    source, tokenKinds, tokenStarts, 22, 125);
                            }
                        }
                    }
                }
            }
        }
        return false;
    }

    private MinimalProgramResult minimalProgramValue(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long opcode,
        long operandToken
    ) {
        long initialEnd = tokenStarts[8] + tokenLengths[8];
        long initial = parseNumber(source, tokenStarts[8], initialEnd);
        if (initial < 0) {
            return new MinimalProgramResult.Error(tokenStarts[8]);
        }
        long operandEnd = tokenStarts[operandToken]
            + tokenLengths[operandToken];
        long operand = parseNumber(
            source, tokenStarts[operandToken], operandEnd);
        if (operand < 0) {
            return new MinimalProgramResult.Error(tokenStarts[operandToken]);
        }
        SourceRange name = new SourceRange(
            tokenStarts[2], tokenLengths[2]);
        SourceRange global = new SourceRange(
            tokenStarts[6], tokenLengths[6]);
        MinimalProgram program = new MinimalProgram(
            name, global, 1, initial, opcode, operand);
        return new MinimalProgramResult.Value(program);
    }

    private MinimalProgramResult minimalEmptyProgramValue(
        utf8 source,
        words tokenStarts,
        words tokenLengths
    ) {
        long initialEnd = tokenStarts[8] + tokenLengths[8];
        long initial = parseNumber(source, tokenStarts[8], initialEnd);
        if (initial < 0) {
            return new MinimalProgramResult.Error(tokenStarts[8]);
        }
        SourceRange name = new SourceRange(
            tokenStarts[2], tokenLengths[2]);
        SourceRange global = new SourceRange(
            tokenStarts[6], tokenLengths[6]);
        MinimalProgram program = new MinimalProgram(
            name, global, 1, initial, -1, 0);
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

    private boolean minimalCountSupported(long count) {
        if (count == 18) {
            return true;
        }
        if (count == 22) {
            return true;
        }
        return count == 23;
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
        if (minimalCountSupported(count)) {
            if (minimalHeaderValid(
                    source, tokenKinds, tokenStarts, tokenLengths)) {
                if (minimalEntryPrefixValid(
                        source, tokenKinds, tokenStarts, tokenLengths)) {
                    if (count == 18) {
                        if (minimalEmptyValid(
                                source, tokenKinds, tokenStarts)) {
                            return minimalEmptyProgramValue(
                                source, tokenStarts, tokenLengths);
                        }
                    }
                    if (count == 22) {
                        if (minimalAssignmentValid(
                                source,
                                tokenKinds,
                                tokenStarts,
                                tokenLengths)) {
                            return minimalProgramValue(
                                source, tokenStarts, tokenLengths, 0, 18);
                        }
                    }
                    if (count == 23) {
                        if (minimalUpdateValid(
                                source,
                                tokenKinds,
                                tokenStarts,
                                tokenLengths)) {
                            long opcode = updateOpcode(source, tokenStarts);
                            return minimalProgramValue(
                                source,
                                tokenStarts,
                                tokenLengths,
                                opcode,
                                19);
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
