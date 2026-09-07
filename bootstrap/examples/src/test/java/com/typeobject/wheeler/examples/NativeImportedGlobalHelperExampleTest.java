package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Imported helpers must not move a root state declaration behind its methods. */
final class NativeImportedGlobalHelperExampleTest {
  @Test
  void retainsClassStateBeforeUnusedImportedHelpers() throws Exception {
    var compiler = NativeModuleCompilerHarness.program();
    for (String declaration : List.of("public void helper() { }",
        "public long helper() { return ANSWER; }")) {
      String imported = "module examples.constants; classical class Constants { "
          + "public const long ANSWER = 42; " + declaration + " }";
      String root = "module examples.root; import examples.constants; "
          + "classical class Root { state long value = 0; "
          + "entry void main() { value = ANSWER; assert(value == 42); } }";
      assertMatches(compiler, List.of(imported), root, 42);
    }
  }

  @Test
  void separatesSharedConstantsFromStateAndDefersImportedInitializers() throws Exception {
    var compiler = NativeModuleCompilerHarness.program();
    String imported = "module examples.constants; classical class Constants { "
        + "private const long BASE = 7; public const long ANSWER = BASE + 35; "
        + "public long helper() { return ANSWER; } }";
    for (String prefix : List.of(
        "private const long BASE = 7; state long value = BASE;",
        "state long value = BASE; private const long BASE = 7;",
        "state long value = ANSWER;",
        "state long value = examples.constants::ANSWER;",
        "private const long BASE = 7; state long value = examples.constants::ANSWER;",
        "state long value = examples.constants::ANSWER; private const long BASE = 7;",
        "state long value = -9223372036854775808;",
        "state long value = 9223372036854775807;")) {
      String root = "module examples.root; import examples.constants; classical class Root { "
          + prefix + " entry void main() { value = ANSWER; assert(value == 42); } }";
      assertMatches(compiler, List.of(imported), root, 42);
    }
  }

  @Test
  void retainsStateAcrossConstantAndHelperFrameOrders() throws Exception {
    var compiler = NativeModuleCompilerHarness.program();
    String imported = "module examples.constants; classical class Constants { "
        + "public const long ANSWER = 42; public long helper() { return ANSWER; } }";
    String extra = "module examples.extra; classical class Extra { public const long EXTRA = 1; }";
    for (String prefix : List.of(
        "const long BASE = 7; state long value = BASE;",
        "state long value = BASE; const long BASE = 7;")) {
      String root = "module examples.root; import examples.constants; import examples.extra; "
          + "classical class Root { " + prefix
          + " entry void main() { value = ANSWER; assert(value == 42); } }";
      for (List<String> frames : List.of(List.of(imported, extra), List.of(extra, imported))) {
        assertMatches(compiler, frames, root, 42);
      }
    }
  }

  @Test
  void privatizesOnlyDeclarationVisibilityAlongAConstantFedHelperEdge() throws Exception {
    var compiler = NativeModuleCompilerHarness.program();
    String leaf = "module examples.leaf; classical class Leaf { public const long public = 42; }";
    String imported = "module examples.constants; import examples.leaf; classical class Constants { "
        + "public const long ANSWER = examples.leaf::public; public long helper() { return ANSWER; } }";
    for (String prefix : List.of(
        "const long ROOT = 0; state long value = examples.constants::ANSWER;",
        "state long value = examples.constants::ANSWER; const long ROOT = 0;")) {
      String root = "module examples.root; import examples.constants; classical class Root { "
          + prefix + " entry void main() { assert(value == 42); } }";
      for (List<String> frames : List.of(List.of(leaf, imported), List.of(imported, leaf))) {
        assertMatches(compiler, frames, root, 42);
      }
    }
  }

