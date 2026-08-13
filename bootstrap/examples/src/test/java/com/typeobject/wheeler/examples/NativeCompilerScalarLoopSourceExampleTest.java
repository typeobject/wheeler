package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for loops inside entryless scalar helpers. */
final class NativeCompilerScalarLoopSourceExampleTest {
  @Test
  void compilesScalarHelperLoopsByteForByte() throws Exception {
    String source = """
        module examples.scalar_loop;

        classical class ScalarLoop {
          public long count(long stop) {
            long cursor = 0;
            while (cursor < stop) limit 8 {
              cursor += 1;
            }
            return cursor;
          }
        }
        """;
    Program compiler = CompilerSources.minimalCompilerProgram();
    var writer = NativeCompilerSelfSourceExampleTest.nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("ScalarLoop.w", source), "examples.scalar_loop");
    assertArrayEquals(new BytecodeWriter().write(expected), writer.hostOutput());
    Program decoded = new BytecodeReader().read(writer.hostOutput());
    assertEquals("examples.scalar_loop::count", decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
  }
}
