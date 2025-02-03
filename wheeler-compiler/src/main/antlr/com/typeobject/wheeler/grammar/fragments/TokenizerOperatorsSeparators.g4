// Defines separators and delimiters
lexer grammar TokenizerOperatorsSeparators;

// Brackets and parentheses
LPAREN      : '(';               // Left parenthesis
RPAREN      : ')';               // Right parenthesis
LBRACE      : '{';               // Left brace
RBRACE      : '}';               // Right brace
LBRACK      : '[';               // Left bracket
RBRACK      : ']';               // Right bracket

// Statement terminators and separators
SEMI        : ';';               // Semicolon
COMMA       : ',';               // Comma
DOT         : '.';               // Dot operator
COLON       : ':';               // Colon
DOUBLECOLON : '::';              // Double colon (namespace)
ELLIPSIS    : '...';             // Varargs

// Special characters
AT          : '@';               // At sign (annotations)
QUESTION    : '?';               // Question mark (ternary)
ARROW       : '->';              // Arrow operator
DOUBLE_ARROW : '=>';             // Double arrow (lambda)
BACK_ARROW  : '<-';             // Back arrow (assignments)