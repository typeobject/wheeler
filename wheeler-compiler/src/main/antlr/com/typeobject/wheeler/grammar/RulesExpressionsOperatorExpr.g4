// Defines rules for operator expressions and precedence
parser grammar RulesExpressionsOperatorExpr;

options { tokenVocab=WheelerLexer; }

// Expression with precedence levels
expression
    : primary                                                  // Atomic expressions
    | expression bop=DOT                                       // Member access
      ( IDENTIFIER
      | methodCall
      | THIS
      | NEW nonWildcardTypeArguments? innerCreator
      | SUPER superSuffix
      )
    | expression LBRACK expression RBRACK                      // Array access
    | methodCall                                              // Method invocation
    | NEW creator                                             // Object creation
    | LPAREN annotation* typeType (AMPERSAND typeType)* RPAREN
      expression                                              // Type cast
    | expression postfix=(INC | DEC)                          // Post inc/dec
    | prefix=(ADD | SUB | INC | DEC) expression               // Pre inc/dec
    | prefix=(TILDE | BANG) expression                        // Bitwise/logical NOT
    | expression bop=(MUL | DIV | MOD) expression             // Multiplicative
    | expression bop=(ADD | SUB) expression                   // Additive
    | expression bop=(LSHIFT | RSHIFT | URSHIFT) expression   // Shift
    | expression bop=(LE | GE | GT | LT) expression           // Relational
    | expression bop=(EQUAL | NOTEQUAL) expression            // Equality
    | expression bop=AMPERSAND expression                     // Bitwise AND
    | expression bop=CARET expression                         // Bitwise XOR
    | expression bop=PIPE expression                          // Bitwise OR
    | expression bop=AND expression                           // Logical AND
    | expression bop=OR expression                            // Logical OR
    | expression bop=TENSOR expression                        // Quantum tensor
    | expression bop=CONJUGATE                                // Quantum conjugate
    | <assoc=right> expression
      bop=QUESTION expression COLON expression                // Conditional
    | <assoc=right> expression
      bop=(ASSIGN | ADD_ASSIGN | SUB_ASSIGN | MUL_ASSIGN     // Assignment
           | DIV_ASSIGN | AND_ASSIGN | OR_ASSIGN | XOR_ASSIGN
           | RSHIFT_ASSIGN | LSHIFT_ASSIGN | MOD_ASSIGN)
      expression
    | lambdaExpression                                        // Lambda
    ;
