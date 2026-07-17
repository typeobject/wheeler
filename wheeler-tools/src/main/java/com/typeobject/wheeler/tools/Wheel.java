package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.file.Files;
import java.nio.file.Path;

/** Execute a verified Wheeler bytecode artifact. */
public final class Wheel {
  private Wheel() {}

  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      System.err.println("Usage: wheel <program.wbc>");
      System.exit(2);
    }
    Program program = new BytecodeReader().read(Files.readAllBytes(Path.of(args[0])));
    VirtualMachine machine = new VirtualMachine(program);
    machine.run();
    System.out.println(program.name() + " halted after " + machine.snapshot().sequence() + " steps");
    machine.snapshot().globals().forEach((name, value) -> System.out.println(name + " = " + value));
  }
}
