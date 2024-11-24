package com.typeobject.wheeler.compiler.ast;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.*;

@DisplayName("AST Construction and Validation")
class ASTTest {
  private Position testPos;
  private ASTBuilder builder;

  @BeforeEach
  void setUp() {
    testPos = new Position("Test.wheel", 1, 1);
    builder = new ASTBuilder();
  }

  @Nested
  @DisplayName("Classical AST Tests")
  class ClassicalASTTests {
    @Test
    @DisplayName("Should create a simple class declaration")
    void testClassDeclaration() {
      ClassDeclaration classDecl =
          builder
              .classDeclaration("MyClass")
              .addModifier(Modifier.PUBLIC)
              .setComputationType(ComputationType.CLASSICAL)
              .build();

      assertAll(
          () -> assertEquals("MyClass", classDecl.getName()),
          () -> assertTrue(classDecl.getModifiers().contains(Modifier.PUBLIC)),
          () -> assertEquals(ComputationType.CLASSICAL, classDecl.getComputationType()));
    }

    @Test
    @DisplayName("Should create a method with parameters")
    void testMethodDeclaration() {
      List<Parameter> params =
          List.of(
              new Parameter(new ClassicalType("int"), "x", false),
              new Parameter(new ClassicalType("String"), "y", false));

      MethodDeclaration method =
          builder
              .methodDeclaration("calculate")
              .addModifier(Modifier.PUBLIC)
              .setReturnType(new ClassicalType("int"))
              .setParameters(params)
              .build();

      assertAll(
          () -> assertEquals("calculate", method.getName()),
          () -> assertEquals(2, method.getParameters().size()),
          () -> assertEquals("int", method.getReturnType().getName()));
    }
  }

  @Nested
  @DisplayName("Quantum AST Tests")
  class QuantumASTTests {
    @Test
    @DisplayName("Should create a quantum register declaration")
    void testQuantumRegisterDeclaration() {
      QuantumRegisterDeclaration qreg =
          new QuantumRegisterDeclaration.Builder(testPos).setName("qbits").setSize(4).build();

      assertAll(
          () -> assertEquals("qbits", qreg.getName()),
          () -> assertEquals(4, qreg.getSize()),
          () -> assertTrue(qreg.getType().isQuantum()));
    }

    @Test
    @DisplayName("Should create a quantum gate sequence")
    void testQuantumCircuit() {
      QuantumBlock circuit =
          new QuantumBlock.Builder(testPos)
              .addStatement(
                  new QuantumGateApplication.Builder(testPos)
                      .setGate(StandardGate.HADAMARD)
                      .addTarget(new QubitReference("q", 0))
                      .build())
              .addStatement(
                  new QuantumGateApplication.Builder(testPos)
                      .setGate(StandardGate.CNOT)
                      .addTarget(new QubitReference("q", 0))
                      .addTarget(new QubitReference("q", 1))
                      .build())
              .build();

      assertAll(
          () -> assertEquals(2, circuit.getStatements().size()),
          () -> assertTrue(circuit.getStatements().get(0) instanceof QuantumGateApplication),
          () -> assertTrue(circuit.getStatements().get(1) instanceof QuantumGateApplication));
    }
  }

  @Nested
  @DisplayName("Hybrid AST Tests")
  class HybridASTTests {
    @Test
    @DisplayName("Should create a hybrid method with quantum and classical parts")
    void testHybridMethod() {
      HybridMethodDeclaration method =
          new HybridMethodDeclaration.Builder(testPos)
              .setName("quantumAlgorithm")
              .addClassicalParameter(new Parameter(new ClassicalType("int"), "shots", false))
              .addQuantumParameter(
                  new Parameter(new QuantumType(QuantumTypeKind.QUREG), "register", false))
              .setBody(
                  new HybridBlock.Builder(testPos)
                      .addClassicalStatement(
                          new VariableDeclaration("result", new ClassicalType("int")))
                      .addQuantumStatement(
                          new QuantumMeasurement(
                              new QubitReference("register", 0), new VariableReference("result")))
                      .build())
              .build();

      assertAll(
          () -> assertEquals("quantumAlgorithm", method.getName()),
          () -> assertEquals(2, method.getParameters().size()),
          () -> assertTrue(method.getBody() instanceof HybridBlock),
          () -> assertEquals(2, ((HybridBlock) method.getBody()).getStatements().size()));
    }
  }

  @Nested
  @DisplayName("Memory Management AST Tests")
  class MemoryManagementTests {
    @Test
    @DisplayName("Should create uncompute block")
    void testUncomputeBlock() {
      UncomputeBlock block =
          new UncomputeBlock.Builder(testPos)
              .addStatement(
                  new QuantumGateApplication.Builder(testPos)
                      .setGate(StandardGate.HADAMARD)
                      .addTarget(new QubitReference("ancilla", 0))
                      .build())
              .build();

      assertAll(
          () -> assertNotNull(block.getStatements()),
          () -> assertEquals(1, block.getStatements().size()),
          () -> assertTrue(block.getStatements().get(0) instanceof QuantumGateApplication));
    }
  }

  @Nested
  @DisplayName("AST Visitor Tests")
  class VisitorTests {
    @Test
    @DisplayName("Should traverse quantum circuit with type checking")
    void testTypeChecking() {
      // Create a simple quantum circuit
      QuantumBlock circuit =
          new QuantumBlock.Builder(testPos)
              .addStatement(
                  new QuantumGateApplication.Builder(testPos)
                      .setGate(StandardGate.HADAMARD)
                      .addTarget(new QubitReference("q", 0))
                      .build())
              .build();

      // Type check the circuit
      TypeCheckingVisitor visitor = new TypeCheckingVisitor();
      Type type = circuit.accept(visitor);

      assertAll(() -> assertNotNull(type), () -> assertTrue(visitor.getErrors().isEmpty()));
    }
  }

  @Nested
  @DisplayName("AST Validation Tests")
  class ValidationTests {
    @Test
    @DisplayName("Should validate quantum gate arity")
    void testGateArityValidation() {
      QuantumGateApplication invalidGate =
          new QuantumGateApplication.Builder(testPos)
              .setGate(StandardGate.CNOT) // CNOT requires 2 qubits
              .addTarget(new QubitReference("q", 0)) // But only providing 1
              .build();

      TypeCheckingVisitor visitor = new TypeCheckingVisitor();
      assertThrows(ValidationException.class, () -> invalidGate.accept(visitor));
    }

    @Test
    @DisplayName("Should validate hybrid computation boundaries")
    void testHybridBoundaryValidation() {
      HybridBlock block =
          new HybridBlock.Builder(testPos)
              .addClassicalStatement(new VariableDeclaration("x", new ClassicalType("int")))
              .addQuantumStatement(
                  new QuantumMeasurement(new QubitReference("q", 0), new VariableReference("x")))
              .build();

      HybridValidationVisitor visitor = new HybridValidationVisitor();
      assertDoesNotThrow(() -> block.accept(visitor));
    }
  }
}
