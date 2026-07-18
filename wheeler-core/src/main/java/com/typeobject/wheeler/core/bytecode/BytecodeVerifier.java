package com.typeobject.wheeler.core.bytecode;

import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumOperation;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Structural and semantic verification for decoded version-1 programs. */
public final class BytecodeVerifier {
  private static final Set<Opcode> COHERENT_OPCODES = Set.of(
      Opcode.NOP, Opcode.XOR_CONST, Opcode.CALL, Opcode.UNCALL, Opcode.RETURN);

  private BytecodeVerifier() {}

  public static void verify(Program program) {
    verifyLimits(program);
    verifyGlobals(program);
    verifyFunctions(program);
    verifyQuantum(program);
    verifyWorkflow(program);

    FunctionBody entry = program.function(program.entryFunctionId());
    if (entry.forward().stream().noneMatch(instruction -> instruction.opcode() == Opcode.HALT)) {
      fail("Entry function must contain HALT");
    }
  }

  private static void verifyLimits(Program program) {
    if (program.name().isBlank()) {
      fail("Program name must not be blank");
    }
    if (program.maxHistoryRecords() <= 0 || program.maxHistoryRecords() > 10_000_000) {
      fail("Invalid history record limit");
    }
    if (program.maxSteps() <= 0 || program.maxSteps() > 1_000_000_000L) {
      fail("Invalid step limit");
    }
    if (program.globals().size() > 65_535
        || program.functions().size() > 65_535
        || program.quantumRegisters().size() > 65_535
        || program.quantumCircuits().size() > 65_535) {
      fail("Program exceeds version-1 table limits");
    }
  }

  private static void verifyGlobals(Program program) {
    Set<String> names = new HashSet<>();
    for (Global global : program.globals()) {
      if (!names.add(global.name())) {
        fail("Duplicate global name: " + global.name());
      }
    }
  }

  private static void verifyFunctions(Program program) {
    Set<String> names = new HashSet<>();
    for (FunctionBody function : program.functions()) {
      if (!names.add(function.name())) {
        fail("Duplicate function name: " + function.name());
      }
      verifyBody(program, function, function.forward(), false);
      if (function.reversible()) {
        verifyBody(program, function, function.inverse(), true);
        verifyGeneratedInverse(function);
      }
      if (function.coherent()) {
        if (!function.reversible()) {
          fail("Coherent function is not reversible: " + function.name());
        }
        for (Instruction instruction : function.forward()) {
          if (!COHERENT_OPCODES.contains(instruction.opcode())) {
            fail("Coherent function contains " + instruction.opcode() + ": " + function.name());
          }
          if (instruction.opcode() == Opcode.CALL || instruction.opcode() == Opcode.UNCALL) {
            FunctionBody target = program.function(Math.toIntExact(instruction.operands().getFirst()));
            if (!target.coherent()) {
              fail("Coherent function calls noncoherent function: " + target.name());
            }
          }
        }
      }
    }
  }

  private static void verifyGeneratedInverse(FunctionBody function) {
    List<Instruction> expected = new ArrayList<>();
    for (int i = function.forward().size() - 2; i >= 0; i--) {
      Instruction forward = function.forward().get(i);
      if (!forward.opcode().supportsGeneratedInverse()) {
        fail("Reversible function contains noninvertible opcode: " + function.name());
      }
      expected.add(forward.inverse());
    }
    expected.add(Instruction.of(Opcode.RETURN));
    if (!expected.equals(function.inverse())) {
      fail("Inverse body does not match forward body: " + function.name());
    }
  }

  private static void verifyBody(
      Program program, FunctionBody owner, List<Instruction> body, boolean inverseBody) {
    if (body.isEmpty()) {
      fail("Function body must not be empty: " + owner.name());
    }
    for (int pc = 0; pc < body.size(); pc++) {
      verifyInstruction(program, owner, body.get(pc), pc, inverseBody);
    }
  }

  private static void verifyInstruction(
      Program program,
      FunctionBody owner,
      Instruction instruction,
      int pc,
      boolean inverseBody) {
    Opcode opcode = instruction.opcode();
    switch (opcode) {
      case ADD_CONST, SUB_CONST, XOR_CONST, SET_LOGGED, EXPECT_EQ ->
          verifyGlobal(program, instruction.operands().getFirst(), owner, pc);
      case SWAP -> {
        verifyGlobal(program, instruction.operands().get(0), owner, pc);
        verifyGlobal(program, instruction.operands().get(1), owner, pc);
      }
      case CALL -> program.function(Math.toIntExact(instruction.operands().getFirst()));
      case UNCALL -> {
        FunctionBody target = program.function(Math.toIntExact(instruction.operands().getFirst()));
        if (!target.reversible()) {
          fail(location(owner, pc) + " calls missing inverse for " + target.name());
        }
      }
      case HALT -> {
        if (owner.id() != program.entryFunctionId() || inverseBody) {
          fail(location(owner, pc) + " HALT is only valid in the forward entry body");
        }
      }
      case RETURN -> {
        if (owner.id() == program.entryFunctionId()) {
          fail(location(owner, pc) + " entry function cannot RETURN");
        }
      }
      case COMMIT -> {
        if (inverseBody) {
          fail(location(owner, pc) + " COMMIT cannot appear in an inverse body");
        }
      }
      case NOP, CHECKPOINT -> {
        // No additional operands to verify.
      }
    }
  }

