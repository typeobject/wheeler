parser grammar WheelerParser;

options { tokenVocab=WheelerLexer; }

@header {
package com.typeobject.wheeler.compiler.antlr;
}

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

interfaceDeclaration
    : annotation* INTERFACE IDENTIFIER typeParameters?
      (EXTENDS typeList)? interfaceBody
    ;

interfaceBody
    : LBRACE interfaceBodyDeclaration* RBRACE
    ;

interfaceBodyDeclaration
    : interfaceMethodDeclaration
    | interfaceFieldDeclaration
    | classDeclaration
    | interfaceDeclaration
    | enumDeclaration
    | SEMI
    ;

interfaceMethodDeclaration
    : annotation* interfaceMethodModifier*
      (typeTypeOrVoid | quantumType) IDENTIFIER formalParameters
      (THROWS qualifiedNameList)? SEMI
    ;

interfaceFieldDeclaration
    : annotation* (PUBLIC | PRIVATE | PROTECTED)? STATIC? FINAL?
      typeType variableDeclarators SEMI
    ;

enumDeclaration
    : annotation* ENUM IDENTIFIER (IMPLEMENTS typeList)? enumBody
    ;

enumBody
    : LBRACE enumConstants? ','? enumBodyDeclarations? RBRACE
    ;

enumConstants
    : enumConstant (',' enumConstant)*
    ;

enumConstant
    : annotation* IDENTIFIER arguments? classBody?
    ;

enumBodyDeclarations
    : SEMI classBodyDeclaration*
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

stateList
    : stateExpression (',' stateExpression)*
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

classicalStatement
    : variableDeclaration
    | expressionStatement
    | selectionStatement
    | iterationStatement
    | jumpStatement
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

// Supporting declarations
annotation
    : '@' qualifiedName ('(' ( elementValuePairs | elementValue )? ')')?
    ;

elementValuePairs
    : elementValuePair (',' elementValuePair)*
    ;

elementValuePair
    : IDENTIFIER '=' elementValue
    ;

elementValue
    : expression
    | annotation
    | elementValueArrayInitializer
    ;

elementValueArrayInitializer
    : '{' (elementValue (',' elementValue)*)? (',')? '}'
    ;

typeParameters
    : '<' typeParameter (',' typeParameter)* '>'
    ;

typeParameter
    : annotation* IDENTIFIER (EXTENDS typeBound)?
    ;

typeBound
    : typeType (AMPERSAND typeType)*
    ;

typeList
    : typeType (',' typeType)*
    ;

formalParameters
    : '(' formalParameterList? ')'
    ;

formalParameterList
    : formalParameter (',' formalParameter)* (',' lastFormalParameter)?
    | lastFormalParameter
    ;

formalParameter
    : variableModifier* typeType variableDeclaratorId
    ;

lastFormalParameter
    : variableModifier* typeType '...' variableDeclaratorId
    ;

variableModifier
    : FINAL
    | annotation
    ;

fieldDeclaration
    : typeType variableDeclarators SEMI
    ;

constructorDeclaration
    : annotation* constructorModifier* IDENTIFIER formalParameters
      (THROWS qualifiedNameList)? constructorBody
    ;

constructorBody
    : '{' explicitConstructorInvocation? blockStatement* '}'
    ;

explicitConstructorInvocation
    : nonWildcardTypeArguments? THIS arguments SEMI
    | nonWildcardTypeArguments? SUPER arguments SEMI
    | expressionName '.' nonWildcardTypeArguments? SUPER arguments SEMI
    ;

// Control flow and expressions
parExpression
    : '(' expression ')'
    ;

forControl
    : enhancedForControl
    | forInit? SEMI expression? SEMI forUpdate?
    ;

forInit
    : localVariableDeclaration
    | expressionList
    ;

enhancedForControl
    : variableModifier* typeType variableDeclaratorId ':' expression
    ;

forUpdate
    : expressionList
    ;

expressionList
    : expression (',' expression)*
    ;

// Expression handling
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
    | LPAREN annotation* typeType (AMPERSAND typeType)* RPAREN expression
    | expression postfix=(INC | DEC)
    | prefix=(ADD | SUB | INC | DEC) expression
    | prefix=(TILDE | BANG) expression
    | expression bop=(MUL | DIV | MOD) expression
    | expression bop=(ADD | SUB) expression
    | expression bop=(LSHIFT | RSHIFT) expression
    | expression bop=(LE | GE | GT | LT) expression
    | expression bop=(EQUAL | NOTEQUAL) expression
    | expression bop=AMPERSAND expression
    | expression bop=CARET expression
    | expression bop=PIPE expression
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

primary
    : '(' expression ')'
    | THIS
    | SUPER
    | literal
    | IDENTIFIER
    | typeTypeOrVoid '.' CLASS
    | nonWildcardTypeArguments (explicitGenericInvocationSuffix | THIS arguments)
    ;

creator
    : nonWildcardTypeArguments? createdName classCreatorRest
    | createdName arrayCreatorRest
    ;

createdName
    : IDENTIFIER typeArgumentsOrDiamond? ('.' IDENTIFIER typeArgumentsOrDiamond?)*
    | primitiveType
    ;

classCreatorRest
    : arguments classBody?
    ;

arrayCreatorRest
    : '[' (']' ('[' ']')* arrayInitializer | expression ']' ('[' expression ']')* ('[' ']')*)
    ;

methodCall
    : IDENTIFIER '(' expressionList? ')'
    | THIS '(' expressionList? ')'
    | SUPER '(' expressionList? ')'
    ;

typeArgumentsOrDiamond
    : '<' '>'
    | typeArguments
    ;

nonWildcardTypeArguments
    : '<' typeList '>'
    ;

