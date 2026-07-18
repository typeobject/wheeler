package com.typeobject.wheeler.core.bytecode;

import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.LiftedCall;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumOperation;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.BitSet;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Structural and semantic verification for decoded version-2 programs. */
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
    if (entry.parameterCount() != 0 || entry.returnsValue()) {
      fail("Entry function must have signature void main()");
    }
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
      fail("Program exceeds version-2 table limits");
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
    verifyLocalFlow(owner, body);
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
      case LOCAL_CONST -> {
        int destination = verifyLocal(owner, instruction.operands().getFirst(), pc);
        if (owner.localType(destination) == ValueType.BOOLEAN) {
          long value = instruction.operands().get(1);
          if (value != 0 && value != 1) {
            fail(location(owner, pc) + " invalid Boolean constant " + value);
          }
        }
      }
      case LOCAL_LOAD_GLOBAL -> {
        int destination = verifyLocal(owner, instruction.operands().get(0), pc);
        requireType(owner, destination, ValueType.SIGNED, pc);
        verifyGlobal(program, instruction.operands().get(1), owner, pc);
      }
      case LOCAL_STORE_GLOBAL -> {
        verifyGlobal(program, instruction.operands().get(0), owner, pc);
        int source = verifyLocal(owner, instruction.operands().get(1), pc);
        requireType(owner, source, ValueType.SIGNED, pc);
      }
      case LOCAL_MOVE -> {
        int destination = verifyLocal(owner, instruction.operands().get(0), pc);
        int source = verifyLocal(owner, instruction.operands().get(1), pc);
        requireSameType(owner, destination, source, pc);
      }
      case LOCAL_ADD, LOCAL_SUB -> {
        for (long operand : instruction.operands()) {
          requireType(owner, verifyLocal(owner, operand, pc), ValueType.SIGNED, pc);
        }
      }
      case LOCAL_XOR -> {
        int destination = verifyLocal(owner, instruction.operands().get(0), pc);
        int left = verifyLocal(owner, instruction.operands().get(1), pc);
        int right = verifyLocal(owner, instruction.operands().get(2), pc);
        requireSameType(owner, destination, left, pc);
        requireSameType(owner, destination, right, pc);
      }
      case LOCAL_EQ -> {
        int destination = verifyLocal(owner, instruction.operands().get(0), pc);
        int left = verifyLocal(owner, instruction.operands().get(1), pc);
        int right = verifyLocal(owner, instruction.operands().get(2), pc);
        requireType(owner, destination, ValueType.BOOLEAN, pc);
        requireSameType(owner, left, right, pc);
      }
      case LOCAL_LT -> {
        requireType(
            owner, verifyLocal(owner, instruction.operands().get(0), pc), ValueType.BOOLEAN, pc);
        requireType(
            owner, verifyLocal(owner, instruction.operands().get(1), pc), ValueType.SIGNED, pc);
        requireType(
            owner, verifyLocal(owner, instruction.operands().get(2), pc), ValueType.SIGNED, pc);
      }
      case JUMP -> verifyJump(owner, instruction.operands().getFirst(), pc, owner.body(inverseBody));
      case JUMP_IF_ZERO -> {
        int condition = verifyLocal(owner, instruction.operands().get(0), pc);
        requireType(owner, condition, ValueType.BOOLEAN, pc);
        verifyJump(owner, instruction.operands().get(1), pc, owner.body(inverseBody));
      }
      case LOCAL_LOOP_CHECK -> {
        requireType(
            owner, verifyLocal(owner, instruction.operands().get(0), pc), ValueType.SIGNED, pc);
        requireType(
            owner, verifyLocal(owner, instruction.operands().get(1), pc), ValueType.SIGNED, pc);
      }
      case SWAP -> {
        verifyGlobal(program, instruction.operands().get(0), owner, pc);
        verifyGlobal(program, instruction.operands().get(1), owner, pc);
      }
      case CALL -> {
        FunctionBody target = program.function(Math.toIntExact(instruction.operands().getFirst()));
        if (target.parameterCount() != 0 || target.returnsValue()) {
          fail(location(owner, pc) + " void call signature mismatch for " + target.name());
        }
      }
      case CALL_VALUE -> {
        FunctionBody target = program.function(Math.toIntExact(instruction.operands().get(0)));
        int base = Math.toIntExact(instruction.operands().get(1));
        int count = Math.toIntExact(instruction.operands().get(2));
        int destination = verifyLocal(owner, instruction.operands().get(3), pc);
        requireType(owner, destination, ValueType.SIGNED, pc);
        if (!target.returnsValue()
            || count != target.parameterCount()
            || base < 0
            || count < 0
            || base > owner.localCount() - count) {
          fail(location(owner, pc) + " value call signature mismatch for " + target.name());
        }
        for (int argument = 0; argument < count; argument++) {
          if (owner.localType(base + argument) != target.localType(argument)) {
            fail(location(owner, pc) + " value call argument type mismatch for " + target.name());
          }
        }
      }
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
        if (owner.id() == program.entryFunctionId() || owner.returnsValue()) {
          fail(location(owner, pc) + " invalid void RETURN");
        }
      }
      case RETURN_VALUE -> {
        int source = verifyLocal(owner, instruction.operands().getFirst(), pc);
        requireType(owner, source, ValueType.SIGNED, pc);
        if (owner.id() == program.entryFunctionId() || !owner.returnsValue()) {
          fail(location(owner, pc) + " invalid value RETURN");
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

  private static void verifyLocalFlow(FunctionBody owner, List<Instruction> body) {
    BitSet[] incoming = new BitSet[body.size()];
    incoming[0] = new BitSet(owner.localCount());
    incoming[0].set(0, owner.parameterCount());
    ArrayDeque<Integer> work = new ArrayDeque<>();
    work.add(0);
    while (!work.isEmpty()) {
      int pc = work.removeFirst();
      BitSet assigned = (BitSet) incoming[pc].clone();
      Instruction instruction = body.get(pc);
      requireAssignedLocals(owner, instruction, pc, assigned);
      int written = writtenLocal(instruction);
      if (written >= 0) {
        assigned.set(written);
      }
      for (int successor : successors(owner, body, pc, instruction)) {
        if (incoming[successor] == null) {
          incoming[successor] = (BitSet) assigned.clone();
          work.add(successor);
        } else {
          BitSet merged = (BitSet) incoming[successor].clone();
          merged.and(assigned);
          if (!merged.equals(incoming[successor])) {
            incoming[successor] = merged;
            work.add(successor);
          }
        }
      }
    }
  }

  private static void requireAssignedLocals(
      FunctionBody owner, Instruction instruction, int pc, BitSet assigned) {
    if (instruction.opcode() == Opcode.CALL_VALUE) {
      int base = Math.toIntExact(instruction.operands().get(1));
      int count = Math.toIntExact(instruction.operands().get(2));
      for (int local = base; local < base + count; local++) {
        if (!assigned.get(local)) {
          fail(location(owner, pc) + " reads uninitialized local " + local);
        }
      }
      return;
    }
    int[] reads = switch (instruction.opcode()) {
      case LOCAL_STORE_GLOBAL -> new int[] {1};
      case LOCAL_MOVE -> new int[] {1};
      case LOCAL_ADD, LOCAL_SUB, LOCAL_XOR, LOCAL_EQ, LOCAL_LT -> new int[] {1, 2};
      case JUMP_IF_ZERO -> new int[] {0};
      case LOCAL_LOOP_CHECK -> new int[] {0, 1};
      case RETURN_VALUE -> new int[] {0};
      default -> new int[0];
    };
    for (int operandIndex : reads) {
      int local = Math.toIntExact(instruction.operands().get(operandIndex));
      if (!assigned.get(local)) {
        fail(location(owner, pc) + " reads uninitialized local " + local);
      }
    }
  }

  private static int writtenLocal(Instruction instruction) {
    return switch (instruction.opcode()) {
      case LOCAL_CONST, LOCAL_LOAD_GLOBAL, LOCAL_MOVE, LOCAL_ADD, LOCAL_SUB,
          LOCAL_XOR, LOCAL_EQ, LOCAL_LT, LOCAL_LOOP_CHECK ->
          Math.toIntExact(instruction.operands().getFirst());
      case CALL_VALUE -> Math.toIntExact(instruction.operands().get(3));
      default -> -1;
    };
  }

  private static List<Integer> successors(
      FunctionBody owner, List<Instruction> body, int pc, Instruction instruction) {
    if (instruction.opcode() == Opcode.HALT
        || instruction.opcode() == Opcode.RETURN
        || instruction.opcode() == Opcode.RETURN_VALUE) {
      return List.of();
    }
    if (instruction.opcode() == Opcode.JUMP) {
      return List.of(Math.toIntExact(instruction.operands().getFirst()));
    }
    if (instruction.opcode() == Opcode.JUMP_IF_ZERO) {
      int next = checkedFallthrough(owner, body, pc);
      return List.of(next, Math.toIntExact(instruction.operands().get(1)));
    }
    return List.of(checkedFallthrough(owner, body, pc));
  }

  private static int checkedFallthrough(FunctionBody owner, List<Instruction> body, int pc) {
    if (pc + 1 >= body.size()) {
      fail(location(owner, pc) + " falls off the function body");
    }
    return pc + 1;
  }

  private static int verifyLocal(FunctionBody owner, long operand, int pc) {
    if (operand < 0 || operand >= owner.localCount()) {
      fail(location(owner, pc) + " invalid local index " + operand);
    }
    return Math.toIntExact(operand);
  }

  private static void requireType(
      FunctionBody owner, int local, ValueType expected, int pc) {
    if (owner.localType(local) != expected) {
      fail(location(owner, pc) + " local " + local + " must have type "
          + expected.name().toLowerCase(java.util.Locale.ROOT));
    }
  }

  private static void requireSameType(
      FunctionBody owner, int left, int right, int pc) {
    if (owner.localType(left) != owner.localType(right)) {
      fail(location(owner, pc) + " local type mismatch between " + left + " and " + right);
    }
  }

  private static void verifyJump(
      FunctionBody owner, long operand, int pc, List<Instruction> body) {
    if (operand < 0 || operand >= body.size()) {
      fail(location(owner, pc) + " invalid jump target " + operand);
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
