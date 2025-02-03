// Defines type modifiers and qualifiers
lexer grammar TokenizerTypesModifierTypes;

// Mutability modifiers
FINAL       : 'final';           // Immutable value
CONST       : 'const';           // Compile-time constant
VAR         : 'var';             // Mutable variable
LET         : 'let';             // Immutable variable

// Access modifiers
PUBLIC      : 'public';          // Accessible everywhere
PRIVATE     : 'private';         // Class-level access
PROTECTED   : 'protected';       // Class and subclass access

// Memory modifiers
VOLATILE    : 'volatile';        // Non-cached value
TRANSIENT   : 'transient';       // Non-serialized value
HIST        : 'hist';            // History-tracked value

// Computation modifiers
PURE        : 'pure';            // No side effects
REV         : 'rev';             // Reversible computation
CLASSICAL   : 'classical';        // Classical computation
QUANTUM     : 'quantum';         // Quantum computation
HYBRID      : 'hybrid';          // Mixed computation

// Nullability
NULLABLE    : 'nullable';        // Can be null
NONNULL     : 'nonnull';         // Cannot be null

// Type parameters
COVARIANT   : 'out';             // Covariant type parameter
CONTRAVARIANT : 'in';            // Contravariant type parameter
INVARIANT   : 'inv';             // Invariant type parameter