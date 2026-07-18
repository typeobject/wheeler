module examples.compiler.helper_parser;
import examples.compiler.ir;
import examples.compiler.statements;
import examples.compiler.structure;
import examples.compiler.tokens;
classical class HelperParser {
    public MinimalProgramResult parseHelperProgram(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        words tokenLengths,
        long count
    ) {
        long helperStart = minimalEntryStart(
            source, tokenKinds, tokenStarts, tokenLengths);
        if (0 < helperStart) {
            if (tokenHash(
                    source, tokenStarts, tokenLengths, helperStart)
                    == 3625364) {
                if (tokenKinds[helperStart + 1] == 1) {
                    if (tokenLengths[helperStart + 1] < 257) {
                        if (punctuationAt(
                                source,
                                tokenKinds,
                                tokenStarts,
                                helperStart + 2,
                                40)) {
                            if (punctuationAt(
                                    source,
                                    tokenKinds,
                                    tokenStarts,
                                    helperStart + 3,
                                    41)) {
                                if (punctuationAt(
                                        source,
                                        tokenKinds,
                                        tokenStarts,
                                        helperStart + 4,
                                        123)) {
                                    long helperBody = helperStart + 5;
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
                                            long entryBody = minimalBodyStart(
                                                source,
                                                tokenKinds,
                                                tokenStarts,
                                                tokenLengths,
                                                entryStart);
                                            if (0 < entryBody) {
                                                if (sameTokenText(
                                                        source,
                                                        tokenStarts,
                                                        tokenLengths,
                                                        helperStart + 1,
                                                        entryBody)) {
                                                    if (punctuationAt(
                                                            source,
                                                            tokenKinds,
                                                            tokenStarts,
                                                            entryBody + 1,
                                                            40)) {
                                                        if (punctuationAt(
                                                                source,
                                                                tokenKinds,
                                                                tokenStarts,
                                                                entryBody + 2,
                                                                41)) {
                                                            if (punctuationAt(
                                                                    source,
                                                                    tokenKinds,
                                                                    tokenStarts,
                                                                    entryBody + 3,
                                                                    59)) {
                                                                if (punctuationAt(
                                                                        source,
                                                                        tokenKinds,
                                                                        tokenStarts,
                                                                        entryBody + 4,
                                                                        125)) {
                                                                    if (punctuationAt(
                                                                            source,
                                                                            tokenKinds,
                                                                            tokenStarts,
                                                                            entryBody + 5,
                                                                            125)) {
                                                                        if (count == entryBody + 6) {
                                                                            long operandToken =
                                                                                statementOperandToken(
                                                                                    source,
                                                                                    tokenStarts,
                                                                                    tokenLengths,
                                                                                    helperBody);
                                                                            SourceRange name =
                                                                                new SourceRange(
                                                                                    tokenStarts[2],
                                                                                    tokenLengths[2]);
                                                                            SourceRange global =
                                                                                new SourceRange(
                                                                                    tokenStarts[6],
                                                                                    tokenLengths[6]);
                                                                            SourceRange helper =
                                                                                new SourceRange(
                                                                                    tokenStarts[
                                                                                        helperStart + 1],
                                                                                    tokenLengths[
                                                                                        helperStart + 1]);
                                                                            MinimalProgram program =
                                                                                new MinimalProgram(
                                                                                    name,
                                                                                    global,
                                                                                    1,
                                                                                    parsedSignedNumber(
                                                                                        source,
                                                                                        tokenStarts,
                                                                                        tokenLengths,
                                                                                        8),
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
                                                                                    1,
                                                                                    statementOpcode(
                                                                                        source,
                                                                                        tokenStarts,
                                                                                        tokenLengths,
                                                                                        helperBody),
                                                                                    parsedSignedNumber(
                                                                                        source,
                                                                                        tokenStarts,
                                                                                        tokenLengths,
                                                                                        operandToken));
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
                    }
                }
            }
        }
        return new MinimalProgramResult.Error(0);
    }
}
