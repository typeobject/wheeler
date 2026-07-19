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

  public int encodedLength() {
    return 8 + operands.size() * Long.BYTES;
  }

  public Instruction inverse() {
    return new Instruction(opcode.inverse(), operands);
  }
}
