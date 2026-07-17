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
  void everyGeneratedInversePairIsSymmetric() {
    for (Opcode opcode : Opcode.values()) {
      if (opcode.supportsGeneratedInverse()) {
        assertEquals(opcode, opcode.inverse().inverse(), opcode.name());
      }
    }
  }

  private static Program programWith(Instruction instruction) {
    return new Program(
        "Invalid",
        0,
        List.of(new Global("value", 0)),
        List.of(new FunctionBody(
            0,
            "main",
            false,
            List.of(instruction, Instruction.of(Opcode.HALT)),
            List.of())));
  }
}
