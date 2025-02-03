// Defines fundamental programming language keywords used in Wheeler
lexer grammar TokenizerKeywordsBasicKeywords;

// Control flow keywords
IF          : 'if';              // Conditional branching
ELSE        : 'else';            // Alternative branch
WHILE       : 'while';           // While loop
DO          : 'do';              // Do-while loop
FOR         : 'for';             // For loop
BREAK       : 'break';           // Exit loop
CONTINUE    : 'continue';        // Skip to next iteration
RETURN      : 'return';          // Return from function
SWITCH      : 'switch';          // Switch statement
CASE        : 'case';            // Switch case
DEFAULT     : 'default';         // Default case
MATCH       : 'match';           // Pattern matching

// Exception handling
TRY         : 'try';             // Try block
CATCH       : 'catch';           // Catch block
FINALLY     : 'finally';         // Finally block
THROW       : 'throw';           // Throw exception
THROWS      : 'throws';          // Method exception declaration

// Package and module keywords
PACKAGE     : 'package';         // Package declaration
IMPORT      : 'import';          // Import declaration
MODULE      : 'module';          // Module declaration
EXPORTS     : 'exports';         // Module exports
REQUIRES    : 'requires';        // Module requirements
USES        : 'uses';            // Service usage
TO          : 'to';              // Export target specification

// Variable declaration
VAR         : 'var';             // Type-inferred variable
LET         : 'let';             // Immutable variable
HIST        : 'hist';            // History-tracking variable