lexer grammar WheelerLexer;

import
   // Keywords
   TokenizerKeywordsBasicKeywords,        // Basic language keywords
   TokenizerKeywordsModifierKeywords,     // Modifier keywords
   TokenizerKeywordsTypeKeywords,         // Type-related keywords
   TokenizerKeywordsQuantumKeywords,      // Quantum computing keywords
   TokenizerKeywordsProofKeywords,        // Proof system keywords

   // Operators
   TokenizerOperatorsArithmeticOps,       // Math operators
   TokenizerOperatorsLogicalOps,          // Logical operators
   TokenizerOperatorsBitwiseOps,          // Bitwise operators
   TokenizerOperatorsComparisonOps,       // Comparison operators
   TokenizerOperatorsAssignmentOps,       // Assignment operators
   TokenizerOperatorsQuantumOps,          // Quantum operators
   TokenizerOperatorsSeparators,          // Separator operators

   // Types
   TokenizerTypesPrimitiveTypes,          // Basic types
   TokenizerTypesContainerTypes,          // Container types
   TokenizerTypesQuantumTypes,            // Quantum types
   TokenizerTypesModifierTypes,           // Type modifiers

   // Literals
   TokenizerLiteralsNumericLiterals,      // Numbers
   TokenizerLiteralsStringLiterals,       // Strings
   TokenizerLiteralsBooleanLiterals,      // Booleans
   TokenizerLiteralsQuantumLiterals,      // Quantum states
   TokenizerLiteralsComplexLiterals;      // Complex numbers

// Identifier must come after all keywords to avoid conflicts
IDENTIFIER
   : [a-zA-Z_] [a-zA-Z0-9_]*    // Letters and digits, must start with letter/underscore
   ;