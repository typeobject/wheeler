package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** End-to-end evidence for native source compilation and test execution. */
final class NativeSourceTestRunExampleTest {
  private static final String PASSING = """
      module example.pass;
      classical class Passing {
        entry void main() {
          assert(true);
        }
      }
      """;
  private static final String FAILING = PASSING
      .replace("module example.pass;", "module example.fail;")
      .replace("class Passing", "class Failing")
      .replace("assert(true);", "assert(false);");

  @Test
  void compilesAndExecutesEachSourceOnceNatively() throws Exception {
    Program runner = sourceRunner();
    assertOutcome(runner, PASSING, "example.pass", true);
    assertOutcome(runner, FAILING, "example.fail", false);
  }

  private static void assertOutcome(
      Program runner, String source, String module, boolean passed) throws Exception {
    Program expected = new WheelerCompiler().compileModuleFiles(
        Map.of("Subject.w", source), module);
    int expectedLength = new BytecodeWriter().write(expected).length;
    VirtualMachine machine = new VirtualMachine(
        runner, source.getBytes(java.nio.charset.StandardCharsets.UTF_8), 14);
    CompilerMachineRunner.runWithoutRewindHistory(machine);

    ByteBuffer output = ByteBuffer.wrap(machine.hostOutput()).order(ByteOrder.LITTLE_ENDIAN);
    assertEquals(expectedLength, output.getInt());
    assertEquals(passed ? 1 : 0, Byte.toUnsignedInt(output.get()));
    assertTrue(Integer.toUnsignedLong(output.getInt()) > 0);
    assertEquals(0, Byte.toUnsignedInt(output.get()));
    int errorOffset = output.getInt();
    assertEquals(passed, errorOffset == 0);
    assertEquals(1, machine.global("published"));
  }

  private static Program sourceRunner() throws Exception {
    var modules = new LinkedHashMap<>(CompilerSources.compilerDriverModules());
    CoreSources.addBinaryClosure(modules);
    for (String source : new String[] {
        "AggregateInterpreter", "ArtifactExecution", "Interpreter", "MapInterpreter",
        "ResultSlots", "StorageInterpreter", "Utf8Interpreter"
    }) {
      modules.put(source + ".w", RuntimeSources.read("runtime/" + source + ".w"));
    }
    modules.put(
        "TestSourceExecution.w",
        RuntimeSources.read("runtime/testing/runners/TestSourceExecution.w"));
    modules.put(
        "NativeSourceTestRun.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/runners/NativeSourceTestRun.w")));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.testing.runners.native_source_test_run");
  }
}
