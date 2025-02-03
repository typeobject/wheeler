// Defines rules for basic statements
parser grammar BasicStmt;

options { tokenVocab=WheelerLexer; }

// Basic statement types
statement
    : blockStatement                     // Block of statements
    | expressionStatement                // Expression as statement
    | variableDeclaration               // Variable declaration
    | returnStatement                   // Return statement
    | assertStatement                   // Assertion
    | emptyStatement                    // Empty statement (;)
    ;

// Block of statements
blockStatement
    : LBRACE
        statement*                       // Zero or more statements
      RBRACE
    ;

// Expression statement (expression followed by semicolon)
// Examples:
// - method();
// - x++;
// - a = b + c;
expressionStatement
    : expression SEMI
    ;

// Variable declaration statement
// Examples:
// - int x = 42;
// - final String name = "Wheeler";
// - var count = getCount();
variableDeclaration
    : variableModifier*                 // Optional modifiers (final, etc.)
      (typeType | VAR)                  // Type or var for inference
      variableDeclarators               // One or more variables
      SEMI
    ;

// Return statement
// Examples:
// - return;
// - return value;
// - return computeResult();
returnStatement
    : RETURN
      expression?
      SEMI
    ;

// Assertion statement
// Examples:
// - assert x > 0;
// - assert isValid() : "Invalid state";
assertStatement
    : ASSERT
      expression
      (COLON expression)?
      SEMI
    ;

// Empty statement (just a semicolon)
emptyStatement
    : SEMI
    ;