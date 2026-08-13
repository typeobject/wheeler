package com.typeobject.wheeler.core.bytecode;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.quantum.ConditionalGateOperation;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.MeasureOperation;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.PrepareOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumOpcode;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.quantum.ResetOperation;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Conformance checks for the provider-neutral quantum instruction registry. */
class QuantumInstructionRegistryTest {
  private static final int REGISTER_ID = 0;
  private static final int CIRCUIT_ID = 0;
  private static final int FUNCTION_ID = 7;
  private static final int REGISTER_QUBITS = 2;
  private static final int FIRST_QUBIT = 0;
  private static final int SECOND_QUBIT = 1;
  private static final int REGISTER_STRING = 0;
  private static final int CIRCUIT_STRING = 1;
  private static final int PARAMETER_STRING = 2;
  private static final double PHASE_ANGLE = 0.25;
  private static final double PARAMETER_SCALE = -2.0;
  private static final int REGISTER_RECORD_BYTES = Integer.BYTES * 3;
  private static final int CIRCUIT_HEADER_BYTES = Integer.BYTES * 4;
  private static final int FIRST_OPERATION_OFFSET = Integer.BYTES
      + REGISTER_RECORD_BYTES
      + Integer.BYTES
      + CIRCUIT_HEADER_BYTES;
  private static final int FIELD_COUNT_OFFSET = FIRST_OPERATION_OFFSET + Integer.BYTES;
  private static final int UNKNOWN_QUANTUM_OPCODE = Integer.MAX_VALUE;
  private static final int IMPOSSIBLE_FIELD_COUNT = Integer.MAX_VALUE;

  @Test
  void givesGatesAndQuantumOpcodesUniqueStableIdentities() {
    Set<Integer> gateIdentities = new HashSet<>();
    for (Gate gate : Gate.values()) {
      assertTrue(gateIdentities.add(gate.code()), gate.name());
      assertEquals(gate, Gate.fromCode(gate.code()));
      assertEquals(gate.arity(), gate.form().qubitCount());
    }

    Set<Integer> opcodeIdentities = new HashSet<>();
    for (QuantumOpcode opcode : QuantumOpcode.values()) {
      assertTrue(opcodeIdentities.add(opcode.code()), opcode.name());
      assertEquals(opcode, QuantumOpcode.fromCode(opcode.code()));
    }
  }

  @Test
  void roundTripsRegularVariableLengthQuantumInstructions() {
    QuantumRegister register = new QuantumRegister(
        REGISTER_ID, "register", REGISTER_QUBITS);
    QuantumCircuit circuit = new QuantumCircuit(
        CIRCUIT_ID,
        "circuit",
        REGISTER_ID,
        List.of(
            GateOperation.of(Gate.H, FIRST_QUBIT),
            new GateOperation(Gate.CPHASE, List.of(FIRST_QUBIT, SECOND_QUBIT), PHASE_ANGLE),
            new ParameterizedGateOperation(
                Gate.PHASE, List.of(SECOND_QUBIT), "theta", PARAMETER_SCALE),
            new LiftedCall(FUNCTION_ID, true),
            new PrepareOperation(1),
            new MeasureOperation(FIRST_QUBIT, 0),
            new ResetOperation(SECOND_QUBIT),
            new ConditionalGateOperation(
                0, true, GateOperation.of(Gate.X, FIRST_QUBIT))));
    Program program = quantumProgram(register, circuit);
    Map<String, Integer> strings = Map.of(
        "register", REGISTER_STRING,
        "circuit", CIRCUIT_STRING,
        "theta", PARAMETER_STRING);

    byte[] encoded = QuantumSectionCodec.write(program, strings);
    var decoded = QuantumSectionCodec.read(
        ByteBuffer.wrap(encoded).order(ByteOrder.LITTLE_ENDIAN),
        List.of("register", "circuit", "theta"));

    assertEquals(List.of(register), decoded.registers());
    assertEquals(List.of(circuit), decoded.circuits());
  }

