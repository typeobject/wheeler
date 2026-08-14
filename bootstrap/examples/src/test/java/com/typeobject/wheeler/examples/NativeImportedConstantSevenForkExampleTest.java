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
class NativeImportedConstantSevenForkExampleTest {
  @Test
  void linksAnUnevenNestedForkBesideTwoDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; classical class Beta { public const long BETA = 3; }",
        "module examples.gamma; import examples.alpha; import examples.beta; "
            + "classical class Gamma { public const long GAMMA = ALPHA + BETA; }",
        "module examples.delta; classical class Delta { public const long DELTA = 6; }",
        "module examples.epsilon; import examples.delta; import examples.gamma; "
            + "classical class Epsilon { public const long EPSILON = DELTA + GAMMA; }",
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
  void linksPairedNestedChainsBesideTwoDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 3; }",
        "module examples.gamma; classical class Gamma { public const long GAMMA = 5; }",
        "module examples.delta; import examples.gamma; classical class Delta { "
            + "public const long DELTA = GAMMA + 2; }",
        "module examples.epsilon; import examples.beta; import examples.delta; "
            + "classical class Epsilon { public const long EPSILON = BETA + DELTA; }",
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
    assertEquals(42, machine.global("outcome"));
  }

  @Test
  void linksAnExtendedForkBesideTwoDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; classical class Gamma { public const long GAMMA = 5; }",
        "module examples.delta; classical class Delta { public const long DELTA = 7; }",
        "module examples.epsilon; import examples.beta; import examples.delta; "
            + "import examples.gamma; classical class Epsilon { "
            + "public const long EPSILON = BETA + DELTA + GAMMA; }",
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
    assertEquals(45, machine.global("outcome"));
  }

  @Test
  void linksALongBranchForkBesideTwoDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; import examples.beta; classical class Gamma { "
            + "public const long GAMMA = BETA * 2; }",
        "module examples.delta; classical class Delta { public const long DELTA = 7; }",
        "module examples.epsilon; import examples.delta; import examples.gamma; "
            + "classical class Epsilon { public const long EPSILON = DELTA + GAMMA; }",
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
    assertEquals(43, machine.global("outcome"));
  }

  @Test
  void linksAnAsymmetricNestedForkBesideTwoDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; classical class Gamma { public const long GAMMA = 5; }",
        "module examples.delta; import examples.beta; import examples.gamma; "
            + "classical class Delta { public const long DELTA = BETA + GAMMA; }",
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
    assertEquals(39, machine.global("outcome"));
  }

  @Test
  void linksASharedDiamondBesideThreeDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; import examples.alpha; classical class Gamma { "
            + "public const long GAMMA = ALPHA + 3; }",
        "module examples.delta; import examples.beta; import examples.gamma; "
            + "classical class Delta { public const long DELTA = BETA + GAMMA; }",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }");
    String root = "module examples.root; import examples.delta; import examples.eleven; "
        + "import examples.seven; import examples.thirteen; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome += DELTA; "
        + "outcome += SEVEN; outcome += ELEVEN; outcome += THIRTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(39, machine.global("outcome"));
  }

  @Test
  void linksASharedDiamondAndSideLeafBesideTwoDirectImports() throws Exception {
    List<String> imported = List.of(
        "module examples.alpha; classical class Alpha { public const long ALPHA = 2; }",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }",
        "module examples.gamma; import examples.alpha; classical class Gamma { "
            + "public const long GAMMA = ALPHA + 3; }",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }",
        "module examples.delta; import examples.beta; import examples.gamma; "
            + "import examples.seven; classical class Delta { "
            + "public const long DELTA = BETA + GAMMA + SEVEN; }",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }",
        "module examples.seventeen; classical class Seventeen { "
            + "public const long SEVENTEEN = 17; }");
    String root = "module examples.root; import examples.delta; import examples.seventeen; "
        + "import examples.thirteen; classical class Root { state long outcome = 0; "
        + "entry void main() { outcome += DELTA; outcome += THIRTEEN; "
        + "outcome += SEVENTEEN; } }";

    byte[] expected = assertOrdersMatchStageZero(imported, root, rotationsAndReversals(imported));
    VirtualMachine machine = new VirtualMachine(new BytecodeReader().read(expected));
    machine.run();
    assertEquals(45, machine.global("outcome"));
  }
}
