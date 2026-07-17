package com.typeobject.wheeler.core.bytecode;

import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumOperation;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

final class QuantumSectionCodec {
  record QuantumContent(List<QuantumRegister> registers, List<QuantumCircuit> circuits) {}

  private static final int GATE = 1;
  private static final int LIFTED_CALL = 2;
  private static final int OPERATION_BYTES = 32;

  private QuantumSectionCodec() {}

  static byte[] write(Program program, Map<String, Integer> strings) {
    int operations = program.quantumCircuits().stream()
        .mapToInt(circuit -> circuit.operations().size())
        .sum();
    int size = 4 + program.quantumRegisters().size() * 12 + 4
        + program.quantumCircuits().size() * 16 + operations * OPERATION_BYTES;
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
      circuit.operations().forEach(operation -> writeOperation(buffer, operation));
    }
    return buffer.array();
  }

  static QuantumContent read(ByteBuffer buffer, List<String> strings) {
    int registerCount = count(buffer, "quantum register");
    List<QuantumRegister> registers = new ArrayList<>(registerCount);
    for (int i = 0; i < registerCount; i++) {
      require(buffer, 12, "quantum register");
      int id = buffer.getInt();
      int name = buffer.getInt();
      int qubits = buffer.getInt();
      registers.add(new QuantumRegister(id, string(strings, name), qubits));
    }
    int circuitCount = count(buffer, "quantum circuit");
    List<QuantumCircuit> circuits = new ArrayList<>(circuitCount);
    for (int i = 0; i < circuitCount; i++) {
      require(buffer, 16, "quantum circuit");
      int id = buffer.getInt();
      int name = buffer.getInt();
      int register = buffer.getInt();
      int operationCount = buffer.getInt();
      if (operationCount < 0 || operationCount > 1_000_000) {
        throw new BytecodeException("Invalid quantum operation count");
      }
      List<QuantumOperation> operations = new ArrayList<>(operationCount);
      for (int operation = 0; operation < operationCount; operation++) {
        operations.add(readOperation(buffer));
      }
      circuits.add(new QuantumCircuit(id, string(strings, name), register, operations));
    }
    if (buffer.hasRemaining()) {
      throw new BytecodeException("Trailing data in quantum section");
    }
    return new QuantumContent(List.copyOf(registers), List.copyOf(circuits));
  }

  private static void writeOperation(ByteBuffer buffer, QuantumOperation operation) {
    if (operation instanceof GateOperation gate) {
      buffer.putInt(GATE);
      buffer.putInt(gate.gate().ordinal());
      buffer.putInt(gate.qubits().getFirst());
      buffer.putInt(gate.qubits().size() == 2 ? gate.qubits().get(1) : -1);
      buffer.putDouble(gate.parameter());
      buffer.putInt(-1);
      buffer.putInt(0);
    } else if (operation instanceof LiftedCall lifted) {
      buffer.putInt(LIFTED_CALL);
      buffer.putInt(0);
      buffer.putInt(-1);
      buffer.putInt(-1);
      buffer.putDouble(0);
      buffer.putInt(lifted.functionId());
      buffer.putInt(lifted.inverseDirection() ? 1 : 0);
    } else {
      throw new IllegalArgumentException("Unsupported quantum operation " + operation);
    }
  }

  private static QuantumOperation readOperation(ByteBuffer buffer) {
    require(buffer, OPERATION_BYTES, "quantum operation");
    int type = buffer.getInt();
    int code = buffer.getInt();
    int first = buffer.getInt();
    int second = buffer.getInt();
    double parameter = buffer.getDouble();
    int function = buffer.getInt();
    int flags = buffer.getInt();
    if (type == GATE) {
      Gate gate = Gate.fromCode(code);
      if (function != -1 || flags != 0 || (gate.arity() == 1 && second != -1)) {
        throw new BytecodeException("Invalid gate operation record");
      }
      return gate.arity() == 1
          ? new GateOperation(gate, List.of(first), parameter)
          : new GateOperation(gate, List.of(first, second), parameter);
    }
    if (type == LIFTED_CALL) {
      if (code != 0 || first != -1 || second != -1 || parameter != 0 || (flags & ~1) != 0) {
        throw new BytecodeException("Invalid lifted-call record");
      }
      return new LiftedCall(function, (flags & 1) != 0);
    }
    throw new BytecodeException("Unknown quantum operation type " + type);
  }

  private static int count(ByteBuffer buffer, String description) {
    require(buffer, 4, description + " count");
    int count = buffer.getInt();
    if (count < 0 || count > 65_535) {
      throw new BytecodeException("Invalid " + description + " count");
    }
    return count;
  }

  private static String string(List<String> strings, int id) {
    if (id < 0 || id >= strings.size()) {
      throw new BytecodeException("Invalid quantum string ID " + id);
    }
    return strings.get(id);
  }

  private static void require(ByteBuffer buffer, int bytes, String description) {
    if (buffer.remaining() < bytes) {
      throw new BytecodeException("Truncated " + description);
    }
  }
}
