package com.typeobject.wheeler.core.bytecode;

import java.util.List;
import java.util.Objects;

/** One decoded canonical bytecode instruction. */
public record Instruction(Opcode opcode, List<Long> operands) {
  public Instruction {
    Objects.requireNonNull(opcode, "opcode");
    operands = List.copyOf(operands);
    if (operands.size() != opcode.operandCount()) {
      throw new IllegalArgumentException(
          "%s expects %d operands, got %d"
              .formatted(opcode, opcode.operandCount(), operands.size()));
    }
  }

  public static Instruction of(Opcode opcode, long... operands) {
    return new Instruction(opcode, java.util.Arrays.stream(operands).boxed().toList());
  }

  public long operand(InstructionForm.OperandRole role) {
    int index = opcode.form().roles().indexOf(role);
    if (index < 0) {
      throw new IllegalArgumentException(opcode + " has no " + role.name().toLowerCase());
    }
    return operands.get(index);
  }

  public int encodedLength() {
    return BytecodeFormat.INSTRUCTION_HEADER_SIZE
        + operands.size() * BytecodeFormat.INSTRUCTION_OPERAND_SIZE;
  }

  public Instruction inverse() {
    return new Instruction(opcode.inverse(), operands);
  }
}
