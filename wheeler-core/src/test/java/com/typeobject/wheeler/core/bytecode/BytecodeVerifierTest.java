package com.typeobject.wheeler.core.bytecode;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;
import org.junit.jupiter.api.Test;

class BytecodeVerifierTest {
  @Test
  void rejectsOutOfRangeGlobalAndFunctionReferences() {
    Program badGlobal = programWith(Instruction.of(Opcode.ADD_CONST, 9, 1));
    Program badFunction = programWith(Instruction.of(Opcode.CALL, 9));

    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(badGlobal));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(badFunction));
  }

  @Test
  void rejectsUninitializedLocalsAndInvalidControlTargets() {
    FunctionBody uninitialized = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(ValueType.SIGNED),
        null,
        List.of(
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    FunctionBody badJump = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.JUMP, 7), Instruction.of(Opcode.HALT)),
        List.of());

    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(uninitialized)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(badJump)));
  }

  @Test
  void rejectsRegisterTypeMismatchesAndInvalidBooleanConstants() {
    FunctionBody signedCondition = typedMain(
        List.of(ValueType.SIGNED),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 1),
            Instruction.of(Opcode.JUMP_IF_ZERO, 0, 2),
            Instruction.of(Opcode.HALT)));
    FunctionBody booleanStore = typedMain(
        List.of(ValueType.BOOLEAN),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 1),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0),
            Instruction.of(Opcode.HALT)));
    FunctionBody invalidBoolean = typedMain(
        List.of(ValueType.BOOLEAN),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 2),
            Instruction.of(Opcode.HALT)));
    FunctionBody unresolvedRecord = typedMain(
        List.of(ValueType.record(7)),
        List.of(
            Instruction.of(Opcode.LOCAL_CONST, 0, 0),
            Instruction.of(Opcode.HALT)));

    assertEquals(ValueType.record(7), ValueType.fromCode(ValueType.record(7).code()));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(signedCondition)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(booleanStore)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(invalidBoolean)));
    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(programWith(unresolvedRecord)));
  }

  @Test
  void recordDescriptorsRejectForwardAndUnknownReferences() {
    RecordType forward = new RecordType(
        0,
        "Forward",
        List.of(new RecordType.Field("next", ValueType.record(1))));
    RecordType later = new RecordType(
        1,
        "Later",
        List.of(new RecordType.Field("value", ValueType.SIGNED)));
    FunctionBody main = typedMain(List.of(), List.of(Instruction.of(Opcode.HALT)));
    Program invalid = new Program(
        "InvalidRecords",
        ProgramKind.CLASSICAL,
        0,
        List.of(),
        List.of(forward, later),
        List.of(main),
        List.of(),
        List.of(),
        List.of(),
        Program.DEFAULT_MAX_HISTORY,
        Program.DEFAULT_MAX_STEPS);

    assertThrows(BytecodeException.class, () -> BytecodeVerifier.verify(invalid));
  }

  @Test
  void everyGeneratedInversePairIsSymmetric() {
    for (Opcode opcode : Opcode.values()) {
      if (opcode.supportsGeneratedInverse()) {
        assertEquals(opcode, opcode.inverse().inverse(), opcode.name());
      }
    }
  }

  private static FunctionBody typedMain(
      List<ValueType> types, List<Instruction> instructions) {
    return new FunctionBody(0, "main", false, 0, types, null, instructions, List.of());
  }

  private static Program programWith(Instruction instruction) {
    return programWith(new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(instruction, Instruction.of(Opcode.HALT)),
        List.of()));
  }

  private static Program programWith(FunctionBody function) {
    return new Program(
        "Invalid", 0, List.of(new Global("value", 0)), List.of(function));
  }
}
