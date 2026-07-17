package com.typeobject.wheeler.runtime.quantum;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.Test;

class StateVectorTargetTest {
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
  void openQasmLoweringIsPortableAndDeterministic() {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(0, "flip", 0, List.of(GateOperation.of(Gate.X, 0)));
    Program program = program(register, circuit, List.of());
    QuantumTask task = new QuantumTask(
        program, 0, 0, List.of(new CircuitApplication(0, false)), 1, 0);

    String qasm = new OpenQasm3Emitter().emit(task);

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
    QuantumTask task = new QuantumTask(
        program, 0, 0, List.of(new CircuitApplication(0, false)), 4, 9);

    QuantumJob job = new StateVectorTarget().submit(task);
    QuantumResult result = job.await(Duration.ofSeconds(1));

    assertEquals(JobState.SUCCEEDED, job.state());
    assertEquals(List.of(1L, 1L, 1L, 1L), result.outcomes());
    assertEquals(4L, result.counts().get(1L));
  }

  @Test
  void coherentlyLiftedXorMatchesClassicalPermutation() {
    FunctionBody flip = new FunctionBody(
        1,
        "flip",
        true,
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
    FunctionBody main = new FunctionBody(
        0, "main", false, List.of(Instruction.of(Opcode.HALT)), List.of());
    List<FunctionBody> functions = new java.util.ArrayList<>();
    functions.add(main);
    functions.addAll(additionalFunctions);
    return new Program(
        "QuantumTest",
        ProgramKind.QUANTUM,
        0,
        List.of(new Global("result", 0)),
        functions,
        List.of(register),
        List.of(circuit),
        List.of(com.typeobject.wheeler.core.workflow.WorkflowStep.halt()),
        Program.DEFAULT_MAX_HISTORY,
        Program.DEFAULT_MAX_STEPS);
  }
}
