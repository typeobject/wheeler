parser grammar WheelerParser;

options { tokenVocab=WheelerLexer; }

// Top Level Structure
compilationUnit
    : packageDeclaration?
      importDeclaration*
      moduleDeclaration?
      typeDeclaration*
      EOF
    ;

packageDeclaration
    : annotation* PACKAGE qualifiedName SEMI
    ;

importDeclaration
    : IMPORT STATIC? qualifiedName (DOT MUL)? SEMI
    ;

moduleDeclaration
    : annotation* MODULE qualifiedName moduleBody
    ;

moduleBody
    : LBRACE moduleDirective* RBRACE
    ;

moduleDirective
    : EXPORTS qualifiedName (TO qualifiedName)? SEMI
    | REQUIRES qualifiedName SEMI
    | USES qualifiedName SEMI
    ;

// Type Declarations
typeDeclaration
    : classDeclaration
    | interfaceDeclaration
    | enumDeclaration
    | annotation* SEMI
    ;

classDeclaration
    : annotation* classModifier*
      (CLASSICAL | QUANTUM | HYBRID)?
      CLASS IDENTIFIER
      typeParameters?
      (EXTENDS typeType)?
      (IMPLEMENTS typeList)?
      classBody
    ;

classBody
    : LBRACE classBodyDeclaration* RBRACE
    ;

classBodyDeclaration
    : SEMI
    | STATIC? block
    | memberDeclaration
    ;

memberDeclaration
    : methodDeclaration
    | fieldDeclaration
    | constructorDeclaration
    | classDeclaration
    | interfaceDeclaration
    | enumDeclaration
    | quantumDeclaration
    ;

// Quantum-specific Declarations
quantumDeclaration
    : annotation* quantumModifier*
      (quantumRegisterDecl
      | quantumStateDecl
      | quantumOracleDecl)
      SEMI
    ;

quantumRegisterDecl
    : QUREG IDENTIFIER arrayDimensions? (ASSIGN quantumInitializer)?
    ;

quantumStateDecl
    : STATE IDENTIFIER (ASSIGN stateExpression)?
    ;

quantumOracleDecl
    : ORACLE IDENTIFIER parameterList? (ASSIGN quantumCircuit)?
    ;

quantumInitializer
    : QUBIT_KET
    | stateExpression
    | NEW QUREG LPAREN expression RPAREN
    ;

stateExpression
    : QUBIT_KET
    | STATE_LITERAL
    | stateExpression TENSOR stateExpression
    | LPAREN stateExpression RPAREN
    | superpositionExpression
    ;

superpositionExpression
    : SUPERPOSITION LPAREN stateList RPAREN
    ;

// Method Declarations
methodDeclaration
    : annotation* methodModifier*
      (CLASSICAL | QUANTUM | HYBRID)?
      (typeTypeOrVoid | quantumType)
      IDENTIFIER
      formalParameters
      (THROWS qualifiedNameList)?
      methodBody
    ;

methodBody
    : block
    | quantumBlock
    | hybridBlock
    | SEMI
    ;

// Blocks and Statements
block
    : LBRACE blockStatement* RBRACE
    ;

quantumBlock
    : QUANTUM LBRACE quantumStatement* RBRACE
    ;

hybridBlock
    : HYBRID LBRACE
      (classicalStatement | quantumStatement)*
      RBRACE
    ;

blockStatement
    : localVariableDeclaration SEMI
    | statement
    ;

statement
    : blockLabel=block
    | IF parExpression statement (ELSE statement)?
    | FOR LPAREN forControl RPAREN statement
    | WHILE parExpression statement
    | DO statement WHILE parExpression SEMI
    | MATCH parExpression matchBlock
    | TRY block (catchClause+ finallyBlock? | finallyBlock)
    | TRANSACTION block (COMMIT | ROLLBACK) SEMI
    | UNCOMPUTE block
    | CLEAN block
    | RETURN expression? SEMI
    | THROW expression SEMI
    | BREAK IDENTIFIER? SEMI
    | CONTINUE IDENTIFIER? SEMI
    | SEMI
    | statementExpression SEMI
    | identifierLabel=IDENTIFIER COLON statement
    ;

quantumStatement
    : quantumGateApplication
    | quantumMeasurement
    | quantumStatePreparation
    | quantumControlFlow
    | quantumUncomputation
    ;

