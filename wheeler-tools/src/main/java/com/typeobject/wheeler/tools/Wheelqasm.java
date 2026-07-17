package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.runtime.quantum.OpenQasm3Emitter;
import com.typeobject.wheeler.runtime.quantum.QuantumTask;
import com.typeobject.wheeler.runtime.quantum.QuantumTaskBuilder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

/** Emit one complete static OpenQASM 3 submission from a Wheeler artifact. */
public final class Wheelqasm {
  private Wheelqasm() {}

  public static void main(String[] args) throws Exception {
    if (args.length != 2) {
      System.err.println("Usage: wheelqasm <program.wbc> <output.qasm>");
      System.exit(2);
    }
    Program program = new BytecodeReader().read(Files.readAllBytes(Path.of(args[0])));
    QuantumTask task = singleTask(program);
    Files.writeString(Path.of(args[1]), new OpenQasm3Emitter().emit(task));
    System.out.println("wrote " + args[1]);
  }

  private static QuantumTask singleTask(Program program) {
    Map<Integer, QuantumTaskBuilder> pending = new HashMap<>();
    QuantumTask result = null;
    for (var step : program.workflow()) {
      switch (step.opcode()) {
        case PREPARE -> pending.put(
            Math.toIntExact(step.first()),
            new QuantumTaskBuilder(program, Math.toIntExact(step.first()), step.second()));
        case APPLY, UNAPPLY -> {
          int circuit = Math.toIntExact(step.first());
          int register = program.quantumCircuit(circuit).registerId();
          QuantumTaskBuilder builder = pending.get(register);
          if (builder == null) {
            throw new IllegalArgumentException("Circuit is applied before register preparation");
          }
          builder.apply(circuit, step.opcode() == WorkflowOpcode.UNAPPLY);
        }
        case MEASURE -> {
          int register = Math.toIntExact(step.first());
          if (result != null || pending.get(register) == null) {
            throw new IllegalArgumentException("wheelqasm requires exactly one static submission");
          }
          result = pending.remove(register).build(1, 0);
        }
        case CLASSICAL_CALL, CLASSICAL_UNCALL, EXPECT, COMMIT, HALT -> {
          // Classical workflow edges do not change the current static quantum task.
        }
      }
    }
    if (result == null || !pending.isEmpty()) {
      throw new IllegalArgumentException("wheelqasm requires one complete prepare/measure task");
    }
    return result;
  }
}