  @Test
  void rejectsUnassignedConditionalResultSlots() {
    QuantumRegister register = new QuantumRegister(
        REGISTER_ID, "register", REGISTER_QUBITS);
    QuantumCircuit circuit = new QuantumCircuit(
        CIRCUIT_ID,
        "circuit",
        REGISTER_ID,
        List.of(
            new PrepareOperation(0),
            new ConditionalGateOperation(
                0, true, GateOperation.of(Gate.X, FIRST_QUBIT))));

    BytecodeException exception = assertThrows(
        BytecodeException.class,
        () -> BytecodeVerifier.verify(quantumProgram(register, circuit)));

    assertTrue(exception.getMessage().contains("unassigned result slot"));
  }

  @Test
  void doubleAdjointRestoresExactSemanticOperations() {
    List<com.typeobject.wheeler.core.quantum.QuantumOperation> operations = List.of(
        GateOperation.of(Gate.H, FIRST_QUBIT),
        new GateOperation(
            Gate.CPHASE, List.of(FIRST_QUBIT, SECOND_QUBIT), PHASE_ANGLE),
        new ParameterizedGateOperation(
            Gate.PHASE, List.of(SECOND_QUBIT), "theta", PARAMETER_SCALE),
        new LiftedCall(FUNCTION_ID, false),
        new ConditionalGateOperation(
            0, true, GateOperation.of(Gate.X, FIRST_QUBIT)));
    QuantumCircuit circuit = new QuantumCircuit(
        CIRCUIT_ID, "circuit", REGISTER_ID, operations);
    QuantumCircuit adjoint = new QuantumCircuit(
        CIRCUIT_ID, "adjoint", REGISTER_ID, circuit.inverseOperations());

    assertEquals(operations, adjoint.inverseOperations());
  }

  @Test
  void rejectsUnknownTruncatedAndUnboundedInstructionRecords() {
    byte[] encoded = encodedSingleGate();
    ByteBuffer unknown = ByteBuffer.wrap(encoded.clone()).order(ByteOrder.LITTLE_ENDIAN);
    unknown.putInt(FIRST_OPERATION_OFFSET, UNKNOWN_QUANTUM_OPCODE);
    assertThrows(BytecodeException.class, () -> read(unknown.array()));

    ByteBuffer unbounded = ByteBuffer.wrap(encoded.clone()).order(ByteOrder.LITTLE_ENDIAN);
    unbounded.putInt(FIELD_COUNT_OFFSET, IMPOSSIBLE_FIELD_COUNT);
    assertThrows(BytecodeException.class, () -> read(unbounded.array()));

    byte[] truncated = Arrays.copyOf(encoded, encoded.length - Byte.BYTES);
    assertThrows(BytecodeException.class, () -> read(truncated));
  }

  @Test
  void rejectsParametersOnFixedGates() {
    assertThrows(
        IllegalArgumentException.class,
        () -> new GateOperation(Gate.X, List.of(FIRST_QUBIT), PHASE_ANGLE));
    assertThrows(
        IllegalArgumentException.class,
        () -> new ConditionalGateOperation(
            0,
            true,
            new GateOperation(Gate.PHASE, List.of(FIRST_QUBIT), PHASE_ANGLE)));
  }

  private static byte[] encodedSingleGate() {
    QuantumRegister register = new QuantumRegister(
        REGISTER_ID, "register", REGISTER_QUBITS);
    QuantumCircuit circuit = new QuantumCircuit(
        CIRCUIT_ID,
        "circuit",
        REGISTER_ID,
        List.of(GateOperation.of(Gate.H, FIRST_QUBIT)));
    return QuantumSectionCodec.write(
        quantumProgram(register, circuit),
        Map.of("register", REGISTER_STRING, "circuit", CIRCUIT_STRING));
  }

  private static QuantumSectionCodec.QuantumContent read(byte[] encoded) {
    return QuantumSectionCodec.read(
        ByteBuffer.wrap(encoded).order(ByteOrder.LITTLE_ENDIAN),
        List.of("register", "circuit"));
  }

  private static Program quantumProgram(QuantumRegister register, QuantumCircuit circuit) {
    return new Program(
        "quantum-registry",
        ProgramKind.QUANTUM,
        CIRCUIT_ID,
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        List.of(register),
        List.of(circuit),
        List.of(),
        Program.DEFAULT_MAX_HISTORY,
        Program.DEFAULT_MAX_STEPS);
  }
}
