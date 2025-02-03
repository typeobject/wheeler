// Defines core type system rules
parser grammar TypeSystem;

options { tokenVocab=WheelerLexer; }

// Base type specification
// Examples:
// - int
// - String
// - List<T>
// - qureg
// - classical Matrix
typeType
    : annotation*                     // Type annotations
      (
        classicalType                 // Regular class types
      | quantumType                   // Quantum types
      | computationType               // Computation type modifiers
      )
      (LBRACK RBRACK)*                // Optional array dimensions
    ;

// Classical type references
classicalType
    : primitiveType                  // Built-in types
    | IDENTIFIER typeArguments?      // Class or interface types
    | qualifiedName typeArguments?   // Fully qualified types
    ;

// Primitive types
primitiveType
    : BOOLEAN_T                      // boolean
    | BYTE_T                         // byte
    | SHORT_T                        // short
    | INT_T                          // int
    | LONG_T                         // long
    | FLOAT_T                        // float
    | DOUBLE_T                       // double
    | CHAR_T                         // char
    ;

// Quantum-specific types
quantumType
    : QUBIT typeArguments?          // Single qubit
    | QUREG typeArguments?          // Quantum register
    | STATE                         // Quantum state
    | ORACLE typeArguments?         // Quantum oracle
    ;

// Computation type modifiers
computationType
    : CLASSICAL                     // Classical computation
    | QUANTUM                       // Quantum computation
    | HYBRID                        // Mixed computation
    ;

// Type or void (for method returns)
typeTypeOrVoid
    : typeType                     // Any type
    | VOID_T                       // void return type
    ;