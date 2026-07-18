//! Parses the bounded Wheeler bootstrap source profile into IR.

module examples.compiler.parser;
import examples.compiler.helper_parser;
import examples.compiler.ir;
import examples.compiler.statements;
import examples.compiler.structure;
import examples.compiler.tokens;
classical class Parser {

    private MinimalProgramResult minimalProgramValue(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long firstStart,
        long secondStart,
        long thirdStart,
        long fourthStart
    ) {
        long initial = parsedSignedNumber(source, tokenStarts, tokenLengths, 8);
        long opcode = statementOpcode(source, tokenStarts, tokenLengths, firstStart);
        long operandToken = statementOperandToken(source, tokenStarts, tokenLengths, firstStart);
        long operand = parsedSignedNumber(source, tokenStarts, tokenLengths, operandToken);
        long statementCount = 1;
        long secondOpcode = -1;
        long secondOperand = 0;
        long thirdOpcode = -1;
        long thirdOperand = 0;
        long fourthOpcode = -1;
        long fourthOperand = 0;
        if (0 < secondStart) {
            statementCount = 2;
            secondOpcode = statementOpcode(source, tokenStarts, tokenLengths, secondStart);
            long secondOperandToken = statementOperandToken(
                source,
                tokenStarts,
                tokenLengths,
                secondStart
            );
            secondOperand = parsedSignedNumber(
                source,
                tokenStarts,
                tokenLengths,
                secondOperandToken
            );
        }
        if (0 < thirdStart) {
            statementCount = 3;
            thirdOpcode = statementOpcode(source, tokenStarts, tokenLengths, thirdStart);
            long thirdOperandToken = statementOperandToken(
                source,
                tokenStarts,
                tokenLengths,
                thirdStart
            );
            thirdOperand = parsedSignedNumber(
                source,
                tokenStarts,
                tokenLengths,
                thirdOperandToken
            );
        }
        if (0 < fourthStart) {
            statementCount = 4;
            fourthOpcode = statementOpcode(source, tokenStarts, tokenLengths, fourthStart);
            long fourthOperandToken = statementOperandToken(
                source,
                tokenStarts,
                tokenLengths,
                fourthStart
            );
            fourthOperand = parsedSignedNumber(
                source,
                tokenStarts,
                tokenLengths,
                fourthOperandToken
            );
        }
        SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
        SourceRange global = new SourceRange(tokenStarts[6], tokenLengths[6]);
        SourceRange helper = new SourceRange(0, 0);
        MinimalProgram program = new MinimalProgram(
            name,
            global,
            1,
            initial,
            statementCount,
            opcode,
            operand,
            secondOpcode,
            secondOperand,
            thirdOpcode,
            thirdOperand,
            fourthOpcode,
            fourthOperand,
            helper,
            0,
            -1,
            0,
            0,
            helper,
            0,
            0,
            0,
            0,
            -1,
            0,
            -1,
            0,
            -1,
            0
        );
        return new MinimalProgramResult.Value(program);
    }

    private MinimalProgramResult minimalEmptyProgramValue(
        utf8 source,
        words tokenStarts,
        words tokenLengths
    ) {
        long initial = parsedSignedNumber(source, tokenStarts, tokenLengths, 8);
        SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
        SourceRange global = new SourceRange(tokenStarts[6], tokenLengths[6]);
        SourceRange helper = new SourceRange(0, 0);
        MinimalProgram program = new MinimalProgram(
            name,
            global,
            1,
            initial,
            0,
            -1,
            0,
            -1,
            0,
            -1,
            0,
            -1,
            0,
            helper,
            0,
            -1,
            0,
            0,
            helper,
            0,
            0,
            0,
            0,
            -1,
            0,
            -1,
            0,
            -1,
            0
        );
        return new MinimalProgramResult.Value(program);
    }

    private long minimalNoGlobalBodyStart(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths
    ) {
        if (tokenHash(source, tokenStarts, tokenLengths, 0) == 87497064671293) {
            if (tokenHash(source, tokenStarts, tokenLengths, 1) == 94742904) {
                if (tokenKinds[2] == 1) {
                    if (tokenLengths[2] < 257) {
                        if (punctuationAt(source, tokenKinds, tokenStarts, 3, 123)) {
                            if (tokenHash(source, tokenStarts, tokenLengths, 4) == 96667762) {
                                if (tokenHash(source, tokenStarts, tokenLengths, 5) == 3625364) {
                                    if (
                                        tokenHash(source, tokenStarts, tokenLengths, 6) == 3343801
                                    ) {
                                        if (
                                            punctuationAt(
                                                source,
                                                tokenKinds,
                                                tokenStarts,
                                                7,
                                                40
                                            )
                                        ) {
                                            if (
                                                punctuationAt(
                                                    source,
                                                    tokenKinds,
                                                    tokenStarts,
                                                    8,
                                                    41
                                                )
                                            ) {
                                                if (
                                                    punctuationAt(
                                                        source,
                                                        tokenKinds,
                                                        tokenStarts,
                                                        9,
                                                        123
                                                    )
                                                ) {
                                                    return 10;
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
        return -1;
    }

    private MinimalProgramResult minimalNoGlobalValue(
        words tokenStarts,
        words tokenLengths,
        long statementCount,
        long operand
    ) {
        SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
        SourceRange global = new SourceRange(0, 0);
        long opcode = -1;
        if (statementCount == 1) {
            opcode = 769;
        }
        MinimalProgram program = new MinimalProgram(
            name,
            global,
            0,
            0,
            statementCount,
            opcode,
            operand,
            -1,
            0,
            -1,
            0,
            -1,
            0,
            global,
            0,
            -1,
            0,
            0,
            global,
            0,
            0,
            0,
            0,
            -1,
            0,
            -1,
            0,
            -1,
            0
        );
        return new MinimalProgramResult.Value(program);
    }

    private MinimalProgramResult minimalNoGlobalProgram(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long count
    ) {
        long bodyStart = minimalNoGlobalBodyStart(source, tokenKinds, tokenStarts, tokenLengths);
        if (0 < bodyStart) {
            if (punctuationAt(source, tokenKinds, tokenStarts, bodyStart, 125)) {
                if (punctuationAt(source, tokenKinds, tokenStarts, bodyStart + 1, 125)) {
                    if (count == bodyStart + 2) {
                        return minimalNoGlobalValue(tokenStarts, tokenLengths, 0, 0);
                    }
                }
            }
            if (tokenHash(source, tokenStarts, tokenLengths, bodyStart) == 3327612) {
                if (tokenKinds[bodyStart + 1] == 1) {
                    if (punctuationAt(source, tokenKinds, tokenStarts, bodyStart + 2, 61)) {
                        long valueToken = bodyStart + 3;
                        long valueWidth = signedNumberWidth(
                            source,
                            tokenKinds,
                            tokenStarts,
                            valueToken
                        );
                        if (0 < valueWidth) {
                            if (
                                signedNumberValid(source, tokenStarts, tokenLengths, valueToken)
                            ) {
                                long semicolon = valueToken + valueWidth;
                                if (
                                    punctuationAt(
                                        source,
                                        tokenKinds,
                                        tokenStarts,
                                        semicolon,
                                        59
                                    )
                                ) {
                                    if (
                                        punctuationAt(
                                            source,
                                            tokenKinds,
                                            tokenStarts,
                                            semicolon + 1,
                                            125
                                        )
                                    ) {
                                        if (
                                            punctuationAt(
                                                source,
                                                tokenKinds,
                                                tokenStarts,
                                                semicolon + 2,
                                                125
                                            )
                                        ) {
                                            if (count == semicolon + 3) {
                                                long operand = parsedSignedNumber(
                                                    source,
                                                    tokenStarts,
                                                    tokenLengths,
                                                    valueToken
                                                );
                                                return minimalNoGlobalValue(
                                                    tokenStarts,
                                                    tokenLengths,
                                                    1,
                                                    operand
                                                );
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

    private boolean bodyClosesAt(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        long statementEnd,
        long count
    ) {
        if (punctuationAt(source, tokenKinds, tokenStarts, statementEnd, 125)) {
            if (punctuationAt(source, tokenKinds, tokenStarts, statementEnd + 1, 125)) {
                return count == statementEnd + 2;
            }
        }
        return false;
    }

    private boolean minimalStateCountSupported(long count) {
        if (17 < count) {
            return count < 128;
        }
        return false;
    }

    /// Parses `minimalProgram` from a bounded canonical input.
    public MinimalProgramResult parseMinimalProgram(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long count
    ) {
        if (count == 12) {
            return minimalNoGlobalProgram(source, tokenKinds, tokenStarts, tokenLengths, count);
        }
        if (count == 17) {
            return minimalNoGlobalProgram(source, tokenKinds, tokenStarts, tokenLengths, count);
        }
        if (count == 18) {
            MinimalProgramResult noGlobal = minimalNoGlobalProgram(
                source,
                tokenKinds,
                tokenStarts,
                tokenLengths,
                count
            );
            match (noGlobal) {
                case MinimalProgramResult.Value(MinimalProgram program) {
                    return new MinimalProgramResult.Value(program);
                }
                case MinimalProgramResult.Error(long noGlobalOffset) {}
            }
        }
        if (minimalStateCountSupported(count)) {
            long firstMember = minimalEntryStart(source, tokenKinds, tokenStarts, tokenLengths);
            if (0 < firstMember) {
                long firstMemberHash = tokenHash(source, tokenStarts, tokenLengths, firstMember);
                if (firstMemberHash == 3625364) {
                    return parseHelperProgram(
                        source,
                        tokenKinds,
                        tokenStarts,
                        tokenLengths,
                        count
                    );
                }
                if (firstMemberHash == 112803) {
                    return parseHelperProgram(
                        source,
                        tokenKinds,
                        tokenStarts,
                        tokenLengths,
                        count
                    );
                }
            }
            long entryStart = minimalEntryStart(source, tokenKinds, tokenStarts, tokenLengths);
            if (0 < entryStart) {
                long bodyStart = minimalBodyStart(
                    source,
                    tokenKinds,
                    tokenStarts,
                    tokenLengths,
                    entryStart
                );
                if (0 < bodyStart) {
                    if (punctuationAt(source, tokenKinds, tokenStarts, bodyStart, 125)) {
                        if (punctuationAt(source, tokenKinds, tokenStarts, bodyStart + 1, 125)) {
                            if (count == bodyStart + 2) {
                                return minimalEmptyProgramValue(source, tokenStarts, tokenLengths);
                            }
                        }
                    }
                    long firstWidth = statementWidth(
                        source,
                        tokenKinds,
                        tokenStarts,
                        tokenLengths,
                        bodyStart
                    );
                    if (0 < firstWidth) {
                        long firstEnd = bodyStart + firstWidth;
                        if (bodyClosesAt(source, tokenKinds, tokenStarts, firstEnd, count)) {
                            return minimalProgramValue(
                                source,
                                tokenStarts,
                                tokenLengths,
                                bodyStart,
                                -1,
                                -1,
                                -1
                            );
                        }
                        long secondWidth = statementWidth(
                            source,
                            tokenKinds,
                            tokenStarts,
                            tokenLengths,
                            firstEnd
                        );
                        if (0 < secondWidth) {
                            long secondEnd = firstEnd + secondWidth;
                            if (
                                bodyClosesAt(source, tokenKinds, tokenStarts, secondEnd, count)
                            ) {
                                return minimalProgramValue(
                                    source,
                                    tokenStarts,
                                    tokenLengths,
                                    bodyStart,
                                    firstEnd,
                                    -1,
                                    -1
                                );
                            }
                            long thirdWidth = statementWidth(
                                source,
                                tokenKinds,
                                tokenStarts,
                                tokenLengths,
                                secondEnd
                            );
                            if (0 < thirdWidth) {
                                long thirdEnd = secondEnd + thirdWidth;
                                if (
                                    bodyClosesAt(
                                        source,
                                        tokenKinds,
                                        tokenStarts,
                                        thirdEnd,
                                        count
                                    )
                                ) {
                                    return minimalProgramValue(
                                        source,
                                        tokenStarts,
                                        tokenLengths,
                                        bodyStart,
                                        firstEnd,
                                        secondEnd,
                                        -1
                                    );
                                }
                                long fourthWidth = statementWidth(
                                    source,
                                    tokenKinds,
                                    tokenStarts,
                                    tokenLengths,
                                    thirdEnd
                                );
                                if (0 < fourthWidth) {
                                    long fourthEnd = thirdEnd + fourthWidth;
                                    if (
                                        bodyClosesAt(
                                            source,
                                            tokenKinds,
                                            tokenStarts,
                                            fourthEnd,
                                            count
                                        )
                                    ) {
                                        return minimalProgramValue(
                                            source,
                                            tokenStarts,
                                            tokenLengths,
                                            bodyStart,
                                            firstEnd,
                                            secondEnd,
                                            thirdEnd
                                        );
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
