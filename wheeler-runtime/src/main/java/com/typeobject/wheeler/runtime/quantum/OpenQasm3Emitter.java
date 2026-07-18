package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.QuantumOperation;
import java.util.List;

/** Lossless OpenQASM 3 lowering for Wheeler's current static-circuit subset. */
public final class OpenQasm3Emitter {
  public String emit(QuantumTask task) {
    int qubits = task.program().quantumRegister(task.registerId()).qubits();
    StringBuilder output = new StringBuilder();
    output.append("OPENQASM 3.0;\n")
        .append("include \"stdgates.inc\";\n")
        .append("bit[").append(qubits).append("] c;\n")
        .append("qubit[").append(qubits).append("] q;\n");
    for (int qubit = 0; qubit < qubits; qubit++) {
      if ((task.basisState() & (1L << qubit)) != 0) {
        output.append("x q[").append(qubit).append("];\n");
      }
    }
    for (CircuitApplication application : task.applications()) {
      List<QuantumOperation> operations = application.inverse()
          ? task.program().quantumCircuit(application.circuitId()).inverseOperations()
          : task.program().quantumCircuit(application.circuitId()).operations();
      for (QuantumOperation operation : operations) {
        appendOperation(output, task, operation, qubits);
      }
    }
    output.append("c = measure q;\n");
    return output.toString();
  }

  private static void appendOperation(
      StringBuilder output, QuantumTask task, QuantumOperation operation, int qubits) {
    if (operation instanceof GateOperation gate) {
      appendGate(output, gate);
      return;
    }
    if (operation instanceof ParameterizedGateOperation gate) {
      appendGate(output, gate.bind(task.bindings()));
      return;
    }
    LiftedCall lifted = (LiftedCall) operation;
    appendLifted(
        output,
        task,
        task.program().function(lifted.functionId()),
        lifted.inverseDirection(),
        qubits);
  }

  private static void appendGate(StringBuilder output, GateOperation operation) {
    List<Integer> q = operation.qubits();
    switch (operation.gate()) {
      case H -> unary(output, "h", q.getFirst());
      case X -> unary(output, "x", q.getFirst());
      case Z -> unary(output, "z", q.getFirst());
      case PHASE -> parameterizedUnary(output, "p", operation.parameter(), q.getFirst());
      case CPHASE -> parameterizedBinary(
          output, "cp", operation.parameter(), q.getFirst(), q.get(1));
      case CNOT -> binary(output, "cx", q.getFirst(), q.get(1));
      case CZ -> binary(output, "cz", q.getFirst(), q.get(1));
      case SWAP -> binary(output, "swap", q.getFirst(), q.get(1));
    }
  }

  private static void appendLifted(
      StringBuilder output,
      QuantumTask task,
      FunctionBody function,
      boolean inverse,
      int qubits) {
    for (Instruction instruction : function.body(inverse)) {
      if (instruction.opcode() == Opcode.XOR_CONST) {
        long mask = instruction.operands().get(1);
        for (int qubit = 0; qubit < qubits; qubit++) {
          if ((mask & (1L << qubit)) != 0) {
            unary(output, "x", qubit);
          }
        }
      } else if (instruction.opcode() == Opcode.CALL
          || instruction.opcode() == Opcode.UNCALL) {
        appendLifted(
            output,
            task,
            task.program().function(Math.toIntExact(instruction.operands().getFirst())),
            instruction.opcode() == Opcode.UNCALL,
            qubits);
      } else if (instruction.opcode() != Opcode.NOP
          && instruction.opcode() != Opcode.RETURN) {
        throw new QuantumExecutionException(
            "OpenQASM lowering cannot represent coherent " + instruction.opcode());
      }
    }
  }

  private static void unary(StringBuilder output, String gate, int qubit) {
    output.append(gate).append(" q[").append(qubit).append("];\n");
  }

  private static void binary(StringBuilder output, String gate, int first, int second) {
    output.append(gate).append(" q[").append(first).append("], q[")
        .append(second).append("];\n");
  }

  private static void parameterizedUnary(
      StringBuilder output, String gate, double parameter, int qubit) {
    output.append(gate).append('(').append(Double.toString(parameter)).append(") q[")
        .append(qubit).append("];\n");
  }

  private static void parameterizedBinary(
      StringBuilder output, String gate, double parameter, int first, int second) {
    output.append(gate).append('(').append(Double.toString(parameter)).append(") q[")
        .append(first).append("], q[").append(second).append("];\n");
  }
}
