package com.typeobject.wheeler.runtime.quantum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.quantum.ConditionalGateOperation;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.MeasureOperation;
import com.typeobject.wheeler.core.quantum.PrepareOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.quantum.ResetOperation;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Conformance evidence for bounded target-resident dynamic control. */
final class DynamicStateVectorSimulatorTest {
  @Test
  void executesCanonicalMeasurementResetAndConditionalInstructionForms() {
    QuantumRegister register = new QuantumRegister(0, "dynamic", 2);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "correct",
        0,
        List.of(
            new PrepareOperation(3),
            new MeasureOperation(1, 0),
            new ConditionalGateOperation(0, true, GateOperation.of(Gate.X, 0)),
            new ResetOperation(1),
            new MeasureOperation(1, 1)));
    Program program = program(register, circuit);

    DynamicCircuitResult result = new DynamicStateVectorSimulator().execute(program, circuit, 0);

    assertEquals(0, result.basisState());
    assertEquals(java.util.Map.of(0, true, 1, false), result.resultSlots());
  }

  @Test
  void staticHostSplitAndDynamicPlansAgreeOnAnIdealBasisResult() {
    QuantumRegister register = new QuantumRegister(0, "plan", 1);
    QuantumCircuit dynamicCircuit = new QuantumCircuit(
        0,
        "dynamic",
        0,
        List.of(
            new PrepareOperation(1),
            new MeasureOperation(0, 0),
            new ConditionalGateOperation(0, true, GateOperation.of(Gate.X, 0))));
    Program dynamicProgram = program(register, dynamicCircuit);
    DynamicCircuitResult dynamic = new DynamicStateVectorSimulator()
        .execute(dynamicProgram, dynamicCircuit, 0);

    StateVectorEngine staticEngine = new StateVectorEngine(0);
    staticEngine.prepare(register, 1);
    staticEngine.applyGate(register, GateOperation.of(Gate.X, 0));
    long staticResult = staticEngine.measure(register);

    StateVectorEngine splitEngine = new StateVectorEngine(0);
    splitEngine.prepare(register, 1);
    boolean observed = splitEngine.measureQubit(register, 0);
    if (observed) {
      splitEngine.applyGate(register, GateOperation.of(Gate.X, 0));
    }
    long hostSplitResult = splitEngine.measure(register);

    assertEquals(0, staticResult);
    assertEquals(staticResult, hostSplitResult);
    assertEquals(staticResult, dynamic.basisState());
  }

  @Test
  void dynamicTeleportationTransfersBothBasisInputsWithoutHostSplit() {
    DynamicStateVectorSimulator simulator = new DynamicStateVectorSimulator();
    for (boolean input : List.of(false, true)) {
      DynamicTeleportationFixture fixture = new DynamicTeleportationFixture(input);
      QuantumRegister register = new QuantumRegister(
          DynamicTeleportationFixture.REGISTER_ID,
          "teleportation",
          DynamicTeleportationFixture.QUBITS);
      QuantumCircuit circuit = fixture.circuit();
      Program source = program(register, circuit);
      byte[] artifact = new com.typeobject.wheeler.core.bytecode.BytecodeWriter().write(source);
      Program program = new com.typeobject.wheeler.core.bytecode.BytecodeReader().read(artifact);
      assertTrue(java.util.Arrays.equals(
          artifact, new com.typeobject.wheeler.core.bytecode.BytecodeWriter().write(program)));
      QuantumCircuit decodedCircuit = program.quantumCircuit(circuit.id());
      DynamicCircuitResult result = simulator.execute(
          program, decodedCircuit, input ? 1 : 0);

      assertEquals(input, fixture.target(result));
      assertEquals(2, result.resultSlots().size());
    }
  }

  @Test
  void syndromeMeasurementConditionallyCorrectsAndResetsWithoutHostSplit() {
    DynamicStateVectorSimulator simulator = new DynamicStateVectorSimulator();
    DynamicSyndromeResult result = simulator.execute(
        new DynamicSyndromeFixture(true, true, 3));

    assertTrue(result.logicalBit());
    assertTrue(result.correctedDataBit());
    assertEquals(List.of(true, false, false), result.syndromes());
    assertEquals(List.of(false, false, false), result.resetAncillas());
    assertEquals(1, result.conditionalCorrections());
    assertTrue(simulator.descriptor().capabilities().containsAll(Set.of(
        TargetCapability.MID_CIRCUIT_MEASUREMENT,
        TargetCapability.RESET,
        TargetCapability.CLASSICAL_CONDITIONAL)));
  }

  @Test
  void staticOpenQasmLoweringRejectsDynamicInstructionFamilies() {
    QuantumRegister register = new QuantumRegister(0, "dynamic", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0, "dynamic", 0, List.of(new PrepareOperation(0)));
    Program program = program(register, circuit);
    QuantumSubmission submission = new QuantumSubmission(
        program,
        0,
        0,
        List.of(new CircuitApplication(0, false)),
        java.util.Map.of(),
        1,
        0);

    QuantumExecutionException exception = assertThrows(
        QuantumExecutionException.class,
        () -> new OpenQasm3Emitter().emit(submission));

    assertTrue(exception.getMessage().contains("cannot represent PrepareOperation"));
  }

  @Test
  void rejectsDynamicOperationsBeforePreparation() {
    QuantumRegister register = new QuantumRegister(0, "dynamic", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0, "bad", 0, List.of(new MeasureOperation(0, 0)));

    QuantumExecutionException exception = assertThrows(
        QuantumExecutionException.class,
        () -> new DynamicStateVectorSimulator().execute(program(register, circuit), circuit, 0));

    assertTrue(exception.getMessage().contains("precedes register preparation"));
  }

  @Test
  void cleanStateProducesNoCorrectionAndBoundsRejectBeforeExecution() {
    DynamicStateVectorSimulator simulator = new DynamicStateVectorSimulator();
    DynamicSyndromeResult result = simulator.execute(
        new DynamicSyndromeFixture(false, false, 2));

    assertFalse(result.correctedDataBit());
    assertEquals(List.of(false, false), result.syndromes());
    assertEquals(0, result.conditionalCorrections());
    assertThrows(
        IllegalArgumentException.class,
        () -> new DynamicSyndromeFixture(false, false, 0));
    assertThrows(
        IllegalArgumentException.class,
        () -> new DynamicSyndromeFixture(
            false, false, DynamicSyndromeFixture.MAX_ROUNDS + 1));
  }

  private static Program program(QuantumRegister register, QuantumCircuit circuit) {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.HALT)),
        List.of());
    return new Program(
        "dynamic",
        ProgramKind.QUANTUM,
        0,
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        List.of(main),
        List.of(),
        List.of(register),
        List.of(circuit),
        List.of(WorkflowStep.halt()),
        Program.DEFAULT_MAX_HISTORY,
        Program.DEFAULT_MAX_STEPS);
  }
}
