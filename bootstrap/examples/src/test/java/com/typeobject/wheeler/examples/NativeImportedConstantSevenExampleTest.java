package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeImportedConstantGraphSupport.assertOrdersMatchStageZero;
import static com.typeobject.wheeler.examples.NativeImportedConstantGraphSupport.rotationsAndReversals;
import static com.typeobject.wheeler.examples.NativeModuleCompilerHarness.assertTrap;
import static com.typeobject.wheeler.examples.NativeModuleCompilerHarness.program;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Differential coverage for seven-module Wheeler-native constant graphs. */
class NativeImportedConstantSevenExampleTest {
  @Test
  void linksSevenDirectConstantModulesAcrossEveryInputPosition() throws Exception {
    List<String> imported = List.of(
        "module examples.two; classical class Two { public const long TWO = 2; }",
        "module examples.three; classical class Three { public const long THREE = 3; }",
        "module examples.five; classical class Five { public const long FIVE = 5; }",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }",
        "module examples.seventeen; classical class Seventeen { "
            + "public const long SEVENTEEN = 17; }");
    String root = "module examples.root; import examples.eleven; import examples.five; "
        + "import examples.seven; import examples.seventeen; import examples.thirteen; "
        + "import examples.three; import examples.two; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += TWO; outcome += THREE; "
        + "outcome += FIVE; outcome += SEVEN; outcome += ELEVEN; outcome += THIRTEEN; "
        + "outcome += SEVENTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(58, machine.global("outcome"));

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
            + "public const long ZETA = EPSILON + 1; }",
        "module examples.eta; import examples.zeta; classical class Eta { "
            + "public const long ETA = ZETA + 1; }");
    String cycleRoot = "module examples.root; import examples.eta; classical class Root { "
        + "entry void main() {} }";
    assertTrap(program(), disconnectedCycle, cycleRoot);
  }

  @Test
  void linksASevenModuleChainBesideFiveDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.two; classical class Two { public const long TWO = 2; }",
        "module examples.three; import examples.two; classical class Three { "
            + "public const long THREE = TWO + 1; }",
        "module examples.five; classical class Five { public const long FIVE = 5; }",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }",
        "module examples.seventeen; classical class Seventeen { "
            + "public const long SEVENTEEN = 17; }");
    String root = "module examples.root; import examples.eleven; import examples.five; "
        + "import examples.seven; import examples.seventeen; import examples.thirteen; "
        + "import examples.three; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += THREE; outcome += FIVE; outcome += SEVEN; "
        + "outcome += ELEVEN; outcome += THIRTEEN; outcome += SEVENTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(56, machine.global("outcome"));
  }

  @Test
  void linksASevenModuleForkBesideFourDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; classical class Beta { public const long BETA = 3; }",
        "module examples.gamma; import examples.alpha; import examples.beta; "
            + "classical class Gamma { public const long GAMMA = ALPHA + BETA; }",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }",
        "module examples.seventeen; classical class Seventeen { "
            + "public const long SEVENTEEN = 17; }");
    String root = "module examples.root; import examples.eleven; import examples.gamma; "
        + "import examples.seven; import examples.seventeen; import examples.thirteen; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "outcome += GAMMA; outcome += SEVEN; outcome += ELEVEN; outcome += THIRTEEN; "
        + "outcome += SEVENTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(53, machine.global("outcome"));

  }

  @Test
  void linksTwoSevenModuleChainsBesideThreeDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; classical class Gamma { public const long GAMMA = 5; }",
        "module examples.delta; import examples.gamma; classical class Delta { "
            + "public const long DELTA = GAMMA + 2; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }",
        "module examples.seventeen; classical class Seventeen { "
            + "public const long SEVENTEEN = 17; }");
    String root = "module examples.root; import examples.beta; import examples.delta; "
        + "import examples.eleven; import examples.seventeen; import examples.thirteen; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "outcome += BETA; outcome += DELTA; outcome += ELEVEN; outcome += THIRTEEN; "
        + "outcome += SEVENTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(51, machine.global("outcome"));
  }

  @Test
  void linksThreeSevenModuleChainsBesideOneDirectImport() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; classical class Gamma { public const long GAMMA = 5; }",
        "module examples.delta; import examples.gamma; classical class Delta { "
            + "public const long DELTA = GAMMA + 2; }",
        "module examples.epsilon; classical class Epsilon { public const long EPSILON = 11; }",
        "module examples.zeta; import examples.epsilon; classical class Zeta { "
            + "public const long ZETA = EPSILON + 2; }",
        "module examples.seventeen; classical class Seventeen { "
            + "public const long SEVENTEEN = 17; }");
    String root = "module examples.root; import examples.beta; import examples.delta; "
        + "import examples.seventeen; import examples.zeta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += BETA; outcome += DELTA; "
        + "outcome += ZETA; outcome += SEVENTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(40, machine.global("outcome"));
  }

  @Test
  void linksAThreeModuleChainBesideFourDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 3; }",
        "module examples.gamma; import examples.beta; classical class Gamma { "
            + "public const long GAMMA = BETA * 2; }",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }",
        "module examples.seventeen; classical class Seventeen { "
            + "public const long SEVENTEEN = 17; }");
    String root = "module examples.root; import examples.eleven; import examples.gamma; "
        + "import examples.seven; import examples.seventeen; import examples.thirteen; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "outcome += GAMMA; outcome += SEVEN; outcome += ELEVEN; outcome += THIRTEEN; "
        + "outcome += SEVENTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(58, machine.global("outcome"));
  }

  @Test
  void linksAFourLeafForkBesideTwoDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; classical class Beta { public const long BETA = 3; }",
        "module examples.gamma; classical class Gamma { public const long GAMMA = 5; }",
        "module examples.delta; classical class Delta { public const long DELTA = 7; }",
        "module examples.eta; import examples.alpha; import examples.beta; "
            + "import examples.delta; import examples.gamma; classical class Eta { "
            + "private const long LEFT = ALPHA + BETA; "
            + "private const long RIGHT = GAMMA + DELTA; "
            + "public const long ETA = LEFT + RIGHT; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }");
    String root = "module examples.root; import examples.eleven; import examples.eta; "
        + "import examples.thirteen; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += ETA; outcome += ELEVEN; outcome += THIRTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(41, machine.global("outcome"));
  }

  @Test
  void linksASixModuleChainBesideOneDirectImport() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; import examples.beta; classical class Gamma { "
            + "public const long GAMMA = BETA + 2; }",
        "module examples.delta; import examples.gamma; classical class Delta { "
            + "public const long DELTA = GAMMA * 2; }",
        "module examples.epsilon; import examples.delta; classical class Epsilon { "
            + "public const long EPSILON = DELTA + 1; }",
        "module examples.zeta; import examples.epsilon; classical class Zeta { "
            + "public const long ZETA = EPSILON + 13; }",
        "module examples.seventeen; classical class Seventeen { "
            + "public const long SEVENTEEN = 17; }");
    String root = "module examples.root; import examples.seventeen; import examples.zeta; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "outcome += ZETA; outcome += SEVENTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(41, machine.global("outcome"));
  }

  @Test
  void linksAFiveModuleChainBesideTwoDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; import examples.beta; classical class Gamma { "
            + "public const long GAMMA = BETA + 2; }",
        "module examples.delta; import examples.gamma; classical class Delta { "
            + "public const long DELTA = GAMMA * 2; }",
        "module examples.epsilon; import examples.delta; classical class Epsilon { "
            + "public const long EPSILON = DELTA + 1; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }",
        "module examples.seventeen; classical class Seventeen { "
            + "public const long SEVENTEEN = 17; }");
    String root = "module examples.root; import examples.epsilon; import examples.seventeen; "
        + "import examples.thirteen; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += EPSILON; outcome += THIRTEEN; "
        + "outcome += SEVENTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(41, machine.global("outcome"));
  }

  @Test
  void linksTwoThreeModuleChainsBesideOneDirectImport() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; import examples.beta; classical class Gamma { "
            + "public const long GAMMA = BETA + 2; }",
        "module examples.delta; classical class Delta { public const long DELTA = 7; }",
        "module examples.epsilon; import examples.delta; classical class Epsilon { "
            + "public const long EPSILON = DELTA + 4; }",
        "module examples.zeta; import examples.epsilon; classical class Zeta { "
            + "public const long ZETA = EPSILON + 2; }",
        "module examples.seventeen; classical class Seventeen { "
            + "public const long SEVENTEEN = 17; }");
    String root = "module examples.root; import examples.gamma; import examples.seventeen; "
        + "import examples.zeta; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += GAMMA; outcome += ZETA; outcome += SEVENTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(35, machine.global("outcome"));
  }

  @Test
  void linksAForkAndChainBesideTwoDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; classical class Beta { public const long BETA = 3; }",
        "module examples.gamma; import examples.alpha; import examples.beta; "
            + "classical class Gamma { public const long GAMMA = ALPHA + BETA; }",
        "module examples.delta; classical class Delta { public const long DELTA = 7; }",
        "module examples.epsilon; import examples.delta; classical class Epsilon { "
            + "public const long EPSILON = DELTA + 4; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }");
    String root = "module examples.root; import examples.eleven; import examples.epsilon; "
        + "import examples.gamma; import examples.thirteen; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += GAMMA; "
        + "outcome += EPSILON; outcome += ELEVEN; outcome += THIRTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(40, machine.global("outcome"));
  }

  @Test
  void linksLongAndShortChainsBesideTwoDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; import examples.beta; classical class Gamma { "
            + "public const long GAMMA = BETA + 2; }",
        "module examples.delta; classical class Delta { public const long DELTA = 7; }",
        "module examples.epsilon; import examples.delta; classical class Epsilon { "
            + "public const long EPSILON = DELTA + 4; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }");
    String root = "module examples.root; import examples.eleven; import examples.epsilon; "
        + "import examples.gamma; import examples.thirteen; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += GAMMA; "
        + "outcome += EPSILON; outcome += ELEVEN; outcome += THIRTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(40, machine.global("outcome"));
  }

  @Test
  void linksAFourModuleChainBesideThreeDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; import examples.beta; classical class Gamma { "
            + "public const long GAMMA = BETA + 2; }",
        "module examples.delta; import examples.gamma; classical class Delta { "
            + "public const long DELTA = GAMMA * 2; }",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }");
    String root = "module examples.root; import examples.delta; import examples.eleven; "
        + "import examples.seven; import examples.thirteen; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += DELTA; outcome += SEVEN; "
        + "outcome += ELEVEN; outcome += THIRTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(41, machine.global("outcome"));
  }

  @Test
  void linksANestedForkBesideThreeDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; classical class Beta { public const long BETA = 3; }",
        "module examples.gamma; import examples.alpha; import examples.beta; "
            + "classical class Gamma { public const long GAMMA = ALPHA + BETA; }",
        "module examples.delta; import examples.gamma; classical class Delta { "
            + "public const long DELTA = GAMMA + 2; }",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }");
    String root = "module examples.root; import examples.delta; import examples.eleven; "
        + "import examples.seven; import examples.thirteen; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += DELTA; outcome += SEVEN; "
        + "outcome += ELEVEN; outcome += THIRTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(38, machine.global("outcome"));
  }

  @Test
  void linksAThreeLeafForkBesideThreeDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; classical class Beta { public const long BETA = 3; }",
        "module examples.gamma; classical class Gamma { public const long GAMMA = 5; }",
        "module examples.eta; import examples.alpha; import examples.beta; "
            + "import examples.gamma; classical class Eta { private const long LEFT = ALPHA + BETA; "
            + "public const long ETA = LEFT + GAMMA; }",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }");
    String root = "module examples.root; import examples.eleven; import examples.eta; "
        + "import examples.seven; import examples.thirteen; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ETA; outcome += SEVEN; "
        + "outcome += ELEVEN; outcome += THIRTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(41, machine.global("outcome"));
  }

  @Test
  void linksAFiveLeafForkBesideOneDirectImport() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; classical class Beta { public const long BETA = 3; }",
        "module examples.gamma; classical class Gamma { public const long GAMMA = 5; }",
        "module examples.delta; classical class Delta { public const long DELTA = 7; }",
        "module examples.epsilon; classical class Epsilon { public const long EPSILON = 11; }",
        "module examples.eta; import examples.alpha; import examples.beta; "
            + "import examples.delta; import examples.epsilon; import examples.gamma; "
            + "classical class Eta { private const long LEFT = ALPHA + BETA; "
            + "private const long MIDDLE = GAMMA + DELTA; "
            + "private const long PARTIAL = LEFT + MIDDLE; "
            + "public const long ETA = PARTIAL + EPSILON; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }");
    String root = "module examples.root; import examples.eta; import examples.thirteen; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "outcome += ETA; outcome += THIRTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(41, machine.global("outcome"));
  }

  @Test
  void linksASevenModuleConstantChainAcrossEveryInputPosition() throws Exception {
    String alpha = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN = 1; public const long BASE = HIDDEN + 1; }";
    String beta = "module examples.beta; import examples.alpha; classical class Beta { "
        + "public const long BETA = BASE + 3; }";
    String gamma = "module examples.gamma; import examples.beta; classical class Gamma { "
        + "public const long GAMMA = BETA * 2; }";
    String delta = "module examples.delta; import examples.gamma; classical class Delta { "
        + "public const long DELTA = GAMMA + 1; }";
    String epsilon = "module examples.epsilon; import examples.delta; "
        + "classical class Epsilon { public const long EPSILON = DELTA + 5; }";
    String zeta = "module examples.zeta; import examples.epsilon; classical class Zeta { "
        + "public const long ZETA = EPSILON + 5; }";
    String eta = "module examples.eta; import examples.zeta; classical class Eta { "
        + "public const long ANSWER = ZETA + 21; }";
    String root = "module examples.root; import examples.eta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ANSWER; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta, eta);

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(42, machine.global("outcome"));
    assertTrap(program(), imported, root.replace("outcome += ANSWER", "outcome += BASE"));
  }

  @Test
  void linksASixLeafForkAcrossEveryInputPosition() throws Exception {
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
    String zeta = "module examples.zeta; classical class Zeta { "
        + "public const long ZETA = 13; }";
    String eta = "module examples.eta; import examples.alpha; import examples.beta; "
        + "import examples.delta; import examples.epsilon; import examples.gamma; "
        + "import examples.zeta; classical class Eta { "
        + "private const long LEFT = ALPHA + BETA; "
        + "private const long MIDDLE = GAMMA + DELTA; "
        + "private const long RIGHT = EPSILON + ZETA; "
        + "private const long PARTIAL = LEFT + MIDDLE; "
        + "public const long ANSWER = PARTIAL + RIGHT; }";
    String root = "module examples.root; import examples.eta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += ANSWER; } }";
    List<String> imported = List.of(alpha, beta, gamma, delta, epsilon, zeta, eta);

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(41, machine.global("outcome"));
  }

}
