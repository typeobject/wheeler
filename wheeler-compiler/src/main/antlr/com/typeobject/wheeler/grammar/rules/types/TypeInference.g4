// Defines rules for type inference and var declarations
parser grammar TypeInference;

options { tokenVocab=WheelerLexer; }

// Variable declaration with type inference
// Examples:
// - var x = 42;
// - var list = new ArrayList<String>();
variableDeclarationWithInference
    : VAR                        // var keyword
      variableDeclarator         // Variable being declared
    ;

// Method return type inference
// Example: var getName() { return "example"; }
methodDeclarationWithInference
    : VAR                       // var keyword
      IDENTIFIER                // Method name
      formalParameters          // Parameters
      methodBody                // Implementation
    ;

// Lambda parameter type inference
// Example: (x, y) -> x + y
inferredLambdaParameters
    : LPAREN
      IDENTIFIER
      (COMMA IDENTIFIER)*
      RPAREN
    ;

// Generic method type inference
// Example: .<String>transform(input)
inferredTypeArguments
    : DOT
      typeArguments           // Inferred type arguments
    ;