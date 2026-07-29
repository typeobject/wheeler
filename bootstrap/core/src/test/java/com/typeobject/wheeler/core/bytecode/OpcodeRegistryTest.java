package com.typeobject.wheeler.core.bytecode;

import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_BASE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ARGUMENT_COUNT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.DESTINATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.FUNCTION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.IMMEDIATE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.ITERATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LEFT_SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.LIMIT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.OPERATION;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RESULT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RESULT_SLOT;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.RIGHT_SOURCE;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.SOURCE;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Conformance checks for stable opcode identities and regular operand forms. */
class OpcodeRegistryTest {
  private static final int VALID_LOCAL = 0;
  private static final int INVALID_LOCAL = 9;

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
  void namesInvalidOperandRolesInVerifierDiagnostics() {
    assertInvalidRole(
        Instruction.of(Opcode.LOCAL_ADD, INVALID_LOCAL, VALID_LOCAL, VALID_LOCAL),
        "destination local index");
    assertInvalidRole(
        Instruction.of(Opcode.RECORD_GET, VALID_LOCAL, INVALID_LOCAL, VALID_LOCAL),
        "owner local index");
    assertInvalidRole(
        Instruction.of(Opcode.BYTES_GET, VALID_LOCAL, INVALID_LOCAL, VALID_LOCAL),
        "owner local index");
  }

  @Test
  void keepsCommonRegisterAndCallFieldsInStablePositions() {
    assertEquals(
        List.of(DESTINATION, LEFT_SOURCE, RIGHT_SOURCE),
        Opcode.LOCAL_ADD.form().roles());
    assertEquals(
        List.of(FUNCTION, ARGUMENT_BASE, ARGUMENT_COUNT, RESULT),
        Opcode.CALL_VALUE.form().roles());
    assertEquals(List.of(ITERATION, LIMIT), Opcode.LOCAL_LOOP_CHECK.form().roles());
    assertEquals(List.of(RESULT_SLOT, SOURCE), Opcode.RESULT_FILL_SOURCE.form().roles());
    assertEquals(
        List.of(RESULT_SLOT, SOURCE, OPERATION, IMMEDIATE),
        Opcode.RESULT_FILL_BINARY.form().roles());
  }

  private static void assertInvalidRole(Instruction instruction, String expectedRole) {
    FunctionBody main = new FunctionBody(
        VALID_LOCAL,
        "main",
        false,
        VALID_LOCAL,
        List.of(ValueType.SIGNED),
        null,
        List.of(instruction, Instruction.of(Opcode.HALT)),
        List.of());
    Program program = new Program("roles", VALID_LOCAL, List.of(), List.of(main));

    BytecodeException exception = assertThrows(
        BytecodeException.class,
        () -> BytecodeVerifier.verify(program));
    assertTrue(exception.getMessage().contains(expectedRole));
  }
}
