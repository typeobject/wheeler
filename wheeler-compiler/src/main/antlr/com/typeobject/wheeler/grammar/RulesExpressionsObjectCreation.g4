// Defines rules for object instantiation
parser grammar RulesExpressionsObjectCreation;

options { tokenVocab=WheelerLexer; }

// Object creation expression
creator
    : nonWildcardTypeArguments? createdName
      (arrayCreatorRest | classCreatorRest)
    ;

// Name of type being created
createdName
    : IDENTIFIER typeArgumentsOrDiamond?
      (DOT IDENTIFIER typeArgumentsOrDiamond?)*
    | primitiveType
    ;

// Class instance creation
classCreatorRest
    : arguments classBody?            // Constructor args and optional body
    ;

// Array creation
arrayCreatorRest
    : LBRACK                         // Array dimension
      (RBRACK LBRACK RBRACK* arrayInitializer    // Initialize with values
      | expression RBRACK            // Size specification
        (LBRACK expression RBRACK)*
        (LBRACK RBRACK)*)
    ;