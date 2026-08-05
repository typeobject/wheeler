package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeModuleCompilerHarness.compile;
import static com.typeobject.wheeler.examples.NativeModuleCompilerHarness.program;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Shared differential ordering support for bounded native constant graphs. */
final class NativeImportedConstantGraphSupport {
  private NativeImportedConstantGraphSupport() {}

  static byte[] assertEveryOrderMatchesStageZero(
      List<String> imported, String root) throws Exception {
    List<List<String>> orders = permutations(imported);
    assertEquals(factorial(imported.size()), orders.size());
    return assertOrdersMatchStageZero(imported, root, orders);
  }

  static byte[] assertOrdersMatchStageZero(
      List<String> imported, String root, List<List<String>> orders) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    for (int index = 0; index < imported.size(); index++) {
      sources.put("Imported" + index + ".w", imported.get(index));
    }
    sources.put("Root.w", root);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileModuleFiles(sources, "examples.root"));

    Program compiler = program();
    for (List<String> order : orders) {
      assertArrayEquals(expected, compile(compiler, order, root));
    }
    return expected;
  }

  static List<List<String>> rotationsAndReversals(List<String> values) {
    List<List<String>> orders = new ArrayList<>();
    List<String> forward = new ArrayList<>(values);
    List<String> reverse = new ArrayList<>(values.reversed());
    for (int offset = 0; offset < values.size(); offset++) {
      orders.add(List.copyOf(forward));
      orders.add(List.copyOf(reverse));
      forward.add(forward.remove(0));
      reverse.add(reverse.remove(0));
    }
    return List.copyOf(orders);
  }

  private static int factorial(int value) {
    int result = 1;
    for (int factor = 2; factor <= value; factor++) {
      result *= factor;
    }
    return result;
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
