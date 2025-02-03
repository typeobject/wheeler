// Defines rules for exception handling
parser grammar ExceptionHandling;

options { tokenVocab=WheelerLexer; }

// Try-catch statement
tryStatement
    : TRY
      resourceSpecification?            // Try-with-resources
      block                            // Try block
      catchClause*                     // Catch blocks
      finallyBlock?                    // Finally block
    ;

// Resource specification for try-with-resources
resourceSpecification
    : LPAREN
      resources
      SEMI?
      RPAREN
    ;

// Resources list
resources
    : resource
      (SEMI resource)*
    ;

// Individual resource
resource
    : variableModifier*
      typeType
      variableDeclaratorId
      ASSIGN
      expression
    ;

// Catch clause
catchClause
    : CATCH
      LPAREN
      catchType                        // Exception type(s)
      IDENTIFIER                       // Exception variable
      RPAREN
      block
    ;

// Exception types in catch
catchType
    : qualifiedName
      (PIPE qualifiedName)*            // Multiple exception types
    ;

// Finally block
finallyBlock
    : FINALLY
      block
    ;

// Throw statement
throwStatement
    : THROW
      expression
      SEMI
    ;