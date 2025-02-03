parser grammar WheelerParser;

options { tokenVocab=WheelerLexer; }

import
   // Program structure
   RulesStructureCompilationUnit,    // Top-level structure
   RulesStructurePackageDecl,        // Package declarations
   RulesStructureImportDecl,         // Import statements
   RulesStructureModuleDecl,         // Module system

   // Declarations
   RulesDeclarationsClassDecl,          // Class declarations
   RulesDeclarationsInterfaceDecl,      // Interface declarations
   RulesDeclarationsEnumDecl,           // Enum declarations
   RulesDeclarationsAnnotationDecl,     // Annotation declarations

   // Class members
   RulesMembersMethodDecl,         // Method declarations
   RulesMembersFieldDecl,          // Field declarations
   RulesMembersConstructorDecl,    // Constructor declarations
   RulesMembersPropertyDecl,       // Property declarations

   // Statements
   RulesStatementsBasicStmt,          // Basic statements
   RulesStatementsControlFlow,        // Control flow
   RulesStatementsExceptionHandling,  // Exception handling
   RulesStatementsTransactions,       // Transaction handling

   // Expressions
   RulesExpressionsPrimaryExpr,        // Primary expressions
   RulesExpressionsOperatorExpr,       // Operator expressions
   RulesExpressionsMethodCall,         // Method calls
   RulesExpressionsObjectCreation,     // Object creation
   RulesExpressionsLambdaExpr,         // Lambda expressions

   // Type system
   RulesTypesTypeSystem,         // Type system core
   RulesTypesGenerics,           // Generics handling
   RulesTypesTypeBounds,         // Type bounds
   RulesTypesTypeInference,      // Type inference

   // Quantum features
   RulesQuantumCircuitDecl,        // Circuit declarations
   RulesQuantumGateApplication,    // Gate applications
   RulesQuantumMeasurement,        // Measurements
   RulesQuantumStatePrep,          // State preparation
   RulesQuantumQuantumControl,     // Quantum control flow

   // Proof system
   RulesProofsTheoremDecl,        // Theorem declarations
   RulesProofsProofStructure,     // Proof structure
   RulesProofsVerificationStmt,   // Verification statements
   RulesProofsProofSteps;         // Proof steps