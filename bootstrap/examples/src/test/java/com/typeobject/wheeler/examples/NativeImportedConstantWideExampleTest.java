package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeModuleCompilerHarness.assertTrap;
import static com.typeobject.wheeler.examples.NativeModuleCompilerHarness.compile;
import static com.typeobject.wheeler.examples.NativeModuleCompilerHarness.program;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential coverage for wider Wheeler-native constant module graphs. */
class NativeImportedConstantWideExampleTest {
  private static final int FIVE_MODULE_PERMUTATIONS = 120;

  @Test
  void linksFiveDirectConstantModulesIndependentOfInputOrder() throws Exception {
    String two = "module examples.two; classical class Two { public const long TWO = 2; }";
    String three = "module examples.three; classical class Three { "
        + "public const long THREE = 3; }";
    String five = "module examples.five; classical class Five { "
        + "public const long FIVE = 5; }";
    String seven = "module examples.seven; classical class Seven { "
        + "public const long SEVEN = 7; }";
    String eleven = "module examples.eleven; classical class Eleven { "
        + "public const long ELEVEN = 11; }";
    String root = "module examples.root; import examples.eleven; import examples.five; "
        + "import examples.seven; import examples.three; import examples.two; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "outcome += TWO; outcome += THREE; outcome += FIVE; outcome += SEVEN; "
        + "outcome += ELEVEN; } }";
    List<String> imported = List.of(two, three, five, seven, eleven);

    Map<String, String> sources = new LinkedHashMap<>();
    for (int index = 0; index < imported.size(); index++) {
      sources.put("Imported" + index + ".w", imported.get(index));
    }
    sources.put("Root.w", root);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileModuleFiles(sources, "examples.root"));

    Program compiler = program();
    List<List<String>> orders = permutations(imported);
    assertEquals(FIVE_MODULE_PERMUTATIONS, orders.size());
    for (List<String> order : orders) {
      assertArrayEquals(expected, compile(compiler, order, root));
    }

    Program artifact = new BytecodeReader().read(expected);
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(28, machine.global("outcome"));
  }

  @Test
  void rejectsSixImportedConstantModulesBeforePublication() throws Exception {
    List<String> imported = List.of(
        "module examples.two; classical class Two { public const long TWO = 2; }",
        "module examples.three; classical class Three { public const long THREE = 3; }",
        "module examples.five; classical class Five { public const long FIVE = 5; }",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }");
    String root = "module examples.root; import examples.eleven; import examples.five; "
        + "import examples.seven; import examples.thirteen; import examples.three; "
        + "import examples.two; classical class Root { entry void main() {} }";
    assertTrap(program(), imported, root);
  }

  private static List<List<String>> permutations(List<String> values) {
    List<List<String>> result = new ArrayList<>();
    addPermutations(new ArrayList<>(values), 0, result);
    return List.copyOf(result);
  }

  private static void addPermutations(
      List<String> values, int cursor, List<List<String>> result) {
    if (cursor == values.size()) {
      result.add(List.copyOf(values));
      return;
    }
    for (int index = cursor; index < values.size(); index++) {
      swap(values, cursor, index);
      addPermutations(values, cursor + 1, result);
      swap(values, cursor, index);
    }
  }

  private static void swap(List<String> values, int left, int right) {
    String value = values.get(left);
    values.set(left, values.get(right));
    values.set(right, value);
  }
}
