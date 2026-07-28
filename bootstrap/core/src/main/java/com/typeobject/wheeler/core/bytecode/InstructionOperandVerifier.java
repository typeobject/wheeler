package com.typeobject.wheeler.core.bytecode;

import java.util.List;

/** Shared role-aware validation and diagnostics for classical instruction operands. */
final class InstructionOperandVerifier {
  private InstructionOperandVerifier() {}

  static int verifyLocal(
      FunctionBody owner,
      Instruction instruction,
      InstructionForm.OperandRole role,
      int pc) {
    long operand = instruction.operand(role);
    if (operand < 0 || operand >= owner.localCount()) {
      failOperand(owner, instruction, role, pc, "local index outside the frame: " + operand);
    }
    return Math.toIntExact(operand);
  }

  static void requireType(
      FunctionBody owner,
      Instruction instruction,
      int local,
      InstructionForm.OperandRole role,
      ValueType expected,
      int pc) {
    if (!owner.localType(local).equals(expected)) {
      failOperand(
          owner,
          instruction,
          role,
          pc,
          "local " + local + " must have type " + expected.displayName());
    }
  }

  static void requireSameType(
      FunctionBody owner,
      Instruction instruction,
      int left,
      InstructionForm.OperandRole leftRole,
      int right,
      InstructionForm.OperandRole rightRole,
      int pc) {
    if (!owner.localType(left).equals(owner.localType(right))) {
      failOperand(
          owner,
          instruction,
          rightRole,
          pc,
          "local " + right + " must match " + leftRole.label()
              + " local " + left);
    }
  }

  static void verifyJump(
      FunctionBody owner,
      Instruction instruction,
      InstructionForm.OperandRole role,
      int pc,
      List<Instruction> body) {
    long operand = instruction.operand(role);
    if (operand < 0 || operand >= body.size()) {
      failOperand(owner, instruction, role, pc, "instruction index outside the body: " + operand);
    }
  }

  static void verifyGlobal(
      Program program,
      Instruction instruction,
      InstructionForm.OperandRole role,
      FunctionBody owner,
      int pc) {
    long operand = instruction.operand(role);
    if (operand < 0 || operand >= program.globals().size()) {
      failOperand(owner, instruction, role, pc, "global index outside the table: " + operand);
    }
  }

  static LocalWindow verifyLocalWindow(
      FunctionBody owner,
      Instruction instruction,
      InstructionForm.OperandRole baseRole,
      InstructionForm.OperandRole countRole,
      int pc) {
    long count = instruction.operand(countRole);
    if (count < 0 || count > owner.localCount()) {
      failOperand(
          owner, instruction, countRole, pc,
          "local window count is outside the frame: " + count);
    }
    long base = instruction.operand(baseRole);
    if (base < 0 || base > owner.localCount() - count) {
      failOperand(
          owner, instruction, baseRole, pc,
          "local window starts outside the frame: " + base);
    }
    return new LocalWindow(Math.toIntExact(base), Math.toIntExact(count));
  }

  static int verifyReference(
      FunctionBody owner,
      Instruction instruction,
      InstructionForm.OperandRole role,
      int pc,
      int size,
      String registry) {
    long operand = instruction.operand(role);
    if (operand < 0 || operand >= size) {
      failOperand(
          owner,
          instruction,
          role,
          pc,
          registry + " ID outside the registry: " + operand);
    }
    return Math.toIntExact(operand);
  }

  record LocalWindow(int base, int count) {}

  static void failOperand(
      FunctionBody owner,
      Instruction instruction,
      InstructionForm.OperandRole role,
      int pc,
      String message) {
    throw new BytecodeException(
        owner.name() + "[" + pc + "] " + instruction.opcode().name() + " "
            + role.label() + " " + message);
  }
}
