package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for bounded mixed scalar helper signatures. */
final class NativeCompilerWideSignatureExampleTest {
  @Test
  void compilesMixedScalarHelperSignaturesByteForByte() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = NativeCompilerSelfSourceExampleTest.twoHelperSource("""
          private boolean flag() {
            return true;
          }

          public boolean ready(long ignored) {
            return flag();
          }

          public boolean ordered(long left, long right) {
            return left < right;
          }

          public boolean accepted(long left, long right) {
            return ordered(left, right);
          }

          public long third(long first, long second, long value) {
            return value;
          }

          public boolean thirdReady(long first, long second, long third) {
            return true;
          }

          public long fourth(long first, long second, long third, long value) {
            return value;
          }

          public boolean fourthReady(long first, long second, long third, long fourth) {
            return false;
          }

          public long eighth(
            long first,
            long second,
            long third,
            long fourth,
            long fifth,
            long sixth,
            long seventh,
            long value
          ) {
            return value;
          }

          public boolean eighthReady(
            long first,
            long second,
            long third,
            long fourth,
            long fifth,
            long sixth,
            long seventh,
            long eighth
          ) {
            return true;
          }

          public long sixteenth(
            long first,
            long second,
            long third,
            long fourth,
            long fifth,
            long sixth,
            long seventh,
            long eighth,
            long ninth,
            long tenth,
            long eleventh,
            long twelfth,
            long thirteenth,
            long fourteenth,
            long fifteenth,
            long value
          ) {
            return value;
          }

          public boolean sixteenthReady(
            long first,
            long second,
            long third,
            long fourth,
            long fifth,
            long sixth,
            long seventh,
            long eighth,
            long ninth,
            long tenth,
            long eleventh,
            long twelfth,
            long thirteenth,
            long fourteenth,
            long fifteenth,
            long sixteenth
          ) {
            return false;
          }
        """);
    VirtualMachine writer = NativeCompilerSelfSourceExampleTest.nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("MixedHelpers.w", source),
        "examples.two_helpers");
    byte[] artifact = writer.hostOutput();
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(0, decoded.functions().get(0).parameterCount());
    assertEquals(1, decoded.functions().get(1).parameterCount());
    assertEquals(2, decoded.functions().get(2).parameterCount());
    assertEquals(2, decoded.functions().get(3).parameterCount());
    assertEquals(3, decoded.functions().get(4).parameterCount());
    assertEquals(3, decoded.functions().get(5).parameterCount());
    assertEquals(4, decoded.functions().get(6).parameterCount());
    assertEquals(4, decoded.functions().get(7).parameterCount());
    assertEquals(8, decoded.functions().get(8).parameterCount());
    assertEquals(8, decoded.functions().get(9).parameterCount());
    assertEquals(16, decoded.functions().get(10).parameterCount());
    assertEquals(16, decoded.functions().get(11).parameterCount());
    assertEquals(2, decoded.functions().get(1).localCount());
    assertEquals(2, decoded.functions().get(1).forward().size());
    assertEquals(7, decoded.functions().get(3).localCount());
    assertEquals(6, decoded.functions().get(3).forward().size());
    assertEquals("$library", decoded.functions().getLast().name());
    NativeCompilerSelfSourceExampleTest.assertNoPublication(
        compiler, source.replace("return flag();", "return missing();"));
    NativeCompilerSelfSourceExampleTest.assertNoPublication(
        compiler,
        source.replace("return ordered(left, right);", "return ready(left, right);"));
    NativeCompilerSelfSourceExampleTest.assertNoPublication(
        compiler,
        source.replace("long left, long right", "long left, long left"));
    NativeCompilerSelfSourceExampleTest.assertNoPublication(
        compiler,
        source.replace(
            "long first, long second, long value",
            "long first, long second, long first"));
    NativeCompilerSelfSourceExampleTest.assertNoPublication(
        compiler,
        source.replace(
            "long first, long second, long third, long value",
            "long first, long second, long third, long second"));
    NativeCompilerSelfSourceExampleTest.assertNoPublication(
        compiler,
        source.replace("long seventh,\n    long value", "long seventh,\n    long first"));
    NativeCompilerSelfSourceExampleTest.assertNoPublication(
        compiler,
        source.replace("long fifteenth,\n    long value", "long fifteenth,\n    long first"));
  }
}
