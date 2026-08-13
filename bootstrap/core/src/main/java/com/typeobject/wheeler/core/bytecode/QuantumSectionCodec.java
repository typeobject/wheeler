package com.typeobject.wheeler.core.bytecode;

import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.ConditionalGateOperation;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.MeasureOperation;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.PrepareOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumOpcode;
import com.typeobject.wheeler.core.quantum.QuantumOperation;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.quantum.ResetOperation;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Strict bounded codec for canonical quantum registers, circuits, and regular instructions. */
final class QuantumSectionCodec {
  record QuantumContent(List<QuantumRegister> registers, List<QuantumCircuit> circuits) {}

  private static final int REGISTER_BYTES = Integer.BYTES * 3;
  private static final int CIRCUIT_HEADER_BYTES = Integer.BYTES * 4;
  private static final int OPERATION_HEADER_BYTES = Integer.BYTES * 2;
  private static final int OPERATION_FIELD_BYTES = Long.BYTES;
  private static final int GATE_ID_FIELDS = 1;
  private static final int SYMBOLIC_PARAMETER_FIELDS = 2;
  private static final int LIFTED_CALL_FIELDS = 2;
  private static final int PREPARATION_FIELDS = 1;
  private static final int MEASUREMENT_FIELDS = 2;
  private static final int RESET_FIELDS = 1;
  private static final int CONDITIONAL_GATE_HEADER_FIELDS = 3;
  private static final int MAX_OPERATION_FIELDS = 64;
  private static final int MAX_SECTION_ITEMS = 65_535;
  private static final int MAX_CIRCUIT_OPERATIONS = 1_000_000;
  private static final int FUNCTION_FIELD = 0;
  private static final int DIRECTION_FIELD = 1;
  private static final int FORWARD_DIRECTION = 0;
  private static final int INVERSE_DIRECTION = 1;
  private static final double NO_PARAMETER = 0.0;

  private QuantumSectionCodec() {}

  static byte[] write(Program program, Map<String, Integer> strings) {
    int operationsBytes = program.quantumCircuits().stream()
        .flatMap(circuit -> circuit.operations().stream())
        .mapToInt(QuantumSectionCodec::operationBytes)
        .sum();
    int size = Integer.BYTES
        + program.quantumRegisters().size() * REGISTER_BYTES
        + Integer.BYTES
        + program.quantumCircuits().size() * CIRCUIT_HEADER_BYTES
        + operationsBytes;
    ByteBuffer buffer = ByteBuffer.allocate(size).order(ByteOrder.LITTLE_ENDIAN);
    buffer.putInt(program.quantumRegisters().size());
    for (QuantumRegister register : program.quantumRegisters()) {
      buffer.putInt(register.id());
      buffer.putInt(strings.get(register.name()));
      buffer.putInt(register.qubits());
    }
    buffer.putInt(program.quantumCircuits().size());
    for (QuantumCircuit circuit : program.quantumCircuits()) {
      buffer.putInt(circuit.id());
      buffer.putInt(strings.get(circuit.name()));
      buffer.putInt(circuit.registerId());
      buffer.putInt(circuit.operations().size());
      circuit.operations().forEach(operation -> writeOperation(buffer, operation, strings));
    }
    return buffer.array();
  }

