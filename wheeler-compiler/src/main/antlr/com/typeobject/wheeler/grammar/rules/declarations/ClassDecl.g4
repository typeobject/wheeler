// Defines rules for class declarations
parser grammar ClassDecl;

options { tokenVocab=WheelerLexer; }

// Class declaration
// Examples:
// - classical class MyClass { ... }
// - @ThreadSafe public quantum class QuantumRegister<T> extends Base implements IQuantum { ... }
classDeclaration
    : annotation*                    // Optional annotations
      classModifier*                 // Optional modifiers (public, private, etc)
      computationType?               // Optional: classical, quantum, or hybrid
      CLASS                          // Class keyword
      IDENTIFIER                     // Class name
      typeParameters?                // Optional generic parameters
      (EXTENDS typeType)?            // Optional superclass
      (IMPLEMENTS typeList)?         // Optional interfaces
      classBody                      // Class body
    ;

// Class body containing members
classBody
    : LBRACE
        classBodyDeclaration*
      RBRACE
    ;

// Individual declarations within a class
classBodyDeclaration
    : SEMI                                  // Empty declaration
    | STATIC? block                         // Static or instance initializer
    | memberDeclaration                     // Field, method, etc.
    ;

// Class member declarations
memberDeclaration
    : methodDeclaration                     // Method definition
    | fieldDeclaration                      // Field definition
    | constructorDeclaration                // Constructor
    | classDeclaration                      // Nested class
    | interfaceDeclaration                  // Nested interface
    | enumDeclaration                       // Nested enum
    | annotationDeclaration                 // Nested annotation
    | quantumDeclaration                    // Quantum member
    ;

// Type parameters for generics
// Example: class Box<T extends Comparable<T>>
typeParameters
    : LT typeParameter
      (COMMA typeParameter)*
      GT
    ;

// Individual type parameter
typeParameter
    : annotation* IDENTIFIER
      (EXTENDS typeBound)?
    ;

// Type bounds for generic parameters
typeBound
    : typeType
      (AMPERSAND typeType)*
    ;