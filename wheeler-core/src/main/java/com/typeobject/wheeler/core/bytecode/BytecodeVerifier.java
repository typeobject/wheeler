package com.typeobject.wheeler.core.bytecode;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Structural and semantic verification for decoded version-1 programs. */
public final class BytecodeVerifier {
  private BytecodeVerifier() {}

  public static void verify(Program program) {
    if (program.name().isBlank()) {
      fail("Program name must not be blank");
    }
    if (program.maxHistoryRecords() <= 0 || program.maxHistoryRecords() > 10_000_000) {
      fail("Invalid history record limit");
    }
    if (program.maxSteps() <= 0 || program.maxSteps() > 1_000_000_000L) {
      fail("Invalid step limit");
    }
    if (program.globals().size() > 65_535 || program.functions().size() > 65_535) {
      fail("Program exceeds version-1 table limits");
    }

    Set<String> globalNames = new HashSet<>();
    for (Global global : program.globals()) {
      if (!globalNames.add(global.name())) {
        fail("Duplicate global name: " + global.name());
      }
    }

    Set<String> functionNames = new HashSet<>();
    for (FunctionBody function : program.functions()) {
      if (!functionNames.add(function.name())) {
        fail("Duplicate function name: " + function.name());
      }
      verifyBody(program, function, function.forward(), false);
      if (function.reversible()) {
        verifyBody(program, function, function.inverse(), true);
      }
    }

    FunctionBody entry = program.function(program.entryFunctionId());
    if (entry.forward().stream().noneMatch(instruction -> instruction.opcode() == Opcode.HALT)) {
      fail("Entry function must contain HALT");
    }
  }

  private static void verifyBody(
      Program program, FunctionBody owner, List<Instruction> body, boolean inverseBody) {
    if (body.isEmpty()) {
      fail("Function body must not be empty: " + owner.name());
    }
    for (int pc = 0; pc < body.size(); pc++) {
      Instruction instruction = body.get(pc);
      verifyInstruction(program, owner, instruction, pc, inverseBody);
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
