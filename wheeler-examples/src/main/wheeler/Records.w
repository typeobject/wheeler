// Immutable nominal records, nested fields, typed calls, and structural equality.
classical class Records {
    record Span(long start, long end) {}
    record Token(Span span, boolean valid) {}

    state long width = 0;
    state long equal = 0;

    Token token(Span span) {
        return new Token(span, true);
    }

    long tokenWidth(Token value) {
        return value.span.end - value.span.start;
    }

    entry void main() {
        Span span = new Span(3, 8);
        Token first = token(span);
        Token second = new Token(new Span(3, 8), true);
        width = tokenWidth(first);
        if (first == second) {
            equal = 1;
        }
        assert width == 5;
        assert equal == 1;
    }
}