// Quantum Operations
quantumGateApplication
    : quantumGate
      LPAREN qubitExpression (COMMA qubitExpression)* RPAREN
      (LBRACK expression RBRACK)?  // For parameterized gates
      SEMI
    ;

quantumGate
    : HADAMARD
    | PAULIX
    | PAULIY
    | PAULIZ
    | CNOT
    | TOFFOLI
    | PHASE
    | ROTATE
    | IDENTIFIER  // Custom gates
    ;

qubitExpression
    : IDENTIFIER                              // Single qubit
    | IDENTIFIER LBRACK expression RBRACK     // Qubit from register
    | qubitExpression TENSOR qubitExpression  // Tensor product
    ;

quantumMeasurement
    : MEASURE qubitExpression
      (ARROW IDENTIFIER)?  // Optional classical result
      SEMI
    ;

quantumStatePreparation
    : PREPARE qubitExpression stateExpression SEMI
    ;

quantumControlFlow
    : QIF LPAREN qubitExpression RPAREN
      quantumBlock
      (ELSE quantumBlock)?
    | QWHILE LPAREN qubitExpression RPAREN
      quantumBlock
      UNTIL LPAREN expression RPAREN
    ;

quantumUncomputation
    : UNCOMPUTE LBRACE quantumStatement* RBRACE
    | CLEAN LBRACE qubitExpression* RBRACE
    ;

// Expressions
expression
    : primary
    | expression bop='.'
      ( IDENTIFIER
      | methodCall
      | THIS
      | NEW nonWildcardTypeArguments? innerCreator
      | SUPER superSuffix
      )
    | expression LBRACK expression RBRACK
    | methodCall
    | NEW creator
    | LPAREN annotation* typeType (BITAND typeType)* RPAREN expression
    | expression postfix=(INC | DEC)
    | prefix=(ADD | SUB | INC | DEC) expression
    | prefix=(TILDE | BANG) expression
    | expression bop=(MUL | DIV | MOD) expression
    | expression bop=(ADD | SUB) expression
    | expression bop=(LSHIFT | RSHIFT) expression
    | expression bop=(LE | GE | GT | LT) expression
    | expression bop=(EQUAL | NOTEQUAL) expression
    | expression bop=BITAND expression
    | expression bop=CARET expression
    | expression bop=BITOR expression
    | expression bop=AND expression
    | expression bop=OR expression
    | <assoc=right> expression bop=QUESTION expression COLON expression
    | <assoc=right> expression
      bop=(ASSIGN | ADD_ASSIGN | SUB_ASSIGN | MUL_ASSIGN | DIV_ASSIGN |
           AND_ASSIGN | OR_ASSIGN | XOR_ASSIGN | RSHIFT_ASSIGN |
           LSHIFT_ASSIGN | MOD_ASSIGN)
      expression
    | lambdaExpression
    ;

// Type System
typeType
    : (classicalType | quantumType)
      (LBRACK RBRACK)*
    ;

classicalType
    : annotation* (
      primitiveType |
      IDENTIFIER typeArguments? |
      qualifiedName typeArguments?
    )
    ;

quantumType
    : QUBIT_T
    | QUREG_T typeArguments?  // For size specification
    | STATE_T
    | ORACLE_T typeArguments? // For input/output types
    ;

typeArguments
    : LT typeArgument (COMMA typeArgument)* GT
    ;

typeArgument
    : typeType
    | annotation* QUESTION (
        (EXTENDS | SUPER) typeType
      )?
    ;

qualifiedName
    : IDENTIFIER (DOT IDENTIFIER)*
    ;

// Modifiers
classModifier
    : annotation
    | PUBLIC
    | PROTECTED
    | PRIVATE
    | STATIC
    | ABSTRACT
    | FINAL
    | CLASSICAL
    | QUANTUM
    | HYBRID
    ;

methodModifier
    : annotation
    | PUBLIC
    | PROTECTED
    | PRIVATE
    | STATIC
    | ABSTRACT
    | FINAL
    | SYNCHRONIZED
    | REV
    | PURE
    | CLASSICAL
    | QUANTUM
    | HYBRID
    ;

// Additional supporting rules...
variableDeclarator
    : variableDeclaratorId (ASSIGN variableInitializer)?
    ;

variableDeclaratorId
    : IDENTIFIER (LBRACK RBRACK)*
    ;

variableInitializer
    : arrayInitializer
    | expression
    ;

arrayInitializer
    : LBRACE
      (variableInitializer (COMMA variableInitializer)* (COMMA)?)?
      RBRACE
    ;