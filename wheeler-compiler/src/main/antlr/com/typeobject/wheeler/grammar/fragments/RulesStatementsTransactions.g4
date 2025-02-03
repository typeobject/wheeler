// Defines rules for transaction handling
parser grammar RulesStatementsTransactions;

options { tokenVocab=WheelerLexer; }

// Transaction statement
transactionStatement
    : TRANSACTION
      block                            // Transaction block
      transactionEnd                   // Commit or rollback
    ;

// Transaction end
transactionEnd
    : commitStatement
    | rollbackStatement
    ;

// Commit statement
commitStatement
    : COMMIT
      SEMI
    ;

// Rollback statement
rollbackStatement
    : ROLLBACK
      SEMI
    ;

// Uncompute block (quantum-specific)
uncomputeBlock
    : UNCOMPUTE
      block
    ;

// Clean block (quantum-specific)
cleanBlock
    : CLEAN
      block
    ;