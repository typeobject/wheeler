// Defines rules for property declarations
parser grammar PropertyDecl;

options { tokenVocab=WheelerLexer; }

// Property declaration
// Examples:
// - property int Value { get; set; }
// - public property Complex Phase {
//     get quantum { return measurePhase(); }
//     set quantum { applyPhase(value); }
//   }
propertyDeclaration
    : annotation*                           // Optional annotations
      propertyModifier*                     // Access modifiers
      computationType?                      // Computation type
      PROPERTY                              // Property keyword
      typeType                              // Property type
      IDENTIFIER                            // Property name
      propertyBody                          // Property implementation
    ;

// Property body with accessors
propertyBody
    : LBRACE
        propertyAccessor*                   // Getter/setter methods
      RBRACE
    ;

// Property accessor (getter or setter)
propertyAccessor
    : annotation*                           // Optional annotations
      accessorModifier?                     // Access modifier
      computationType?                      // Computation type
      (getter | setter)                     // Getter or setter
    ;

// Getter method
getter
    : GET
      (SEMI | block | quantumBlock)         // Auto or implemented
    ;

// Setter method
setter
    : SET
      (SEMI | block | quantumBlock)         // Auto or implemented
    ;

// Property backing field (if needed)
propertyBackingField
    : fieldDeclaration
    ;