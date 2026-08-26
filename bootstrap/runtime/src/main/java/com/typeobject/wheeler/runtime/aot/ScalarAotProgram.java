package com.typeobject.wheeler.runtime.aot;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.bytecode.ResultBinaryOperation;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.List;

/** Closed semantic profile accepted by the x86-64 scalar AOT leaf. */
public final class ScalarAotProgram {
  public static final int MAX_FUNCTIONS = 24;
  public static final int MAX_GLOBALS = 32;
  public static final int MAX_PARAMETERS = 16;
  public static final int MAX_LOCALS = 256;
  public static final int MAX_OUTPUT_LOCALS = 64;
  public static final int MAX_INSTRUCTIONS = 512;
  public static final int MAX_LOOP_ITERATIONS = 4096;
  public static final int MAX_INPUT_BYTES = 4096;
  public static final int MAX_OUTPUT_BYTES = 4096;
  public static final int MAX_EXECUTED_INSTRUCTIONS = 65_536;
  public static final int MAX_CALL_DEPTH = 64;

  private final Program program;
  private final Integer processStatus;
  private final byte[] applicationOutput;
  private final boolean dynamicApplicationIo;
  private final boolean boundedRecursion;

  private ScalarAotProgram(
      Program program,
      Integer processStatus,
      byte[] applicationOutput,
      boolean dynamicApplicationIo,
      boolean boundedRecursion) {
    this.program = program;
    this.processStatus = processStatus;
    this.applicationOutput = applicationOutput == null ? null : applicationOutput.clone();
    this.dynamicApplicationIo = dynamicApplicationIo;
    this.boundedRecursion = boundedRecursion;
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
    if (!ScalarAotCallGraph.hasReachableStatusWriter(program)) {
      throw new IllegalArgumentException("Scalar AOT entry cannot publish process status");
    }
    boolean boundedRecursion = ScalarAotCallGraph.hasRecursiveCalls(program);
    if (entry.parameterCount() == 2) {
      return new ScalarAotProgram(program, null, null, true, boundedRecursion);
    }
    long[] arguments = entry.parameterCount() == 0 ? new long[0] : new long[] {1};
    ScalarAotEvaluator.Result evaluation = ScalarAotEvaluator.evaluate(program, arguments);
    if (!evaluation.stored()
        || evaluation.status() < 0
        || evaluation.status() > 124) {
      throw new IllegalArgumentException("AOT process status must be between 0 and 124");
    }
    byte[] applicationOutput = evaluation.applicationOutput();
    if (entry.parameterCount() == 1 && applicationOutput == null) {
      throw new IllegalArgumentException("Scalar AOT output length was not committed");
    }
    return new ScalarAotProgram(
        program,
        Math.toIntExact(evaluation.status()),
        applicationOutput,
        false,
        boundedRecursion);
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

  public boolean usesBoundedRecursion() {
    return boundedRecursion;
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
        || function.forward().size() < 2
        || function.forward().size() > MAX_INSTRUCTIONS
        || function.inverse().size() > MAX_INSTRUCTIONS
        || !function.inverse().isEmpty()
            && (entry || !function.implicitResultSlot()
                && (function.parameterCount() != 0 || function.resultType() != null))
        || entry && function.resultType() != null
        || !entry && function.resultType() != null
            && !function.resultType().equals(ValueType.SIGNED)
            && !function.resultType().equals(ValueType.BOOLEAN)) {
      throw new IllegalArgumentException("AOT function signature is outside the scalar profile");
    }

    if (function.implicitResultSlot()
        && (function.forward().size() != 2
            || function.inverse().size() != 2
            || !function.forward().getFirst().equals(function.inverse().getFirst()))) {
      throw new IllegalArgumentException("Scalar AOT result-slot relation is not exact");
    }
    validateBody(program, function, function.forward(), entry, dynamicIo, output);
    if (!function.inverse().isEmpty()) {
      validateBody(program, function, function.inverse(), false, dynamicIo, output);
    }
  }

