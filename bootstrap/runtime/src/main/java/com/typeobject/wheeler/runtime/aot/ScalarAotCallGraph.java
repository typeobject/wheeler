package com.typeobject.wheeler.runtime.aot;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.List;

/** Closed call-graph analyses used before scalar machine publication. */
final class ScalarAotCallGraph {
  private ScalarAotCallGraph() {}

  static boolean hasReachableStatusWriter(Program program) {
    boolean[][] visited = new boolean[program.functions().size()][2];
    return reachesStatusWriter(program, program.entryFunctionId(), false, visited);
  }

  private static boolean reachesStatusWriter(
      Program program,
      int functionId,
      boolean inverse,
      boolean[][] visited) {
    int direction = inverse ? 1 : 0;
    if (visited[functionId][direction]) {
      return false;
    }
    visited[functionId][direction] = true;
    for (Instruction instruction : program.function(functionId).body(inverse)) {
      if (writesStatus(instruction)) {
        return true;
      }
      if (isCall(instruction.opcode())) {
        int target = Math.toIntExact(instruction.operands().getFirst());
        boolean targetInverse = instruction.opcode() == Opcode.UNCALL
            || instruction.opcode() == Opcode.UNCALL_RESULT_SLOT;
        if (reachesStatusWriter(program, target, targetInverse, visited)) {
          return true;
        }
      }
    }
    return false;
  }

  private static boolean writesStatus(Instruction instruction) {
    return switch (instruction.opcode()) {
      case ADD_CONST, SUB_CONST, XOR_CONST, SET_LOGGED, LOCAL_STORE_GLOBAL ->
        instruction.operands().getFirst() == 0;
      case SWAP -> instruction.operands().getFirst() == 0 || instruction.operands().get(1) == 0;
      default -> false;
    };
  }

  static boolean hasRecursiveCalls(Program program) {
    int[] states = new int[program.functions().size()];
    boolean recursive = false;
    for (FunctionBody function : program.functions()) {
      recursive = visitCalls(program, function.id(), states) || recursive;
    }
    return recursive;
  }

  private static boolean visitCalls(Program program, int functionId, int[] states) {
    if (states[functionId] == 2) {
      return false;
    }
    if (states[functionId] == 1) {
      return true;
    }

    states[functionId] = 1;
    boolean recursive = false;
    FunctionBody function = program.function(functionId);
    for (List<Instruction> body : List.of(function.forward(), function.inverse())) {
      for (Instruction instruction : body) {
        if (isCall(instruction.opcode())) {
          recursive = visitCalls(
              program,
              Math.toIntExact(instruction.operands().getFirst()),
              states) || recursive;
        }
      }
    }
    states[functionId] = 2;
    return recursive;
  }

  private static boolean isCall(Opcode opcode) {
    return opcode == Opcode.CALL
        || opcode == Opcode.UNCALL
        || opcode == Opcode.CALL_VALUE
        || opcode == Opcode.CALL_VOID
        || opcode == Opcode.CALL_RESULT_SLOT
        || opcode == Opcode.UNCALL_RESULT_SLOT;
  }
}
