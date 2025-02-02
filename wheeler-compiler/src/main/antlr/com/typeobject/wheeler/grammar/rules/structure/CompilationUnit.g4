// Defines the top-level structure of a Wheeler source file
parser grammar CompilationUnit;

// Link to our lexer grammar for token definitions
options { tokenVocab=WheelerLexer; }

// Top-level structure
compilationUnit
    : packageDeclaration?              // Optional package
      importDeclaration*               // Zero or more imports
      moduleDeclaration?               // Optional module
      declaration*                     // Zero or more declarations
      EOF                             // End of file marker
    ;

// Package declarations define the namespace for the current file
// Example: package com.example.project;
packageDeclaration
    : annotation*                      // Optional annotations
      PACKAGE qualifiedName SEMI       // Package name and semicolon
    ;

// Import statements bring external definitions into scope
// Examples:
// - import com.example.MyClass;
// - import static com.example.Utility.helper;
// - import com.example.*;
importDeclaration
    : IMPORT                          // Import keyword
      STATIC?                         // Optional static import
      qualifiedName                   // The name being imported
      (DOT MUL)?                      // Optional .* for wildcard imports
      SEMI                            // Semicolon
    ;

// Module declarations define a module's dependencies and exports
// Example:
// module com.example.project {
//     exports com.example.api;
//     requires com.example.dependency;
// }
moduleDeclaration
    : annotation*                    // Optional annotations
      MODULE qualifiedName           // Module name
      LBRACE                         // Open brace
        moduleDirective*             // Module directives
      RBRACE                         // Close brace
    ;

// Module directives specify module requirements and exports
moduleDirective
    : EXPORTS qualifiedName              // What this module exports
      (TO qualifiedName                  // Optional specific target
      (COMMA qualifiedName)*)?           // Additional targets
      SEMI
    | REQUIRES qualifiedName SEMI        // What this module requires
    | USES qualifiedName SEMI            // Services this module uses
    ;

// Top-level declarations in a source file
declaration
    : classDeclaration                // Class definition
    | interfaceDeclaration            // Interface definition
    | enumDeclaration                 // Enum definition
    | proofClassDeclaration           // Proof class definition
    | theoremDeclaration              // Theorem definition
    | annotation* SEMI                // Standalone annotations
    ;

// A qualified name is a dot-separated sequence of identifiers
// Example: com.example.project.MyClass
qualifiedName
    : IDENTIFIER                      // Single identifier
    | qualifiedName DOT IDENTIFIER    // Nested identifiers
    ;

// Annotations can be applied to various declarations
annotation
    : AT qualifiedName                               // Simple annotation
      (LPAREN annotationElement? RPAREN)?            // Optional elements
    ;

// Elements that can appear in an annotation
annotationElement
    : elementValuePair                             // Named element
    | elementValue                                 // Single value
    ;

// Name-value pair in an annotation
elementValuePair
    : IDENTIFIER ASSIGN elementValue               // name = value
    ;

// Possible values in an annotation
elementValue
    : expression                                   // Expression
    | annotation                                   // Nested annotation
    | elementValueArrayInitializer                 // Array initializer
    ;

// Array initializer in an annotation
elementValueArrayInitializer
    : LBRACE
      (elementValue (COMMA elementValue)*)?
      COMMA?                                       // Optional trailing comma
      RBRACE
    ;

// Expression placeholder - actual implementation in Expressions.g4
expression
    : qualifiedName      // Simplified for this file - full version elsewhere
    ;