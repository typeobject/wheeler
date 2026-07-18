// Bounded parser over token metadata produced by an imported scanner module.
module examples.lexer.main;
import examples.lexer.parser;
import examples.lexer.scanner;
classical class Utf8Lexer {

    state long tokenCount = 0;
    state long numberStart = 0;
    state long commentStart = 0;
    state long numericValue = 0;
    state long parseError = -1;
    state long lexicalError = 0;
    state long outputLength = 0;
    state long finalCursor = 0;

    long emitNumber(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        bytes output
    ) {
        long start = tokenStarts[2];
        long length = tokenLengths[2];
        long cursor = 0;
        while (cursor < length) limit 10 {
            setByte(output, cursor, utf8Scalar(source, start + cursor));
            cursor += 1;
        }
        return cursor;
    }

    entry void main(utf8 source, bytes output) {
        region arena = new region(384, 3);
        words tokenKinds = allocate(arena, 16);
        words tokenStarts = allocate(arena, 16);
        words tokenLengths = allocate(arena, 16);
        long sourceLength = bufferLength(source);
        long count = 0;
        long cursor = 0;

        while (cursor < sourceLength) limit 256 {
            long scalar = utf8Scalar(source, cursor);
            long width = utf8Width(source, cursor);
            long kind = tokenKind(scalar);
            if (scalar == 34) {
                kind = 6;
            }
            if (scalar == 47) {
                long detectedComment = commentKind(source, cursor, sourceLength);
                if (3 < detectedComment) {
                    kind = detectedComment;
                }
            }
            if (kind == 0) {
                cursor += width;
            } else {
                long tokenIndex = count;
                long tokenStart = cursor;
                set(tokenKinds, tokenIndex, kind);
                set(tokenStarts, tokenIndex, tokenStart);
                count += 1;
                cursor += width;

                if (kind < 3) {
                    boolean scanning = true;
                    while (scanning) limit 256 {
                        if (cursor < sourceLength) {
                            long next = utf8Scalar(source, cursor);
                            long nextKind = tokenKind(next);
                            if (nextKind == kind) {
                                cursor += utf8Width(source, cursor);
                            } else {
                                scanning = false;
                            }
                        } else {
                            scanning = false;
                        }
                    }
                } else {
                    if (kind == 4) {
                        boolean scanningComment = true;
                        while (scanningComment) limit 256 {
                            if (cursor < sourceLength) {
                                long nextComment = utf8Scalar(source, cursor);
                                if (nextComment == 10) {
                                    scanningComment = false;
                                } else {
                                    cursor += utf8Width(source, cursor);
                                }
                            } else {
                                scanningComment = false;
                            }
                        }
                    }
                    if (kind == 5) {
                        long blockEnd = blockCommentEnd(
                            source, tokenStart, sourceLength);
                        if (blockEnd < 0) {
                            lexicalError = tokenStart + 1;
                            cursor = sourceLength;
                        } else {
                            cursor = blockEnd;
                        }
                    }
                    if (kind == 6) {
                        long literalEnd = asciiLiteralEnd(
                            source, tokenStart, sourceLength);
                        if (literalEnd < 0) {
                            lexicalError = tokenStart + 1;
                            cursor = sourceLength;
                        } else {
                            cursor = literalEnd;
                        }
                    }
                }
                set(tokenLengths, tokenIndex, cursor - tokenStart);
            }
        }

        tokenCount = count;
        numberStart = tokenStarts[2];
        commentStart = tokenStarts[4];
        AssignmentResult parsed = parseAssignment(
            source, tokenKinds, tokenStarts, tokenLengths, tokenCount);
        if (lexicalError == 0) {
            match (parsed) {
                case AssignmentResult.Value(long value) {
                    numericValue = value;
                    parseError = 0;
                }
                case AssignmentResult.Error(long offset) {
                    numericValue = -1;
                    parseError = offset + 1;
                }
            }
        } else {
            numericValue = -1;
            parseError = lexicalError;
        }
        outputLength = emitNumber(source, tokenStarts, tokenLengths, output);
        finalCursor = cursor;
        assert tokenCount == 5;
        assert numberStart == 2;
        assert commentStart == 6;
        assert numericValue == 123;
        assert parseError == 0;
        assert lexicalError == 0;
        assert outputLength == 3;
        assert finalCursor == 11;

        drop(tokenLengths);
        drop(tokenStarts);
        drop(tokenKinds);
        drop(arena);
    }
}
