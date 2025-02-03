// Defines rules for type bounds and constraints
parser grammar TypeBounds;

options { tokenVocab=WheelerLexer; }

// Type bounds for generics
// Examples:
// - extends Comparable<T>
// - extends Number & Serializable
typeBound
    : EXTENDS typeType             // Upper bound
      (AMPERSAND typeType)*        // Additional interfaces
    ;

// Type bounds for wildcards
wildcardBounds
    : EXTENDS typeType            // Upper bound
    | SUPER typeType             // Lower bound
    ;

// Interface type list
// Example: implements Runnable, AutoCloseable
typeList
    : typeType
      (COMMA typeType)*
    ;

// Qualified type name
qualifiedName
    : IDENTIFIER                  // Simple name
    | qualifiedName
      DOT
      IDENTIFIER                 // Qualified name
    ;