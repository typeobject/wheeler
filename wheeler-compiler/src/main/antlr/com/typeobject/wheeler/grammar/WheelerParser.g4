parser grammar WheelerParser;

options { tokenVocab=WheelerLexer; }

// Program structure
import CompilationUnit;     // Top-level structure
import PackageDecl;         // Package declarations
import ImportDecl;          // Import statements
import ModuleDecl;          // Module system

// Declarations
import ClassDecl;          // Class declarations
import InterfaceDecl;      // Interface declarations
import EnumDecl;           // Enum declarations
import AnnotationDecl;     // Annotation declarations

// Class members
import MethodDecl;         // Method declarations
import FieldDecl;          // Field declarations
import ConstructorDecl;    // Constructor declarations
import PropertyDecl;       // Property declarations

// Statements
import BasicStmt;          // Basic statements
import ControlFlow;        // Control flow
import ExceptionHandling;  // Exception handling
import Transactions;       // Transaction handling

// Expressions
import PrimaryExpr;        // Primary expressions
import OperatorExpr;       // Operator expressions
import MethodCall;         // Method calls
import ObjectCreation;     // Object creation
import LambdaExpr;        // Lambda expressions

// Type system
import TypeSystem;         // Type system core
import Generics;          // Generics handling
import TypeBounds;        // Type bounds
import TypeInference;     // Type inference

// Quantum features
import CircuitDecl;       // Circuit declarations
import GateApplication;   // Gate applications
import Measurement;       // Measurements
import StatePrep;        // State preparation
import QuantumControl;    // Quantum control flow

// Proof system
import TheoremDecl;      // Theorem declarations
import ProofStructure;    // Proof structure
import VerificationStmt;  // Verification statements
import ProofSteps;       // Proof steps