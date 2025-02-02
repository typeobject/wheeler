// Defines type-related keywords
lexer grammar TypeKeywords;

// Class-related keywords
CLASS       : 'class';           // Class definition
INTERFACE   : 'interface';       // Interface definition
EXTENDS     : 'extends';         // Inheritance
IMPLEMENTS  : 'implements';      // Interface implementation
NEW         : 'new';             // Object instantiation
THIS        : 'this';            // Current instance reference
SUPER       : 'super';           // Parent class reference

// Computation types
CLASSICAL   : 'classical';       // Classical computation
HYBRID      : 'hybrid';          // Mixed classical/quantum

// Type system
ENUM        : 'enum';            // Enumeration type
TRANSITIVE  : 'transitive';      // Transitive dependency