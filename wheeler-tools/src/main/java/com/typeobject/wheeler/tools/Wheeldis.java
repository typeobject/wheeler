package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Disassembler;
import java.nio.file.Files;
import java.nio.file.Path;

/** Decode, verify, and disassemble a Wheeler artifact. */
public final class Wheeldis {
  private Wheeldis() {}

  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      System.err.println("Usage: wheeldis <program.wbc>");
      System.exit(2);
    }
    byte[] bytes = Files.readAllBytes(Path.of(args[0]));
    System.out.print(new Disassembler().disassemble(new BytecodeReader().read(bytes)));
  }
}
