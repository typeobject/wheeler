package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerSignedOrderingExampleTest.assertArtifact;
import static com.typeobject.wheeler.examples.NativeCompilerSignedOrderingExampleTest.assertRejected;
import static com.typeobject.wheeler.examples.NativeCompilerSignedOrderingExampleTest.reference;
import static com.typeobject.wheeler.examples.NativeCompilerSignedOrderingExampleTest.source;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Statement, helper, and signature limits remain independent of the two operand words. */
final class NativeCompilerSignedOrderingBoundaryExampleTest {
  @Test
  void keepsSixtyFourStatementsAndRejectsTheNextBeforePublication() throws Exception {
    var compiler = CompilerSources.minimalCompilerProgram();
    assertArtifact(compiler, source("", "", "assert(-1 < 0);".repeat(63) + "observed = 7;"), true);
    String excess = source("", "", "assert(-1 < 0);".repeat(64) + "observed = 7;");
    reference(excess);
    assertRejected(compiler, excess, 32_768, false);
  }

  @Test
  void keepsTheTwentyThirdOrderingHelperAndRejectsTheNext() throws Exception {
    var compiler = CompilerSources.minimalCompilerProgram();
    String helpers = IntStream.range(0, 23).mapToObj(i ->
        "long h%02d(long value) { assert(-1 < value); return value; }".formatted(i))
        .collect(java.util.stream.Collectors.joining(" "));
    String body = "long one = 1; observed = h22(one); observed = 7;";
    assertArtifact(compiler, source("", helpers, body), true);
    String excess = source("", helpers + " long h23(long value) { assert(-1 < value); return value; }", body);
    reference(excess);
    assertRejected(compiler, excess, 32_768, false);
  }

  @Test
  void retainsBothLastSignatureOperandsWithoutWideningCallArguments() throws Exception {
    var compiler = CompilerSources.minimalCompilerProgram();
    for (int count : new int[] {16, 17}) {
      String parameters = IntStream.range(0, count).mapToObj(i -> "long p" + i)
          .collect(java.util.stream.Collectors.joining(", "));
      String source = "module consumer.globals; classical class Signature { public long checked("
          + parameters + ") { assert(p0 < p" + (count - 1) + "); return p0; } }";
      var expected = new WheelerCompiler().compileLibraryModuleFiles(Map.of("Input.w", source), "consumer.globals");
      if (count == 17) {
        assertRejected(compiler, source, 32_768, false);
      } else {
        var writer = new VirtualMachine(compiler, source.getBytes(StandardCharsets.UTF_8), 32_768);
        CompilerMachineRunner.runWithoutRewindHistory(writer);
        assertArrayEquals(new BytecodeWriter().write(expected), writer.hostOutput());
        assertEquals(16, expected.functions().getFirst().parameterCount());
      }
    }
  }
}
