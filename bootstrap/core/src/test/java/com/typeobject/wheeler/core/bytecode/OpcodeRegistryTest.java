package com.typeobject.wheeler.core.bytecode;

import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_BASE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_COUNT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.DESTINATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.FUNCTION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LEFT_SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RESULT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RIGHT_SOURCE;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Conformance checks for stable opcode identities and regular operand forms. */
class OpcodeRegistryTest {
  @Test
  void givesEveryOpcodeOneUniqueIdentityAndOneCompleteForm() {
    Set<Integer> identities = new HashSet<>();

    for (Opcode opcode : Opcode.values()) {
      assertTrue(identities.add(opcode.code()), opcode.name());
      assertEquals(opcode.form().roles().size(), opcode.operandCount(), opcode.name());
      assertEquals(opcode, Opcode.fromCode(opcode.code()));
    }
  }

  @Test
  void keepsCommonRegisterAndCallFieldsInStablePositions() {
    assertEquals(
        List.of(DESTINATION, LEFT_SOURCE, RIGHT_SOURCE),
        Opcode.LOCAL_ADD.form().roles());
    assertEquals(
        List.of(FUNCTION, ARGUMENT_BASE, ARGUMENT_COUNT, RESULT),
        Opcode.CALL_VALUE.form().roles());
  }
}