  static QuantumContent read(ByteBuffer buffer, List<String> strings) {
    int registerCount = count(buffer, "quantum register", MAX_SECTION_ITEMS);
    List<QuantumRegister> registers = new ArrayList<>(registerCount);
    for (int register = 0; register < registerCount; register++) {
      require(buffer, REGISTER_BYTES, "quantum register");
      int id = buffer.getInt();
      int name = buffer.getInt();
      int qubits = buffer.getInt();
      registers.add(new QuantumRegister(id, string(strings, name), qubits));
    }

    int circuitCount = count(buffer, "quantum circuit", MAX_SECTION_ITEMS);
    List<QuantumCircuit> circuits = new ArrayList<>(circuitCount);
    for (int circuit = 0; circuit < circuitCount; circuit++) {
      require(buffer, CIRCUIT_HEADER_BYTES, "quantum circuit");
      int id = buffer.getInt();
      int name = buffer.getInt();
      int register = buffer.getInt();
      int operationCount = boundedCount(
          buffer.getInt(), "quantum operation", MAX_CIRCUIT_OPERATIONS);
      List<QuantumOperation> operations = new ArrayList<>(operationCount);
      for (int operation = 0; operation < operationCount; operation++) {
        operations.add(readOperation(buffer, strings));
      }
      circuits.add(new QuantumCircuit(id, string(strings, name), register, operations));
    }
    if (buffer.hasRemaining()) {
      throw new BytecodeException("Trailing data in quantum section");
    }
    return new QuantumContent(List.copyOf(registers), List.copyOf(circuits));
  }

  private static int operationBytes(QuantumOperation operation) {
    return Math.addExact(
        OPERATION_HEADER_BYTES,
        Math.multiplyExact(operationFieldCount(operation), OPERATION_FIELD_BYTES));
  }

  private static int operationFieldCount(QuantumOperation operation) {
    if (operation instanceof GateOperation gate) {
      return GATE_ID_FIELDS + gate.qubits().size() + gate.gate().form().parameterCount();
    }
    if (operation instanceof ParameterizedGateOperation gate) {
      return GATE_ID_FIELDS + gate.qubits().size() + SYMBOLIC_PARAMETER_FIELDS;
    }
    if (operation instanceof LiftedCall) {
      return LIFTED_CALL_FIELDS;
    }
    if (operation instanceof PrepareOperation) {
      return PREPARATION_FIELDS;
    }
    if (operation instanceof MeasureOperation) {
      return MEASUREMENT_FIELDS;
    }
    if (operation instanceof ResetOperation) {
      return RESET_FIELDS;
    }
    if (operation instanceof ConditionalGateOperation conditional) {
      return CONDITIONAL_GATE_HEADER_FIELDS + conditional.gate().qubits().size();
    }
    throw new IllegalArgumentException("Unsupported quantum operation " + operation);
  }

  private static void writeOperation(
      ByteBuffer buffer, QuantumOperation operation, Map<String, Integer> strings) {
    int fieldCount = operationFieldCount(operation);
    if (operation instanceof GateOperation gate) {
      writeHeader(buffer, QuantumOpcode.APPLY_GATE, fieldCount);
      buffer.putLong(gate.gate().code());
      gate.qubits().forEach(qubit -> buffer.putLong(qubit));
      if (gate.gate().parameterized()) {
        buffer.putLong(Double.doubleToRawLongBits(gate.parameter()));
      }
      return;
    }
    if (operation instanceof ParameterizedGateOperation gate) {
      writeHeader(buffer, QuantumOpcode.APPLY_SYMBOLIC_GATE, fieldCount);
      buffer.putLong(gate.gate().code());
      gate.qubits().forEach(qubit -> buffer.putLong(qubit));
      buffer.putLong(strings.get(gate.parameterName()));
      buffer.putLong(Double.doubleToRawLongBits(gate.scale()));
      return;
    }

    if (operation instanceof LiftedCall lifted) {
      writeHeader(buffer, QuantumOpcode.CALL_UNITARY, fieldCount);
      buffer.putLong(lifted.functionId());
      buffer.putLong(lifted.inverseDirection() ? INVERSE_DIRECTION : FORWARD_DIRECTION);
      return;
    }
    if (operation instanceof PrepareOperation preparation) {
      writeHeader(buffer, QuantumOpcode.PREPARE_REGISTER, fieldCount);
      buffer.putLong(preparation.basisState());
      return;
    }
    if (operation instanceof MeasureOperation measurement) {
      writeHeader(buffer, QuantumOpcode.MEASURE_QUBIT, fieldCount);
      buffer.putLong(measurement.qubit());
      buffer.putLong(measurement.resultSlot());
      return;
    }
    if (operation instanceof ResetOperation reset) {
      writeHeader(buffer, QuantumOpcode.RESET_QUBIT, fieldCount);
      buffer.putLong(reset.qubit());
      return;
    }

    ConditionalGateOperation conditional = (ConditionalGateOperation) operation;
    writeHeader(buffer, QuantumOpcode.APPLY_CONDITIONAL_GATE, fieldCount);
    buffer.putLong(conditional.resultSlot());
    buffer.putLong(conditional.expected() ? 1 : 0);
    buffer.putLong(conditional.gate().gate().code());
    conditional.gate().qubits().forEach(qubit -> buffer.putLong(qubit));
  }