  @Test
  void rejectsQualifiedPrivateInitializersEvenWhenTheRootSharesTheDeclaration() throws Exception {
    var compiler = NativeModuleCompilerHarness.program();
    String extra = "module examples.extra; classical class Extra { public const long EXTRA = 1; }";
    for (String helper : List.of("", "public long helper() { return ANSWER; }")) {
      String imported = "module examples.constants; classical class Constants { "
          + "private const long BASE = 7; public const long ANSWER = BASE + 35; " + helper + " }";
      for (String prefix : List.of(
          "private const long BASE = 7; state long value = examples.constants::BASE;",
          "state long value = examples.constants::BASE; private const long BASE = 7;",
          "state long value = examples.constants::BASE;")) {
        String root = "module examples.root; import examples.constants; classical class Root { "
            + prefix + " entry void main() { assert(value == 7); } }";
        assertThrows(CompilerException.class, () -> new WheelerCompiler().compileModuleFiles(
            Map.of("Constants.w", imported, "Root.w", root), "examples.root"));
        assertRejectedAndRewound(compiler, List.of(imported), root);
        String multiple = root.replace("classical class Root", "import examples.extra; classical class Root");
        assertThrows(CompilerException.class, () -> new WheelerCompiler().compileModuleFiles(
            Map.of("Constants.w", imported, "Extra.w", extra, "Root.w", multiple), "examples.root"));
        for (List<String> frames : List.of(List.of(imported, extra), List.of(extra, imported))) {
          assertRejectedAndRewound(compiler, frames, multiple);
        }
      }
    }
  }

  @Test
  void rejectsUnknownNamespacePrefixesInsteadOfRebindingTheirSuffixes() throws Exception {
    var compiler = NativeModuleCompilerHarness.program();
    String imported = "module examples.constants; classical class Constants { "
        + "private const long BASE = 7; public const long ANSWER = BASE + 35; "
        + "public long helper() { return ANSWER; } }";
    String root = "module examples.root; import examples.constants; classical class Root { "
        + "private const long BASE = 7; private const long myBASE = 7; "
        + "state long value = myexamples.constants::BASE; entry void main() { assert(value == 7); } }";
    assertMatches(compiler, List.of(imported), root.replace("myexamples.constants::BASE", "myBASE"), 7);
    assertThrows(CompilerException.class, () -> new WheelerCompiler().compileModuleFiles(
        Map.of("Constants.w", imported, "Root.w", root), "examples.root"));
    assertRejectedAndRewound(compiler, List.of(imported), root);
  }

  @Test
  void rejectsUnloweredStateExpressionsWithoutDroppingTheirSuffixes() throws Exception {
    var compiler = NativeModuleCompilerHarness.program();
    String imported = "module examples.constants; classical class Constants { "
        + "public const long ANSWER = 42; public long helper() { return ANSWER; } }";
    for (String prefix : List.of("const long ROOT = 0; ", "")) {
      for (String expression : List.of("1 + 2", "examples.constants::ANSWER + 0", "(42)")) {
        long value = expression.equals("1 + 2") ? 3 : 42;
        String root = "module examples.root; import examples.constants; classical class Root { "
            + prefix + "state long value = " + expression + "; entry void main() { assert(value == "
            + value + "); } }";
        Program expected = new WheelerCompiler().compileModuleFiles(
            Map.of("Constants.w", imported, "Root.w", root), "examples.root");
        var reference = new VirtualMachine(expected);
        reference.run();
        assertEquals(value, reference.global("value"));
        assertRejectedAndRewound(compiler, List.of(imported), root);
      }
    }
  }

  private static void assertRejectedAndRewound(Program compiler, List<String> imported, String root) {
    var writer = NativeModuleCompilerHarness.writer(compiler, imported, root);
    var initial = writer.snapshot();
    assertThrows(VmTrap.class, writer::run);
    assertEquals(0, writer.global("published"));
    assertArrayEquals(new byte[32_768], writer.hostOutput());
    while (writer.historySize() > 0) {
      writer.rewindOne();
    }
    assertEquals(initial, writer.snapshot());
  }

  private static void assertMatches(Program compiler, List<String> imported, String root, long value) {
    var sources = new LinkedHashMap<String, String>();
    for (int index = 0; index < imported.size(); index++) {
      sources.put("Imported" + index + ".w", imported.get(index));
    }
    sources.put("Root.w", root);
    var expected = new WheelerCompiler().compileModuleFiles(sources, "examples.root");
    byte[] actual = assertDoesNotThrow(
        () -> NativeModuleCompilerHarness.compile(compiler, imported, root), root);
    assertArrayEquals(new BytecodeWriter().write(expected), actual);
    var artifact = new BytecodeReader().read(actual);
    assertEquals(List.of("examples.constants::helper", "examples.root::main"),
        artifact.functions().stream().map(function -> function.name()).toList());
    assertEquals(1, artifact.globals().size());
    var machine = new VirtualMachine(artifact);
    var initial = machine.snapshot();
    machine.run();
    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(value, machine.global("value"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
