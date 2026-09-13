package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeImportedConstantGraphSupport.assertBoundedOrdersMatchStageZero;
import static com.typeobject.wheeler.examples.NativeImportedConstantGraphSupport.assertOrdersMatchStageZero;
import static com.typeobject.wheeler.examples.NativeImportedConstantGraphSupport.rotationsAndReversals;
import static com.typeobject.wheeler.examples.NativeModuleCompilerHarness.assertTrap;
import static com.typeobject.wheeler.examples.NativeModuleCompilerHarness.program;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential coverage for six- and seven-module Wheeler-native constant graphs. */
class NativeImportedConstantLargeGraphExampleTest {

  @Test
  void linksSixDirectConstantModulesIndependentOfInputOrder() throws Exception {
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
        + "import examples.two; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += TWO; outcome += THREE; outcome += FIVE; "
        + "outcome += SEVEN; outcome += ELEVEN; outcome += THIRTEEN; } }";

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(41, machine.global("outcome"));
  }

  @Test
  void linksAnArbitraryRedundantSixModuleDag() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 1; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; import examples.beta; classical class Gamma { "
            + "public const long GAMMA = BETA + 1; }",
        "module examples.delta; import examples.gamma; classical class Delta { "
            + "public const long DELTA = GAMMA + 1; }",
        "module examples.epsilon; import examples.delta; classical class Epsilon { "
            + "public const long EPSILON = DELTA + 1; }",
        "module examples.zeta; import examples.alpha; import examples.epsilon; "
            + "classical class Zeta { public const long ZETA = ALPHA + EPSILON; }");
    String root = "module examples.root; import examples.zeta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ZETA; } }";

