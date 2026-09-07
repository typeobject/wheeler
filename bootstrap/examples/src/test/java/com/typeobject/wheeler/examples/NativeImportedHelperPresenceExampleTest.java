package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Constant imports retain unused helpers instead of requiring a caller to exist. */
final class NativeImportedHelperPresenceExampleTest {
  @Test
  void retainsUnusedImportedHelpersWithCompleteArtifactsAndRewind() throws Exception {
    var compiler = NativeModuleCompilerHarness.program();
    for (String declaration : List.of("public void helper() { }",
        "public long helper() { return ANSWER; }")) {
      String imported = "module examples.constants; classical class Constants { "
          + "public const long ANSWER = 42; " + declaration + " }";
      String root = "module examples.root; import examples.constants; "
          + "classical class Root { entry void main() { long value = ANSWER; } }";
      var expected = new WheelerCompiler().compileModuleFiles(
          Map.of("Constants.w", imported, "Root.w", root), "examples.root");
      byte[] actual = assertDoesNotThrow(
          () -> NativeModuleCompilerHarness.compile(compiler, imported, root), imported + "\n" + root);
      assertArrayEquals(new BytecodeWriter().write(expected), actual);
      var artifact = new BytecodeReader().read(actual);
      assertEquals(List.of("examples.constants::helper", "examples.root::main"),
          artifact.functions().stream().map(function -> function.name()).toList());
      assertEquals(0, artifact.globals().size());
      var machine = new VirtualMachine(artifact);
      var initial = machine.snapshot();
      machine.run();
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot());
    }
  }
}
