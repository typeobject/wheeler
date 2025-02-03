// Defines rules for field declarations
parser grammar FieldDecl;

options { tokenVocab=WheelerLexer; }

// Field declaration
// Examples:
// - private int count = 0;
// - public static final double PI = 3.14159;
// - quantum qureg register;
fieldDeclaration
    : annotation*                           // Optional annotations
      fieldModifier*                        // Access and state modifiers
      typeType                              // Field type
      variableDeclarators                   // One or more variables
      SEMI                                  // End of declaration
    ;

// Multiple variable declarations
variableDeclarators
    : variableDeclarator
      (COMMA variableDeclarator)*
    ;

// Single variable declaration
variableDeclarator
    : variableDeclaratorId                  // Variable name
      (ASSIGN variableInitializer)?         // Optional initialization
    ;

// Variable name with optional array dimensions
variableDeclaratorId
    : IDENTIFIER
      (LBRACK RBRACK)*                      // Array dimensions
    ;

// Variable initializer
variableInitializer
    : arrayInitializer                      // Array initialization
    | expression                            // Single value
    ;

// Array initializer
arrayInitializer
    : LBRACE
        (variableInitializer
          (COMMA variableInitializer)*)?
        COMMA?                              // Optional trailing comma
      RBRACE
    ;
