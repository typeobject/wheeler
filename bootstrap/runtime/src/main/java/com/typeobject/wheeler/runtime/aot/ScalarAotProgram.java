package com.typeobject.wheeler.runtime.aot;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.bytecode.ValueType;

/** Closed semantic profile accepted by the x86-64 scalar AOT leaf. */
public final class ScalarAotProgram {
  public static final int MAX_FUNCTIONS = 24;
  public static final int MAX_GLOBALS = 32;
  public static final int MAX_PARAMETERS = 16;
  public static final int MAX_LOCALS = 32;
  public static final int MAX_OUTPUT_LOCALS = 64;
  public static final int MAX_INSTRUCTIONS = 128;
  public static final int MAX_LOOP_ITERATIONS = 4096;
  public static final int MAX_INPUT_BYTES = 4096;
  public static final int MAX_OUTPUT_BYTES = 4096;
  public static final int MAX_EXECUTED_INSTRUCTIONS = 65_536;

  private final Program program;
  private final Integer processStatus;
  private final byte[] applicationOutput;
  private final boolean dynamicApplicationIo;

  private ScalarAotProgram(
      Program program,
      Integer processStatus,
      byte[] applicationOutput,
      boolean dynamicApplicationIo) {
    this.program = program;
    this.processStatus = processStatus;
    this.applicationOutput = applicationOutput == null ? null : applicationOutput.clone();
    this.dynamicApplicationIo = dynamicApplicationIo;
  }

  /** Validates and independently evaluates one decoded program without projection. */
  public static ScalarAotProgram validate(Program program) {
    requireProgramShape(program);
    FunctionBody entry = program.function(program.entryFunctionId());
    boolean dynamicIo = entry.parameterCount() == 2;
    boolean outputBearing = entry.parameterCount() > 0;
    for (FunctionBody function : program.functions()) {
      validateFunction(program, function, dynamicIo, outputBearing);
    }
    validateCallGraph(program);
    if (entry.parameterCount() == 2) {
      return new ScalarAotProgram(program, null, null, true);
    }
    OutputState output = new OutputState();
    EvaluationState state = new EvaluationState(program);
    long[] arguments = entry.parameterCount() == 0 ? new long[0] : new long[] {1};
    Evaluation evaluation = evaluate(
        program,
        program.entryFunctionId(),
        arguments,
        output,
        state,
        new EvaluationBudget());
    if (!evaluation.stored()
        || evaluation.value() < 0
        || evaluation.value() > 124) {
      throw new IllegalArgumentException("AOT process status must be between 0 and 124");
    }
    byte[] applicationOutput = null;
    if (entry.parameterCount() == 1) {
      if (output.length < 0) {
        throw new IllegalArgumentException("Scalar AOT output length was not committed");
      }
      applicationOutput = java.util.Arrays.copyOf(output.bytes, output.length);
    }
    return new ScalarAotProgram(
        program, Math.toIntExact(evaluation.value()), applicationOutput, false);
  }

  public Program program() {
    return program;
  }

  public FunctionBody entry() {
    return program.function(program.entryFunctionId());
  }

  public boolean hasStaticProcessStatus() {
    return processStatus != null;
  }

  public int processStatus() {
    if (processStatus == null) {
      throw new IllegalStateException("Scalar AOT process status depends on application input");
    }
    return processStatus;
  }

  public boolean usesDynamicApplicationIo() {
    return dynamicApplicationIo;
  }

  public boolean writesApplicationOutput() {
    return applicationOutput != null;
  }

