# Overview of Grammar

```
grammar/
├── WheelerLexer.g4               # Main lexer combining all token definitions
├── WheelerParser.g4              # Main parser combining all grammar rules
│
├── lexer/
│   ├── keywords/
│   │   ├── BasicKeywords.g4      # Basic programming keywords (if, while, for...)
│   │   ├── ModifierKeywords.g4   # Access and state modifiers (public, static...)
│   │   ├── TypeKeywords.g4       # Type-related keywords (class, interface...)
│   │   ├── QuantumKeywords.g4    # Quantum-specific keywords (qubit, measure...)
│   │   └── ProofKeywords.g4      # Proof system keywords (theorem, verify...)
│   │
│   ├── operators/
│   │   ├── ArithmeticOps.g4      # Arithmetic operators (+, -, *, /)
│   │   ├── LogicalOps.g4         # Logical operators (&&, ||, !)
│   │   ├── BitwiseOps.g4         # Bitwise operators (&, |, ^)
│   │   ├── ComparisonOps.g4      # Comparison operators (==, !=, <, >)
│   │   ├── AssignmentOps.g4      # Assignment operators (=, +=, -=)
│   │   ├── QuantumOps.g4         # Quantum operators (⊗, †)
│   │   └── Separators.g4         # Separators ({}, (), [], ;)
│   │
│   ├── literals/
│   │   ├── NumericLiterals.g4    # Integer and floating-point literals
│   │   ├── StringLiterals.g4     # String and character literals
│   │   ├── BooleanLiterals.g4    # Boolean literals
│   │   ├── QuantumLiterals.g4    # Quantum state literals (|0⟩, |1⟩)
│   │   └── ComplexLiterals.g4    # Complex number literals
│   │
│   ├── types/
│   │   ├── PrimitiveTypes.g4     # Primitive type tokens (int, boolean...)
│   │   ├── ContainerTypes.g4     # Container type tokens (array, list...)
│   │   ├── QuantumTypes.g4       # Quantum type tokens (qubit, qureg...)
│   │   └── ModifierTypes.g4      # Type modifier tokens (final, const...)
│   │
│   └── formatting/
│       ├── Whitespace.g4         # Whitespace handling rules
│       └── Comments.g4           # Comment handling rules
│
└── parser/
    ├── structure/
    │   ├── CompilationUnit.g4    # Top-level program structure
    │   ├── PackageDecl.g4        # Package declaration rules
    │   ├── ImportDecl.g4         # Import statement rules
    │   └── ModuleDecl.g4         # Module system rules
    │
    ├── declarations/
    │   ├── ClassDecl.g4          # Class declaration rules
    │   ├── InterfaceDecl.g4      # Interface declaration rules
    │   ├── EnumDecl.g4           # Enum declaration rules
    │   └── AnnotationDecl.g4     # Annotation declaration rules
    │
    ├── members/
    │   ├── MethodDecl.g4         # Method declaration rules
    │   ├── FieldDecl.g4          # Field declaration rules
    │   ├── ConstructorDecl.g4    # Constructor declaration rules
    │   └── PropertyDecl.g4       # Property declaration rules
    │
    ├── statements/
    │   ├── BasicStmt.g4          # Basic statement rules
    │   ├── ControlFlow.g4        # Control flow statement rules
    │   ├── ExceptionHandling.g4  # Exception handling rules
    │   └── Transactions.g4       # Transaction handling rules
    │
    ├── expressions/
    │   ├── PrimaryExpr.g4        # Primary expression rules
    │   ├── OperatorExpr.g4       # Operator expression rules
    │   ├── MethodCall.g4         # Method call rules
    │   ├── ObjectCreation.g4     # Object creation rules
    │   └── LambdaExpr.g4         # Lambda expression rules
    │
    ├── types/
    │   ├── TypeSystem.g4         # Basic type system rules
    │   ├── Generics.g4           # Generic type handling
    │   ├── TypeBounds.g4         # Type bound rules
    │   └── TypeInference.g4      # Type inference rules
    │
    ├── quantum/
    │   ├── CircuitDecl.g4        # Quantum circuit declarations
    │   ├── GateApplication.g4    # Gate application rules
    │   ├── Measurement.g4        # Measurement rules
    │   ├── StatePrep.g4          # State preparation rules
    │   └── QuantumControl.g4     # Quantum control flow rules
    │
    └── proofs/
        ├── TheoremDecl.g4        # Theorem declaration rules
        ├── ProofStructure.g4     # Proof structure rules
        ├── VerificationStmt.g4   # Verification statement rules
        └── ProofSteps.g4         # Proof step rules
```