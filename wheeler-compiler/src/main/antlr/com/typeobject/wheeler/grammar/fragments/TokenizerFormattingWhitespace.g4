// Defines whitespace handling rules
// All whitespace is skipped unless inside strings or comments
lexer grammar TokenizerFormattingWhitespace;

// Standard whitespace characters
WS  : [ \t\r\n\f]+    -> skip    // Space, tab, carriage return, newline, form feed
    ;