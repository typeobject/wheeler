// Defines rules for generic type parameters and arguments
parser grammar RulesTypesGenerics;

options { tokenVocab=WheelerLexer; }

// Generic type parameters
// Examples:
// - <T>
// - <T extends Comparable<T>>
// - <T, U extends Number>
typeParameters
    : LT typeParameter
      (COMMA typeParameter)*
      GT
    ;

// Single type parameter
typeParameter
    : annotation*                   // Type parameter annotations
      IDENTIFIER                    // Type parameter name
      typeBound?                    // Optional bounds
    ;

// Type arguments for generic types
// Examples:
// - List<String>
// - Map<K, V>
// - Optional<? extends Number>
typeArguments
    : LT typeArgument
      (COMMA typeArgument)*
      GT
    ;

// Single type argument
typeArgument
    : typeType                     // Concrete type
    | wildcardType                 // Wildcard type
    ;

// Wildcard type argument
// Examples:
// - ?
// - ? extends Number
// - ? super Integer
wildcardType
    : annotation*
      QUESTION
      (
        (EXTENDS | SUPER)
        typeType
      )?
    ;