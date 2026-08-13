package com.typeobject.wheeler.runtime.quantum;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.ConditionalGateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.MeasureOperation;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.PrepareOperation;
import com.typeobject.wheeler.core.quantum.ResetOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import java.time.Duration;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Conformance tests for the bounded ideal state-vector target contract. */
class StateVectorTargetTest {
  @Test
  void targetIdentityAndMissingCapabilityDiagnosticsAreCanonical() {
    TargetDescriptor first = new TargetDescriptor(
        "adapter",
        "target",
        new LinkedHashSet<>(List.of(
            TargetCapability.BATCH_SUBMISSION, TargetCapability.STATIC_CIRCUIT)),
        8,
        100);
    TargetDescriptor second = new TargetDescriptor(
        "adapter",
        "target",
        new LinkedHashSet<>(List.of(
            TargetCapability.STATIC_CIRCUIT, TargetCapability.BATCH_SUBMISSION)),
        8,
        100);

    assertEquals(first.identity(), second.identity());
    QuantumExecutionException exception = assertThrows(
        QuantumExecutionException.class,
        () -> first.require(Set.of(
            TargetCapability.RESET, TargetCapability.MID_CIRCUIT_MEASUREMENT)));
    assertTrue(exception.getMessage().contains("MID_CIRCUIT_MEASUREMENT, RESET"));
  }

  @Test
  void staticTargetRejectsTargetResidentSurfaceCodeRequirements() {
    StateVectorTarget target = new StateVectorTarget();
    Set<TargetCapability> required = Set.of(
        TargetCapability.MID_CIRCUIT_MEASUREMENT,
        TargetCapability.RESET,
        TargetCapability.CLASSICAL_CONDITIONAL);

    QuantumExecutionException failure = assertThrows(
        QuantumExecutionException.class,
        () -> target.descriptor().require(required));

    assertTrue(failure.getMessage().contains(
        "CLASSICAL_CONDITIONAL, MID_CIRCUIT_MEASUREMENT, RESET"));
  }

  @Test
  void staticTargetRejectsDynamicSubmissionBeforeAllocatingAJobIdentity() {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "dynamic",
        0,
        List.of(
            new PrepareOperation(0),
            new MeasureOperation(0, 0),
            new ResetOperation(0),
            new ConditionalGateOperation(0, true, GateOperation.of(Gate.X, 0))));
    QuantumSubmission submission = new QuantumSubmission(
        program(register, circuit, List.of()),
        0,
        0,
        List.of(new CircuitApplication(0, false)),
        Map.of(),
        1,
        0);

    QuantumExecutionException failure = assertThrows(
        QuantumExecutionException.class, () -> new StateVectorTarget().submit(submission));

