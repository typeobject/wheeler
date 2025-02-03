// Defines rules for import statements in Wheeler source files
parser grammar ImportDecl;

options { tokenVocab=WheelerLexer; }

// Top-level import declaration
// Handles all forms of imports including:
// - Regular imports:         import com.example.MyClass;
// - Static imports:          import static com.example.Utility.method;
// - Wildcard imports:        import com.example.*;
// - Static wildcard imports: import static com.example.Utility.*;
importDeclaration
    : IMPORT                          // Import keyword
      importModifier?                 // Optional modifiers (static)
      importSpec                      // What is being imported
      SEMI                           // Required semicolon
    ;

// Import modifiers - currently only static is supported
// Example: import static com.example.Utility.method;
importModifier
    : STATIC                         // Static import modifier
    ;

// What is being imported - can be a regular import or a wildcard import
importSpec
    : singleImport                   // Import a specific type/member
    | wildcardImport                 // Import all types from a package
    ;

// Regular import of a specific type or static member
// Examples:
// - import com.example.MyClass;
// - import static com.example.Utility.method;
singleImport
    : qualifiedName                  // Full path to imported item
    ;

// Wildcard import of all types from a package
// Examples:
// - import com.example.*;
// - import static com.example.Utility.*;
wildcardImport
    : qualifiedName                  // Package or type name
      DOT                           // Dot separator
      MUL                           // Asterisk for wildcard
    ;

// Qualified name represents a dot-separated sequence of identifiers
// Examples:
// - com.example.MyClass
// - java.util.List
qualifiedName
    : IDENTIFIER                     // Single identifier
    | qualifiedName                  // Nested package/type name
      DOT                           // Dot separator
      IDENTIFIER                    // Next part of name
    ;