  private static void writeHeader(
      ByteBuffer buffer, QuantumOpcode opcode, int fieldCount) {
    buffer.putInt(opcode.code());
    buffer.putInt(fieldCount);
  }

  private static QuantumOperation readOperation(ByteBuffer buffer, List<String> strings) {
    require(buffer, OPERATION_HEADER_BYTES, "quantum instruction header");
    QuantumOpcode opcode = QuantumOpcode.fromCode(buffer.getInt());
    int fieldCount = boundedCount(
        buffer.getInt(), "quantum instruction field", MAX_OPERATION_FIELDS);
    require(
        buffer,
        Math.multiplyExact(fieldCount, OPERATION_FIELD_BYTES),
        "quantum instruction fields");
    long[] fields = new long[fieldCount];
    for (int field = 0; field < fieldCount; field++) {
      fields[field] = buffer.getLong();
    }

    return switch (opcode) {
      case APPLY_GATE -> readGate(fields);
      case APPLY_SYMBOLIC_GATE -> readSymbolicGate(fields, strings);
      case CALL_UNITARY -> readLiftedCall(fields);
      case PREPARE_REGISTER -> readPreparation(fields);
      case MEASURE_QUBIT -> readMeasurement(fields);
      case RESET_QUBIT -> readReset(fields);
      case APPLY_CONDITIONAL_GATE -> readConditionalGate(fields);
    };
  }

  private static GateOperation readGate(long[] fields) {
    int cursor = 0;
    Gate gate = Gate.fromCode(exactInt(field(fields, cursor++, "gate identity"), "gate identity"));
    int expected = GATE_ID_FIELDS + gate.arity() + gate.form().parameterCount();
    requireFieldCount(fields, expected, "gate");
    List<Integer> qubits = readQubits(fields, cursor, gate);
    cursor += gate.arity();
    double parameter = NO_PARAMETER;
    if (gate.parameterized()) {
      parameter = Double.longBitsToDouble(fields[cursor]);
    }
    return new GateOperation(gate, qubits, parameter);
  }

  private static ParameterizedGateOperation readSymbolicGate(
      long[] fields, List<String> strings) {
    int cursor = 0;
    Gate gate = Gate.fromCode(exactInt(field(fields, cursor++, "gate identity"), "gate identity"));
    if (!gate.parameterized()) {
      throw new BytecodeException("Symbolic instruction requires a parameterized gate");
    }
    int expected = GATE_ID_FIELDS + gate.arity() + SYMBOLIC_PARAMETER_FIELDS;
    requireFieldCount(fields, expected, "symbolic gate");
    List<Integer> qubits = readQubits(fields, cursor, gate);
    cursor += gate.arity();
    int parameterName = exactInt(fields[cursor++], "quantum parameter string");
    double scale = Double.longBitsToDouble(fields[cursor]);
    return new ParameterizedGateOperation(
        gate, qubits, string(strings, parameterName), scale);
  }

  private static LiftedCall readLiftedCall(long[] fields) {
    requireFieldCount(fields, LIFTED_CALL_FIELDS, "unitary call");
    int function = exactInt(fields[FUNCTION_FIELD], "lifted function");
    long direction = fields[DIRECTION_FIELD];
    if (direction != FORWARD_DIRECTION && direction != INVERSE_DIRECTION) {
      throw new BytecodeException("Invalid unitary-call direction");
    }
    return new LiftedCall(function, direction == INVERSE_DIRECTION);
  }

