package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeImportedConstantGraphSupport.assertBoundedOrdersMatchStageZero;
import static com.typeobject.wheeler.examples.NativeImportedConstantGraphSupport.assertOrdersMatchStageZero;
import static com.typeobject.wheeler.examples.NativeImportedConstantGraphSupport.rotationsAndReversals;
import static com.typeobject.wheeler.examples.NativeModuleCompilerHarness.assertTrap;
import static com.typeobject.wheeler.examples.NativeModuleCompilerHarness.program;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Differential coverage for Wheeler-native constant graphs through five imports. */
class NativeImportedConstantWideExampleTest {

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

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
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

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
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

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
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

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
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

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
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

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
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

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
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

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
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

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
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

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(23, machine.global("outcome"));
  }

  @Test
  void linksTwoNestedForkLevelsIndependentOfInputOrder() throws Exception {
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
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(12, machine.global("outcome"));
  }

  @Test
  void linksASharedDiamondWithASideLeafIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long BETA = ALPHA + 1; }";
    String gamma = "module examples.gamma; import examples.alpha; classical class Gamma { "
        + "public const long GAMMA = ALPHA + 2; }";
    String delta = "module examples.delta; classical class Delta { "
        + "public const long DELTA = 7; }";
    String epsilon = "module examples.epsilon; import examples.beta; import examples.delta; "
        + "import examples.gamma; classical class Epsilon { "
        + "private const long LEFT = BETA + GAMMA; "
        + "public const long ANSWER = LEFT + DELTA; }";
    String root = "module examples.root; import examples.epsilon; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ANSWER; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(14, machine.global("outcome"));
  }

  @Test
  void linksAnArbitrarySharedFiveModuleDag() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; classical class Beta { "
        + "public const long BETA = 3; }";
    String gamma = "module examples.gamma; import examples.alpha; import examples.beta; "
        + "classical class Gamma { public const long GAMMA = ALPHA + BETA; }";
    String delta = "module examples.delta; import examples.alpha; import examples.beta; "
        + "classical class Delta { public const long DELTA = ALPHA + BETA; }";
    String epsilon = "module examples.epsilon; import examples.delta; import examples.gamma; "
        + "classical class Epsilon { public const long ANSWER = DELTA + GAMMA; }";
    String root = "module examples.root; import examples.epsilon; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ANSWER; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon);
    byte[] artifact = assertOrdersMatchStageZero(
        imported,
        root,
        rotationsAndReversals(imported)
    );
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(artifact));
    machine.run();
    assertEquals(10, machine.global("outcome"));
  }
}