    byte[] artifact = assertOrdersMatchStageZero(
        imported,
        root,
        rotationsAndReversals(imported)
    );
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(artifact));
    machine.run();
    assertEquals(6, machine.global("outcome"));
  }

  @Test
  void linksASixModuleConstantChainIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN = 1; public const long BASE = HIDDEN + 1; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long BETA = BASE + 3; }";
    String gamma = "module examples.gamma; import examples.beta; classical class Gamma { "
        + "public const long GAMMA = BETA * 2; }";
    String delta = "module examples.delta; import examples.gamma; classical class Delta { "
        + "public const long DELTA = GAMMA + 1; }";
    String epsilon = "module examples.epsilon; import examples.delta; "
        + "classical class Epsilon { public const long EPSILON = DELTA + 10; }";
    String zeta = "module examples.zeta; import examples.epsilon; classical class Zeta { "
        + "public const long ANSWER = EPSILON + 21; }";
    String root = "module examples.root; import examples.zeta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ANSWER; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(42, machine.global("outcome"));
    assertTrap(program(), imported, root.replace("outcome += ANSWER", "outcome += BASE"));
  }

  @Test
  void linksAFiveLeafForkIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; classical class Beta { "
        + "public const long BETA = 3; }";
    String gamma = "module examples.gamma; classical class Gamma { "
        + "public const long GAMMA = 5; }";
    String delta = "module examples.delta; classical class Delta { "
        + "public const long DELTA = 7; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 11; }";
    String zeta = "module examples.zeta; import examples.alpha; import examples.beta; "
        + "import examples.delta; import examples.epsilon; import examples.gamma; "
        + "classical class Zeta { private const long LEFT = ALPHA + BETA; "
        + "private const long MIDDLE = GAMMA + DELTA; "
        + "public const long ANSWER = LEFT + MIDDLE + EPSILON; }";
    String root = "module examples.root; import examples.zeta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ANSWER; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(28, machine.global("outcome"));
  }

  @Test
  void linksAThreeLeafForkBesideTwoDirectModulesIndependentOfInputOrder() throws Exception {
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
        + "public const long EPSILON = 7; }";
    String zeta = "module examples.zeta; classical class Zeta { "
        + "public const long ZETA = 11; }";
    String root = "module examples.root; import examples.delta; import examples.epsilon; "
        + "import examples.zeta; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += ANSWER; outcome += EPSILON; "
        + "outcome += ZETA; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(28, machine.global("outcome"));
  }

  @Test
  void linksANestedForkBesideTwoDirectModulesIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; classical class Beta { "
        + "public const long BETA = 3; }";
    String gamma = "module examples.gamma; import examples.alpha; import examples.beta; "
        + "classical class Gamma { public const long MIDDLE = ALPHA + BETA; }";
    String delta = "module examples.delta; import examples.gamma; classical class Delta { "
        + "public const long ANSWER = MIDDLE + 2; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 7; }";
    String zeta = "module examples.zeta; classical class Zeta { "
        + "public const long ZETA = 11; }";
    String root = "module examples.root; import examples.delta; import examples.epsilon; "
        + "import examples.zeta; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += ANSWER; outcome += EPSILON; "
        + "outcome += ZETA; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(25, machine.global("outcome"));
  }

  @Test
  void linksAnUnevenTreeBesideTwoDirectModulesIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long MIDDLE = ALPHA + 3; }";
    String gamma = "module examples.gamma; classical class Gamma { "
        + "public const long GAMMA = 7; }";
    String delta = "module examples.delta; import examples.beta; import examples.gamma; "
        + "classical class Delta { public const long ANSWER = MIDDLE + GAMMA; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 11; }";
    String zeta = "module examples.zeta; classical class Zeta { "
        + "public const long ZETA = 13; }";
    String root = "module examples.root; import examples.delta; import examples.epsilon; "
        + "import examples.zeta; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += ANSWER; outcome += EPSILON; "
        + "outcome += ZETA; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(36, machine.global("outcome"));
  }

  @Test
  void linksAForkChainAndDirectModuleIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; classical class Beta { "
        + "public const long BETA = 3; }";
    String gamma = "module examples.gamma; import examples.alpha; import examples.beta; "
        + "classical class Gamma { public const long FORK = ALPHA + BETA; }";
    String delta = "module examples.delta; classical class Delta { "
        + "public const long DELTA = 7; }";
    String epsilon = "module examples.epsilon; import examples.delta; "
        + "classical class Epsilon { public const long CHAIN = DELTA + 4; }";
    String zeta = "module examples.zeta; classical class Zeta { "
        + "public const long ZETA = 13; }";
    String root = "module examples.root; import examples.epsilon; import examples.gamma; "
        + "import examples.zeta; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += FORK; outcome += CHAIN; outcome += ZETA; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(29, machine.global("outcome"));
  }

  @Test
  void linksThreeIndependentChainsRegardlessOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long FIRST = ALPHA + 1; }";
    String gamma = "module examples.gamma; classical class Gamma { "
        + "public const long GAMMA = 5; }";
    String delta = "module examples.delta; import examples.gamma; classical class Delta { "
        + "public const long SECOND = GAMMA + 2; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 11; }";
    String zeta = "module examples.zeta; import examples.epsilon; classical class Zeta { "
        + "public const long THIRD = EPSILON + 2; }";
    String root = "module examples.root; import examples.beta; import examples.delta; "
        + "import examples.zeta; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += FIRST; outcome += SECOND; outcome += THIRD; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(23, machine.global("outcome"));
  }

  @Test
  void linksLongAndShortChainsBesideADirectModuleIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long MIDDLE = ALPHA + 3; }";
    String gamma = "module examples.gamma; import examples.beta; classical class Gamma { "
        + "public const long LONG = MIDDLE + 2; }";
    String delta = "module examples.delta; classical class Delta { "
        + "public const long DELTA = 11; }";
    String epsilon = "module examples.epsilon; import examples.delta; "
        + "classical class Epsilon { public const long SHORT = DELTA + 3; }";
    String zeta = "module examples.zeta; classical class Zeta { "
        + "public const long ZETA = 17; }";
    String root = "module examples.root; import examples.epsilon; import examples.gamma; "
        + "import examples.zeta; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += LONG; outcome += SHORT; outcome += ZETA; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(38, machine.global("outcome"));
  }

  @Test
  void linksAChainBesideFourDirectModulesAndRejectsDisconnectedCycles() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long BETA = ALPHA + 1; }";
    List<String> imported = List.of(
        alpha,
        beta,
        "module examples.five; classical class Five { public const long FIVE = 5; }",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }");
    String root = "module examples.root; import examples.beta; import examples.eleven; "
        + "import examples.five; import examples.seven; import examples.thirteen; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "outcome += BETA; outcome += FIVE; outcome += SEVEN; outcome += ELEVEN; "
        + "outcome += THIRTEEN; } }";
    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine mixedMachine = new VirtualMachine(artifact);
    mixedMachine.run();
    assertEquals(39, mixedMachine.global("outcome"));

    Program compiler = program();
    List<String> disconnectedCycle = List.of(
        "module examples.alpha; import examples.beta; classical class Alpha { "
            + "public const long ALPHA = BETA + 1; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; classical class Gamma { public const long GAMMA = 2; }",
        "module examples.delta; import examples.gamma; classical class Delta { "
            + "public const long DELTA = GAMMA + 1; }",
        "module examples.epsilon; import examples.delta; classical class Epsilon { "
            + "public const long EPSILON = DELTA + 1; }",
        "module examples.zeta; import examples.epsilon; classical class Zeta { "
            + "public const long ZETA = EPSILON + 1; }");
    String cycleRoot = "module examples.root; import examples.zeta; classical class Root { "
        + "entry void main() {} }";
    assertTrap(compiler, disconnectedCycle, cycleRoot);
  }

  @Test
  void linksATwoLeafForkBesideThreeDirectModulesIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; classical class Beta { "
        + "public const long BETA = 3; }";
    String gamma = "module examples.gamma; import examples.alpha; import examples.beta; "
        + "classical class Gamma { public const long ANSWER = ALPHA + BETA; }";
    String delta = "module examples.delta; classical class Delta { "
        + "public const long DELTA = 5; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 7; }";
    String zeta = "module examples.zeta; classical class Zeta { "
        + "public const long ZETA = 11; }";
    String root = "module examples.root; import examples.delta; import examples.epsilon; "
        + "import examples.gamma; import examples.zeta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ANSWER; "
        + "outcome += DELTA; outcome += EPSILON; outcome += ZETA; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(28, machine.global("outcome"));
  }

  @Test
  void linksAThreeModuleChainBesideThreeDirectModulesIndependentOfInputOrder()
      throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long BETA = ALPHA + 1; }";
    String gamma = "module examples.gamma; import examples.beta; classical class Gamma { "
        + "public const long ANSWER = BETA + 2; }";
    String delta = "module examples.delta; classical class Delta { "
        + "public const long DELTA = 5; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 7; }";
    String zeta = "module examples.zeta; classical class Zeta { "
        + "public const long ZETA = 11; }";
    String root = "module examples.root; import examples.delta; import examples.epsilon; "
        + "import examples.gamma; import examples.zeta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ANSWER; "
        + "outcome += DELTA; outcome += EPSILON; outcome += ZETA; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(28, machine.global("outcome"));
  }

  @Test
  void linksAFourModuleChainBesideTwoDirectModulesIndependentOfInputOrder()
      throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long BETA = ALPHA + 1; }";
    String gamma = "module examples.gamma; import examples.beta; classical class Gamma { "
        + "public const long GAMMA = BETA + 2; }";
    String delta = "module examples.delta; import examples.gamma; classical class Delta { "
        + "public const long ANSWER = GAMMA + 2; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 11; }";
    String zeta = "module examples.zeta; classical class Zeta { "
        + "public const long ZETA = 13; }";
    String root = "module examples.root; import examples.delta; import examples.epsilon; "
        + "import examples.zeta; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += ANSWER; outcome += EPSILON; "
        + "outcome += ZETA; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(31, machine.global("outcome"));
  }

  @Test
  void linksTwoChainsBesideTwoDirectModulesIndependentOfInputOrder() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 2; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long FIRST = ALPHA + 2; }";
    String gamma = "module examples.gamma; classical class Gamma { "
        + "public const long GAMMA = 3; }";
    String delta = "module examples.delta; import examples.gamma; classical class Delta { "
        + "public const long SECOND = GAMMA + 4; }";
    String epsilon = "module examples.epsilon; classical class Epsilon { "
        + "public const long EPSILON = 5; }";
    String zeta = "module examples.zeta; classical class Zeta { "
        + "public const long ZETA = 11; }";
    String root = "module examples.root; import examples.beta; import examples.delta; "
        + "import examples.epsilon; import examples.zeta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += FIRST; "
        + "outcome += SECOND; outcome += EPSILON; outcome += ZETA; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta);

    Program artifact = new BytecodeReader().read(assertBoundedOrdersMatchStageZero(imported, root));
    VirtualMachine machine = new VirtualMachine(artifact);
    machine.run();
    assertEquals(27, machine.global("outcome"));
  }

  @Test
  void rejectsEightImportedModulesBeforePublication() throws Exception {
    List<String> imported = List.of(
        "module examples.two; classical class Two { public const long TWO = 2; }",
        "module examples.three; classical class Three { public const long THREE = 3; }",
        "module examples.five; classical class Five { public const long FIVE = 5; }",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }",
        "module examples.seventeen; classical class Seventeen { "
            + "public const long SEVENTEEN = 17; }",
        "module examples.nineteen; classical class Nineteen { "
            + "public const long NINETEEN = 19; }");
    String root = "module examples.root; import examples.eleven; import examples.five; "
        + "import examples.nineteen; import examples.seven; import examples.seventeen; "
        + "import examples.thirteen; import examples.three; import examples.two; "
        + "classical class Root { entry void main() {} }";
    assertTrap(program(), imported, root);
  }

  @Test
  void acceptsTheFormerThirtyTwoKiBCommentPaddingNegative() throws Exception {
    String importedPadding = "x".repeat(14_000);
    String rootPadding = "r".repeat(5_000);
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 1; /*" + importedPadding + "*/ }";
    String beta = "module examples.beta; classical class Beta { "
        + "public const long BETA = 2; /*" + importedPadding + "*/ }";
    String root = "module examples.root; import examples.alpha; import examples.beta; "
        + "classical class Root { public const long ANSWER = ALPHA + BETA; /*"
        + rootPadding + "*/ }";

    assertTrue(alpha.length() < 16_385);
    assertTrue(beta.length() < 16_385);
    assertTrue(root.length() < 16_385);
    assertTrue(alpha.length() + beta.length() + root.length() > 32_768);
    assertTrue(alpha.length() + beta.length() + root.length() < linkedSourceCapacity());
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Alpha.w", alpha, "Beta.w", beta, "Root.w", root), "examples.root"));
    Program compiler = program();
    for (var order : List.of(List.of(alpha, beta), List.of(beta, alpha))) {
      assertArrayEquals(expected, NativeModuleCompilerHarness.compile(compiler, order, root));
    }
  }

  @Test
  void matchesTheDeclaredLinkedSourceCapacityAndRejectsItsSuccessor() throws Exception {
    int capacity = linkedSourceCapacity();
    int sourceCount = 3;
    String padding = "x".repeat(capacity / sourceCount);
    String alphaDeclaration = "public const long ALPHA = 1; /*" + padding + "*/ ";
    String betaDeclaration = "public const long BETA = 2; /*" + padding + "*/ ";
    String alpha = "module examples.alpha; classical class Alpha { " + alphaDeclaration + "}";
    String beta = "module examples.beta; classical class Beta { " + betaDeclaration + "}";
    String rootPrefix = "module examples.root; import examples.alpha; import examples.beta; "
        + "classical class Root { public const long ANSWER = ALPHA + BETA; /*";
    String rootSuffix = "*/ }";
    int fixedBytes = alphaDeclaration.length() + betaDeclaration.length()
        + rootPrefix.length() + rootSuffix.length();
    int rootPadding = capacity - fixedBytes;
    assertTrue(rootPadding > 0);
    Program compiler = program();
    for (int excess : new int[] {-1, 0, 1}) {
      String root = rootPrefix + "r".repeat(rootPadding + excess) + rootSuffix;
      assertEquals(capacity + excess, alphaDeclaration.length() + betaDeclaration.length() + root.length());
      var writer = NativeModuleCompilerHarness.writer(compiler, List.of(alpha, beta), root);
      var input = writer.snapshot().buffers().getFirst();
      if (excess > 0) {
        VmTrap trap = assertThrows(VmTrap.class,
            () -> CompilerMachineRunner.runWithoutRewindHistory(writer));
        assertEquals(VmTrap.Code.ASSERTION, trap.code());
        assertEquals(0, writer.global("published"));
        assertTrue(writer.hostOutput().length > 0);
        assertArrayEquals(new byte[writer.hostOutput().length], writer.hostOutput());
      } else {
        CompilerMachineRunner.runWithoutRewindHistory(writer);
        assertEquals(1, writer.global("published"));
        byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("Alpha.w", alpha, "Beta.w", beta, "Root.w", root), "examples.root"));
        assertArrayEquals(expected, writer.hostOutput());
      }
      assertEquals(input, writer.snapshot().buffers().get(input.id()));
    }
  }

  private static int linkedSourceCapacity() throws Exception {
    String module = "wheeler.compiler.module_qualifications";
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(module));
    sources.put("Limit.w", "module example.linked_source_limit; import " + module + "; "
        + "classical class Limit { state long capacity = MAX_LINKED_SOURCE_BYTES; entry void main() {} }");
    Program oracle = new WheelerCompiler().compileModuleFiles(sources, "example.linked_source_limit");
    return Math.toIntExact(oracle.globals().getFirst().initialValue());
  }
}
