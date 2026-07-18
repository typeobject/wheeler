//! Bounded parser over token metadata produced by an imported scanner module.
module examples.lexer.main;
import examples.lexer.parser;
import examples.lexer.scanner;
classical class Utf8Lexer {

    state long tokenCount = 0;
    state long numberStart = 0;
    state long commentStart = 0;
    state long numericValue = 0;
    state long parseError = -1;
    state long lexicalCode = 0;
    state long lexicalError = 0;
    state long lexicalLine = 0;
    state long lexicalColumn = 0;
    state long outputLength = 0;
    state long finalCursor = 0;

    long emitNumber(utf8 source, words tokenStarts, words tokenLengths, bytes output) {
        long start = tokenStarts[3];
        long length = tokenLengths[3];
        long cursor = 0;
        while (cursor < length) limit 10 {
            setByte(output, cursor, utf8Scalar(source, start + cursor));
            cursor += 1;
        }
        return cursor;
    }

    /// Runs the bounded `Utf8Lexer` fixture.
    ///
    /// - Effects: Mutates declared state and caller-owned byte output.
    entry void main(utf8 source, bytes output) {
        region arena = new region(384, 3);
        words tokenKinds = allocate(arena, 16);
        words tokenStarts = allocate(arena, 16);
        words tokenLengths = allocate(arena, 16);
        long sourceLength = bufferLength(source);
        long count = 0;
        ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
        match (scanned) {
            case ScanResult.Value(long scannedCount) {
                count = scannedCount;
            }
            case ScanResult.Error(ScanDiagnostic diagnostic) {
                lexicalCode = diagnostic.code;
                lexicalError = diagnostic.offset + 1;
                lexicalLine = diagnostic.line;
                lexicalColumn = diagnostic.column;
            }
        }

        tokenCount = count;
        numberStart = tokenStarts[3];
        commentStart = tokenStarts[5];
        DeclarationResult parsed = parseDeclaration(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            tokenCount
        );
        if (lexicalError == 0) {
            match (parsed) {
                case DeclarationResult.Value(long value) {
                    numericValue = value;
                    parseError = 0;
                }
                case DeclarationResult.Error(long parseOffset) {
                    numericValue = -1;
                    parseError = parseOffset + 1;
                }
            }
        } else {
            numericValue = -1;
            parseError = lexicalError;
        }
        outputLength = emitNumber(source, tokenStarts, tokenLengths, output);
        finalCursor = sourceLength;
        assert tokenCount == 6;
        assert numberStart == 8;
        assert commentStart == 12;
        assert numericValue == 123;
        assert parseError == 0;
        assert lexicalCode == 0;
        assert lexicalError == 0;
        assert lexicalLine == 0;
        assert lexicalColumn == 0;
        assert outputLength == 3;
        assert finalCursor == 17;

        drop(tokenLengths);
        drop(tokenStarts);
        drop(tokenKinds);
        drop(arena);
    }
}
