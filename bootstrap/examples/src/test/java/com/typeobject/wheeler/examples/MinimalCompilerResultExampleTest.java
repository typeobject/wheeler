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

/** Differential tests for bounded scalar helper parameters and results. */
class MinimalCompilerResultExampleTest {
  @Test
  void compilesSignedHelperResultsAndCheckedArithmetic() throws Exception {
    Program writerProgram = CompilerSources.minimalCompilerProgram();

    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanResultHelper { boolean ready() { return true; } "
            + "entry void main() { boolean value = ready(); assert(value); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanFalseResultHelper { boolean ready() { return false; } "
            + "entry void main() { boolean value = ready(); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class BooleanLocalResultHelper { "
            + "boolean ready() { boolean result = true; return result; } "
            + "entry void main() { boolean value = ready(); assert(value); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class RepeatedBooleanResultCalls { boolean ready() { return true; } "
            + "entry void main() { boolean first = ready(); boolean second = ready(); "
            + "assert(first == second); } }");

    assertDifferentialHalt(
        writerProgram,
        "classical class SignedResultHelper { long answer() { return -42; } "
            + "entry void main() { long value = answer(); assert(value == -42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedResultLocalHelper { "
            + "long answer() { long base = 20; long result = base + 22; return result; } "
            + "entry void main() { long value = answer(); assert(value == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterHelper { long identity(long value) { return value; } "
            + "entry void main() { long answer = identity(-42); "
            + "assert(answer == -42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterAdd { "
            + "long add(long left, long right) { return left + right; } "
            + "entry void main() { long answer = add(20, 22); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterLocalResult { "
            + "long add(long left, long right) { long result = left + right; return result; } "
            + "entry void main() { long answer = add(20, 22); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoLocalArguments { "
            + "long add(long left, long right) { return left + right; } "
            + "entry void main() { long first = 20; long second = 22; long ignored = 0; "
            + "long answer = add(first, second); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class RepeatedSignedResultCalls { "
            + "long increment(long value) { return value + 1; } "
            + "entry void main() { long first = increment(20); "
            + "long second = increment(first); assert(second == 22); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterFirstLocal { "
            + "long add(long left, long right) { return left + right; } "
            + "entry void main() { long left = 20; long answer = add(left, 22); "
            + "assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterSecondLocal { "
            + "long add(long left, long right) { return left + right; } "
            + "entry void main() { long right = 22; long answer = add(20, right); "
            + "assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterBothLocal { "
            + "long add(long left, long right) { return left + right; } "
            + "entry void main() { long half = 21; long answer = add(half, half); "
            + "assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterSubtract { "
            + "long subtract(long left, long right) { return left - right; } "
            + "entry void main() { long answer = subtract(64, 22); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterMultiply { "
            + "long multiply(long left, long right) { return left * right; } "
            + "entry void main() { long answer = multiply(6, 7); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterDivide { "
            + "long divide(long left, long right) { return left / right; } "
            + "entry void main() { long answer = divide(84, 2); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedTwoParameterRemainder { "
            + "long remainder(long left, long right) { return left % right; } "
            + "entry void main() { long answer = remainder(85, 43); assert(answer == 42); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class SignedTwoParameterDivideZero { "
            + "long divide(long left, long right) { return left / right; } "
            + "entry void main() { long answer = divide(42, 0); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterPairAdd { long twice(long value) { return value + value; } "
            + "entry void main() { long answer = twice(21); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterPairSubtract { "
            + "long zero(long value) { return value - value; } "
            + "entry void main() { long answer = zero(42); assert(answer == 0); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterPairMultiply { "
            + "long square(long value) { return value * value; } "
            + "entry void main() { long answer = square(6); assert(answer == 36); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterPairDivide { "
            + "long unit(long value) { return value / value; } "
            + "entry void main() { long answer = unit(42); assert(answer == 1); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterPairRemainder { "
            + "long zero(long value) { return value % value; } "
            + "entry void main() { long answer = zero(42); assert(answer == 0); } }");
    assertDifferentialTrap(
        writerProgram,
        "classical class SignedParameterPairDivideZero { "
            + "long fail(long value) { return value / value; } "
            + "entry void main() { long answer = fail(0); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterAdd { long increment(long value) { return value + 1; } "
            + "entry void main() { long answer = increment(41); "
            + "assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterLocalResult { "
            + "long increment(long value) { long result = value + 1; return result; } "
            + "entry void main() { long answer = increment(41); assert(answer == 42); } }");
    assertDifferentialHalt(
        writerProgram,
        "classical class SignedParameterLocalChain { "
            + "long adjust(long value) { "
            + "long doubled = value * 2; long result = doubled - 42; return result; } "
            + "entry void main() { long answer = adjust(42); assert(answer == 42); } }");
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
              + writer.snapshot().selectedFrames().getLast().programCounter()
              + " (" + writerProgramInstruction(writer, writerProgram) + ")"
              + ", output cursor " + writer.global("finalCursor")
              + ", and verification " + writer.global("verification"),
          trap);
    }
  }

  private static String writerProgramInstruction(VirtualMachine writer, Program writerProgram) {
    var frame = writer.snapshot().selectedFrames().getLast();
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
