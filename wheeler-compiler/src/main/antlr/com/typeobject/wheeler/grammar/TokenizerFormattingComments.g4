// Defines comment handling
lexer grammar TokenizerFormattingComments;

// Single-line comments
LINE_COMMENT
    : '//'                    // Comment start
      ~[\r\n]*               // Any chars except newline
      -> skip                // Skip for parser
    ;

// Traditional multi-line comments
BLOCK_COMMENT
    : '/*'                   // Comment start
      .*?                    // Non-greedy match of any chars
      '*/'                   // Comment end
      -> skip                // Skip for parser
    ;

// Documentation comments (similar to Javadoc)
DOC_COMMENT
    : '/**'                  // Doc comment start
      .*?                    // Non-greedy match of any chars
      '*/'                   // Doc comment end
      -> channel(HIDDEN)     // Preserve for documentation
    ;

// Quantum circuit comments (special syntax for quantum circuit diagrams)
CIRCUIT_COMMENT
    : '/|'                   // Circuit comment start
      .*?                    // Non-greedy match of any chars
      '|/'                   // Circuit comment end
      -> channel(HIDDEN)     // Preserve for visualization
    ;

// ===================================================================
// Usage Examples
// ===================================================================

// Whitespace Examples:
//   function foo() {     // Spaces around and inside parentheses handled
//       return 42;       // Indentation handled
//   }                    // Newlines handled

// Comment Examples:
//   // Single line comment
//
//   /* Multi-line
//      comment */
//
//   /** Documentation
//    *  comment with special
//    *  formatting
//    */
//
//   /| Quantum circuit comment
//      q0: --H--●--
//      q1: -----X--
//   |/

// ===================================================================
// Important Notes
// ===================================================================

// 1. Whitespace Handling:
//    - All standard whitespace is skipped by default
//    - Whitespace in strings is preserved
//    - Indentation is not semantically significant

// 2. Comment Types:
//    - LINE_COMMENT: Basic single-line comments
//    - BLOCK_COMMENT: Traditional multi-line comments
//    - DOC_COMMENT: Documentation comments (preserved)
//    - CIRCUIT_COMMENT: Special quantum circuit diagrams

// 3. Lexer Channels:
//    - Most tokens go to the default channel
//    - Whitespace and basic comments are skipped
//    - Doc comments go to HIDDEN channel for tools
//    - Circuit comments go to HIDDEN for visualization

// 4. Special Cases:
//    - Whitespace is significant in string literals
//    - Doc comments must be properly nested
//    - Circuit comments have special visualization rules

// 5. Error Handling:
//    - Unterminated comments are caught by lexer
//    - Invalid Unicode whitespace is rejected
//    - Nested comments are not allowed