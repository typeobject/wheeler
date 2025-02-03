// Defines rules for interface declarations
parser grammar InterfaceDecl;

options { tokenVocab=WheelerLexer; }

// Interface declaration
// Example: public interface Quantum<T> extends BaseQuantum { ... }
interfaceDeclaration
    : annotation*                           // Optional annotations
      interfaceModifier*                    // Access modifiers
      INTERFACE                             // Interface keyword
      IDENTIFIER                            // Interface name
      typeParameters?                       // Generic parameters
      (EXTENDS typeList)?                   // Extended interfaces
      interfaceBody                         // Interface body
    ;

// Interface body
interfaceBody
    : LBRACE
        interfaceBodyDeclaration*
      RBRACE
    ;

// Individual declarations within an interface
interfaceBodyDeclaration
    : interfaceMethodDeclaration            // Method declaration
    | interfaceFieldDeclaration             // Constant declaration
    | interfaceDeclaration                  // Nested interface
    | classDeclaration                      // Nested class
    | enumDeclaration                       // Nested enum
    | annotationDeclaration                 // Nested annotation
    | SEMI                                  // Empty declaration
    ;

// Interface method declaration
interfaceMethodDeclaration
    : annotation*                           // Optional annotations
      interfaceMethodModifier*              // Method modifiers
      (typeTypeOrVoid | quantumType)        // Return type
      IDENTIFIER                            // Method name
      formalParameters                      // Parameters
      (THROWS qualifiedNameList)?           // Exceptions
      methodBody?                           // Optional body for default methods
    ;