arrayDimensions
    : '[' expression? ']'
    ;

quantumModifier
    : QUANTUM
    | REV
    | PURE
    ;

matchBlock
    : '{' matchEntry* '}'
    ;

matchEntry
    : expression ARROW statement
    | DEFAULT ARROW statement
    ;

statementExpression
    : expression
    ;

variableDeclarators
    : variableDeclarator (',' variableDeclarator)*
    ;

variableDeclarator
    : variableDeclaratorId ('=' variableInitializer)?
    ;

variableDeclaratorId
    : IDENTIFIER ('[' ']')*
    ;

variableInitializer
    : arrayInitializer
    | expression
    ;

arrayInitializer
    : '{' (variableInitializer (',' variableInitializer)* (',')?)? '}'
    ;

typeArguments
    : '<' typeArgument (',' typeArgument)* '>'
    ;

typeArgument
    : typeType
    | annotation* QUESTION (EXTENDS | SUPER)? typeType?
    ;

qualifiedName
    : IDENTIFIER ('.' IDENTIFIER)*
    ;

// Method and constructor modifiers
constructorModifier
    : annotation
    | PUBLIC
    | PROTECTED
    | PRIVATE
    ;

interfaceMethodModifier
    : annotation
    | PUBLIC
    | ABSTRACT
    | DEFAULT
    | STATIC
    | QUANTUM
    | REV
    | PURE
    ;

// Class member modifiers
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

// Additional quantum-specific rules
quantumCircuit
    : '{' quantumStatement* '}'
    ;

parameterList
    : '(' parameter (',' parameter)* ')'
    ;

parameter
    : typeType variableDeclaratorId
    ;

quantumGateApplication
    : quantumGate arguments SEMI
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

quantumMeasurement
    : MEASURE qubitExpression (ARROW IDENTIFIER)? SEMI
    ;

qubitExpression
    : IDENTIFIER
    | IDENTIFIER '[' expression ']'
    | qubitExpression TENSOR qubitExpression
    ;

quantumStatePreparation
    : PREPARE qubitExpression stateExpression SEMI
    ;

quantumControlFlow
    : QIF parExpression quantumBlock (ELSE quantumBlock)?
    | QWHILE parExpression quantumBlock UNTIL parExpression
    ;

quantumUncomputation
    : UNCOMPUTE '{' quantumStatement* '}'
    | CLEAN '{' qubitExpression* '}'
    ;

// Exception handling
catchClause
    : CATCH '(' variableModifier* catchType IDENTIFIER ')' block
    ;

catchType
    : qualifiedName (PIPE qualifiedName)*
    ;

finallyBlock
    : FINALLY block
    ;

// Lambda expressions
lambdaExpression
    : lambdaParameters ARROW lambdaBody
    ;

lambdaParameters
    : IDENTIFIER
    | '(' formalParameterList? ')'
    | '(' IDENTIFIER (',' IDENTIFIER)* ')'
    ;

lambdaBody
    : expression
    | block
    ;

// Type system additions
primitiveType
    : BOOLEAN_T
    | BYTE_T
    | SHORT_T
    | INT_T
    | LONG_T
    | FLOAT_T
    | DOUBLE_T
    | CHAR_T
    ;

typeType
    : annotation* (
      classicalType
      | quantumType
      ) (LBRACK RBRACK)*
    ;

classicalType
    : primitiveType
    | IDENTIFIER typeArguments?
    | qualifiedName typeArguments?
    ;

quantumType
    : QUBIT typeArguments?
    | QUREG typeArguments?
    | STATE
    | ORACLE typeArguments?
    ;

typeTypeOrVoid
    : typeType
    | VOID_T
    ;

// Additional utility rules
qualifiedNameList
    : qualifiedName (',' qualifiedName)*
    ;

explicitGenericInvocationSuffix
    : SUPER superSuffix
    | IDENTIFIER arguments
    ;

superSuffix
    : arguments
    | '.' IDENTIFIER arguments?
    ;

arguments
    : '(' expressionList? ')'
    ;

// Local variable handling
localVariableDeclaration
    : variableModifier* typeType variableDeclarators
    ;

// Support for expression names
expressionName
    : IDENTIFIER
    | ambiguousName '.' IDENTIFIER
    ;

ambiguousName
    : IDENTIFIER
    | ambiguousName '.' IDENTIFIER
    ;

// Add literal rule
literal
    : INTEGER_LITERAL
    | FLOAT_LITERAL
    | BOOL_LITERAL
    | CHAR_LITERAL
    | STRING_LITERAL
    | NULL_LITERAL
    | QUBIT_KET
    | STATE_LITERAL
    | MATRIX_LITERAL
    ;

innerCreator
    : IDENTIFIER nonWildcardTypeArgumentsOrDiamond? classCreatorRest
    ;

nonWildcardTypeArgumentsOrDiamond
    : '<' '>'
    | nonWildcardTypeArguments
    ;

variableDeclaration
    : typeType variableDeclarators SEMI
    ;

expressionStatement
    : expression SEMI
    ;

selectionStatement
    : IF parExpression statement (ELSE statement)?
    | SWITCH parExpression '{' switchBlockStatementGroup* switchLabel* '}'
    ;

switchBlockStatementGroup
    : switchLabel+ blockStatement+
    ;

switchLabel
    : CASE constantExpression ':'
    | DEFAULT ':'
    ;

constantExpression
    : expression
    ;

iterationStatement
    : WHILE parExpression statement
    | DO statement WHILE parExpression SEMI
    | FOR '(' forControl ')' statement
    ;

jumpStatement
    : BREAK IDENTIFIER? SEMI
    | CONTINUE IDENTIFIER? SEMI
    | RETURN expression? SEMI
    | THROW expression SEMI
    ;