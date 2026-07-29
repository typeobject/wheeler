package com.typeobject.wheeler.core.bytecode;

import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_BASE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_COUNT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.DESTINATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.FUNCTION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.SOURCE;

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
      int destination = Math.toIntExact(borrow.operand(DESTINATION));
      int callPc = nextCall(body, pc);
      if (callPc < 0) {
        fail(owner, borrow, SOURCE, pc, "borrow is not a transient call argument");
      }
      Instruction call = body.get(callPc);
      int base = Math.toIntExact(call.operand(ARGUMENT_BASE));
      int count = Math.toIntExact(call.operand(ARGUMENT_COUNT));
      int parameter = destination - base;
      FunctionBody target = program.function(Math.toIntExact(call.operand(FUNCTION)));
      ValueType expected = borrow.opcode() == Opcode.UTF8_BORROW
          ? ValueType.UTF8_BORROW
          : borrow.opcode() == Opcode.MAP_BORROW
              ? ValueType.LONG_MAP_BORROW
              : borrow.opcode() == Opcode.REGION_BORROW
                  ? ValueType.REGION_BORROW
                  : owner.localType(destination);
      if (parameter < 0 || parameter >= count
          || !target.localType(parameter).equals(expected)) {
        fail(owner, borrow, DESTINATION, pc, "borrow targets a nonborrowed argument");
      }
      boolean immutable = borrow.opcode() == Opcode.UTF8_BORROW
          || owner.localType(destination).equals(ValueType.BYTE_VIEW);
      if (!immutable
          && !mutableSources.computeIfAbsent(callPc, ignored -> new HashSet<>())
              .add(borrow.operand(SOURCE))) {
        fail(
            owner, borrow, SOURCE, pc,
            "one storage owner aliases multiple mutable parameters");
      }
    }
  }

  private static int nextCall(List<Instruction> body, int pc) {
    for (int next = pc + 1; next < body.size(); next++) {
      Opcode opcode = body.get(next).opcode();
      if (opcode == Opcode.CALL_VALUE || opcode == Opcode.CALL_VOID
          || opcode == Opcode.CALL_RESULT_SLOT || opcode == Opcode.UNCALL_RESULT_SLOT) {
        return next;
      }
      if (opcode != Opcode.LOCAL_MOVE && opcode != Opcode.OWNED_MOVE && !isBorrow(opcode)) {
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

  private static void fail(
      FunctionBody owner,
      Instruction instruction,
      InstructionForm.OperandRole role,
      int pc,
      String message) {
    InstructionOperandVerifier.failOperand(owner, instruction, role, pc, message);
  }
}
