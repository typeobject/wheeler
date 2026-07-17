package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.runtime.ExecutionResult;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import com.typeobject.wheeler.runtime.quantum.StateVectorTarget;
import java.nio.file.Files;
import java.nio.file.Path;

/** Execute a verified classical, quantum, or hybrid Wheeler artifact. */
public final class Wheel {
  private Wheel() {}

  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      System.err.println("Usage: wheel <program.wbc>");
      System.exit(2);
    }
    Program program = new BytecodeReader().read(Files.readAllBytes(Path.of(args[0])));
    ExecutionResult result = new WheelerRuntime().execute(program, new StateVectorTarget());
    System.out.println(program.name() + " (" + program.kind().name().toLowerCase()
        + ") halted after " + result.workflowSteps() + " steps");
    result.globals().forEach((name, value) -> System.out.println(name + " = " + value));
    if (!result.measurements().isEmpty()) {
      System.out.println("measurements = " + result.measurements());
    }
  }
}
