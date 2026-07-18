module examples.compiler.statements;
import examples.compiler.tokens;
classical class Statements {
    public long statementWidth(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long statementStart
    ) {
        long statementKind = statementOpcode(
            source, tokenStarts, tokenLengths, statementStart);
        if (statementKind == 768) {
            if (tokenKinds[statementStart + 1] == 1) {
                if (sameTokenText(
                        source,
                        tokenStarts,
                        tokenLengths,
                        6,
                        statementStart + 1)) {
                    if (punctuationAt(
                            source,
                            tokenKinds,
                            tokenStarts,
                            statementStart + 2,
                            61)) {
                        if (punctuationAt(
                                source,
                                tokenKinds,
                                tokenStarts,
                                statementStart + 3,
                                61)) {
                            long assertWidth = signedNumberWidth(
                                source,
                                tokenKinds,
                                tokenStarts,
                                statementStart + 4);
                            if (0 < assertWidth) {
                                if (signedNumberValid(
                                        source,
                                        tokenStarts,
                                        tokenLengths,
                                        statementStart + 4)) {
                                    if (punctuationAt(
                                            source,
                                            tokenKinds,
                                            tokenStarts,
                                            statementStart + 4 + assertWidth,
                                            59)) {
                                        return 5 + assertWidth;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return -1;
        }
        if (statementKind == 769) {
            if (tokenKinds[statementStart + 1] == 1) {
                if (punctuationAt(
                        source,
                        tokenKinds,
                        tokenStarts,
                        statementStart + 2,
                        61)) {
                    long localWidth = signedNumberWidth(
                        source,
                        tokenKinds,
                        tokenStarts,
                        statementStart + 3);
                    if (0 < localWidth) {
                        if (signedNumberValid(
                                source,
                                tokenStarts,
                                tokenLengths,
                                statementStart + 3)) {
                            if (punctuationAt(
                                    source,
                                    tokenKinds,
                                    tokenStarts,
                                    statementStart + 3 + localWidth,
                                    59)) {
                                return 4 + localWidth;
                            }
                        }
                    }
                }
            }
            return -1;
        }
        if (tokenKinds[statementStart] == 1) {
            if (sameTokenText(
                    source,
                    tokenStarts,
                    tokenLengths,
                    6,
                    statementStart)) {
                long opcode = statementOpcode(
                    source, tokenStarts, tokenLengths, statementStart);
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

    public long statementOperandToken(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long statementStart
    ) {
        long opcode = statementOpcode(
            source, tokenStarts, tokenLengths, statementStart);
        if (opcode == 0) {
            return statementStart + 2;
        }
        if (opcode == 768) {
            return statementStart + 4;
        }
        return statementStart + 3;
    }
}
