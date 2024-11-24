lexer grammar WheelerOperators;

// Separators
LPAREN: '(';
RPAREN: ')';
LBRACE: '{';
RBRACE: '}';
LBRACK: '[';
RBRACK: ']';
SEMI: ';';
COMMA: ',';
DOT: '.';
ELLIPSIS: '...';
AT: '@';
DOUBLECOLON: '::';

// Operators
ASSIGN: '=';
GT: '>';
LT: '<';
BANG: '!';
TILDE: '~';
QUESTION: '?';
COLON: ':';
ARROW: '->';
DOUBLE_ARROW: '=>';
TENSOR: '\u2297';
CONJUGATE: '\u2020';

// Basic operators
MUL: '*';
DIV: '/';
ADD: '+';
SUB: '-';

// Comparison
EQUAL: '==';
LE: '<=';
GE: '>=';
NOTEQUAL: '!=';

// Logical
AND: '&&';
OR: '||';

// Bitwise and type operators
AMPERSAND: '&';  // Used for both bitwise AND and type bounds
PIPE: '|';       // Used for both bitwise OR and catch type alternatives
CARET: '^';
MOD: '%';
LSHIFT: '<<';
RSHIFT: '>>';
URSHIFT: '>>>';

// Compound operators
INC: '++';
DEC: '--';
ADD_ASSIGN: '+=';
SUB_ASSIGN: '-=';
MUL_ASSIGN: '*=';
DIV_ASSIGN: '/=';
AND_ASSIGN: '&=';
OR_ASSIGN: '|=';
XOR_ASSIGN: '^=';
MOD_ASSIGN: '%=';
LSHIFT_ASSIGN: '<<=';
RSHIFT_ASSIGN: '>>=';
URSHIFT_ASSIGN: '>>>=';