  public byte[] applicationOutput() {
    if (applicationOutput == null) {
      throw new IllegalStateException("Scalar AOT program has no application output");
    }
    return applicationOutput.clone();
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
        || program.globals().isEmpty()
        || program.globals().size() > MAX_GLOBALS
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

  private static void validateFunction(
      Program program,
      FunctionBody function,
      boolean dynamicIo,
      boolean output) {
    boolean entry = function.id() == program.entryFunctionId();
    if (function.coherent()
        || entry && !validEntryParameters(function)
        || !entry && function.parameterCount() > MAX_PARAMETERS
        || function.localCount() == 0
        || function.localCount() > (entry && function.parameterCount() > 0
            ? MAX_OUTPUT_LOCALS : MAX_LOCALS)
        || function.localTypes().stream().anyMatch(type ->
            !type.equals(ValueType.SIGNED)
                && !type.equals(ValueType.BOOLEAN)
                && !(output && type.equals(ValueType.BYTES_BORROW))
                && !(dynamicIo && (type.equals(ValueType.BYTE_VIEW)
                    || type.equals(ValueType.UTF8_BORROW))))
        || function.implicitResultSlot()
        || !function.inverse().isEmpty()
        || function.forward().size() < 2
        || function.forward().size() > MAX_INSTRUCTIONS
        || entry && function.resultType() != null
        || !entry && function.resultType() != null
            && !function.resultType().equals(ValueType.SIGNED)) {
      throw new IllegalArgumentException("AOT function signature is outside the scalar profile");
    }

    int stores = 0;
    int last = function.forward().size() - 1;
    for (int pc = 0; pc < function.forward().size(); pc++) {
      Instruction instruction = function.forward().get(pc);
      switch (instruction.opcode()) {
        case NOP -> requireOperands(instruction, 0);
        case LOCAL_CONST, LOCAL_MOVE, BUFFER_BORROW, UTF8_BORROW ->
          validateUnary(function, instruction);
        case LOCAL_LOAD_GLOBAL -> validateGlobalLoad(program, function, instruction);
        case BUFFER_LENGTH -> validateInputLength(function, instruction, dynamicIo);
        case UTF8_VALID, UTF8_COUNT ->
          validateUtf8Whole(function, instruction, dynamicIo);
        case BYTES_GET -> validateInputRead(function, instruction, dynamicIo);
        case UTF8_SCALAR, UTF8_WIDTH ->
          validateInputRead(function, instruction, dynamicIo);
        case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR,
            LOCAL_ROTR32, LOCAL_EQ, LOCAL_LT -> validateBinary(function, instruction);
        case JUMP -> {
          requireOperands(instruction, 1);
          branchTarget(function, instruction.operands().get(0), pc, last);
        }
        case JUMP_IF_ZERO -> {
          requireOperands(instruction, 2);
          local(instruction.operands().get(0), function.localCount());
          branchTarget(function, instruction.operands().get(1), pc, last);
        }
        case LOCAL_LOOP_CHECK -> validateLoopCheck(function, instruction, pc);
        case BYTES_SET -> validateOutputWrite(function, instruction, output);
        case OUTPUT_LENGTH -> validateOutputLength(function, instruction, output);
        case EXPECT_TRUE -> {
          requireOperands(instruction, 1);
          int condition = local(instruction.operands().get(0), function.localCount());
          if (!function.localType(condition).equals(ValueType.BOOLEAN)) {
            throw new IllegalArgumentException("Scalar AOT assertion condition is not Boolean");
          }
        }
        case CALL_VALUE -> validateCall(program, function, instruction, true);
        case CALL_VOID -> validateCall(program, function, instruction, false);
        case LOCAL_STORE_GLOBAL -> {
          requireOperands(instruction, 2);
          int global = global(instruction.operands().get(0), program.globals().size());
          int source = local(instruction.operands().get(1), function.localCount());
          if (!function.localType(source).equals(ValueType.SIGNED)
              || global == 0 && !entry) {
            throw new IllegalArgumentException("Scalar AOT global store is invalid");
          }
          if (global == 0) {
            stores++;
          }
        }
        case RETURN -> {
          if (entry
              || function.resultType() != null
              || pc != last
              || !instruction.operands().isEmpty()) {
            throw new IllegalArgumentException("Scalar AOT void helper return is not terminal");
          }
        }
        case RETURN_VALUE -> {
          if (entry || function.resultType() == null || pc != last) {
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
        || !entry && function.resultType() == null && terminal != Opcode.RETURN
        || !entry && function.resultType() != null && terminal != Opcode.RETURN_VALUE) {
      throw new IllegalArgumentException("Scalar AOT function has no canonical terminal");
    }
  }

  private static boolean validEntryParameters(FunctionBody function) {
    return function.parameterCount() == 0
        || function.parameterCount() == 1
            && function.localType(0).equals(ValueType.BYTES_BORROW)
        || function.parameterCount() == 2
            && (function.localType(0).equals(ValueType.BYTE_VIEW)
                || function.localType(0).equals(ValueType.UTF8_BORROW))
            && function.localType(1).equals(ValueType.BYTES_BORROW);
  }

  private static void validateUnary(FunctionBody function, Instruction instruction) {
    requireOperands(instruction, 2);
    local(instruction.operands().get(0), function.localCount());
    if (instruction.opcode() == Opcode.LOCAL_MOVE
        || instruction.opcode() == Opcode.BUFFER_BORROW
        || instruction.opcode() == Opcode.UTF8_BORROW) {
      local(instruction.operands().get(1), function.localCount());
    }
  }

  private static void validateInputLength(
      FunctionBody function, Instruction instruction, boolean dynamicIo) {
    requireOperands(instruction, 2);
    int destination = local(instruction.operands().get(0), function.localCount());
    int source = local(instruction.operands().get(1), function.localCount());
    if (!dynamicIo
        || !function.localType(destination).equals(ValueType.SIGNED)
        || !(function.localType(source).equals(ValueType.BYTE_VIEW)
            || function.localType(source).equals(ValueType.UTF8_BORROW))) {
      throw new IllegalArgumentException("Scalar AOT input length is invalid");
    }
  }

  private static void validateUtf8Whole(
      FunctionBody function, Instruction instruction, boolean dynamicIo) {
    requireOperands(instruction, 2);
    int destination = local(instruction.operands().get(0), function.localCount());
    int source = local(instruction.operands().get(1), function.localCount());
    ValueType expected = instruction.opcode() == Opcode.UTF8_VALID
        ? ValueType.BOOLEAN : ValueType.SIGNED;
    if (!dynamicIo
        || !function.localType(destination).equals(expected)
        || !function.localType(source).equals(ValueType.UTF8_BORROW)) {
      throw new IllegalArgumentException("Scalar AOT UTF-8 analysis is invalid");
    }
  }

  private static void validateInputRead(
      FunctionBody function, Instruction instruction, boolean dynamicIo) {
    requireOperands(instruction, 3);
    int destination = local(instruction.operands().get(0), function.localCount());
    int owner = local(instruction.operands().get(1), function.localCount());
    int index = local(instruction.operands().get(2), function.localCount());
    ValueType expectedOwner = instruction.opcode() == Opcode.BYTES_GET
        ? ValueType.BYTE_VIEW : ValueType.UTF8_BORROW;
    if (!dynamicIo
        || !function.localType(destination).equals(ValueType.SIGNED)
        || !function.localType(owner).equals(expectedOwner)
        || !function.localType(index).equals(ValueType.SIGNED)) {
      throw new IllegalArgumentException("Scalar AOT input byte read is invalid");
    }
  }

  private static void validateOutputWrite(
      FunctionBody function, Instruction instruction, boolean output) {
    requireOperands(instruction, 3);
    int owner = local(instruction.operands().get(0), function.localCount());
    int index = local(instruction.operands().get(1), function.localCount());
    int value = local(instruction.operands().get(2), function.localCount());
    if (!output
        || !function.localType(owner).equals(ValueType.BYTES_BORROW)
        || !function.localType(index).equals(ValueType.SIGNED)
        || !function.localType(value).equals(ValueType.SIGNED)) {
      throw new IllegalArgumentException("Scalar AOT byte output write is invalid");
    }
  }

  private static void validateOutputLength(
      FunctionBody function, Instruction instruction, boolean output) {
    requireOperands(instruction, 2);
    int owner = local(instruction.operands().get(0), function.localCount());
    int length = local(instruction.operands().get(1), function.localCount());
    if (!output
        || !function.localType(owner).equals(ValueType.BYTES_BORROW)
        || !function.localType(length).equals(ValueType.SIGNED)) {
      throw new IllegalArgumentException("Scalar AOT output length is invalid");
    }
  }

  private static void validateGlobalLoad(
      Program program, FunctionBody function, Instruction instruction) {
    requireOperands(instruction, 2);
    int destination = local(instruction.operands().get(0), function.localCount());
    global(instruction.operands().get(1), program.globals().size());
    if (!function.localType(destination).equals(ValueType.SIGNED)) {
      throw new IllegalArgumentException("Scalar AOT global load is invalid");
    }
  }

  private static void validateBinary(FunctionBody function, Instruction instruction) {
    requireOperands(instruction, 3);
    local(instruction.operands().get(0), function.localCount());
    local(instruction.operands().get(1), function.localCount());
    local(instruction.operands().get(2), function.localCount());
  }

  private static void validateLoopCheck(
      FunctionBody function, Instruction instruction, int pc) {
    requireOperands(instruction, 2);
    int iteration = local(instruction.operands().get(0), function.localCount());
    int limit = local(instruction.operands().get(1), function.localCount());
    if (!function.localType(iteration).equals(ValueType.SIGNED)
        || !function.localType(limit).equals(ValueType.SIGNED)
        || iteration == limit) {
      throw new IllegalArgumentException("Scalar AOT loop locals are invalid");
    }
    int iterationConstants = 0;
    int limitConstants = 0;
    long limitValue = -1;
    for (int index = 0; index < function.forward().size(); index++) {
      Instruction candidate = function.forward().get(index);
      int written = writtenLocal(candidate);
      if (written == iteration) {
        if (candidate.opcode() == Opcode.LOCAL_CONST
            && index < pc
            && candidate.operands().get(1) == 0) {
          iterationConstants++;
        } else if (candidate.opcode() != Opcode.LOCAL_LOOP_CHECK) {
          throw new IllegalArgumentException("Scalar AOT loop counter is not stable");
        }
      }
      if (written == limit) {
        if (candidate.opcode() == Opcode.LOCAL_CONST && index < pc) {
          limitConstants++;
          limitValue = candidate.operands().get(1);
        } else {
          throw new IllegalArgumentException("Scalar AOT loop limit is not stable");
        }
      }
    }
    if (iterationConstants != 1
        || limitConstants != 1
        || limitValue < 1
        || limitValue > MAX_LOOP_ITERATIONS) {
      throw new IllegalArgumentException("Scalar AOT loop bound is outside 1 through 4096");
    }
  }

  private static int writtenLocal(Instruction instruction) {
    return switch (instruction.opcode()) {
      case LOCAL_CONST, LOCAL_LOAD_GLOBAL, LOCAL_MOVE, BUFFER_BORROW, UTF8_BORROW,
          BUFFER_LENGTH, BYTES_GET, UTF8_VALID, UTF8_COUNT, UTF8_SCALAR, UTF8_WIDTH,
          LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR,
          LOCAL_ROTR32, LOCAL_EQ, LOCAL_LT, LOCAL_LOOP_CHECK ->
          Math.toIntExact(instruction.operands().get(0));
      case CALL_VALUE -> Math.toIntExact(instruction.operands().get(3));
      default -> -1;
    };
  }

  private static void validateCall(
      Program program,
      FunctionBody owner,
      Instruction instruction,
      boolean returnsValue) {
    requireOperands(instruction, returnsValue ? 4 : 3);
    int target = Math.toIntExact(instruction.operands().get(0));
    int argumentBase = Math.toIntExact(instruction.operands().get(1));
    int argumentCount = Math.toIntExact(instruction.operands().get(2));
    if (target < 0 || target >= program.entryFunctionId()) {
      throw new IllegalArgumentException("Scalar AOT call target is not a helper");
    }
    FunctionBody callee = program.function(target);
    if (argumentCount != callee.parameterCount()
        || argumentBase < 0
        || argumentBase > owner.localCount() - argumentCount
        || returnsValue != (callee.resultType() != null)
        || returnsValue && !callee.resultType().equals(ValueType.SIGNED)) {
      throw new IllegalArgumentException("Scalar AOT call signature does not match its helper");
    }
    for (int parameter = 0; parameter < argumentCount; parameter++) {
      if (!owner.localType(argumentBase + parameter).equals(callee.localType(parameter))) {
        throw new IllegalArgumentException("Scalar AOT call argument type does not match");
      }
    }
    if (returnsValue) {
      int destination = local(instruction.operands().get(3), owner.localCount());
      if (!owner.localType(destination).equals(ValueType.SIGNED)) {
        throw new IllegalArgumentException("Scalar AOT call destination is not signed");
      }
    }
  }

  private static void validateCallGraph(Program program) {
    int[] states = new int[program.functions().size()];
    for (FunctionBody function : program.functions()) {
      validateCallGraph(program, function.id(), states);
    }
  }

  private static void validateCallGraph(Program program, int functionId, int[] states) {
    if (states[functionId] == 2) {
      return;
    }
    if (states[functionId] == 1) {
      throw new IllegalArgumentException("Scalar AOT call graph contains a cycle");
    }

    states[functionId] = 1;
    for (Instruction instruction : program.function(functionId).forward()) {
      if (instruction.opcode() == Opcode.CALL_VALUE
          || instruction.opcode() == Opcode.CALL_VOID) {
        validateCallGraph(
            program,
            Math.toIntExact(instruction.operands().get(0)),
            states);
      }
    }
    states[functionId] = 2;
  }

  private static Evaluation evaluate(
      Program program,
      int functionId,
      long[] arguments,
      OutputState output,
      EvaluationState state,
      EvaluationBudget budget) {
    FunctionBody function = program.function(functionId);
    long[] values = new long[function.localCount()];
    boolean[] assigned = new boolean[function.localCount()];
    System.arraycopy(arguments, 0, values, 0, arguments.length);
    java.util.Arrays.fill(assigned, 0, arguments.length, true);
    int pc = 0;
    while (pc < function.forward().size()) {
      budget.consume();
      Instruction instruction = function.forward().get(pc);
      try {
        switch (instruction.opcode()) {
          case LOCAL_CONST -> {
            int destination = destination(instruction, 0, assigned);
            values[destination] = instruction.operands().get(1);
            assigned[destination] = true;
            pc++;
          }
          case NOP -> pc++;
          case LOCAL_LOAD_GLOBAL -> {
            int destination = destination(instruction, 0, assigned);
            int source = Math.toIntExact(instruction.operands().get(1));
            values[destination] = state.globals[source];
            assigned[destination] = true;
            pc++;
          }
          case LOCAL_MOVE, BUFFER_BORROW, UTF8_BORROW -> {
            int destination = destination(instruction, 0, assigned);
            int source = assignedLocal(instruction, 1, assigned);
            values[destination] = values[source];
            assigned[destination] = true;
            pc++;
          }
          case LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR,
              LOCAL_ROTR32, LOCAL_EQ, LOCAL_LT -> {
            int destination = destination(instruction, 0, assigned);
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
          case LOCAL_LOOP_CHECK -> {
            int iteration = assignedLocal(instruction, 0, assigned);
            int limit = assignedLocal(instruction, 1, assigned);
            if (values[iteration] < 0
                || values[limit] < 0
                || values[iteration] >= values[limit]
                || values[limit] > MAX_LOOP_ITERATIONS) {
              throw new ArithmeticException("Loop iteration limit exceeded");
            }
            values[iteration] = Math.addExact(values[iteration], 1);
            pc++;
          }
          case BYTES_SET -> {
            int owner = assignedLocal(instruction, 0, assigned);
            int index = assignedLocal(instruction, 1, assigned);
            int value = assignedLocal(instruction, 2, assigned);
            if (values[owner] != 1
                || values[index] < 0
                || values[index] >= MAX_OUTPUT_BYTES
                || values[value] < 0
                || values[value] > 255) {
              throw new ArithmeticException("Scalar AOT byte output write is out of range");
            }
            output.bytes[Math.toIntExact(values[index])] = (byte) values[value];
            pc++;
          }
          case OUTPUT_LENGTH -> {
            int owner = assignedLocal(instruction, 0, assigned);
            int length = assignedLocal(instruction, 1, assigned);
            if (values[owner] != 1
                || values[length] < 1
                || values[length] > MAX_OUTPUT_BYTES
                || output.length >= 0) {
              throw new ArithmeticException("Scalar AOT output length is invalid");
            }
            output.length = Math.toIntExact(values[length]);
            pc++;
          }
          case EXPECT_TRUE -> {
            if (values[assignedLocal(instruction, 0, assigned)] == 0) {
              throw new ArithmeticException("Scalar AOT assertion failed");
            }
            pc++;
          }
          case CALL_VALUE, CALL_VOID -> {
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
                callArguments,
                output,
                state,
                budget);
            if (instruction.opcode() == Opcode.CALL_VALUE) {
              int destination = destination(instruction, 3, assigned);
              values[destination] = result.value();
              assigned[destination] = true;
            }
            pc++;
          }
          case LOCAL_STORE_GLOBAL -> {
            int destination = Math.toIntExact(instruction.operands().get(0));
            state.globals[destination] = values[assignedLocal(instruction, 1, assigned)];
            if (destination == 0) {
              state.statusStored = true;
            }
            pc++;
          }
          case RETURN -> {
            return new Evaluation(0, false);
          }
          case RETURN_VALUE -> {
            return new Evaluation(
                values[assignedLocal(instruction, 0, assigned)], false);
          }
          case HALT -> {
            return new Evaluation(state.globals[0], state.statusStored);
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
      case LOCAL_ROTR32 -> {
        if (right < 0 || right > 31) {
          throw new ArithmeticException("32-bit rotate amount is out of range");
        }
        yield Integer.toUnsignedLong(Integer.rotateRight((int) left, Math.toIntExact(right)));
      }
      case LOCAL_EQ -> left == right ? 1 : 0;
      case LOCAL_LT -> left < right ? 1 : 0;
      default -> throw new IllegalStateException("Validated scalar AOT arithmetic changed");
    };
  }

  private static int destination(
      Instruction instruction, int operand, boolean[] assigned) {
    return local(instruction.operands().get(operand), assigned.length);
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

  private static int global(long value, int count) {
    int result = Math.toIntExact(value);
    if (result < 0 || result >= count) {
      throw new IllegalArgumentException("Scalar AOT global is out of range");
    }
    return result;
  }

  private static void branchTarget(
      FunctionBody function, long value, int pc, int last) {
    int target = Math.toIntExact(value);
    if (target < 0 || target > last || target == pc) {
      throw new IllegalArgumentException("Scalar AOT branch target is not bounded");
    }
    if (target < pc
        && function.forward().subList(target, pc).stream()
            .noneMatch(candidate -> candidate.opcode() == Opcode.LOCAL_LOOP_CHECK)) {
      throw new IllegalArgumentException("Scalar AOT backward branch has no loop check");
    }
  }

  private static void requireOperands(Instruction instruction, int count) {
    if (instruction.operands().size() != count) {
      throw new IllegalArgumentException("Scalar AOT operand count changed");
    }
  }

  private record Evaluation(long value, boolean stored) {}

  private static final class EvaluationState {
    private final long[] globals;
    private boolean statusStored;

    EvaluationState(Program program) {
      globals = program.globals().stream()
          .mapToLong(global -> global.initialValue())
          .toArray();
    }
  }

  private static final class EvaluationBudget {
    private int remaining = MAX_EXECUTED_INSTRUCTIONS;

    void consume() {
      if (remaining-- == 0) {
        throw new IllegalArgumentException("Scalar AOT execution bound exceeded");
      }
    }
  }

  private static final class OutputState {
    private final byte[] bytes = new byte[MAX_OUTPUT_BYTES];
    private int length = -1;
  }
}
