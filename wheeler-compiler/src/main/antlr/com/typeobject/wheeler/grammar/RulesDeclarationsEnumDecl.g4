// Defines rules for enum declarations
parser grammar RulesDeclarationsEnumDecl;

options { tokenVocab=WheelerLexer; }

// Enum declaration
// Example: public enum Spin { UP(1), DOWN(-1) }
enumDeclaration
    : annotation*                           // Optional annotations
      enumModifier*                         // Access modifiers
      ENUM                                  // Enum keyword
      IDENTIFIER                            // Enum name
      (IMPLEMENTS typeList)?                // Optional interfaces
      enumBody                              // Enum body
    ;

// Enum body containing constants and members
enumBody
    : LBRACE
        enumConstants?                       // Enum constant list
        COMMA?                              // Optional trailing comma
        enumBodyDeclarations?               // Additional declarations
      RBRACE
    ;

// List of enum constants
enumConstants
    : enumConstant
      (COMMA enumConstant)*
    ;

// Individual enum constant
enumConstant
    : annotation*                           // Optional annotations
      IDENTIFIER                            // Constant name
      arguments?                            // Optional constructor args
      classBody?                            // Optional class body
    ;

// Additional enum body declarations
enumBodyDeclarations
    : SEMI
      classBodyDeclaration*
    ;