  private static PrepareOperation readPreparation(long[] fields) {
    requireFieldCount(fields, PREPARATION_FIELDS, "preparation");
    try {
      return new PrepareOperation(fields[0]);
    } catch (IllegalArgumentException exception) {
      throw new BytecodeException(exception.getMessage());
    }
  }

  private static MeasureOperation readMeasurement(long[] fields) {
    requireFieldCount(fields, MEASUREMENT_FIELDS, "measurement");
    try {
      return new MeasureOperation(
          exactInt(fields[0], "measurement qubit"),
          exactInt(fields[1], "measurement result slot"));
    } catch (IllegalArgumentException exception) {
      throw new BytecodeException(exception.getMessage());
    }
  }

  private static ResetOperation readReset(long[] fields) {
    requireFieldCount(fields, RESET_FIELDS, "reset");
    try {
      return new ResetOperation(exactInt(fields[0], "reset qubit"));
    } catch (IllegalArgumentException exception) {
      throw new BytecodeException(exception.getMessage());
    }
  }

  private static ConditionalGateOperation readConditionalGate(long[] fields) {
    if (fields.length < CONDITIONAL_GATE_HEADER_FIELDS) {
      throw new BytecodeException("Noncanonical conditional gate field count");
    }
    int slot = exactInt(fields[0], "conditional result slot");
    if (fields[1] != 0 && fields[1] != 1) {
      throw new BytecodeException("Invalid conditional Boolean value");
    }
    Gate gate = Gate.fromCode(exactInt(fields[2], "conditional gate identity"));
    if (gate.parameterized()) {
      throw new BytecodeException("Conditional instruction requires a fixed gate");
    }
    requireFieldCount(
        fields, CONDITIONAL_GATE_HEADER_FIELDS + gate.arity(), "conditional gate");
    List<Integer> qubits = readQubits(fields, CONDITIONAL_GATE_HEADER_FIELDS, gate);
    try {
      return new ConditionalGateOperation(
          slot, fields[1] == 1, new GateOperation(gate, qubits, NO_PARAMETER));
    } catch (IllegalArgumentException exception) {
      throw new BytecodeException(exception.getMessage());
    }
  }

  private static List<Integer> readQubits(long[] fields, int start, Gate gate) {
    List<Integer> qubits = new ArrayList<>(gate.arity());
    for (int qubit = 0; qubit < gate.arity(); qubit++) {
      qubits.add(exactInt(fields[start + qubit], "logical qubit"));
    }
    return List.copyOf(qubits);
  }

  private static long field(long[] fields, int index, String description) {
    if (index < 0 || index >= fields.length) {
      throw new BytecodeException("Missing " + description);
    }
    return fields[index];
  }

  private static void requireFieldCount(long[] fields, int expected, String description) {
    if (fields.length != expected) {
      throw new BytecodeException("Noncanonical " + description + " field count");
    }
  }

  private static int count(ByteBuffer buffer, String description, int maximum) {
    require(buffer, Integer.BYTES, description + " count");
    return boundedCount(buffer.getInt(), description, maximum);
  }

  private static int boundedCount(int count, String description, int maximum) {
    if (count < 0 || count > maximum) {
      throw new BytecodeException("Invalid " + description + " count");
    }
    return count;
  }

  private static int exactInt(long value, String description) {
    try {
      return Math.toIntExact(value);
    } catch (ArithmeticException exception) {
      throw new BytecodeException("Invalid " + description, exception);
    }
  }

  private static String string(List<String> strings, int id) {
    if (id < 0 || id >= strings.size()) {
      throw new BytecodeException("Invalid quantum string ID " + id);
    }
    return strings.get(id);
  }

  private static void require(ByteBuffer buffer, int bytes, String description) {
    if (bytes < 0 || buffer.remaining() < bytes) {
      throw new BytecodeException("Truncated " + description);
    }
  }
}
