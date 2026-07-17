package com.typeobject.wheeler.core.bytecode;

import java.util.StringJoiner;

/** Produces deterministic human-readable Wheeler assembly. */
public final class Disassembler {
  public String disassemble(Program program) {
    StringBuilder output = new StringBuilder();
    output.append("program ").append(program.name()).append('\n');
    output.append("entry ").append(program.entryFunctionId()).append("\n\n");
    for (int i = 0; i < program.globals().size(); i++) {
      Global global = program.globals().get(i);
      output.append("global ").append(i).append(' ')
          .append(global.name()).append(" = ").append(global.initialValue()).append('\n');
    }
    for (FunctionBody function : program.functions()) {
      output.append("\nfunction ").append(function.id()).append(' ').append(function.name());
      if (function.coherent()) {
        output.append(" coherent");
      }
      if (function.reversible()) {
        output.append(" reversible");
      }
      output.append('\n');
      appendBody(output, "forward", function.forward());
      if (function.reversible()) {
        appendBody(output, "inverse", function.inverse());
      }
    }
    return output.toString();
  }

  private static void appendBody(StringBuilder output, String label, java.util.List<Instruction> body) {
    output.append("  ").append(label).append(':').append('\n');
    for (int pc = 0; pc < body.size(); pc++) {
      Instruction instruction = body.get(pc);
      StringJoiner operands = new StringJoiner(", ");
      instruction.operands().forEach(operand -> operands.add(Long.toString(operand)));
      output.append("    %04d  %-12s %s%n".formatted(pc, instruction.opcode(), operands));
    }
  }
}
