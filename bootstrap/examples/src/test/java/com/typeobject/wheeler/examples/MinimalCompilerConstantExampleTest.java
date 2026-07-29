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

/** Differential coverage for the Wheeler-native scalar class-constant slice. */
class MinimalCompilerConstantExampleTest {
  private static final int OUTPUT_CAPACITY = 2_048;
  private static final int MAX_NATIVE_CONSTANTS = 64;

  @Test
  void substitutesSignedAndBooleanConstantsWithoutRuntimeState() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = "classical class ScalarConstants { "
        + "public const long ANSWER = -42; private const boolean READY = true; "
        + "entry void main() { long answer = ANSWER; boolean ready = READY; "
        + "boolean blocked = !READY; assert(answer == -42); assert(ready); } }";

    byte[] artifact = assertDifferentialHalt(compiler, source);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(0, decoded.globals().size());
  }

  @Test
  void substitutesConstantsInStatefulAndValueReturningClasses() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertDifferentialHalt(
        compiler,
        "classical class StatefulConstants { state long value = 0; "
            + "const long ANSWER = 42; entry void main() { long answer = ANSWER; "
            + "value += answer; assert(value == 42); } }");
    assertDifferentialHalt(
        compiler,
        "classical class ConstantResults { const long ANSWER = -42; "
            + "long answer() { return ANSWER; } entry void main() { "
            + "long result = answer(); assert(result == -42); } }");
    assertDifferentialHalt(
        compiler,
        "classical class ConstantBooleanResults { const boolean READY = true; "
            + "boolean ready() { return READY; } entry void main() { "
            + "boolean result = ready(); assert(result); } }");
  }

  @Test
  void keepsIndependentDeclarationOrderOutOfTheArtifact() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String prefix = "classical class OrderedConstants { ";
    String body = "entry void main() { long answer = ANSWER; boolean ready = READY; "
        + "assert(answer == 42); assert(ready); } }";
    String first = prefix + "const long ANSWER = 42; const boolean READY = true; " + body;
    String second = prefix + "const boolean READY = true; const long ANSWER = 42; " + body;

    assertArrayEquals(compileNative(compiler, first), compileNative(compiler, second));
    assertArrayEquals(
        new WheelerCompiler().compileToBytecode(first),
        new WheelerCompiler().compileToBytecode(second));
  }

  @Test
  void rejectsMalformedAmbiguousAndOversizedConstantPrefixes() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    assertNativeTrap(
        compiler,
        "classical class DuplicateConstants { const long VALUE = 1; "
            + "const long VALUE = 2; entry void main() { long value = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class ConstantStateCollision { state long VALUE = 0; "
            + "const long VALUE = 1; entry void main() { } }");
    assertNativeTrap(
        compiler,
        "classical class ConstantHelperCollision { const long answer = 1; "
            + "long answer() { return 1; } entry void main() { long value = answer(); } }");
    assertNativeTrap(
        compiler,
        "classical class ConstantEntryCollision { const long main = 1; "
            + "entry void main() { } }");
    assertNativeTrap(
        compiler,
        "classical class WrongConstantType { const boolean READY = true; "
            + "entry void main() { long value = READY; } }");
    assertNativeTrap(
        compiler,
        "classical class UnsupportedConstantExpression { const long VALUE = 1 + 1; "
            + "entry void main() { long value = VALUE; } }");
    assertNativeTrap(
        compiler,
        "classical class MissingConstant { entry void main() { long value = MISSING; } }");

    StringBuilder oversized = new StringBuilder("classical class TooManyConstants { ");
    for (int index = 0; index <= MAX_NATIVE_CONSTANTS; index++) {
      oversized.append("const long VALUE_").append(index).append(" = ")
          .append(index).append("; ");
    }
    oversized.append("entry void main() { } }");
    assertNativeTrap(compiler, oversized.toString());
  }

  private static byte[] assertDifferentialHalt(Program compiler, String source) {
    byte[] nativeArtifact = compileNative(compiler, source);
    assertArrayEquals(new WheelerCompiler().compileToBytecode(source), nativeArtifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(nativeArtifact));
    program.run();
    assertEquals(MachineStatus.HALTED, program.status());
    return nativeArtifact;
  }

  private static byte[] compileNative(Program compiler, String source) {
    VirtualMachine writer = new VirtualMachine(
        compiler, source.getBytes(StandardCharsets.UTF_8), OUTPUT_CAPACITY);
    CompilerMachineRunner.runWithoutRewindHistory(writer);
    return writer.hostOutput();
  }

  private static void assertNativeTrap(Program compiler, String source) {
    VirtualMachine writer = new VirtualMachine(
        compiler, source.getBytes(StandardCharsets.UTF_8), OUTPUT_CAPACITY);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(writer));
    assertArrayEquals(new byte[OUTPUT_CAPACITY], writer.hostOutput());
  }
}
