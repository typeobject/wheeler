package com.typeobject.wheeler.core.bytecode;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Structural lifetime and alias checks for transient call-argument borrows. */
final class BorrowWindowVerifier {
  private BorrowWindowVerifier() {}

  static void verify(Program program, FunctionBody owner, List<Instruction> body) {
    Map<Integer, Set<Long>> mutableSources = new HashMap<>();
    for (int pc = 0; pc < body.size(); pc++) {
      Instruction borrow = body.get(pc);
      if (!isBorrow(borrow.opcode())) {
        continue;
      }
      int destination = Math.toIntExact(borrow.operands().getFirst());
      int callPc = nextCall(body, pc);
      if (callPc < 0) {
        fail(owner, pc, "borrow is not a transient call argument");
      }
      Instruction call = body.get(callPc);
      int base = Math.toIntExact(call.operands().get(1));
      int count = Math.toIntExact(call.operands().get(2));
      int parameter = destination - base;
      FunctionBody target = program.function(Math.toIntExact(call.operands().get(0)));
      ValueType expected = borrow.opcode() == Opcode.UTF8_BORROW
          ? ValueType.UTF8_BORROW
          : borrow.opcode() == Opcode.MAP_BORROW
              ? ValueType.LONG_MAP_BORROW
              : borrow.opcode() == Opcode.REGION_BORROW
                  ? ValueType.REGION_BORROW
                  : owner.localType(destination);
      if (parameter < 0 || parameter >= count
          || !target.localType(parameter).equals(expected)) {
        fail(owner, pc, "borrow targets a nonborrowed argument");
      }
      if (borrow.opcode() != Opcode.UTF8_BORROW
          && !mutableSources.computeIfAbsent(callPc, ignored -> new HashSet<>())
              .add(borrow.operands().get(1))) {
        fail(owner, pc, "one storage owner aliases multiple mutable parameters");
      }
    }
  }

  private static int nextCall(List<Instruction> body, int pc) {
    for (int next = pc + 1; next < body.size(); next++) {
      Opcode opcode = body.get(next).opcode();
      if (opcode == Opcode.CALL_VALUE || opcode == Opcode.CALL_VOID) {
        return next;
      }
      if (opcode != Opcode.LOCAL_MOVE && !isBorrow(opcode)) {
        return -1;
      }
    }
    return -1;
  }

  private static boolean isBorrow(Opcode opcode) {
    return opcode == Opcode.UTF8_BORROW
        || opcode == Opcode.MAP_BORROW
        || opcode == Opcode.BUFFER_BORROW
        || opcode == Opcode.REGION_BORROW;
  }

  private static void fail(FunctionBody owner, int pc, String message) {
    throw new BytecodeException(owner.name() + "[" + pc + "] " + message);
  }
}
