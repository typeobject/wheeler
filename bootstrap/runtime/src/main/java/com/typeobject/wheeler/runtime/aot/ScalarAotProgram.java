package com.typeobject.wheeler.runtime.aot;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.bytecode.ValueType;

/** Closed semantic profile accepted by the x86-64 scalar AOT leaf. */
public final class ScalarAotProgram {
  public static final int MAX_FUNCTIONS = 8;
  public static final int MAX_PARAMETERS = 6;
  public static final int MAX_LOCALS = 32;
  public static final int MAX_INSTRUCTIONS = 128;

  private final Program program;
  private final int processStatus;

  private ScalarAotProgram(Program program, int processStatus) {
    this.program = program;
    this.processStatus = processStatus;
  }

  /** Validates and independently evaluates one decoded program without projection. */
  public static ScalarAotProgram validate(Program program) {
    requireProgramShape(program);
    for (FunctionBody function : program.functions()) {
      validateFunction(program, function);
    }
    Evaluation evaluation = evaluate(program, program.entryFunctionId(), new long[0]);
    if (!evaluation.stored()
        || evaluation.value() < 0
        || evaluation.value() > 124) {
      throw new IllegalArgumentException("AOT process status must be between 0 and 124");
    }
    return new ScalarAotProgram(program, Math.toIntExact(evaluation.value()));
  }

  public Program program() {
    return program;
  }

  public FunctionBody entry() {
    return program.function(program.entryFunctionId());
  }

  public int processStatus() {
    return processStatus;
  }

  private static void requireProgramShape(Program program) {
    if (program.kind() != ProgramKind.CLASSICAL
        || !program.recordTypes().isEmpty()
        || !program.variantTypes().isEmpty()
        || !program.arrayTypes().isEmpty()
        || !program.sliceTypes().isEmpty()
        || !program.proofCertificates().isEmpty()
        || !program.quantumRegisters().isEmpty()
        || !program.quantumCircuits().isEmpty()
        || !program.workflow().isEmpty()
        || !program.requiredInstructionExtensions().isEmpty()
        || program.globals().size() != 1
        || !program.globals().getFirst().name().equals("status")
        || program.globals().getFirst().initialValue() != 0
        || program.functions().isEmpty()
        || program.functions().size() > MAX_FUNCTIONS
        || program.entryFunctionId() != program.functions().size() - 1) {
      throw new IllegalArgumentException("WBC is outside the scalar AOT process-status profile");
    }
    for (int index = 0; index < program.functions().size(); index++) {
      if (program.functions().get(index).id() != index) {
        throw new IllegalArgumentException("Scalar AOT functions are not canonical and dense");
      }
    }
  }

  private static void validateFunction(Program program, FunctionBody function) {
    boolean entry = function.id() == program.entryFunctionId();
    if (function.coherent()
        || function.parameterCount() > MAX_PARAMETERS
        || entry && function.parameterCount() != 0
        || function.localCount() == 0
        || function.localCount() > MAX_LOCALS
        || function.localTypes().stream().anyMatch(type ->
            !type.equals(ValueType.SIGNED) && !type.equals(ValueType.BOOLEAN))
        || function.implicitResultSlot()
        || !function.inverse().isEmpty()
        || function.forward().size() < 2
        || function.forward().size() > MAX_INSTRUCTIONS
        || entry != (function.resultType() == null)
        || !entry && !function.resultType().equals(ValueType.SIGNED)) {
      throw new IllegalArgumentException("AOT function signature is outside the scalar profile");
    }

    int stores = 0;
    int last = function.forward().size() - 1;
    for (int pc = 0; pc < function.forward().size(); pc++) {
      Instruction instruction = function.forward().get(pc);
      switch (instruction.opcode()) {
        case LOCAL_CONST, LOCAL_MOVE -> validateUnary(function, instruction);
        case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR,
            LOCAL_EQ, LOCAL_LT -> validateBinary(function, instruction);
        case JUMP -> {
          requireOperands(instruction, 1);
          forwardTarget(instruction.operands().get(0), pc, last);
        }
        case JUMP_IF_ZERO -> {
          requireOperands(instruction, 2);
          local(instruction.operands().get(0), function.localCount());
          forwardTarget(instruction.operands().get(1), pc, last);
        }
        case CALL_VALUE -> validateCall(program, function, instruction);
        case LOCAL_STORE_GLOBAL -> {
          if (!entry) {
            throw new IllegalArgumentException("Scalar AOT helper stores global state");
          }
          requireOperands(instruction, 2);
          if (instruction.operands().get(0) != 0) {
            throw new IllegalArgumentException("Scalar AOT store targets an unknown global");
          }
          local(instruction.operands().get(1), function.localCount());
          stores++;
        }
        case RETURN_VALUE -> {
          if (entry || pc != last) {
            throw new IllegalArgumentException("Scalar AOT helper return is not terminal");
          }
          requireOperands(instruction, 1);
          local(instruction.operands().get(0), function.localCount());
        }
        case HALT -> {
          if (!entry || pc != last || !instruction.operands().isEmpty()) {
            throw new IllegalArgumentException("Scalar AOT halt is not the entry terminal");
          }
        }
        default -> throw new IllegalArgumentException(
            "Unsupported scalar AOT opcode " + instruction.opcode());
      }
    }
    Opcode terminal = function.forward().getLast().opcode();
    if (entry && (stores == 0 || terminal != Opcode.HALT)
        || !entry && terminal != Opcode.RETURN_VALUE) {
      throw new IllegalArgumentException("Scalar AOT function has no canonical terminal");
    }
  }

