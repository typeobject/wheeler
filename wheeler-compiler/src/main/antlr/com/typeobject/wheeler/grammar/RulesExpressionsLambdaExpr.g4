// Defines rules for lambda expressions
parser grammar RulesExpressionsLambdaExpr;

options { tokenVocab=WheelerLexer; }

// Lambda expression
lambdaExpression
    : lambdaParameters ARROW lambdaBody
    ;

// Lambda parameters
lambdaParameters
    : IDENTIFIER                     // Single parameter
    | LPAREN formalParameterList? RPAREN  // Multiple parameters
    | LPAREN inferredParameterList RPAREN // Inferred types
    ;

// Lambda parameter with inferred type
inferredParameterList
    : IDENTIFIER (COMMA IDENTIFIER)*
    ;

// Lambda body
lambdaBody
    : expression                     // Expression body
    | block                          // Block body
    | quantumBlock                   // Quantum implementation
    ;