  private static void validateBody(
      Program program,
      FunctionBody function,
      List<Instruction> body,
      boolean entry,
      boolean dynamicIo,
      boolean output) {
    if (body.size() < 2 || body.size() > MAX_INSTRUCTIONS) {
      throw new IllegalArgumentException("Scalar AOT function body is outside the profile");
    }
    int last = body.size() - 1;
    for (int pc = 0; pc < body.size(); pc++) {
      Instruction instruction = body.get(pc);
      switch (instruction.opcode()) {
        case NOP, CHECKPOINT, COMMIT -> requireOperands(instruction, 0);
        case LOCAL_CONST, LOCAL_MOVE, BUFFER_BORROW, UTF8_BORROW ->
          validateUnary(function, instruction);
        case LOCAL_LOAD_GLOBAL -> validateGlobalLoad(program, function, instruction);
        case ADD_CONST, SUB_CONST, XOR_CONST, SET_LOGGED ->
          validateGlobalInstruction(program, instruction);
        case SWAP -> {
          requireOperands(instruction, 2);
          global(instruction.operands().get(0), program.globals().size());
          global(instruction.operands().get(1), program.globals().size());
        }
        case EXPECT_EQ -> validateGlobalInstruction(program, instruction);
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
        case CALL, UNCALL -> validateDirectionalCall(program, instruction);
        case CALL_RESULT_SLOT, UNCALL_RESULT_SLOT ->
          validateResultSlotCall(program, function, instruction);
        case RESULT_FILL_CONSTANT, RESULT_FILL_SOURCE, RESULT_FILL_BINARY,
            RESULT_FILL_BINARY_SOURCES -> validateResultFill(function, instruction);
        case LOCAL_STORE_GLOBAL -> {
          requireOperands(instruction, 2);
          global(instruction.operands().get(0), program.globals().size());
          int source = local(instruction.operands().get(1), function.localCount());
          if (!function.localType(source).equals(ValueType.SIGNED)) {
            throw new IllegalArgumentException("Scalar AOT global store is invalid");
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
          if (entry
              || function.resultType() == null
              || function.implicitResultSlot()
              || pc != last) {
            throw new IllegalArgumentException("Scalar AOT helper return is not terminal");
          }
          requireOperands(instruction, 1);
          int result = local(instruction.operands().getFirst(), function.localCount());
          if (!function.localType(result).equals(function.resultType())) {
            throw new IllegalArgumentException("Scalar AOT helper result type changed");
          }
        }
        case RETURN_RESULT_SLOT -> validateResultSlotReturn(function, instruction, pc, last);
        case HALT -> {
          if (!entry || pc != last || !instruction.operands().isEmpty()) {
            throw new IllegalArgumentException("Scalar AOT halt is not the entry terminal");
          }
        }
        default -> throw new IllegalArgumentException(
            "Unsupported scalar AOT opcode " + instruction.opcode());
      }
    }
    Opcode terminal = body.getLast().opcode();
    if (entry && terminal != Opcode.HALT
        || !entry && function.resultType() == null && terminal != Opcode.RETURN
        || !entry && function.implicitResultSlot() && terminal != Opcode.RETURN_RESULT_SLOT
        || !entry && function.resultType() != null && !function.implicitResultSlot()
            && terminal != Opcode.RETURN_VALUE) {
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

  private static void validateGlobalInstruction(
      Program program, Instruction instruction) {
    requireOperands(instruction, 2);
    global(instruction.operands().get(0), program.globals().size());
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
      if (writesLocal(candidate, iteration)) {
        if (candidate.opcode() == Opcode.LOCAL_CONST
            && index < pc
            && candidate.operands().get(1) == 0) {
          iterationConstants++;
        } else if (candidate.opcode() != Opcode.LOCAL_LOOP_CHECK) {
          throw new IllegalArgumentException("Scalar AOT loop counter is not stable");
        }
      }
      if (writesLocal(candidate, limit)) {
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

  private static boolean writesLocal(Instruction instruction, int local) {
    return switch (instruction.opcode()) {
      case LOCAL_CONST, LOCAL_LOAD_GLOBAL, LOCAL_MOVE, BUFFER_BORROW, UTF8_BORROW,
          BUFFER_LENGTH, BYTES_GET, UTF8_VALID, UTF8_COUNT, UTF8_SCALAR, UTF8_WIDTH,
          LOCAL_ADD, LOCAL_SUB, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_XOR,
          LOCAL_ROTR32, LOCAL_EQ, LOCAL_LT, LOCAL_LOOP_CHECK ->
        instruction.operands().getFirst() == local;
      case CALL_VALUE -> instruction.operands().get(3) == local;
      case CALL_RESULT_SLOT, UNCALL_RESULT_SLOT ->
        instruction.operands().get(3) == local || instruction.operands().get(3) + 1 == local;
      default -> false;
    };
  }

  private static void validateDirectionalCall(
      Program program, Instruction instruction) {
    requireOperands(instruction, 1);
    int target = Math.toIntExact(instruction.operands().get(0));
    if (target < 0 || target >= program.entryFunctionId()) {
      throw new IllegalArgumentException("Scalar AOT directional call target is not a helper");
    }
    FunctionBody callee = program.function(target);
    if (callee.parameterCount() != 0
        || callee.resultType() != null
        || instruction.opcode() == Opcode.UNCALL && callee.inverse().isEmpty()) {
      throw new IllegalArgumentException("Scalar AOT directional call signature is invalid");
    }
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
        || callee.implicitResultSlot()
        || returnsValue != (callee.resultType() != null)) {
      throw new IllegalArgumentException("Scalar AOT call signature does not match its helper");
    }
    for (int parameter = 0; parameter < argumentCount; parameter++) {
      if (!owner.localType(argumentBase + parameter).equals(callee.localType(parameter))) {
        throw new IllegalArgumentException("Scalar AOT call argument type does not match");
      }
    }
    if (returnsValue) {
      int destination = local(instruction.operands().get(3), owner.localCount());
      if (!owner.localType(destination).equals(callee.resultType())) {
        throw new IllegalArgumentException("Scalar AOT call destination type does not match");
      }
    }
  }

  private static void validateResultSlotCall(
      Program program, FunctionBody owner, Instruction instruction) {
    requireOperands(instruction, 4);
    int target = Math.toIntExact(instruction.operands().getFirst());
    int argumentBase = Math.toIntExact(instruction.operands().get(1));
    int argumentCount = Math.toIntExact(instruction.operands().get(2));
    int slot = local(instruction.operands().get(3), owner.localCount());
    if (target < 0 || target >= program.entryFunctionId()) {
      throw new IllegalArgumentException("Scalar AOT result-slot target is not a helper");
    }
    FunctionBody callee = program.function(target);
    int argumentEnd = Math.addExact(argumentBase, argumentCount);
    boolean overlaps = argumentCount > 0 && argumentBase < slot + 2 && slot < argumentEnd;
    if (!callee.implicitResultSlot()
        || argumentCount != callee.parameterCount()
        || argumentBase < 0
        || argumentEnd > owner.localCount()
        || slot + 1 >= owner.localCount()
        || overlaps
        || !owner.localType(slot).equals(ValueType.BOOLEAN)
        || !owner.localType(slot + 1).equals(callee.resultType())) {
      throw new IllegalArgumentException("Scalar AOT result-slot call signature is invalid");
    }
    for (int parameter = 0; parameter < argumentCount; parameter++) {
      if (!owner.localType(argumentBase + parameter).equals(callee.localType(parameter))) {
        throw new IllegalArgumentException("Scalar AOT result-slot argument type changed");
      }
    }
  }

  private static void validateResultFill(
      FunctionBody function, Instruction instruction) {
    int operandCount = switch (instruction.opcode()) {
      case RESULT_FILL_CONSTANT, RESULT_FILL_SOURCE -> 2;
      case RESULT_FILL_BINARY, RESULT_FILL_BINARY_SOURCES -> 4;
      default -> throw new IllegalStateException("Scalar AOT result fill changed");
    };
    requireOperands(instruction, operandCount);
    int slot = local(instruction.operands().getFirst(), function.localCount());
    if (!function.implicitResultSlot() || slot != function.resultSlotBase()) {
      throw new IllegalArgumentException("Scalar AOT result fill has no matching slot");
    }
    if (instruction.opcode() == Opcode.RESULT_FILL_CONSTANT) {
      long value = instruction.operands().get(1);
      if (function.resultType().equals(ValueType.BOOLEAN) && value != 0 && value != 1) {
        throw new IllegalArgumentException("Scalar AOT Boolean result constant is invalid");
      }
      return;
    }
    int source = local(instruction.operands().get(1), function.parameterCount());
    if (!function.localType(source).equals(function.resultType())) {
      throw new IllegalArgumentException("Scalar AOT result source type changed");
    }
    if (instruction.opcode() == Opcode.RESULT_FILL_BINARY
        || instruction.opcode() == Opcode.RESULT_FILL_BINARY_SOURCES) {
      long operation = instruction.operands().get(2);
      if (!function.resultType().equals(ValueType.SIGNED)
          || !ResultBinaryOperation.supported(operation)) {
        throw new IllegalArgumentException("Scalar AOT result operation is invalid");
      }
      if (instruction.opcode() == Opcode.RESULT_FILL_BINARY_SOURCES) {
        int right = local(instruction.operands().get(3), function.parameterCount());
        if (!function.localType(right).equals(function.resultType())) {
          throw new IllegalArgumentException("Scalar AOT right result source type changed");
        }
      }
    }
  }

  private static void validateResultSlotReturn(
      FunctionBody function, Instruction instruction, int pc, int last) {
    requireOperands(instruction, 1);
    int slot = local(instruction.operands().getFirst(), function.localCount());
    if (!function.implicitResultSlot() || slot != function.resultSlotBase() || pc != last) {
      throw new IllegalArgumentException("Scalar AOT result-slot return is invalid");
    }
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

}
