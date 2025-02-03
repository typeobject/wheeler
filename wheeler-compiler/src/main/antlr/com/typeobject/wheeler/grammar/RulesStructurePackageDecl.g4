// Defines rules for package declarations in Wheeler source files
// Package declarations must be the first non-comment code in a file
parser grammar RulesStructurePackageDecl;

options { tokenVocab=WheelerLexer; }

// Top-level package declaration
// Examples:
// package com.example.project;
// @Version("1.0")
// package com.example.project;
packageDeclaration
    : annotation*                    // Optional annotations
      PACKAGE                        // Package keyword
      qualifiedName                  // Package name
      SEMI                          // Required semicolon
    ;

// Qualified name for package path
// Examples:
// - com
// - com.example
// - com.example.project
// - com.example.project.subpackage
qualifiedName
    : IDENTIFIER                    // Single package name
    | qualifiedName                 // Nested package name
      DOT                          // Dot separator
      IDENTIFIER                   // Next part of name
    ;

// Annotations that can be applied to packages
// Examples:
// @Deprecated
// @Version("1.0")
// @Author(name="dev", email="dev@example.com")
annotation
    : AT qualifiedName              // Annotation name
      (LPAREN                       // Open parenthesis
        annotationElement?          // Optional elements
      RPAREN)?                      // Close parenthesis
    ;

// Elements within an annotation
annotationElement
    : elementValuePair              // Named element
    | elementValue                  // Single value
    ;

// Name-value pair in an annotation
// Example: name="value"
elementValuePair
    : IDENTIFIER                    // Element name
      ASSIGN                        // Equals sign
      elementValue                  // Element value
    ;

// Possible values in an annotation
elementValue
    : expression                    // Expression value
    | annotation                    // Nested annotation
    | elementValueArrayInitializer  // Array initializer
    ;

// Array initializer in an annotation
// Example: @Authors({"dev1", "dev2"})
elementValueArrayInitializer
    : LBRACE
      (elementValue                 // First value
        (COMMA elementValue)*       // Additional values
      )?
      COMMA?                        // Optional trailing comma
      RBRACE
    ;

// Expression placeholder - actual implementation in Expressions.g4
expression
    : qualifiedName                 // Simplified for this file
    ;