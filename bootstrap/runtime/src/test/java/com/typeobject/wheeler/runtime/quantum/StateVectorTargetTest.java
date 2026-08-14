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
  void batchPreflightRejectsDynamicMemberBeforeSubmittingAnyMember() {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit idle = new QuantumCircuit(0, "idle", 0, List.of());
    QuantumCircuit dynamic = new QuantumCircuit(
        1, "dynamic", 0, List.of(new PrepareOperation(0), new MeasureOperation(0, 0)));
    Program program = program(register, idle, List.of(), dynamic);
    QuantumSubmission staticSubmission = new QuantumSubmission(
        program, 0, 0, List.of(new CircuitApplication(0, false)), Map.of(), 1, 0);
    QuantumSubmission dynamicSubmission = new QuantumSubmission(
        program, 0, 0, List.of(new CircuitApplication(1, false)), Map.of(), 1, 0);
    StateVectorTarget target = new StateVectorTarget();

    QuantumExecutionException failure = assertThrows(
        QuantumExecutionException.class,
        () -> target.submitBatch(new QuantumBatch(List.of(staticSubmission, dynamicSubmission))));

    assertTrue(failure.getMessage().contains("MID_CIRCUIT_MEASUREMENT"));
    assertThrows(
        QuantumExecutionException.class,
        () -> target.recover("state-vector-1", staticSubmission));
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
  void submissionRejectsMismatchedRegisterBasisAndDynamicInverse() {
    QuantumRegister first = new QuantumRegister(0, "first", 1);
    QuantumRegister second = new QuantumRegister(1, "second", 1);
    QuantumCircuit dynamic = new QuantumCircuit(
        0, "dynamic", 1, List.of(new PrepareOperation(0), new MeasureOperation(0, 0)));
    Program program = program(List.of(first, second), dynamic);

    assertThrows(
        IllegalArgumentException.class,
        () -> new QuantumSubmission(
            program, 0, 0, List.of(new CircuitApplication(0, false)), Map.of(), 1, 0));
    assertThrows(
        IllegalArgumentException.class,
        () -> new QuantumSubmission(
            program, 1, 2, List.of(new CircuitApplication(0, false)), Map.of(), 1, 0));
    assertThrows(
        IllegalArgumentException.class,
        () -> new QuantumSubmission(
            program, 1, 0, List.of(new CircuitApplication(0, true)), Map.of(), 1, 0));
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
  void coinedWalkCompositionHasExactAmplitudesAndGeneratedAdjointRestoration() {
    QuantumRegister register = new QuantumRegister(0, "walker", 2);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "walkStep",
        0,
        List.of(GateOperation.of(Gate.H, 0), GateOperation.of(Gate.CNOT, 0, 1)));
    Program program = program(register, circuit, List.of());
    StateVectorEngine simulator = new StateVectorEngine(1);

    simulator.prepare(register, 0);
    simulator.apply(program, circuit, false);
    assertArrayEquals(
        new double[] {1 / Math.sqrt(2), 0, 0, 0, 0, 0, 1 / Math.sqrt(2), 0},
        simulator.amplitudes(register),
        1e-12);
    simulator.apply(program, circuit, false);
    assertArrayEquals(
        new double[] {0.5, 0, -0.5, 0, 0.5, 0, 0.5, 0},
        simulator.amplitudes(register),
        1e-12);
    simulator.apply(program, circuit, true);
    simulator.apply(program, circuit, true);

    assertArrayEquals(
        new double[] {1, 0, 0, 0, 0, 0, 0, 0},
        simulator.amplitudes(register),
        1e-12);
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
  void composedGroverOracleAndDiffusionHaveExactAmplitudeAndSeededCounts() {
    QuantumRegister register = new QuantumRegister(0, "search", 2);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "groverIteration",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            GateOperation.of(Gate.H, 1),
            new GateOperation(Gate.CPHASE, List.of(0, 1), Math.PI),
            GateOperation.of(Gate.H, 0),
            GateOperation.of(Gate.H, 1),
            GateOperation.of(Gate.X, 0),
            GateOperation.of(Gate.X, 1),
            new GateOperation(Gate.CPHASE, List.of(0, 1), Math.PI),
            GateOperation.of(Gate.X, 0),
            GateOperation.of(Gate.X, 1),
            GateOperation.of(Gate.H, 0),
            GateOperation.of(Gate.H, 1)));
    Program program = program(register, circuit, List.of());
    StateVectorEngine simulator = new StateVectorEngine(29);
    simulator.prepare(register, 0);
    simulator.apply(program, circuit, false);

    assertArrayEquals(
        new double[] {0, 0, 0, 0, 0, 0, -1, 0},
        simulator.amplitudes(register),
        1e-12);
    QuantumSubmission submission = new QuantumSubmission(
        program, 0, 0, List.of(new CircuitApplication(0, false)), Map.of(), 256, 29);
    QuantumResult result = new StateVectorTarget()
        .submit(submission)
        .await(Duration.ofSeconds(1));
    assertTrue(result.counts().getOrDefault(3L, 0L) >= 250);
    assertEquals(256L, result.counts().values().stream().mapToLong(Long::longValue).sum());
  }

  @Test
  void amplitudeEstimatorMatchesExactStateAndReportsSeededUncertainty() {
    QuantumRegister register = new QuantumRegister(0, "estimate", 2);
    QuantumCircuit preparation = new QuantumCircuit(
        0, "prepareAmplitude", 0, List.of(GateOperation.of(Gate.H, 1)));
    QuantumCircuit estimation = new QuantumCircuit(
        1,
        "estimateRound",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            new GateOperation(Gate.CPHASE, List.of(1, 0), Math.PI / 2),
            new GateOperation(Gate.CPHASE, List.of(1, 0), Math.PI / 2),
            GateOperation.of(Gate.H, 0)));
    Program program = program(register, preparation, List.of(), estimation);
    StateVectorEngine simulator = new StateVectorEngine(41);
    simulator.prepare(register, 0);
    simulator.apply(program, preparation, false);
    simulator.apply(program, estimation, false);
    assertArrayEquals(
        new double[] {1 / Math.sqrt(2), 0, 0, 0, 0, 0, 1 / Math.sqrt(2), 0},
        simulator.amplitudes(register),
        1e-12);
    simulator.apply(program, estimation, true);
    simulator.apply(program, preparation, true);
    assertArrayEquals(
        new double[] {1, 0, 0, 0, 0, 0, 0, 0},
        simulator.amplitudes(register),
        1e-12);

    QuantumSubmission submission = new QuantumSubmission(
        program,
        0,
        0,
        List.of(new CircuitApplication(0, false), new CircuitApplication(1, false)),
        Map.of(),
        4_096,
        41);
    QuantumResult result = new StateVectorTarget()
        .submit(submission)
        .await(Duration.ofSeconds(1));
    AmplitudeEstimate estimate = AmplitudeEstimate.from(result, 2, 2, 2, 4);
    assertTrue(
        1_900 <= estimate.successes() && estimate.successes() <= 2_196,
        estimate.toString());
    assertEquals(4_096, estimate.shots());
    assertTrue(0.45 <= estimate.probability() && estimate.probability() <= 0.55);
    assertTrue(estimate.standardError() < 0.009);
    assertTrue(estimate.lowerBound() <= 0.5 && 0.5 <= estimate.upperBound());
    assertEquals(2, estimate.qubits());
    assertEquals(4, estimate.circuitApplications());
    assertEquals(submission.identity(), estimate.resultIdentity());

    QuantumCircuit certainPreparation = new QuantumCircuit(
        0, "prepareCertainAmplitude", 0, List.of(GateOperation.of(Gate.X, 1)));
    Program certainProgram = program(register, certainPreparation, List.of(), estimation);
    QuantumSubmission certainSubmission = new QuantumSubmission(
        certainProgram,
        0,
        0,
        List.of(new CircuitApplication(0, false), new CircuitApplication(1, false)),
        Map.of(),
        4_096,
        43);
    AmplitudeEstimate certain = AmplitudeEstimate.from(
        new StateVectorTarget().submit(certainSubmission).await(Duration.ofSeconds(1)),
        2,
        2,
        2,
        4);
    assertEquals(4_096, certain.successes());
    assertEquals(1.0, certain.probability());
    assertEquals(0.0, certain.standardError());
    assertEquals(1.0, certain.lowerBound());
    assertEquals(1.0, certain.upperBound());
    assertEquals(certainSubmission.identity(), certain.resultIdentity());
  }

  @Test
  void twoBitStaticPhaseEstimateHasOneExactIdealAmplitude() {
    QuantumRegister register = new QuantumRegister(0, "phase", 3);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "estimate",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            GateOperation.of(Gate.H, 1),
            new GateOperation(Gate.CPHASE, List.of(2, 0), 3 * Math.PI),
            new GateOperation(Gate.CPHASE, List.of(2, 1), 3 * Math.PI / 2),
            GateOperation.of(Gate.SWAP, 0, 1),
            GateOperation.of(Gate.H, 1),
            new GateOperation(Gate.CPHASE, List.of(1, 0), -Math.PI / 2),
            GateOperation.of(Gate.H, 0)));
    Program program = program(register, circuit, List.of());
    StateVectorEngine simulator = new StateVectorEngine(31);
    simulator.prepare(register, 4);
    simulator.apply(program, circuit, false);

    assertArrayEquals(
        new double[] {
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 1, 0
        },
        simulator.amplitudes(register),
        1e-12);
    simulator.apply(program, circuit, true);
    assertArrayEquals(
        new double[] {0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0},
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
  void widthExplicitCoherentAddAndMarkExhaustEveryBasisAndCleanWorkspace() {
    FunctionBody addThree = new FunctionBody(
        1,
        "modularAddThree",
        true,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.ADD_CONST, 0, 3), Instruction.of(Opcode.RETURN)),
        List.of(Instruction.of(Opcode.SUB_CONST, 0, 3), Instruction.of(Opcode.RETURN)));
    QuantumRegister register = new QuantumRegister(0, "oracle", 3);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "addAndMark",
        0,
        List.of(
            new LiftedCall(1, false),
            new GateOperation(Gate.CPHASE, List.of(0, 1), Math.PI)));
    Program program = program(register, circuit, List.of(addThree));

    for (int basis = 0; basis < 8; basis++) {
      StateVectorEngine simulator = new StateVectorEngine(37 + basis);
      simulator.prepare(register, basis);
      simulator.apply(program, circuit, false);
      double[] expected = new double[16];
      int target = (basis + 3) & 7;
      expected[target * 2] = (target & 3) == 3 ? -1 : 1;
      assertArrayEquals(expected, simulator.amplitudes(register), 1e-12);

      simulator.apply(program, circuit, true);
      expected = new double[16];
      expected[basis * 2] = 1;
      assertArrayEquals(expected, simulator.amplitudes(register), 1e-12);
    }
  }

  @Test
  void variationalBatchCoversVqeQaoaKernelAndParameterShift() {
    QuantumRegister one = new QuantumRegister(0, "variational", 1);
    QuantumCircuit ansatz = new QuantumCircuit(
        0,
        "ansatz",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            new ParameterizedGateOperation(Gate.PHASE, List.of(0), "theta", 1),
            GateOperation.of(Gate.H, 0)));
    Program vqe = program(one, ansatz, List.of());
    QuantumSubmission thetaZero = new QuantumSubmission(
        vqe, 0, 0, List.of(new CircuitApplication(0, false)),
        Map.of("theta", 0.0), 64, 101);
    QuantumSubmission thetaPi = new QuantumSubmission(
        vqe, 0, 0, List.of(new CircuitApplication(0, false)),
        Map.of("theta", Math.PI), 64, 103);
    QuantumBatchResult vqeBatch = new StateVectorTarget()
        .submitBatch(new QuantumBatch(List.of(thetaZero, thetaPi)))
        .await(Duration.ofSeconds(1));
    assertEquals(1.0, vqeBatch.results().get(0).zExpectation(0).value());
    assertEquals(-1.0, vqeBatch.results().get(1).zExpectation(0).value());

    QuantumSubmission shiftPlus = new QuantumSubmission(
        vqe, 0, 0, List.of(new CircuitApplication(0, false)),
        Map.of("theta", Math.PI), 64, 107);
    QuantumSubmission shiftMinus = new QuantumSubmission(
        vqe, 0, 0, List.of(new CircuitApplication(0, false)),
        Map.of("theta", 0.0), 64, 109);
    QuantumBatch shifts = new QuantumBatch(List.of(shiftPlus, shiftMinus));
    QuantumBatchResult shifted = new StateVectorTarget()
        .submitBatch(shifts)
        .await(Duration.ofSeconds(1));
    double derivative = (shifted.results().get(0).zExpectation(0).value()
        - shifted.results().get(1).zExpectation(0).value()) / 2;
    assertEquals(-1.0, derivative, 1e-12);
    assertEquals(shifts.identity(), shifted.batchIdentity());

    QuantumCircuit featureX = new QuantumCircuit(
        0,
        "featureX",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            new ParameterizedGateOperation(Gate.PHASE, List.of(0), "x", 1)));
    QuantumCircuit featureY = new QuantumCircuit(
        1,
        "featureY",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            new ParameterizedGateOperation(Gate.PHASE, List.of(0), "y", 1)));
    Program kernel = program(one, featureX, List.of(), featureY);
    List<CircuitApplication> overlap = List.of(
        new CircuitApplication(0, false), new CircuitApplication(1, true));
    QuantumSubmission equalFeatures = new QuantumSubmission(
        kernel, 0, 0, overlap, Map.of("x", Math.PI / 3, "y", Math.PI / 3), 64, 113);
    QuantumSubmission distinctFeatures = new QuantumSubmission(
        kernel, 0, 0, overlap, Map.of("x", 0.0, "y", Math.PI), 64, 127);
    QuantumBatchResult kernels = new StateVectorTarget()
        .submitBatch(new QuantumBatch(List.of(equalFeatures, distinctFeatures)))
        .await(Duration.ofSeconds(1));
    assertEquals(64, kernels.results().get(0).outcomes().stream()
        .filter(outcome -> outcome == 0).count());
    assertEquals(64, kernels.results().get(1).outcomes().stream()
        .filter(outcome -> outcome == 1).count());

    QuantumRegister pair = new QuantumRegister(0, "qaoa", 2);
    QuantumCircuit qaoa = new QuantumCircuit(
        0,
        "qaoaLayer",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            GateOperation.of(Gate.H, 1),
            new ParameterizedGateOperation(Gate.CPHASE, List.of(0, 1), "gamma", 1),
            GateOperation.of(Gate.H, 0),
            GateOperation.of(Gate.H, 1)));
    Program qaoaProgram = program(pair, qaoa, List.of());
    StateVectorEngine exact = new StateVectorEngine(131);
    exact.prepare(pair, 0);
    exact.apply(qaoaProgram, qaoa, false, Map.of("gamma", Math.PI));
    assertArrayEquals(
        new double[] {0.5, 0, 0.5, 0, 0.5, 0, -0.5, 0},
        exact.amplitudes(pair),
        1e-12);
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
    return program(List.of(register), circuit, additionalFunctions, additionalCircuits);
  }

  private static Program program(List<QuantumRegister> registers, QuantumCircuit circuit) {
    return program(registers, circuit, List.of(), new QuantumCircuit[0]);
  }

  private static Program program(
      List<QuantumRegister> registers,
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
        registers,
        circuits,
        List.of(com.typeobject.wheeler.core.workflow.WorkflowStep.halt()),
        Program.DEFAULT_MAX_HISTORY,
        Program.DEFAULT_MAX_STEPS);
  }
}
