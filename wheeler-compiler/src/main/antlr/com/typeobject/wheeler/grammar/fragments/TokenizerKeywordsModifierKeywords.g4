// Defines access and state modifiers in Wheeler
lexer grammar TokenizerKeywordsModifierKeywords;

// Access modifiers
PUBLIC      : 'public';          // Accessible everywhere
PRIVATE     : 'private';         // Class-level access only
PROTECTED   : 'protected';       // Class and subclass access

// State modifiers
STATIC      : 'static';          // Class-level member
FINAL       : 'final';           // Immutable declaration
ABSTRACT    : 'abstract';        // Incomplete definition
SYNCHRONIZED : 'synchronized';    // Thread synchronization
DEFAULT     : 'default';         // Interface default method

// Transaction control
TRANSACTION : 'transaction';      // Transaction block
COMMIT      : 'commit';          // Commit transaction
ROLLBACK    : 'rollback';        // Rollback transaction

// Memory management
UNCOMPUTE   : 'uncompute';       // Quantum uncomputation
CLEAN       : 'clean';           // Resource cleanup