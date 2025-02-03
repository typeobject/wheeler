// Defines rules for control flow statements
parser grammar RulesStatementsControlFlow;

options { tokenVocab=WheelerLexer; }

// Control flow statements
controlFlowStatement
    : ifStatement                       // If-then-else
    | forStatement                      // For loops
    | whileStatement                    // While loops
    | doWhileStatement                  // Do-while loops
    | switchStatement                   // Switch statements
    | matchStatement                    // Pattern matching
    | breakStatement                    // Break
    | continueStatement                 // Continue
    ;

// If statement
// Examples:
// - if (condition) statement
// - if (condition) statement else statement
ifStatement
    : IF
      parExpression                     // Parenthesized condition
      statement                         // Then branch
      (ELSE statement)?                 // Optional else branch
    ;

// For loop variations
forStatement
    : FOR
      LPAREN
      forControl                        // Loop control
      RPAREN
      statement
    ;

// For loop control section
forControl
    : forInit? SEMI                     // Initialization
      expression? SEMI                  // Condition
      forUpdate?                        // Update
    | enhancedForControl                // For-each loop
    ;

// While loop
whileStatement
    : WHILE
      parExpression
      statement
    ;

// Do-while loop
doWhileStatement
    : DO
      statement
      WHILE
      parExpression
      SEMI
    ;

// Switch statement
switchStatement
    : SWITCH
      parExpression
      LBRACE
        switchBlockStatementGroup*
      RBRACE
    ;

// Match statement (pattern matching)
matchStatement
    : MATCH
      parExpression
      LBRACE
        matchCase*
      RBRACE
    ;

// Break statement
breakStatement
    : BREAK
      IDENTIFIER?
      SEMI
    ;

// Continue statement
continueStatement
    : CONTINUE
      IDENTIFIER?
      SEMI
    ;