package com.typeobject.wheeler.runtime.quantum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.runtime.quantum.CalibrationAwareCompiler.CalibrationResult;
import com.typeobject.wheeler.runtime.quantum.CalibrationAwareCompiler.GateMetric;
import com.typeobject.wheeler.runtime.quantum.CalibrationAwareCompiler.StalePolicy;
import java.util.List;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

/** Exact calibration provenance and stale policy gate every compiled target plan. */
final class CalibrationAwareCompilerTest {
  private static final int SHOTS = 128;

  @Test
  void closesSemanticCircuitAgainstExactImmutableCalibration() {
    Program program = program();
    TargetDescriptor target = target();
    CalibrationAwareCompiler compiler = new CalibrationAwareCompiler();
    AtomicInteger experiments = new AtomicInteger();

    var first = compiler.compile(
        program, 0, target, 7, SHOTS, 71, StalePolicy.reject(), request -> {
          experiments.incrementAndGet();
          return result(request, 7, List.of(phaseMetric(), hMetric()));
        });
    var second = compiler.compile(
        program, 0, target, 7, SHOTS, 71, StalePolicy.reject(), request ->
            result(request, 7, List.of(hMetric(), phaseMetric())));

    assertEquals(2, first.metrics().size());
    assertEquals(List.of(Gate.H, Gate.PHASE),
        first.metrics().stream().map(GateMetric::gate).toList());
    assertEquals(7, first.estimatedDurationCycles());
    assertEquals(40, first.unionErrorBoundPartsPerTrillion());
    assertFalse(first.acceptedOlderEpoch());
    assertEquals(first.identity(), second.identity());
    var permissive = compiler.compile(
        program, 0, target, 7, SHOTS, 71, StalePolicy.acceptWithin(1), request ->
            result(request, 7, List.of(hMetric(), phaseMetric())));
    assertNotEquals(first.identity(), permissive.identity());
    assertEquals(1, experiments.get());
  }

  @Test
  void staleEpochRequiresExplicitBoundedPolicy() {
    CalibrationAwareCompiler compiler = new CalibrationAwareCompiler();
    assertThrows(QuantumExecutionException.class, () -> compiler.compile(
        program(), 0, target(), 7, SHOTS, 73, StalePolicy.reject(), request ->
            result(request, 6, List.of(hMetric(), phaseMetric()))));
    assertThrows(QuantumExecutionException.class, () -> compiler.compile(
        program(), 0, target(), 7, SHOTS, 73, StalePolicy.acceptWithin(1), request ->
            result(request, 5, List.of(hMetric(), phaseMetric()))));

    var accepted = compiler.compile(
        program(), 0, target(), 7, SHOTS, 73, StalePolicy.acceptWithin(1), request ->
            result(request, 6, List.of(hMetric(), phaseMetric())));
    assertTrue(accepted.acceptedOlderEpoch());
    assertEquals(6, accepted.measuredEpoch());
    assertNotEquals(accepted.identity(), compiler.compile(
        program(), 0, target(), 7, SHOTS, 73, StalePolicy.reject(), request ->
            result(request, 7, List.of(hMetric(), phaseMetric()))).identity());
  }

  @Test
  void malformedProviderDataAndMissingCapabilityFailClosed() {
    CalibrationAwareCompiler compiler = new CalibrationAwareCompiler();
    AtomicInteger experiments = new AtomicInteger();
    TargetDescriptor incapable = new TargetDescriptor(
        "test", "incapable", Set.of(TargetCapability.PARAMETER_BINDING), 1, SHOTS);
    assertThrows(QuantumExecutionException.class, () -> compiler.compile(
        program(), 0, incapable, 7, SHOTS, 79, StalePolicy.reject(), request -> {
          experiments.incrementAndGet();
          return result(request, 7, List.of(hMetric(), phaseMetric()));
        }));
    assertEquals(0, experiments.get());

    assertThrows(QuantumExecutionException.class, () -> compiler.compile(
        program(), 0, target(), 7, SHOTS, 79, StalePolicy.reject(), request ->
            new CalibrationResult(
                request.identity(), request.targetIdentity(), 7, List.of(hMetric()))));
    assertThrows(QuantumExecutionException.class, () -> compiler.compile(
        program(), 0, target(), 7, SHOTS, 79, StalePolicy.reject(), request ->
            new CalibrationResult(
                request.identity(), "0".repeat(64), 7, List.of(hMetric(), phaseMetric()))));
    assertThrows(QuantumExecutionException.class, () -> compiler.compile(
        program(), 0, target(), 7, SHOTS, 79, StalePolicy.reject(), request ->
            new CalibrationResult(
                "0".repeat(64), request.targetIdentity(), 7, List.of(hMetric(), phaseMetric()))));
    assertThrows(QuantumExecutionException.class, () -> compiler.compile(
        program(), 0, target(), 7, SHOTS, 79, StalePolicy.reject(), request ->
            result(request, 8, List.of(hMetric(), phaseMetric()))));
    assertThrows(QuantumExecutionException.class, () -> compiler.compile(
        program(), 0, target(), 7, SHOTS, 79, StalePolicy.reject(), request ->
            result(request, 7, List.of(hMetric(), new GateMetric(Gate.PHASE, 20, 3, 127)))));
  }

  private static CalibrationResult result(
      CalibrationAwareCompiler.CalibrationRequest request,
      long epoch,
      List<GateMetric> metrics) {
    return new CalibrationResult(
        request.identity(), request.targetIdentity(), epoch, metrics);
  }

  private static GateMetric hMetric() {
    return new GateMetric(Gate.H, 10, 2, SHOTS);
  }

  private static GateMetric phaseMetric() {
    return new GateMetric(Gate.PHASE, 20, 3, SHOTS);
  }

  private static TargetDescriptor target() {
    return new TargetDescriptor(
        "test",
        "calibrated",
        Set.of(TargetCapability.STATIC_CIRCUIT, TargetCapability.PARAMETER_BINDING),
        1,
        SHOTS);
  }

  private static Program program() {
    QuantumRegister register = new QuantumRegister(0, "calibrated", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "ansatz",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            new ParameterizedGateOperation(Gate.PHASE, List.of(0), "theta", 1),
            GateOperation.of(Gate.H, 0)));
    return StateVectorTargetTest.program(register, circuit, List.<FunctionBody>of());
  }
}