  private static void validateUnary(FunctionBody function, Instruction instruction) {
    requireOperands(instruction, 2);
    local(instruction.operands().get(0), function.localCount());
    if (instruction.opcode() == Opcode.LOCAL_MOVE) {
      local(instruction.operands().get(1), function.localCount());
    }
  }

  private static void validateBinary(FunctionBody function, Instruction instruction) {
    requireOperands(instruction, 3);
    local(instruction.operands().get(0), function.localCount());
    local(instruction.operands().get(1), function.localCount());
    local(instruction.operands().get(2), function.localCount());
  }

  private static void validateCall(
      Program program, FunctionBody owner, Instruction instruction) {
    requireOperands(instruction, 4);
    int target = Math.toIntExact(instruction.operands().get(0));
    int argumentBase = Math.toIntExact(instruction.operands().get(1));
    int argumentCount = Math.toIntExact(instruction.operands().get(2));
    if (target < 0 || target >= owner.id()) {
      throw new IllegalArgumentException("Scalar AOT call target is not a prior helper");
    }
    FunctionBody callee = program.function(target);
    if (argumentCount != callee.parameterCount()
        || argumentBase < 0
        || argumentBase > owner.localCount() - argumentCount
        || !callee.resultType().equals(ValueType.SIGNED)) {
      throw new IllegalArgumentException("Scalar AOT call signature does not match its helper");
    }
    for (int parameter = 0; parameter < argumentCount; parameter++) {
      if (!owner.localType(argumentBase + parameter).equals(callee.localType(parameter))) {
        throw new IllegalArgumentException("Scalar AOT call argument type does not match");
      }
    }
    int destination = local(instruction.operands().get(3), owner.localCount());
    if (!owner.localType(destination).equals(ValueType.SIGNED)) {
      throw new IllegalArgumentException("Scalar AOT call destination is not signed");
    }
  }

