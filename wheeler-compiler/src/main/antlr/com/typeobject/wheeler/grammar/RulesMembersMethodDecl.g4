// Defines rules for method declarations
parser grammar RulesMembersMethodDecl;

options { tokenVocab=WheelerLexer; }

// Method declaration
// Examples:
// - public void normalMethod() { ... }
// - @Measure quantum Complex measureState(qubit q) { ... }
// - classical int add(int a, int b) pure { ... }
methodDeclaration
    : annotation*                           // Optional annotations
      methodModifier*                       // Access and state modifiers
      computationType?                      // classical/quantum/hybrid
      (typeTypeOrVoid | quantumType)        // Return type
      IDENTIFIER                            // Method name
      typeParameters?                       // Generic parameters
      formalParameters                      // Parameter list
      (THROWS qualifiedNameList)?           // Exception declarations
      methodBody                            // Method implementation
    ;

// Method parameters
formalParameters
    : LPAREN
        formalParameterList?
      RPAREN
    ;

// Parameter list with possible varargs
formalParameterList
    : formalParameter
      (COMMA formalParameter)*
      (COMMA lastFormalParameter)?          // Varargs parameter
    | lastFormalParameter                   // Only varargs
    ;

// Regular parameter
formalParameter
    : variableModifier*                     // Optional modifiers
      typeType                              // Parameter type
      variableDeclaratorId                  // Parameter name
    ;

// Varargs parameter
lastFormalParameter
    : variableModifier*                     // Optional modifiers
      typeType                              // Parameter type
      ELLIPSIS                              // Varargs indicator
      variableDeclaratorId                  // Parameter name
    ;

// Method body
methodBody
    : block                                 // Regular method body
    | quantumBlock                          // Quantum implementation
    | hybridBlock                           // Mixed implementation
    | SEMI                                  // Abstract method
    ;