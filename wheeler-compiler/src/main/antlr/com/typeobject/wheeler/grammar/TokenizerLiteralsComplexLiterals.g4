// Defines complex number literals
lexer grammar TokenizerLiteralsComplexLiterals;

// Complex number literals
COMPLEX_LITERAL
    : DecimalComplex              // Regular complex numbers
    | PolarComplex                // Polar form complex numbers
    ;

fragment DecimalComplex
    : [0-9]+ ('.' [0-9]*)?         // Real part
      ([+-] [0-9]+ ('.' [0-9]*)?)? // Optional imaginary part
      'i'?                         // Optional i
    ;

fragment PolarComplex
    : [0-9]+ ('.' [0-9]*)?       // Magnitude
      'e^{i'
      [0-9]+ ('.' [0-9]*)?       // Phase
      'π}'                       // In units of π
    ;