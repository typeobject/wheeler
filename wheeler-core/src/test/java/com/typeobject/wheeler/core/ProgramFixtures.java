package com.typeobject.wheeler.core;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.List;

public final class ProgramFixtures {
  private ProgramFixtures() {}

  public static Program counter() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        List.of(
            Instruction.of(Opcode.CALL, 1),
            Instruction.of(Opcode.CALL, 1),
            Instruction.of(Opcode.EXPECT_EQ, 0, 2),
            Instruction.of(Opcode.UNCALL, 1),
            Instruction.of(Opcode.UNCALL, 1),
            Instruction.of(Opcode.EXPECT_EQ, 0, 0),
            Instruction.of(Opcode.HALT)),
        List.of());
    FunctionBody increment = new FunctionBody(
        1,
        "increment",
        true,
        List.of(Instruction.of(Opcode.ADD_CONST, 0, 1), Instruction.of(Opcode.RETURN)),
        List.of(Instruction.of(Opcode.SUB_CONST, 0, 1), Instruction.of(Opcode.RETURN)));
    return new Program("Counter", 0, List.of(new Global("count", 0)), List.of(main, increment));
  }
}