  private static void verifyQuantum(Program program) {
    if (program.kind() == ProgramKind.CLASSICAL) {
      if (!program.quantumRegisters().isEmpty()
          || !program.quantumCircuits().isEmpty()
          || !program.workflow().isEmpty()) {
        fail("Classical program contains quantum or workflow content");
      }
      return;
    }

    Set<String> registerNames = new HashSet<>();
    for (QuantumRegister register : program.quantumRegisters()) {
      if (!registerNames.add(register.name())) {
        fail("Duplicate quantum register name: " + register.name());
      }
    }
    Set<String> circuitNames = new HashSet<>();
    for (QuantumCircuit circuit : program.quantumCircuits()) {
      if (!circuitNames.add(circuit.name())) {
        fail("Duplicate quantum circuit name: " + circuit.name());
      }
      QuantumRegister register = program.quantumRegister(circuit.registerId());
      for (QuantumOperation operation : circuit.operations()) {
        if (operation instanceof GateOperation gate) {
          Set<Integer> used = new HashSet<>();
          for (int qubit : gate.qubits()) {
            if (qubit < 0 || qubit >= register.qubits() || !used.add(qubit)) {
              fail("Invalid or repeated qubit in circuit " + circuit.name());
            }
          }
        } else if (operation instanceof ParameterizedGateOperation gate) {
          Set<Integer> used = new HashSet<>();
          for (int qubit : gate.qubits()) {
            if (qubit < 0 || qubit >= register.qubits() || !used.add(qubit)) {
              fail("Invalid or repeated qubit in circuit " + circuit.name());
            }
          }
        } else if (operation instanceof LiftedCall lifted) {
          FunctionBody function = program.function(lifted.functionId());
          if (!function.coherent()) {
            fail("Lifted function is not coherent: " + function.name());
          }
        }
      }
    }
  }

  private static void verifyWorkflow(Program program) {
    if (program.kind() == ProgramKind.CLASSICAL) {
      return;
    }
    if (program.workflow().isEmpty()
        || program.workflow().getLast().opcode() != WorkflowOpcode.HALT) {
      fail("Quantum and hybrid workflows must end in HALT");
    }
    int halts = 0;
    for (WorkflowStep step : program.workflow()) {
      switch (step.opcode()) {
        case PREPARE -> {
          QuantumRegister register = program.quantumRegister(Math.toIntExact(step.first()));
          if (step.second() < 0
              || (register.qubits() < 63 && step.second() >= (1L << register.qubits()))) {
            fail("Preparation basis value does not fit register " + register.name());
          }
        }
        case APPLY, UNAPPLY -> program.quantumCircuit(Math.toIntExact(step.first()));
        case MEASURE -> {
          program.quantumRegister(Math.toIntExact(step.first()));
          verifyGlobal(program, step.second(), program.function(program.entryFunctionId()), 0);
        }
        case CLASSICAL_CALL -> program.function(Math.toIntExact(step.first()));
        case CLASSICAL_UNCALL -> {
          FunctionBody function = program.function(Math.toIntExact(step.first()));
          if (!function.reversible()) {
            fail("Workflow uncalls nonreversible function " + function.name());
          }
        }
        case EXPECT -> verifyGlobal(
            program, step.first(), program.function(program.entryFunctionId()), 0);
        case COMMIT -> requireZeroOperands(step);
        case HALT -> {
          requireZeroOperands(step);
          halts++;
        }
      }
    }
    if (halts != 1) {
      fail("Workflow must contain exactly one final HALT");
    }
  }

  private static void requireZeroOperands(WorkflowStep step) {
    if (step.first() != 0 || step.second() != 0 || step.third() != 0) {
      fail(step.opcode() + " workflow record has nonzero operands");
    }
  }

  private static void verifyGlobal(
      Program program, long operand, FunctionBody owner, int pc) {
    if (operand < 0 || operand >= program.globals().size()) {
      fail(location(owner, pc) + " invalid global index " + operand);
    }
  }

  private static String location(FunctionBody function, int pc) {
    return function.name() + "[" + pc + "]";
  }

  private static void fail(String message) {
    throw new BytecodeException(message);
  }
}
