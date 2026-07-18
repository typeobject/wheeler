module examples.compiler.helper_parser;
import examples.compiler.ir;
import examples.compiler.statements;
import examples.compiler.structure;
import examples.compiler.tokens;
classical class HelperParser {
    private boolean reversibleBodyValid(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long statementStart
    ) {
        long opcode = statementOpcode(
            source, tokenStarts, tokenLengths, statementStart);
        if (opcode == 1040) {
            return true;
        }
        if (opcode == 1041) {
            return true;
        }
        return opcode == 1042;
    }

    private boolean callValid(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long nameToken,
        long callStart
    ) {
        if (sameTokenText(
                source,
                tokenStarts,
                tokenLengths,
                nameToken,
                callStart)) {
            if (punctuationAt(
                    source, tokenKinds, tokenStarts, callStart + 1, 40)) {
                if (punctuationAt(
                        source, tokenKinds, tokenStarts, callStart + 2, 41)) {
                    return punctuationAt(
                        source, tokenKinds, tokenStarts, callStart + 3, 59);
                }
            }
        }
        return false;
    }

    private MinimalProgramResult helperProgram(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long nameToken,
        long helperBody,
        long reversible,
        long proofToken,
        long proofCount,
        long entryStatement,
        long helperCallCount,
        long preReverseStatement,
        long helperSecondStatement,
        long helperThirdStatement,
        long helperFourthStatement
    ) {
        long operandToken = statementOperandToken(
            source, tokenStarts, tokenLengths, helperBody);
        SourceRange name = new SourceRange(
            tokenStarts[2], tokenLengths[2]);
        SourceRange global = new SourceRange(
            tokenStarts[6], tokenLengths[6]);
        SourceRange helper = new SourceRange(
            tokenStarts[nameToken], tokenLengths[nameToken]);
        SourceRange proof = new SourceRange(0, 0);
        if (proofCount == 1) {
            proof = new SourceRange(
                tokenStarts[proofToken], tokenLengths[proofToken]);
        }
        long helperStatementCount = 1;
        long helperSecondOpcode = -1;
        long helperSecondOperand = 0;
        long helperThirdOpcode = -1;
        long helperThirdOperand = 0;
        long helperFourthOpcode = -1;
        long helperFourthOperand = 0;
        if (-1 < helperSecondStatement) {
            helperStatementCount = 2;
            helperSecondOpcode = statementOpcode(
                source, tokenStarts, tokenLengths, helperSecondStatement);
            long helperSecondOperandToken = statementOperandToken(
                source, tokenStarts, tokenLengths, helperSecondStatement);
            helperSecondOperand = parsedSignedNumber(
                source,
                tokenStarts,
                tokenLengths,
                helperSecondOperandToken);
        }
        if (-1 < helperThirdStatement) {
            helperStatementCount = 3;
            helperThirdOpcode = statementOpcode(
                source, tokenStarts, tokenLengths, helperThirdStatement);
            long helperThirdOperandToken = statementOperandToken(
                source, tokenStarts, tokenLengths, helperThirdStatement);
            helperThirdOperand = parsedSignedNumber(
                source,
                tokenStarts,
                tokenLengths,
                helperThirdOperandToken);
        }
        if (-1 < helperFourthStatement) {
            helperStatementCount = 4;
            helperFourthOpcode = statementOpcode(
                source, tokenStarts, tokenLengths, helperFourthStatement);
            long helperFourthOperandToken = statementOperandToken(
                source, tokenStarts, tokenLengths, helperFourthStatement);
            helperFourthOperand = parsedSignedNumber(
                source,
                tokenStarts,
                tokenLengths,
                helperFourthOperandToken);
        }
        long entryCount = 0;
        long entryOpcode = -1;
        long entryOperand = 0;
        long secondEntryOpcode = -1;
        long secondEntryOperand = 0;
        long preReverseCount = 0;
        if (-1 < preReverseStatement) {
            entryCount = 1;
            preReverseCount = 1;
            entryOpcode = statementOpcode(
                source, tokenStarts, tokenLengths, preReverseStatement);
            long preOperandToken = statementOperandToken(
                source, tokenStarts, tokenLengths, preReverseStatement);
            entryOperand = parsedSignedNumber(
                source, tokenStarts, tokenLengths, preOperandToken);
        }
        if (-1 < entryStatement) {
            long entryOperandToken = statementOperandToken(
                source, tokenStarts, tokenLengths, entryStatement);
            if (entryCount == 0) {
                entryCount = 1;
                entryOpcode = statementOpcode(
                    source, tokenStarts, tokenLengths, entryStatement);
                entryOperand = parsedSignedNumber(
                    source, tokenStarts, tokenLengths, entryOperandToken);
            } else {
                entryCount = 2;
                secondEntryOpcode = statementOpcode(
                    source, tokenStarts, tokenLengths, entryStatement);
                secondEntryOperand = parsedSignedNumber(
                    source, tokenStarts, tokenLengths, entryOperandToken);
            }
        }
        MinimalProgram program = new MinimalProgram(
            name,
            global,
            1,
            parsedSignedNumber(source, tokenStarts, tokenLengths, 8),
            entryCount,
            entryOpcode,
            entryOperand,
            secondEntryOpcode,
            secondEntryOperand,
            -1,
            0,
            -1,
            0,
            helper,
            1,
            statementOpcode(
                source, tokenStarts, tokenLengths, helperBody),
            parsedSignedNumber(
                source, tokenStarts, tokenLengths, operandToken),
            reversible,
            proof,
            proofCount,
            helperCallCount,
            preReverseCount,
            helperStatementCount,
            helperSecondOpcode,
            helperSecondOperand,
            helperThirdOpcode,
            helperThirdOperand,
            helperFourthOpcode,
            helperFourthOperand);
        return new MinimalProgramResult.Value(program);
    }

    private MinimalProgramResult finishEntry(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long count,
        long closeStart,
        long nameToken,
        long helperBody,
        long reversible,
        long proofToken,
        long proofCount,
        long helperCallCount,
        long preReverseStatement,
        long helperSecondStatement,
        long helperThirdStatement,
        long helperFourthStatement
    ) {
        long entryStatement = -1;
        long entryClose = closeStart;
        if (punctuationAt(
                source, tokenKinds, tokenStarts, entryClose, 125)) {
            entryClose = closeStart;
        } else {
            long entryWidth = statementWidth(
                source,
                tokenKinds,
                tokenStarts,
                tokenLengths,
                closeStart);
            if (entryWidth < 1) {
                return new MinimalProgramResult.Error(0);
            }
            entryStatement = closeStart;
            entryClose += entryWidth;
        }
        if (punctuationAt(
                source, tokenKinds, tokenStarts, entryClose, 125)) {
            if (punctuationAt(
                    source, tokenKinds, tokenStarts, entryClose + 1, 125)) {
                if (count == entryClose + 2) {
                    return helperProgram(
                        source,
                        tokenStarts,
                        tokenLengths,
                        nameToken,
                        helperBody,
                        reversible,
                        proofToken,
                        proofCount,
                        entryStatement,
                        helperCallCount,
                        preReverseStatement,
                        helperSecondStatement,
                        helperThirdStatement,
                        helperFourthStatement);
                }
            }
        }
        return new MinimalProgramResult.Error(0);
    }

    public MinimalProgramResult parseHelperProgram(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long count
    ) {
        long memberStart = minimalEntryStart(
            source, tokenKinds, tokenStarts, tokenLengths);
        if (0 < memberStart) {
            long reversible = 0;
            long voidToken = memberStart;
            if (tokenHash(
                    source, tokenStarts, tokenLengths, memberStart)
                    == 112803) {
                reversible = 1;
                voidToken += 1;
            }
            if (tokenHash(source, tokenStarts, tokenLengths, voidToken)
                    == 3625364) {
                long nameToken = voidToken + 1;
                if (tokenKinds[nameToken] == 1) {
                    if (tokenLengths[nameToken] < 257) {
                        if (punctuationAt(
                                source,
                                tokenKinds,
                                tokenStarts,
                                nameToken + 1,
                                40)) {
                            if (punctuationAt(
                                    source,
                                    tokenKinds,
                                    tokenStarts,
                                    nameToken + 2,
                                    41)) {
                                if (punctuationAt(
                                        source,
                                        tokenKinds,
                                        tokenStarts,
                                        nameToken + 3,
                                        123)) {
                                    long helperBody = nameToken + 4;
                                    long helperWidth = statementWidth(
                                        source,
                                        tokenKinds,
                                        tokenStarts,
                                        tokenLengths,
                                        helperBody);
                                    long helperSecondStatement = -1;
                                    long helperThirdStatement = -1;
                                    long helperFourthStatement = -1;
                                    long helperEnd = helperBody + helperWidth;
                                    if (0 < helperWidth) {
                                        if (punctuationAt(
                                                source,
                                                tokenKinds,
                                                tokenStarts,
                                                helperEnd,
                                                125)) {
                                            helperEnd = helperEnd;
                                        } else {
                                            helperSecondStatement = helperEnd;
                                            long helperSecondWidth = statementWidth(
                                                source,
                                                tokenKinds,
                                                tokenStarts,
                                                tokenLengths,
                                                helperSecondStatement);
                                            helperEnd += helperSecondWidth;
                                            if (0 < helperSecondWidth) {
                                                if (punctuationAt(
                                                        source,
                                                        tokenKinds,
                                                        tokenStarts,
                                                        helperEnd,
                                                        125)) {
                                                    helperEnd = helperEnd;
                                                } else {
                                                    helperThirdStatement = helperEnd;
                                                    long helperThirdWidth = statementWidth(
                                                        source,
                                                        tokenKinds,
                                                        tokenStarts,
                                                        tokenLengths,
                                                        helperThirdStatement);
                                                    helperEnd += helperThirdWidth;
                                                    if (0 < helperThirdWidth) {
                                                        if (punctuationAt(
                                                                source,
                                                                tokenKinds,
                                                                tokenStarts,
                                                                helperEnd,
                                                                125)) {
                                                            helperEnd = helperEnd;
                                                        } else {
                                                            helperFourthStatement = helperEnd;
                                                            long helperFourthWidth = statementWidth(
                                                                source,
                                                                tokenKinds,
                                                                tokenStarts,
                                                                tokenLengths,
                                                                helperFourthStatement);
                                                            helperEnd += helperFourthWidth;
                                                            if (helperFourthWidth < 1) {
                                                                helperEnd = -1;
                                                            }
                                                        }
                                                    } else {
                                                        helperEnd = -1;
                                                    }
                                                }
                                            } else {
                                                helperEnd = -1;
                                            }
                                        }
                                    }
                                    boolean helperStatementsValid = 0 < helperWidth;
                                    if (reversible == 1) {
                                        helperStatementsValid = reversibleBodyValid(
                                            source,
                                            tokenStarts,
                                            tokenLengths,
                                            helperBody);
                                        if (-1 < helperSecondStatement) {
                                            boolean secondReversible = reversibleBodyValid(
                                                source,
                                                tokenStarts,
                                                tokenLengths,
                                                helperSecondStatement);
                                            if (helperStatementsValid) {
                                                helperStatementsValid = secondReversible;
                                            }
                                        }
                                        if (-1 < helperThirdStatement) {
                                            boolean thirdReversible = reversibleBodyValid(
                                                source,
                                                tokenStarts,
                                                tokenLengths,
                                                helperThirdStatement);
                                            if (helperStatementsValid) {
                                                helperStatementsValid = thirdReversible;
                                            }
                                        }
                                        if (-1 < helperFourthStatement) {
                                            boolean fourthReversible = reversibleBodyValid(
                                                source,
                                                tokenStarts,
                                                tokenLengths,
                                                helperFourthStatement);
                                            if (helperStatementsValid) {
                                                helperStatementsValid = fourthReversible;
                                            }
                                        }
                                    }
                                    if (helperStatementsValid) {
                                        if (punctuationAt(
                                                source,
                                                tokenKinds,
                                                tokenStarts,
                                                helperEnd,
                                                125)) {
                                            long entryStart = helperEnd + 1;
                                            long proofToken = -1;
                                            long proofCount = 0;
                                            if (reversible == 1) {
                                                if (tokenHash(
                                                        source,
                                                        tokenStarts,
                                                        tokenLengths,
                                                        entryStart)
                                                        == 106024553916) {
                                                    if (tokenKinds[entryStart + 1] == 1) {
                                                        if (tokenHash(
                                                                source,
                                                                tokenStarts,
                                                                tokenLengths,
                                                                entryStart + 2)
                                                                == 3315169751) {
                                                            if (tokenHash(
                                                                    source,
                                                                    tokenStarts,
                                                                    tokenLengths,
                                                                    entryStart + 3)
                                                                    == 96449190704) {
                                                                if (punctuationAt(
                                                                        source,
                                                                        tokenKinds,
                                                                        tokenStarts,
                                                                        entryStart + 4,
                                                                        40)) {
                                                                    if (sameTokenText(
                                                                            source,
                                                                            tokenStarts,
                                                                            tokenLengths,
                                                                            nameToken,
                                                                            entryStart + 5)) {
                                                                        if (punctuationAt(
                                                                                source,
                                                                                tokenKinds,
                                                                                tokenStarts,
                                                                                entryStart + 6,
                                                                                41)) {
                                                                            if (punctuationAt(
                                                                                    source,
                                                                                    tokenKinds,
                                                                                    tokenStarts,
                                                                                    entryStart + 7,
                                                                                    59)) {
                                                                                proofToken = entryStart + 1;
                                                                                proofCount = 1;
                                                                                entryStart += 8;
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            long entryBody = minimalBodyStart(
                                                source,
                                                tokenKinds,
                                                tokenStarts,
                                                tokenLengths,
                                                entryStart);
                                            if (0 < entryBody) {
                                                if (callValid(
                                                        source,
                                                        tokenKinds,
                                                        tokenStarts,
                                                        tokenLengths,
                                                        nameToken,
                                                        entryBody)) {
                                                    long helperCallCount = 1;
                                                    long afterCalls = entryBody + 4;
                                                    if (callValid(
                                                            source,
                                                            tokenKinds,
                                                            tokenStarts,
                                                            tokenLengths,
                                                            nameToken,
                                                            afterCalls)) {
                                                        helperCallCount = 2;
                                                        afterCalls += 4;
                                                    }
                                                    long preReverseStatement = -1;
                                                    if (reversible == 1) {
                                                        long reverseHash = tokenHash(
                                                            source,
                                                            tokenStarts,
                                                            tokenLengths,
                                                            afterCalls);
                                                        if (reverseHash
                                                                == 104179061474) {
                                                            afterCalls = afterCalls;
                                                        } else {
                                                            long preReverseWidth = statementWidth(
                                                                source,
                                                                tokenKinds,
                                                                tokenStarts,
                                                                tokenLengths,
                                                                afterCalls);
                                                            if (0 < preReverseWidth) {
                                                                preReverseStatement = afterCalls;
                                                                afterCalls += preReverseWidth;
                                                            } else {
                                                                afterCalls = -1;
                                                            }
                                                        }
                                                    }
                                                    if (reversible == 0) {
                                                        return finishEntry(
                                                            source,
                                                            tokenKinds,
                                                            tokenStarts,
                                                            tokenLengths,
                                                            count,
                                                            afterCalls,
                                                            nameToken,
                                                            helperBody,
                                                            reversible,
                                                            proofToken,
                                                            proofCount,
                                                            helperCallCount,
                                                            -1,
                                                            helperSecondStatement,
                                                            helperThirdStatement,
                                                            helperFourthStatement);
                                                    }
                                                    if (reversible == 1) {
                                                        if (tokenHash(
                                                                source,
                                                                tokenStarts,
                                                                tokenLengths,
                                                                afterCalls)
                                                                == 104179061474) {
                                                            if (punctuationAt(
                                                                    source,
                                                                    tokenKinds,
                                                                    tokenStarts,
                                                                    afterCalls + 1,
                                                                    123)) {
                                                                long reverseCall = afterCalls + 2;
                                                                if (callValid(
                                                                        source,
                                                                        tokenKinds,
                                                                        tokenStarts,
                                                                        tokenLengths,
                                                                        nameToken,
                                                                        reverseCall)) {
                                                                    long reverseEnd = reverseCall + 4;
                                                                    boolean reverseCallsValid = true;
                                                                    if (helperCallCount == 2) {
                                                                        if (callValid(
                                                                                source,
                                                                                tokenKinds,
                                                                                tokenStarts,
                                                                                tokenLengths,
                                                                                nameToken,
                                                                                reverseEnd)) {
                                                                            reverseEnd += 4;
                                                                        } else {
                                                                            reverseCallsValid = false;
                                                                        }
                                                                    }
                                                                    if (reverseCallsValid) {
                                                                        if (punctuationAt(
                                                                                source,
                                                                                tokenKinds,
                                                                                tokenStarts,
                                                                                reverseEnd,
                                                                                125)) {
                                                                            return finishEntry(
                                                                                source,
                                                                                tokenKinds,
                                                                                tokenStarts,
                                                                                tokenLengths,
                                                                                count,
                                                                                reverseEnd + 1,
                                                                                nameToken,
                                                                                helperBody,
                                                                                reversible,
                                                                                proofToken,
                                                                                proofCount,
                                                                                helperCallCount,
                                                                                preReverseStatement,
                                                                                helperSecondStatement,
                                                                                helperThirdStatement,
                                                                                helperFourthStatement);
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
                    }
                }
            }
        }
        return new MinimalProgramResult.Error(0);
    }
}
