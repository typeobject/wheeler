module examples.compiler.helper_parser;
import examples.compiler.ir;
import examples.compiler.statements;
import examples.compiler.structure;
import examples.compiler.tokens;
classical class HelperParser {
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
        long entryStatement
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
        long entryCount = 0;
        long entryOpcode = -1;
        long entryOperand = 0;
        if (-1 < entryStatement) {
            entryCount = 1;
            entryOpcode = statementOpcode(
                source, tokenStarts, tokenLengths, entryStatement);
            long entryOperandToken = statementOperandToken(
                source, tokenStarts, tokenLengths, entryStatement);
            entryOperand = parsedSignedNumber(
                source, tokenStarts, tokenLengths, entryOperandToken);
        }
        MinimalProgram program = new MinimalProgram(
            name,
            global,
            1,
            parsedSignedNumber(source, tokenStarts, tokenLengths, 8),
            entryCount,
            entryOpcode,
            entryOperand,
            -1,
            0,
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
            proofCount);
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
        long proofCount
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
                        entryStatement);
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
                                    if (0 < helperWidth) {
                                        long helperEnd = helperBody + helperWidth;
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
                                                    if (reversible == 0) {
                                                        return finishEntry(
                                                            source,
                                                            tokenKinds,
                                                            tokenStarts,
                                                            tokenLengths,
                                                            count,
                                                            entryBody + 4,
                                                            nameToken,
                                                            helperBody,
                                                            reversible,
                                                            proofToken,
                                                            proofCount);
                                                    }
                                                    if (reversible == 1) {
                                                        if (tokenHash(
                                                                source,
                                                                tokenStarts,
                                                                tokenLengths,
                                                                entryBody + 4)
                                                                == 104179061474) {
                                                            if (punctuationAt(
                                                                    source,
                                                                    tokenKinds,
                                                                    tokenStarts,
                                                                    entryBody + 5,
                                                                    123)) {
                                                                if (callValid(
                                                                        source,
                                                                        tokenKinds,
                                                                        tokenStarts,
                                                                        tokenLengths,
                                                                        nameToken,
                                                                        entryBody + 6)) {
                                                                    if (punctuationAt(
                                                                            source,
                                                                            tokenKinds,
                                                                            tokenStarts,
                                                                            entryBody + 10,
                                                                            125)) {
                                                                        return finishEntry(
                                                                            source,
                                                                            tokenKinds,
                                                                            tokenStarts,
                                                                            tokenLengths,
                                                                            count,
                                                                            entryBody + 11,
                                                                            nameToken,
                                                                            helperBody,
                                                                            reversible,
                                                                            proofToken,
                                                                            proofCount);
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
