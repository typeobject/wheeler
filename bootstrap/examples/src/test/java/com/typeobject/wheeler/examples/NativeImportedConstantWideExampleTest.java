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

    Program artifact = new BytecodeReader().read(assertEveryOrderMatchesStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(28, machine.global("outcome"));
  }

  @Test
  void linksAFiveModuleConstantChainIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN = 1; public const long BASE = HIDDEN + 1; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long BETA = BASE + 3; }";
    String gamma = "module examples.gamma; import examples.beta; classical class Gamma { "
        + "public const long GAMMA = BETA * 2; }";
    String delta = "module examples.delta; import examples.gamma; classical class Delta { "
        + "public const long DELTA = GAMMA + 1; }";
    String epsilon = "module examples.epsilon; import examples.delta; "
        + "classical class Epsilon { public const long ANSWER = DELTA + 31; }";
    String root = "module examples.root; import examples.epsilon; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ANSWER; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon);

    Program artifact = new BytecodeReader().read(assertEveryOrderMatchesStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(42, machine.global("outcome"));
    assertTrap(program(), imported, root.replace("outcome += ANSWER", "outcome += BASE"));
  }

  @Test
  void linksAFourLeafConstantForkIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; classical class Beta { "
        + "public const long BETA = 3; }";
    String gamma = "module examples.gamma; classical class Gamma { "
        + "public const long GAMMA = 5; }";
    String delta = "module examples.delta; classical class Delta { "
        + "public const long DELTA = 7; }";
    String epsilon = "module examples.epsilon; import examples.alpha; import examples.beta; "
        + "import examples.delta; import examples.gamma; classical class Epsilon { "
        + "private const long LEFT = ALPHA + BETA; "
        + "private const long RIGHT = GAMMA + DELTA; "
        + "public const long ANSWER = LEFT + RIGHT; }";
    String root = "module examples.root; import examples.epsilon; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ANSWER; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon);

    Program artifact = new BytecodeReader().read(assertEveryOrderMatchesStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(17, machine.global("outcome"));
  }

  @Test
  void linksAThreeLeafForkBesideADirectModuleIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; classical class Beta { "
        + "public const long BETA = 3; }";
    String gamma = "module examples.gamma; classical class Gamma { "
        + "public const long GAMMA = 5; }";
    String delta = "module examples.delta; import examples.alpha; import examples.beta; "
        + "import examples.gamma; classical class Delta { "
        + "private const long LEFT = ALPHA + BETA; "
        + "public const long ANSWER = LEFT + GAMMA; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long DIRECT = 7; }";
    String root = "module examples.root; import examples.delta; import examples.epsilon; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "outcome += ANSWER; outcome += DIRECT; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon);

    Program artifact = new BytecodeReader().read(assertEveryOrderMatchesStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(17, machine.global("outcome"));
  }

  @Test
  void linksAChainBesideThreeDirectModulesIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long BETA = ALPHA + 1; }";
    String delta = "module examples.delta; classical class Delta { "
        + "public const long DELTA = 5; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 7; }";
    String gamma = "module examples.gamma; classical class Gamma { "
        + "public const long GAMMA = 11; }";
    String root = "module examples.root; import examples.beta; import examples.delta; "
        + "import examples.epsilon; import examples.gamma; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += BETA; outcome += DELTA; "
        + "outcome += EPSILON; outcome += GAMMA; } }";
    List<String> imported = List.of(alpha, beta, delta, epsilon, gamma);

    Program artifact = new BytecodeReader().read(assertEveryOrderMatchesStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(26, machine.global("outcome"));
  }

  @Test
  void linksATwoLeafForkBesideTwoDirectModulesIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String gamma = "module examples.gamma; classical class Gamma { "
        + "public const long GAMMA = 11; }";
    String beta = "module examples.beta; import examples.alpha; import examples.gamma; "
        + "classical class Beta { public const long BETA = ALPHA + GAMMA; }";
    String delta = "module examples.delta; classical class Delta { "
        + "public const long DELTA = 5; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 7; }";
    String root = "module examples.root; import examples.beta; import examples.delta; "
        + "import examples.epsilon; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += BETA; outcome += DELTA; outcome += EPSILON; } }";
    List<String> imported = List.of(alpha, gamma, beta, delta, epsilon);

    Program artifact = new BytecodeReader().read(assertEveryOrderMatchesStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(25, machine.global("outcome"));
  }

  @Test
  void linksTwoChainsBesideADirectModuleIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long BETA = ALPHA + 1; }";
    String gamma = "module examples.gamma; classical class Gamma { "
        + "public const long GAMMA = 5; }";
    String delta = "module examples.delta; import examples.gamma; classical class Delta { "
        + "public const long DELTA = GAMMA + 7; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 11; }";
    String root = "module examples.root; import examples.beta; import examples.delta; "
        + "import examples.epsilon; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += BETA; outcome += DELTA; outcome += EPSILON; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon);

    Program artifact = new BytecodeReader().read(assertEveryOrderMatchesStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(26, machine.global("outcome"));
  }

  @Test
  void linksAThreeModuleChainBesideTwoDirectModulesIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long BETA = ALPHA + 1; }";
    String gamma = "module examples.gamma; import examples.beta; classical class Gamma { "
        + "public const long GAMMA = BETA + 2; }";
    String delta = "module examples.delta; classical class Delta { "
        + "public const long DELTA = 7; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 11; }";
    String root = "module examples.root; import examples.delta; import examples.epsilon; "
        + "import examples.gamma; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += GAMMA; outcome += DELTA; outcome += EPSILON; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon);

    Program artifact = new BytecodeReader().read(assertEveryOrderMatchesStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(23, machine.global("outcome"));
  }

  @Test
  void linksAFourModuleChainBesideADirectModuleIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long BETA = ALPHA + 1; }";
    String gamma = "module examples.gamma; import examples.beta; classical class Gamma { "
        + "public const long GAMMA = BETA + 2; }";
    String delta = "module examples.delta; import examples.gamma; classical class Delta { "
        + "public const long DELTA = GAMMA + 2; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 11; }";
    String root = "module examples.root; import examples.delta; import examples.epsilon; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "outcome += DELTA; outcome += EPSILON; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon);

    Program artifact = new BytecodeReader().read(assertEveryOrderMatchesStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(18, machine.global("outcome"));
  }

  @Test
  void linksANestedForkBesideADirectModuleIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; classical class Beta { "
        + "public const long BETA = 3; }";
    String gamma = "module examples.gamma; import examples.alpha; import examples.beta; "
        + "classical class Gamma { public const long GAMMA = ALPHA + BETA; }";
    String delta = "module examples.delta; import examples.gamma; classical class Delta { "
        + "public const long DELTA = GAMMA + 7; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 11; }";
    String root = "module examples.root; import examples.delta; import examples.epsilon; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "outcome += DELTA; outcome += EPSILON; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon);

    Program artifact = new BytecodeReader().read(assertEveryOrderMatchesStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(23, machine.global("outcome"));
  }

  @Test
  void rejectsAnUnsupportedFiveModuleGraphBeforePublication() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; classical class Beta { "
        + "public const long BETA = 3; }";
    String gamma = "module examples.gamma; import examples.alpha; import examples.beta; "
        + "classical class Gamma { public const long GAMMA = ALPHA + BETA; }";
    String delta = "module examples.delta; classical class Delta { "
        + "public const long DELTA = 7; }";
    String epsilon = "module examples.epsilon; import examples.delta; import examples.gamma; "
        + "classical class Epsilon { public const long ANSWER = DELTA + GAMMA; }";
    String root = "module examples.root; import examples.epsilon; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ANSWER; } }";
    assertTrap(program(), List.of(alpha, beta, gamma, delta, epsilon), root);
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

  private static byte[] assertEveryOrderMatchesStageZero(
      List<String> imported, String root) throws Exception {
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
    return expected;
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
