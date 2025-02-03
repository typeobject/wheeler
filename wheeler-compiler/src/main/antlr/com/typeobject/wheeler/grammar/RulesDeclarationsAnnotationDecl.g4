// Defines rules for annotation declarations in Wheeler
parser grammar RulesDeclarationsAnnotationDecl;

options { tokenVocab=WheelerLexer; }

// Annotation type declaration
// Example: public @interface Version { String value(); }
annotationDeclaration
    : annotation*                           // Meta-annotations
      annotationModifier*                   // Access modifiers
      AT                                    // @ symbol
      INTERFACE                             // Interface keyword
      IDENTIFIER                            // Annotation name
      annotationBody                        // Annotation body
    ;

// Annotation body containing elements
annotationBody
    : LBRACE
        annotationElementDeclaration*
      RBRACE
    ;

// Individual annotation element declarations
annotationElementDeclaration
    : annotation*                           // Element annotations
      annotationElementModifier*            // Element modifiers
      typeType                              // Element type
      IDENTIFIER                            // Element name
      LPAREN RPAREN                         // Empty parentheses
      defaultValue?                         // Optional default
      SEMI
    | classDeclaration                      // Nested class
    | interfaceDeclaration                  // Nested interface
    | enumDeclaration                       // Nested enum
    | annotationDeclaration                 // Nested annotation
    | SEMI                                  // Empty declaration
    ;

// Default value for annotation element
defaultValue
    : DEFAULT
      elementValue
    ;

// Possible element values
elementValue
    : expression                            // Expression value
    | annotation                            // Nested annotation
    | elementValueArrayInitializer          // Array initializer
    ;

// Array initializer for annotation values
elementValueArrayInitializer
    : LBRACE
        (elementValue (COMMA elementValue)*)?
        COMMA?                              // Optional trailing comma
      RBRACE
    ;