    assertTrue(failure.getMessage().contains(
        "CLASSICAL_CONDITIONAL, MID_CIRCUIT_MEASUREMENT, RESET"));
  }

  @Test
  void targetRejectsQubitAndShotLimitsBeforeAllocatingAJobIdentity() {
    QuantumRegister wideRegister = new QuantumRegister(
        0, "wide", StateVectorTarget.MAX_QUBITS + 1);
    QuantumCircuit wideCircuit = new QuantumCircuit(0, "wide", 0, List.of());
    Program wideProgram = program(wideRegister, wideCircuit, List.of());
    StateVectorTarget target = new StateVectorTarget();

    QuantumExecutionException qubits = assertThrows(
        QuantumExecutionException.class,
        () -> target.submit(new QuantumSubmission(
            wideProgram,
            0,
            0,
            List.of(new CircuitApplication(0, false)),
            Map.of(),
            1,
            0)));

    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(0, "idle", 0, List.of());
    Program program = program(register, circuit, List.of());
    QuantumExecutionException shots = assertThrows(
        QuantumExecutionException.class,
        () -> target.submit(new QuantumSubmission(
            program,
            0,
            0,
            List.of(new CircuitApplication(0, false)),
            Map.of(),
            target.descriptor().maxShots() + 1,
            0)));

    assertTrue(qubits.getMessage().contains("qubit limit"));
    assertTrue(shots.getMessage().contains("shot limit"));
  }

  @Test
  void classicalOperationSelectionChangesSubmissionIdentity() {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit idle = new QuantumCircuit(0, "idle", 0, List.of());
    QuantumCircuit flip = new QuantumCircuit(
        1, "flip", 0, List.of(GateOperation.of(Gate.X, 0)));
    Program program = program(register, idle, List.of(), flip);

    QuantumSubmission selectedIdle = new QuantumSubmission(
        program,
        0,
        0,
        List.of(new CircuitApplication(0, false)),
        Map.of(),
        1,
        0);
    QuantumSubmission selectedFlip = new QuantumSubmission(
        program,
        0,
        0,
        List.of(new CircuitApplication(1, false)),
        Map.of(),
        1,
        0);

    assertNotEquals(selectedIdle.identity(), selectedFlip.identity());
  }

  @Test
  void gateAndGeneratedAdjointRestoreState() {
    QuantumRegister register = new QuantumRegister(0, "q", 2);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "bell",
        0,
        List.of(GateOperation.of(Gate.H, 0), GateOperation.of(Gate.CNOT, 0, 1)));
    Program program = program(register, circuit, List.of());
    StateVectorEngine simulator = new StateVectorEngine(1);

    simulator.prepare(register, 0);
    simulator.apply(program, circuit, false);
    assertArrayEquals(new double[] {0.5, 0, 0, 0.5}, simulator.probabilities(register), 1e-12);
    simulator.apply(program, circuit, true);

    assertArrayEquals(new double[] {1, 0, 0, 0}, simulator.probabilities(register), 1e-12);
  }

  @Test
  void exactAmplitudesTrackPhaseAndGeneratedAdjointCleansAncilla() {
    QuantumRegister register = new QuantumRegister(0, "q", 2);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "phaseAncilla",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            new GateOperation(Gate.PHASE, List.of(0), Math.PI / 2),
            GateOperation.of(Gate.CNOT, 0, 1)));
    Program program = program(register, circuit, List.of());
    StateVectorEngine simulator = new StateVectorEngine(1);

    simulator.prepare(register, 0);
    simulator.apply(program, circuit, false);
    assertArrayEquals(
        new double[] {1 / Math.sqrt(2), 0, 0, 0, 0, 0, 0, 1 / Math.sqrt(2)},
        simulator.amplitudes(register),
        1e-12);
    simulator.apply(program, circuit, true);

    assertArrayEquals(
        new double[] {1, 0, 0, 0, 0, 0, 0, 0},
        simulator.amplitudes(register),
        1e-12);
  }

  @Test
  void openQasmLoweringIsPortableAndDeterministic() {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(0, "flip", 0, List.of(GateOperation.of(Gate.X, 0)));
    Program program = program(register, circuit, List.of());
    QuantumSubmission submission = new QuantumSubmission(
        program, 0, 0, List.of(new CircuitApplication(0, false)), Map.of(), 1, 0);

    String qasm = new OpenQasm3Emitter().emit(submission);

    assertEquals("""
        OPENQASM 3.0;
        include "stdgates.inc";
        bit[1] c;
        qubit[1] q;
        x q[0];
        c = measure q;
        """, qasm);
  }

  @Test
  void targetSubmitsACompleteAsynchronousTask() {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(0, "flip", 0, List.of(GateOperation.of(Gate.X, 0)));
    Program program = program(register, circuit, List.of());
    QuantumSubmission submission = new QuantumSubmission(
        program, 0, 0, List.of(new CircuitApplication(0, false)), Map.of(), 4, 9);

    StateVectorTarget target = new StateVectorTarget();
    QuantumJob job = target.submit(submission);
    QuantumResult result = job.await(Duration.ofSeconds(1));

    assertEquals(JobState.SUCCEEDED, job.state());
    assertEquals(submission.identity(), result.submissionIdentity());
    assertEquals(List.of(1L, 1L, 1L, 1L), result.outcomes());
    assertEquals(4L, result.counts().get(1L));
    assertEquals(job.id(), target.recover(job.id(), submission).id());
    QuantumSubmission mismatched = new QuantumSubmission(
        program, 0, 0, List.of(new CircuitApplication(0, false)), Map.of(), 4, 10);
    assertThrows(QuantumExecutionException.class, () -> target.recover(job.id(), mismatched));
  }

  @Test
  void resultByteLimitRejectsOversizedProviderMaterial() {
    List<Long> oversized = java.util.Collections.nCopies(1_048_575, 0L);

    assertThrows(
        IllegalArgumentException.class,
        () -> new QuantumResult(
            "job",
            "submission",
            oversized,
            Map.of(0L, (long) oversized.size()),
            "target"));
  }

  @Test
  void coherentLiftPreservesSuperpositionWithoutMeasurement() {
    FunctionBody flip = new FunctionBody(
        1,
        "flip",
        true,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.XOR_CONST, 0, 1), Instruction.of(Opcode.RETURN)),
        List.of(Instruction.of(Opcode.XOR_CONST, 0, 1), Instruction.of(Opcode.RETURN)));
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "coherent",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            new LiftedCall(1, false),
            GateOperation.of(Gate.H, 0)));
    Program program = program(register, circuit, List.of(flip));
    StateVectorEngine simulator = new StateVectorEngine(2);

    simulator.prepare(register, 0);
    simulator.apply(program, circuit, false);

    assertArrayEquals(new double[] {1, 0}, simulator.probabilities(register), 1e-12);
  }

  @Test
  void symbolicParameterBindingSurvivesBytecodeAndChangesBatchResult() {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "phaseInterference",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            new ParameterizedGateOperation(Gate.PHASE, List.of(0), "theta", 1),
            GateOperation.of(Gate.H, 0)));
    Program source = program(register, circuit, List.of());
    byte[] artifact = new BytecodeWriter().write(source);
    Program program = new BytecodeReader().read(artifact);
    assertArrayEquals(artifact, new BytecodeWriter().write(program));
    QuantumSubmission zero = new QuantumSubmission(
        program,
        0,
        0,
        List.of(new CircuitApplication(0, false)),
        Map.of("theta", 0.0),
        8,
        3);
    QuantumSubmission pi = new QuantumSubmission(
        program,
        0,
        0,
        List.of(new CircuitApplication(0, false)),
        Map.of("theta", Math.PI),
        8,
        4);
    assertThrows(
        IllegalArgumentException.class,
        () -> new QuantumSubmission(
            program,
            0,
            0,
            List.of(new CircuitApplication(0, false)),
            Map.of(),
            1,
            0));

    QuantumBatchResult result = new StateVectorTarget()
        .submitBatch(new QuantumBatch(List.of(zero, pi)))
        .await(Duration.ofSeconds(1));

    assertEquals(List.of(0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L), result.results().get(0).outcomes());
    assertEquals(List.of(1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L), result.results().get(1).outcomes());
    assertEquals(1.0, result.results().get(0).zExpectation(0).value());
    assertEquals(-1.0, result.results().get(1).zExpectation(0).value());
  }

  @Test
  void orderedBatchPreservesTaskIdentityAndExpectationOrder() {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0, "flip", 0, List.of(GateOperation.of(Gate.X, 0)));
    Program program = program(register, circuit, List.of());
    QuantumSubmission first = new QuantumSubmission(
        program, 0, 0, List.of(new CircuitApplication(0, false)), Map.of(), 8, 3);
    QuantumSubmission second = new QuantumSubmission(
        program, 0, 1, List.of(new CircuitApplication(0, false)), Map.of(), 8, 4);
    QuantumBatch batch = new QuantumBatch(List.of(first, second));
    StateVectorTarget target = new StateVectorTarget();

    QuantumBatchJob job = target.submitBatch(batch);
    QuantumBatchResult result = job.await(Duration.ofSeconds(1));

    assertEquals(JobState.SUCCEEDED, job.state());
    assertEquals(batch.identity(), result.batchIdentity());
    assertEquals(List.of(first.identity(), second.identity()), result.results().stream()
        .map(QuantumResult::submissionIdentity)
        .toList());
    assertEquals(-1.0, result.results().get(0).zExpectation(0).value());
    assertEquals(1.0, result.results().get(1).zExpectation(0).value());
    assertEquals(0.0, result.results().get(0).zExpectation(0).standardError());
    assertNotEquals(batch.identity(), new QuantumBatch(List.of(second, first)).identity());
  }

  @Test
  void coherentlyLiftedXorMatchesClassicalPermutation() {
    FunctionBody flip = new FunctionBody(
        1,
        "flip",
        true,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.XOR_CONST, 0, 1), Instruction.of(Opcode.RETURN)),
        List.of(Instruction.of(Opcode.XOR_CONST, 0, 1), Instruction.of(Opcode.RETURN)));
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(0, "oracle", 0, List.of(new LiftedCall(1, false)));
    Program program = program(register, circuit, List.of(flip));
    StateVectorEngine simulator = new StateVectorEngine(2);

    simulator.prepare(register, 0);
    simulator.apply(program, circuit, false);
    assertEquals(1, simulator.measure(register));
  }

  static Program program(
      QuantumRegister register, QuantumCircuit circuit, List<FunctionBody> additionalFunctions) {
    return program(register, circuit, additionalFunctions, new QuantumCircuit[0]);
  }

  static Program program(
      QuantumRegister register,
      QuantumCircuit circuit,
      List<FunctionBody> additionalFunctions,
      QuantumCircuit... additionalCircuits) {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.HALT)),
        List.of());
    List<FunctionBody> functions = new java.util.ArrayList<>();
    functions.add(main);
    functions.addAll(additionalFunctions);
    List<QuantumCircuit> circuits = new java.util.ArrayList<>();
    circuits.add(circuit);
    circuits.addAll(List.of(additionalCircuits));
    return new Program(
        "QuantumTest",
        ProgramKind.QUANTUM,
        0,
        List.of(new Global("result", 0)),
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        functions,
        List.of(),
        List.of(register),
        circuits,
        List.of(com.typeobject.wheeler.core.workflow.WorkflowStep.halt()),
        Program.DEFAULT_MAX_HISTORY,
        Program.DEFAULT_MAX_STEPS);
  }
}