  private static Evaluation evaluate(
      Program program, int functionId, long[] arguments) {
    FunctionBody function = program.function(functionId);
    long[] values = new long[function.localCount()];
    boolean[] assigned = new boolean[function.localCount()];
    System.arraycopy(arguments, 0, values, 0, arguments.length);
    java.util.Arrays.fill(assigned, 0, arguments.length, true);
    long status = 0;
    boolean stored = false;
    int pc = 0;
    while (pc < function.forward().size()) {
      Instruction instruction = function.forward().get(pc);
      try {
        switch (instruction.opcode()) {
          case LOCAL_CONST -> {
            int destination = freshDestination(instruction, assigned);
            values[destination] = instruction.operands().get(1);
            assigned[destination] = true;
            pc++;
          }
          case LOCAL_MOVE -> {
            int destination = freshDestination(instruction, assigned);
            int source = assignedLocal(instruction, 1, assigned);
            values[destination] = values[source];
            assigned[source] = false;
            assigned[destination] = true;
            pc++;
          }
          case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR,
              LOCAL_EQ, LOCAL_LT -> {
            int destination = freshDestination(instruction, assigned);
            int left = assignedLocal(instruction, 1, assigned);
            int right = assignedLocal(instruction, 2, assigned);
            values[destination] = evaluateBinary(
                instruction.opcode(), values[left], values[right]);
            assigned[destination] = true;
            pc++;
          }
          case JUMP -> pc = Math.toIntExact(instruction.operands().get(0));
          case JUMP_IF_ZERO -> {
            int condition = assignedLocal(instruction, 0, assigned);
            pc = values[condition] == 0
                ? Math.toIntExact(instruction.operands().get(1))
                : pc + 1;
          }
          case CALL_VALUE -> {
            int destination = freshDestination(instruction, 3, assigned);
            int argumentBase = Math.toIntExact(instruction.operands().get(1));
            int argumentCount = Math.toIntExact(instruction.operands().get(2));
            long[] callArguments = new long[argumentCount];
            for (int argument = 0; argument < argumentCount; argument++) {
              int source = argumentBase + argument;
              if (!assigned[source]) {
                throw new IllegalArgumentException("Scalar AOT call reads an unassigned local");
              }
              callArguments[argument] = values[source];
            }
            Evaluation result = evaluate(
                program,
                Math.toIntExact(instruction.operands().get(0)),
                callArguments);
            values[destination] = result.value();
            assigned[destination] = true;
            pc++;
          }
          case LOCAL_STORE_GLOBAL -> {
            status = values[assignedLocal(instruction, 1, assigned)];
            stored = true;
            pc++;
          }
          case RETURN_VALUE -> {
            return new Evaluation(
                values[assignedLocal(instruction, 0, assigned)], false);
          }
          case HALT -> {
            return new Evaluation(status, stored);
          }
          default -> throw new IllegalStateException("Validated scalar AOT opcode changed");
        }
      } catch (ArithmeticException exception) {
        throw new IllegalArgumentException("Scalar AOT arithmetic traps", exception);
      }
    }
    throw new IllegalStateException("Validated scalar AOT function did not terminate");
  }

  private static long evaluateBinary(Opcode opcode, long left, long right) {
    return switch (opcode) {
      case LOCAL_ADD -> Math.addExact(left, right);
      case LOCAL_SUB -> Math.subtractExact(left, right);
      case LOCAL_MUL -> Math.multiplyExact(left, right);
      case LOCAL_DIV -> {
        if (right == 0 || left == Long.MIN_VALUE && right == -1) {
          throw new ArithmeticException("Invalid bounded division");
        }
        yield left / right;
      }
      case LOCAL_MOD -> {
        if (right == 0 || left == Long.MIN_VALUE && right == -1) {
          throw new ArithmeticException("Invalid bounded remainder");
        }
        yield left % right;
      }
      case LOCAL_AND -> left & right;
      case LOCAL_XOR -> left ^ right;
      case LOCAL_EQ -> left == right ? 1 : 0;
      case LOCAL_LT -> left < right ? 1 : 0;
      default -> throw new IllegalStateException("Validated scalar AOT arithmetic changed");
    };
  }

  private static int freshDestination(Instruction instruction, boolean[] assigned) {
    return freshDestination(instruction, 0, assigned);
  }

  private static int freshDestination(
      Instruction instruction, int operand, boolean[] assigned) {
    int destination = local(instruction.operands().get(operand), assigned.length);
    if (assigned[destination]) {
      throw new IllegalArgumentException("Scalar AOT destination is already assigned");
    }
    return destination;
  }

  private static int assignedLocal(
      Instruction instruction, int operand, boolean[] assigned) {
    int result = local(instruction.operands().get(operand), assigned.length);
    if (!assigned[result]) {
      throw new IllegalArgumentException("Scalar AOT reads an unassigned local");
    }
    return result;
  }

  private static int local(long value, int count) {
    int result = Math.toIntExact(value);
    if (result < 0 || result >= count) {
      throw new IllegalArgumentException("Scalar AOT local is out of range");
    }
    return result;
  }

  private static int forwardTarget(long value, int pc, int last) {
    int target = Math.toIntExact(value);
    if (target <= pc || target > last) {
      throw new IllegalArgumentException("Scalar AOT branch is not forward and bounded");
    }
    return target;
  }

  private static void requireOperands(Instruction instruction, int count) {
    if (instruction.operands().size() != count) {
      throw new IllegalArgumentException("Scalar AOT operand count changed");
    }
  }

  private record Evaluation(long value, boolean stored) {}
}
