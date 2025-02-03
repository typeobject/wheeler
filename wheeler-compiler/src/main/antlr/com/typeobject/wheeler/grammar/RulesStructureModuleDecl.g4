// Defines rules for module declarations in Wheeler source files
parser grammar RulesStructureModuleDecl;

options { tokenVocab=WheelerLexer; }

// Top-level module declaration
// Example:
// module com.example.project {
//     exports com.example.api;
//     requires com.example.dependency;
//     uses com.example.service;
// }
moduleDeclaration
    : annotation*                    // Optional annotations
      MODULE                         // Module keyword
      qualifiedName                  // Module name
      moduleBody                     // Module body in braces
    ;

// Module body contains directives
moduleBody
    : LBRACE
        moduleDirective*             // Zero or more directives
      RBRACE
    ;

// Module directives define the module's interface
moduleDirective
    : exportsDirective              // What this module exports
    | requiresDirective             // What this module needs
    | usesDirective                 // Services this module uses
    | providesDirective             // Services this module provides
    ;

// Exports directive specifies packages this module makes available
// Examples:
// - exports com.example.api;                    // Export to all modules
// - exports com.example.api to com.other.mod;   // Export to specific module
exportsDirective
    : EXPORTS qualifiedName                     // Package to export
      (TO targetModules)?                       // Optional specific targets
      SEMI
    ;

// List of target modules for qualified exports
targetModules
    : qualifiedName                             // First target module
      (COMMA qualifiedName)*                    // Additional targets
    ;

// Requires directive specifies module dependencies
// Examples:
// - requires com.example.common;               // Required module
// - requires static com.example.compile;       // Compile-time only
// - requires transitive com.example.api;       // Re-exported requirement
requiresDirective
    : REQUIRES
      requiresModifier*                         // Optional modifiers
      qualifiedName                             // Required module name
      SEMI
    ;

// Modifiers for requires directives
requiresModifier
    : STATIC                                    // Compile-time only dependency
    | TRANSITIVE                                // Re-exported dependency
    | PUBLIC                                    // Visible to dependents
    ;

// Uses directive declares service dependencies
// Example: uses com.example.Service;
usesDirective
    : USES
      serviceType                               // Service interface
      SEMI
    ;

// Provides directive implements a service
// Example: provides com.example.Service with com.example.ServiceImpl;
providesDirective
    : PROVIDES
      serviceType                               // Service interface
      WITH                                      // Implementation specifier
      serviceImplementations                    // One or more implementations
      SEMI
    ;

// Service type specification
serviceType
    : qualifiedName                            // Service interface name
    ;

// List of service implementations
serviceImplementations
    : qualifiedName                            // First implementation
      (COMMA qualifiedName)*                   // Additional implementations
    ;

// Qualified names for various identifiers
qualifiedName
    : IDENTIFIER                               // Single identifier
    | qualifiedName
      DOT
      IDENTIFIER                               // Nested identifiers
    ;

// Annotations that can be applied to modules
annotation
    : AT qualifiedName                         // Simple annotation
      (LPAREN annotationElement? RPAREN)?      // Optional elements
    ;

// Elements within annotations
annotationElement
    : elementValuePair                         // Named element
    | elementValue                             // Single value
    ;

// Name-value pairs in annotations
elementValuePair
    : IDENTIFIER ASSIGN elementValue           // name = value
    ;

// Possible annotation values
elementValue
    : expression                               // Expression
    | annotation                               // Nested annotation
    | elementValueArrayInitializer             // Array initializer
    ;

// Array initializer in annotations
elementValueArrayInitializer
    : LBRACE
      (elementValue (COMMA elementValue)*)?
      COMMA?                                   // Optional trailing comma
      RBRACE
    ;

// Expression placeholder - full implementation elsewhere
expression
    : qualifiedName                            // Simplified for this file
    ;