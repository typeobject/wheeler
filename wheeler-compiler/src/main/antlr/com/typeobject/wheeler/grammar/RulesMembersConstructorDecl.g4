// Defines rules for constructor declarations
parser grammar RulesMembersConstructorDecl;

options { tokenVocab=WheelerLexer; }

// Constructor declaration
// Examples:
// - public MyClass() { ... }
// - protected QuantumRegister(int size) quantum { ... }
constructorDeclaration
    : annotation*                           // Optional annotations
      constructorModifier*                  // Access modifiers
      computationType?                      // Computation type
      IDENTIFIER                            // Must match class name
      formalParameters                      // Parameter list
      (THROWS qualifiedNameList)?           // Exception declarations
      constructorBody                       // Implementation
    ;

// Constructor body
constructorBody
    : LBRACE
        explicitConstructorInvocation?      // super() or this()
        blockStatement*                     // Constructor code
      RBRACE
    ;

// Calls to other constructors
explicitConstructorInvocation
    : typeArguments?                        // Generic type args
      (THIS | SUPER)                        // this() or super()
      arguments                             // Constructor arguments
      SEMI
    | expressionName DOT                    // Qualified super call
      typeArguments?
      SUPER
      arguments
      SEMI
    ;