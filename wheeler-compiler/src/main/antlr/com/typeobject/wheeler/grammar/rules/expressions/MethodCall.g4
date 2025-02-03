// Defines rules for method invocation
parser grammar MethodCall;

options { tokenVocab=WheelerLexer; }

// Method call
methodCall
    : IDENTIFIER                      // Method name
      (typeArguments)?                // Optional generic args
      arguments                       // Method arguments
    | THIS arguments                  // Constructor call
    | SUPER arguments                 // Super method call
    ;

// Method arguments
arguments
    : LPAREN
      (expressionList)?               // Argument list
      RPAREN
    ;

// List of expressions (for arguments)
expressionList
    : expression
      (COMMA expression)*
    ;