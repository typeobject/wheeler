package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Differential tests for bounded signed helper parameters and results. */
class MinimalCompilerResultExampleTest {
  @Test
  void compilesSignedHelperResultsAndCheckedArithmetic() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();

    assertDifferentialHalt(
        writerProgram,
        "classical class SignedResultHelper { long answer() { return -42; } "
            + "entry void main() { long value = answer(); assert(value == -42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterHelper { long identity(long value) { return value; } "
            + "entry void main() { long answer = identity(-42); "
            + "assert(answer == -42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterAdd { long increment(long value) { return value + 1; } "
            + "entry void main() { long answer = increment(41); "
            + "assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedLocalArgument { long increment(long value) { return value + 1; } "
            + "entry void main() { long seed = 41; long answer = increment(seed); "
            + "assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterSubtract { "
            + "long adjust(long value) { return value - 2; } "
            + "entry void main() { long answer = adjust(44); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterMultiply { "
            + "long doubleValue(long value) { return value * 2; } "
            + "entry void main() { long answer = doubleValue(21); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterDivide { "
            + "long half(long value) { return value / 2; } "
            + "entry void main() { long answer = half(84); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterRemainder { "
            + "long reduce(long value) { return value % 43; } "
            + "entry void main() { long answer = reduce(85); assert(answer == 42); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class SignedParameterDivideZero { "
            + "long fail(long value) { return value / 0; } "
            + "entry void main() { long answer = fail(42); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class SignedParameterOverflow { "
            + "long increment(long value) { return value + 1; } "
            + "entry void main() { long answer = increment(9223372036854775807); } }");
  }

  private static void assertDifferentialHalt(Program writerProgram, String source) {
    VirtualMachine writer = writer(writerProgram, source);
    runWriter(writer, writerProgram);
    byte[] expected = new WheelerCompiler().compileToBytecode(source);
    assertArrayEquals(expected, writer.hostOutput());

    VirtualMachine artifact = new VirtualMachine(new BytecodeReader().read(writer.hostOutput()));
    artifact.run();
    assertEquals(MachineStatus.HALTED, artifact.status());
  }

  private static void assertDifferentialTrap(Program writerProgram, String source) {
    VirtualMachine writer = writer(writerProgram, source);
    runWriter(writer, writerProgram);
    assertArrayEquals(new WheelerCompiler().compileToBytecode(source), writer.hostOutput());

    VirtualMachine artifact = new VirtualMachine(new BytecodeReader().read(writer.hostOutput()));
    assertThrows(VmTrap.class, artifact::run);
  }

  private static void runWriter(VirtualMachine writer, Program writerProgram) {
    try {
      writer.run();
    } catch (VmTrap trap) {
      throw new AssertionError(
          "Wheeler compiler trapped at instruction "
              + writer.snapshot().frames().getLast().programCounter()
              + " (" + writerProgramInstruction(writer, writerProgram) + ")"
              + ", output cursor " + writer.global("finalCursor")
              + ", and verification " + writer.global("verification"),
          trap);
    }
  }

  private static String writerProgramInstruction(VirtualMachine writer, Program writerProgram) {
    var frame = writer.snapshot().frames().getLast();
    return writerProgram.function(frame.functionId()).name() + " "
        + writerProgram.function(frame.functionId()).forward().get(frame.programCounter()).toString();
  }

  private static VirtualMachine writer(Program writerProgram, String source) {
    return new VirtualMachine(
        writerProgram,
        source.getBytes(StandardCharsets.UTF_8),
        8192);
  }
}
