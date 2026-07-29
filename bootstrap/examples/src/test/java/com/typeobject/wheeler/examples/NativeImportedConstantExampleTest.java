package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential coverage for bounded Wheeler-native constant module graphs. */
class NativeImportedConstantExampleTest {
  private static final Path FIXTURE = Path.of(
      "../wheeler-examples/src/main/wheeler/native/compiler/NativeModuleCompiler.w");
  private static final int OUTPUT_CAPACITY = 8_192;

  @Test
  void linksOnePublicConstantGraphWithoutRuntimeState() throws Exception {
    Program compiler = program();
    String imported = "module examples.constants; classical class Constants { "
        + "public const boolean READY = ANSWER == 42; "
        + "public const long ANSWER = rotateRight32(BASE, ROTATION); "
        + "private const long BASE = 0x2a0; private const long ROTATION = 4; }";
    String root = "module examples.root; import examples.constants; "
        + "classical class ImportedConstants { state long outcome = 0; "
        + "entry void main() { long answer = ANSWER; boolean ready = READY; "
        + "long qualified = examples.constants::ANSWER; "
        + "long second = examples.constants::ANSWER; long sum = qualified + second; "
        + "outcome = sum; assert(answer == 42); assert(ready); assert(outcome == 84); } }";

    byte[] artifact = compileNative(compiler, imported, root);
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Constants.w", imported);
    sources.put("Root.w", root);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileModuleFiles(sources, "examples.root"));
    assertArrayEquals(expected, artifact);

    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(84, program.global("outcome"));

    String reversibleRoot = "module examples.root; import examples.constants; "
        + "classical class ImportedReversibleConstant { state long outcome = 0; "
        + "rev void bump() { outcome += examples.constants::ANSWER; } "
        + "theorem bumpInverse proves inverse(bump); entry void main() { bump(); "
        + "assert(outcome == 42); reverse { bump(); } assert(outcome == 0); } }";
    byte[] reversibleArtifact = compileNative(compiler, imported, reversibleRoot);
    sources.put("Root.w", reversibleRoot);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        reversibleArtifact);
    VirtualMachine reversibleProgram = new VirtualMachine(
        new BytecodeReader().read(reversibleArtifact));
    reversibleProgram.run();
    assertEquals(0, reversibleProgram.global("outcome"));
  }

  @Test
  void linksTwoDistinctConstantModulesIndependentOfInputOrder() throws Exception {
    Program compiler = program();
    String first = "module examples.alpha; classical class Alpha { "
        + "private const long BASE = 20; public const long LEFT = BASE + 1; }";
    String second = "module examples.beta; classical class Beta { "
        + "public const long RIGHT = 21; public const boolean READY = RIGHT == 21; }";
    String root = "module examples.root; import examples.alpha; import examples.beta; "
        + "classical class ImportedPair { state long outcome = 0; entry void main() { "
        + "long left = examples.alpha::LEFT; long right = RIGHT; long sum = left + right; "
        + "boolean ready = examples.beta::READY; outcome = sum; assert(ready); "
        + "assert(outcome == 42); } }";

    byte[] artifact = compileNative(compiler, List.of(first, second), root);
    assertArrayEquals(artifact, compileNative(compiler, List.of(second, first), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", first);
    sources.put("Beta.w", second);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));
  }

  @Test
  void linksThreeDirectConstantModulesIndependentOfInputOrder() throws Exception {
    Program compiler = program();
    String alpha = "module examples.alpha; classical class Alpha { "
        + "private const long BASE = 20; public const long LEFT = BASE + 1; }";
    String beta = "module examples.beta; classical class Beta { "
        + "public const long MIDDLE = 20; public const boolean READY = MIDDLE == 20; }";
    String gamma = "module examples.gamma; classical class Gamma { "
        + "public const long RIGHT = 1; }";
    String root = "module examples.root; import examples.alpha; import examples.beta; "
        + "import examples.gamma; classical class ImportedTriple { state long outcome = 0; "
        + "entry void main() { long left = examples.alpha::LEFT; long middle = MIDDLE; "
        + "long right = examples.gamma::RIGHT; boolean ready = examples.beta::READY; "
        + "long partial = left + middle; long answer = partial + right; outcome = answer; "
        + "assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(compiler, List.of(alpha, beta, gamma), root);
    assertArrayEquals(artifact, compileNative(compiler, List.of(gamma, alpha, beta), root));
    assertArrayEquals(artifact, compileNative(compiler, List.of(beta, gamma, alpha), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", alpha);
    sources.put("Beta.w", beta);
    sources.put("Gamma.w", gamma);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));
  }

  @Test
  void linksFourDirectConstantModulesIndependentOfInputOrder() throws Exception {
    Program compiler = program();
    String alpha = "module examples.alpha; classical class Alpha { "
        + "public const long ALPHA = 10; }";
    String beta = "module examples.beta; classical class Beta { "
        + "public const long BETA = 11; }";
    String delta = "module examples.delta; classical class Delta { "
        + "public const long DELTA = 9; }";
    String gamma = "module examples.gamma; classical class Gamma { "
        + "public const long GAMMA = 12; public const boolean READY = GAMMA == 12; }";
    String root = "module examples.root; import examples.alpha; import examples.beta; "
        + "import examples.delta; import examples.gamma; classical class DirectFour { "
        + "state long outcome = 0; entry void main() { long alpha = ALPHA; long beta = BETA; "
        + "long delta = examples.delta::DELTA; long gamma = examples.gamma::GAMMA; "
        + "long first = alpha + beta; long second = delta + gamma; "
        + "long answer = first + second; boolean ready = READY; outcome = answer; "
        + "assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(compiler, List.of(alpha, beta, delta, gamma), root);
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(gamma, alpha, delta, beta), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", alpha);
    sources.put("Beta.w", beta);
    sources.put("Delta.w", delta);
    sources.put("Gamma.w", gamma);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));
  }

  @Test
  void linksAFourEdgeConstantChainIndependentOfInputOrder() throws Exception {
    Program compiler = program();
    String leaf = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN = 38; public const long BASE = HIDDEN + 1; }";
    String middle = "module examples.beta; import examples.alpha; "
        + "classical class Beta { public const long FIRST = examples.alpha::BASE + 1; }";
    String firstDependent = "module examples.gamma; import examples.beta; "
        + "classical class Gamma { public const long SECOND = examples.beta::FIRST + 1; }";
    String secondDependent = "module examples.delta; import examples.gamma; "
        + "classical class Delta { public const long ANSWER = examples.gamma::SECOND + 1; "
        + "public const boolean READY = ANSWER == 42; }";
    String root = "module examples.root; import examples.delta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome = examples.delta::ANSWER; "
        + "boolean ready = READY; assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(
        compiler, List.of(leaf, middle, firstDependent, secondDependent), root);
    assertArrayEquals(
        artifact,
        compileNative(
            compiler,
            List.of(secondDependent, middle, leaf, firstDependent),
            root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", leaf);
    sources.put("Beta.w", middle);
    sources.put("Gamma.w", firstDependent);
    sources.put("Delta.w", secondDependent);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(middle, secondDependent, firstDependent, leaf),
        root.replace("outcome = examples.delta::ANSWER;", "outcome = BASE;"));
  }

  @Test
  void linksAThreeLeafConstantForkIndependentOfInputOrder() throws Exception {
    Program compiler = program();
    String left = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN_LEFT = 9; public const long LEFT = HIDDEN_LEFT + 1; }";
    String middle = "module examples.beta; classical class Beta { "
        + "private const long HIDDEN_MIDDLE = 10; "
        + "public const long MIDDLE = HIDDEN_MIDDLE + 1; }";
    String right = "module examples.gamma; classical class Gamma { "
        + "private const long HIDDEN_RIGHT = 20; public const long RIGHT = HIDDEN_RIGHT + 1; }";
    String dependent = "module examples.delta; import examples.alpha; import examples.beta; "
        + "import examples.gamma; classical class Delta { "
        + "private const long PARTIAL = examples.alpha::LEFT + examples.beta::MIDDLE; "
        + "public const long ANSWER = PARTIAL + examples.gamma::RIGHT; "
        + "public const boolean READY = ANSWER == 42; }";
    String root = "module examples.root; import examples.delta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome = examples.delta::ANSWER; "
        + "boolean ready = READY; assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(
        compiler, List.of(left, middle, right, dependent), root);
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(dependent, right, left, middle), root));
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(middle, dependent, right, left), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", left);
    sources.put("Beta.w", middle);
    sources.put("Gamma.w", right);
    sources.put("Delta.w", dependent);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(right, dependent, middle, left),
        root.replace("outcome = examples.delta::ANSWER;", "outcome = LEFT;"));
    assertNativeTrap(
        compiler,
        List.of(dependent, left, right, middle),
        root.replace("outcome = examples.delta::ANSWER;", "outcome = PARTIAL;"));
  }

  @Test
  void linksAThreeEdgeChainBesideADirectModule() throws Exception {
    Program compiler = program();
    String leaf = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN = 38; public const long BASE = HIDDEN + 1; }";
    String middle = "module examples.beta; import examples.alpha; "
        + "classical class Beta { public const long MIDDLE = examples.alpha::BASE + 1; }";
    String dependent = "module examples.gamma; import examples.beta; "
        + "classical class Gamma { public const long LEFT = examples.beta::MIDDLE + 1; }";
    String direct = "module examples.delta; classical class Delta { "
        + "public const long RIGHT = 1; public const boolean READY = RIGHT == 1; }";
    String root = "module examples.root; import examples.delta; import examples.gamma; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "long left = examples.gamma::LEFT; long right = examples.delta::RIGHT; "
        + "long answer = left + right; boolean ready = READY; outcome = answer; "
        + "assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(
        compiler, List.of(leaf, middle, dependent, direct), root);
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(direct, dependent, leaf, middle), root));
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(middle, direct, dependent, leaf), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", leaf);
    sources.put("Beta.w", middle);
    sources.put("Gamma.w", dependent);
    sources.put("Delta.w", direct);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(dependent, leaf, direct, middle),
        root.replace("long left = examples.gamma::LEFT;", "long left = BASE;"));
  }

  @Test
  void linksATwoEdgeChainBesideTwoDirectModules() throws Exception {
    Program compiler = program();
    String leaf = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN = 9; public const long BASE = HIDDEN + 1; }";
    String dependent = "module examples.beta; import examples.alpha; "
        + "classical class Beta { public const long LEFT = examples.alpha::BASE + 1; }";
    String firstDirect = "module examples.gamma; classical class Gamma { "
        + "public const long MIDDLE = 11; public const boolean READY = MIDDLE == 11; }";
    String secondDirect = "module examples.delta; classical class Delta { "
        + "public const long RIGHT = 20; }";
    String root = "module examples.root; import examples.beta; import examples.delta; "
        + "import examples.gamma; classical class Root { state long outcome = 0; "
        + "entry void main() { long left = examples.beta::LEFT; "
        + "long middle = examples.gamma::MIDDLE; long right = examples.delta::RIGHT; "
        + "long partial = left + middle; long answer = partial + right; "
        + "boolean ready = READY; outcome = answer; assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(
        compiler, List.of(leaf, dependent, firstDirect, secondDirect), root);
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(secondDirect, firstDirect, dependent, leaf), root));
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(dependent, secondDirect, leaf, firstDirect), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", leaf);
    sources.put("Beta.w", dependent);
    sources.put("Gamma.w", firstDirect);
    sources.put("Delta.w", secondDirect);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(firstDirect, leaf, secondDirect, dependent),
        root.replace("long left = examples.beta::LEFT;", "long left = BASE;"));
  }

  @Test
  void linksTwoIndependentConstantChains() throws Exception {
    Program compiler = program();
    String leftLeaf = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN_LEFT = 19; "
        + "public const long LEFT_BASE = HIDDEN_LEFT + 1; }";
    String leftDependent = "module examples.beta; import examples.alpha; "
        + "classical class Beta { public const long LEFT = examples.alpha::LEFT_BASE + 1; }";
    String rightLeaf = "module examples.gamma; classical class Gamma { "
        + "private const long HIDDEN_RIGHT = 20; "
        + "public const long RIGHT_BASE = HIDDEN_RIGHT + 1; }";
    String rightDependent = "module examples.delta; import examples.gamma; "
        + "classical class Delta { public const long RIGHT = examples.gamma::RIGHT_BASE; "
        + "public const boolean READY = RIGHT == 21; }";
    String root = "module examples.root; import examples.beta; import examples.delta; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "long left = examples.beta::LEFT; long right = examples.delta::RIGHT; "
        + "long answer = left + right; boolean ready = READY; outcome = answer; "
        + "assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(
        compiler, List.of(leftLeaf, leftDependent, rightLeaf, rightDependent), root);
    assertArrayEquals(
        artifact,
        compileNative(
            compiler,
            List.of(rightDependent, leftLeaf, rightLeaf, leftDependent),
            root));
    assertArrayEquals(
        artifact,
        compileNative(
            compiler,
            List.of(rightLeaf, leftDependent, leftLeaf, rightDependent),
            root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", leftLeaf);
    sources.put("Beta.w", leftDependent);
    sources.put("Gamma.w", rightLeaf);
    sources.put("Delta.w", rightDependent);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(rightDependent, rightLeaf, leftDependent, leftLeaf),
        root.replace("long left = examples.beta::LEFT;", "long left = LEFT_BASE;"));
  }

  @Test
  void linksATwoLeafForkBesideADirectModule() throws Exception {
    Program compiler = program();
    String leftLeaf = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN_LEFT = 9; public const long LEFT = HIDDEN_LEFT + 1; }";
    String rightLeaf = "module examples.beta; classical class Beta { "
        + "private const long HIDDEN_RIGHT = 10; "
        + "public const long MIDDLE = HIDDEN_RIGHT + 1; }";
    String dependent = "module examples.gamma; import examples.alpha; import examples.beta; "
        + "classical class Gamma { private const long PARTIAL = examples.alpha::LEFT; "
        + "public const long BRANCH = PARTIAL + examples.beta::MIDDLE; }";
    String direct = "module examples.delta; classical class Delta { "
        + "public const long DIRECT = 21; public const boolean READY = DIRECT == 21; }";
    String root = "module examples.root; import examples.delta; import examples.gamma; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "long branch = examples.gamma::BRANCH; long direct = examples.delta::DIRECT; "
        + "long answer = branch + direct; boolean ready = READY; outcome = answer; "
        + "assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(
        compiler, List.of(leftLeaf, rightLeaf, dependent, direct), root);
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(direct, dependent, rightLeaf, leftLeaf), root));
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(rightLeaf, direct, leftLeaf, dependent), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", leftLeaf);
    sources.put("Beta.w", rightLeaf);
    sources.put("Gamma.w", dependent);
    sources.put("Delta.w", direct);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(dependent, leftLeaf, direct, rightLeaf),
        root.replace("long branch = examples.gamma::BRANCH;", "long branch = LEFT;"));
    assertNativeTrap(
        compiler,
        List.of(rightLeaf, dependent, leftLeaf, direct),
        root.replace("long branch = examples.gamma::BRANCH;", "long branch = PARTIAL;"));
  }

  @Test
  void linksATwoLeafForkBelowAnotherDependent() throws Exception {
    Program compiler = program();
    String leftLeaf = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN_LEFT = 9; public const long LEFT = HIDDEN_LEFT + 1; }";
    String rightLeaf = "module examples.beta; classical class Beta { "
        + "private const long HIDDEN_RIGHT = 10; "
        + "public const long RIGHT = HIDDEN_RIGHT + 1; }";
    String fork = "module examples.gamma; import examples.alpha; import examples.beta; "
        + "classical class Gamma { public const long BRANCH = "
        + "examples.alpha::LEFT + examples.beta::RIGHT; }";
    String parent = "module examples.delta; import examples.gamma; "
        + "classical class Delta { private const long BIAS = 21; "
        + "public const long ANSWER = examples.gamma::BRANCH + BIAS; "
        + "public const boolean READY = ANSWER == 42; }";
    String root = "module examples.root; import examples.delta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome = examples.delta::ANSWER; "
        + "boolean ready = READY; assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(
        compiler, List.of(leftLeaf, rightLeaf, fork, parent), root);
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(parent, fork, rightLeaf, leftLeaf), root));
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(rightLeaf, parent, leftLeaf, fork), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", leftLeaf);
    sources.put("Beta.w", rightLeaf);
    sources.put("Gamma.w", fork);
    sources.put("Delta.w", parent);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(fork, parent, leftLeaf, rightLeaf),
        root.replace("outcome = examples.delta::ANSWER;", "outcome = BRANCH;"));
  }

  @Test
  void linksAnUnevenNestedConstantFork() throws Exception {
    Program compiler = program();
    String leaf = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN = 9; public const long BASE = HIDDEN + 1; }";
    String middle = "module examples.beta; import examples.alpha; "
        + "classical class Beta { public const long DEEP = examples.alpha::BASE + 10; }";
    String otherLeaf = "module examples.gamma; classical class Gamma { "
        + "private const long BIAS = 21; public const long SHALLOW = BIAS + 1; }";
    String dependent = "module examples.delta; import examples.beta; import examples.gamma; "
        + "classical class Delta { public const long ANSWER = "
        + "examples.beta::DEEP + examples.gamma::SHALLOW; "
        + "public const boolean READY = ANSWER == 42; }";
    String root = "module examples.root; import examples.delta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome = examples.delta::ANSWER; "
        + "boolean ready = READY; assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(
        compiler, List.of(leaf, middle, otherLeaf, dependent), root);
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(dependent, otherLeaf, leaf, middle), root));
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(middle, dependent, leaf, otherLeaf), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", leaf);
    sources.put("Beta.w", middle);
    sources.put("Gamma.w", otherLeaf);
    sources.put("Delta.w", dependent);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(otherLeaf, dependent, middle, leaf),
        root.replace("outcome = examples.delta::ANSWER;", "outcome = DEEP;"));
    assertNativeTrap(
        compiler,
        List.of(dependent, leaf, otherLeaf, middle),
        root.replace("outcome = examples.delta::ANSWER;", "outcome = SHALLOW;"));
  }

  @Test
  void linksASharedDependencyConstantDiamond() throws Exception {
    Program compiler = program();
    String leaf = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN = 9; public const long BASE = HIDDEN + 1; }";
    String left = "module examples.beta; import examples.alpha; "
        + "classical class Beta { public const long LEFT = examples.alpha::BASE + 10; }";
    String right = "module examples.gamma; import examples.alpha; "
        + "classical class Gamma { public const long RIGHT = examples.alpha::BASE + 12; }";
    String join = "module examples.delta; import examples.beta; import examples.gamma; "
        + "classical class Delta { public const long ANSWER = "
        + "examples.beta::LEFT + examples.gamma::RIGHT; "
        + "public const boolean READY = ANSWER == 42; }";
    String root = "module examples.root; import examples.delta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome = examples.delta::ANSWER; "
        + "boolean ready = READY; assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(compiler, List.of(leaf, left, right, join), root);
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(join, right, leaf, left), root));
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(left, leaf, join, right), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", leaf);
    sources.put("Beta.w", left);
    sources.put("Gamma.w", right);
    sources.put("Delta.w", join);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(right, join, left, leaf),
        root.replace("outcome = examples.delta::ANSWER;", "outcome = BASE;"));
  }

  @Test
  void linksATransitiveConstantChainWithoutReexportingTheLeaf() throws Exception {
    Program compiler = program();
    String leaf = "module examples.alpha; classical class Alpha { "
        + "private const long OFFSET = 2; public const long BASE = 40; "
        + "public const long SUM = BASE + OFFSET; public const long ZERO = 0; "
        + "public const boolean READY = SUM == 42; }";
    String dependent = "module examples.beta; import examples.alpha; "
        + "classical class Beta { public const long ANSWER = SUM + examples.alpha::ZERO; "
        + "public const boolean VALID = READY; }";
    String root = "module examples.root; import examples.beta; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome = ANSWER; "
        + "boolean valid = VALID; assert(valid); assert(outcome == 42); } }";

    byte[] artifact = compileNative(compiler, List.of(leaf, dependent), root);
    assertArrayEquals(artifact, compileNative(compiler, List.of(dependent, leaf), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", leaf);
    sources.put("Beta.w", dependent);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(leaf, dependent),
        root.replace("outcome = ANSWER;", "outcome = BASE;"));
  }

  @Test
  void linksAChainBesideADirectConstantModule() throws Exception {
    Program compiler = program();
    String leaf = "module examples.alpha; classical class Alpha { "
        + "private const long BASE = 20; public const long LEFT_BASE = BASE; }";
    String dependent = "module examples.beta; import examples.alpha; "
        + "classical class Beta { public const long LEFT = examples.alpha::LEFT_BASE + 1; }";
    String direct = "module examples.gamma; classical class Gamma { "
        + "public const long RIGHT = 21; public const boolean READY = RIGHT == 21; }";
    String root = "module examples.root; import examples.beta; import examples.gamma; "
        + "classical class Root { state long outcome = 0; entry void main() { "
        + "long left = examples.beta::LEFT; long right = examples.gamma::RIGHT; "
        + "boolean ready = READY; long sum = left + right; outcome = sum; "
        + "assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(compiler, List.of(leaf, dependent, direct), root);
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(direct, leaf, dependent), root));
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(dependent, direct, leaf), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", leaf);
    sources.put("Beta.w", dependent);
    sources.put("Gamma.w", direct);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(dependent, direct, leaf),
        root.replace("long left = examples.beta::LEFT;", "long left = BASE;"));
  }

  @Test
  void linksATwoLeafConstantForkWithoutTransitiveExports() throws Exception {
    Program compiler = program();
    String left = "module examples.alpha; classical class Alpha { "
        + "private const long LEFT_BASE = 19; public const long LEFT = LEFT_BASE + 1; }";
    String right = "module examples.beta; classical class Beta { "
        + "private const long RIGHT_BASE = 21; public const long RIGHT = RIGHT_BASE + 1; }";
    String dependent = "module examples.gamma; import examples.alpha; import examples.beta; "
        + "classical class Gamma { public const long ANSWER = "
        + "examples.alpha::LEFT + examples.beta::RIGHT; "
        + "public const boolean READY = ANSWER == 42; }";
    String root = "module examples.root; import examples.gamma; classical class Root { "
        + "state long outcome = 0; entry void main() { outcome = examples.gamma::ANSWER; "
        + "boolean ready = READY; assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(compiler, List.of(left, right, dependent), root);
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(dependent, right, left), root));
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(right, dependent, left), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", left);
    sources.put("Beta.w", right);
    sources.put("Gamma.w", dependent);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(dependent, left, right),
        root.replace("outcome = examples.gamma::ANSWER;", "outcome = LEFT;"));
    assertNativeTrap(
        compiler,
        List.of(right, dependent, left),
        root.replace("outcome = examples.gamma::ANSWER;", "outcome = RIGHT;"));
  }

  @Test
  void linksAThreeEdgeConstantChainWithoutTransitiveExports() throws Exception {
    Program compiler = program();
    String leaf = "module examples.alpha; classical class Alpha { "
        + "private const long HIDDEN = 39; public const long BASE = HIDDEN + 1; }";
    String middle = "module examples.beta; import examples.alpha; "
        + "classical class Beta { public const long PARTIAL = examples.alpha::BASE + 1; }";
    String dependent = "module examples.gamma; import examples.beta; "
        + "classical class Gamma { public const long ANSWER = examples.beta::PARTIAL + 1; "
        + "public const boolean READY = ANSWER == 42; }";
    String root = "module examples.root; import examples.gamma; classical class Root { "
        + "state long outcome = 0; entry void main() { "
        + "outcome = examples.gamma::ANSWER; boolean ready = examples.gamma::READY; "
        + "assert(ready); assert(outcome == 42); } }";

    byte[] artifact = compileNative(compiler, List.of(leaf, middle, dependent), root);
    assertArrayEquals(
        artifact,
        compileNative(compiler, List.of(dependent, leaf, middle), root));
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put("Alpha.w", leaf);
    sources.put("Beta.w", middle);
    sources.put("Gamma.w", dependent);
    sources.put("Root.w", root);
    assertArrayEquals(
        new BytecodeWriter().write(
            new WheelerCompiler().compileModuleFiles(sources, "examples.root")),
        artifact);
    VirtualMachine program = new VirtualMachine(new BytecodeReader().read(artifact));
    program.run();
    assertEquals(42, program.global("outcome"));

    assertNativeTrap(
        compiler,
        List.of(middle, dependent, leaf),
        root.replace("outcome = examples.gamma::ANSWER;", "outcome = BASE;"));
    assertNativeTrap(
        compiler,
        List.of(leaf, middle, dependent),
        root.replace("outcome = examples.gamma::ANSWER;", "outcome = PARTIAL;"));
  }

  @Test
  void rejectsInaccessibleMismatchedAndNonconstantImportsBeforePublication() throws Exception {
    Program compiler = program();
    String root = "module examples.root; import examples.constants; "
        + "classical class Root { entry void main() { long value = ANSWER; } }";
    assertNativeTrap(
        compiler,
        "module examples.constants; classical class Constants { "
            + "private const long ANSWER = 42; }",
        root);
    assertNativeTrap(
        compiler,
        "module examples.other; classical class Constants { "
            + "public const long ANSWER = 42; }",
        root);
    assertNativeTrap(
        compiler,
        "module examples.constants; classical class Constants { "
            + "public const long ANSWER = 42; public void helper() { } }",
        root);
    assertNativeTrap(
        compiler,
        "module examples.constants; classical class Constants { "
            + "private const long HIDDEN = 40; public const long ANSWER = HIDDEN + 2; }",
        root.replace("long value = ANSWER;", "long HIDDEN = 0; long value = ANSWER;"));
    assertNativeTrap(
        compiler,
        "module examples.constants; import examples.transitive; "
            + "classical class Constants { public const long ANSWER = 42; }",
        root);
    assertNativeTrap(
        compiler,
        "module examples.constants; classical class Constants { "
            + "public const boolean ANSWER = true; }",
        root);
    assertNativeTrap(
        compiler,
        "module examples.constants; classical class Constants { "
            + "public const long ANSWER = 42; }",
        root.replace("ANSWER", "examples.other::ANSWER"));
    assertNativeTrap(
        compiler,
        "module examples.constants; classical class Constants { "
            + "public const long ANSWER = 42; }",
        root.replace(
            "import examples.constants;",
            "import examples.constants; import examples.other;"));
    assertNativeTrap(
        compiler,
        "module examples.constants; classical class Constants { "
            + "public const long ANSWER = 42; }",
        root + " /* café */");
    String firstCollision = "module examples.alpha; classical class Alpha { "
        + "public const long VALUE = 1; }";
    String secondCollision = "module examples.beta; classical class Beta { "
        + "public const long VALUE = 2; }";
    String collisionRoot = "module examples.root; import examples.alpha; "
        + "import examples.beta; classical class Root { entry void main() { "
        + "long first = examples.alpha::VALUE; long second = examples.beta::VALUE; } }";
    assertNativeTrap(
        compiler,
        List.of(firstCollision, secondCollision),
        collisionRoot);
    assertNativeTrap(
        compiler,
        List.of(firstCollision, secondCollision, secondCollision),
        collisionRoot);
    String thirdDistinct = "module examples.gamma; classical class Gamma { "
        + "public const long THIRD = 3; }";
    String tripleCollisionRoot = "module examples.root; import examples.alpha; "
        + "import examples.beta; import examples.gamma; classical class Root { "
        + "entry void main() { long first = examples.alpha::VALUE; "
        + "long second = examples.beta::VALUE; long third = examples.gamma::THIRD; } }";
    assertNativeTrap(
        compiler,
        List.of(firstCollision, secondCollision, thirdDistinct),
        tripleCollisionRoot);
    assertNativeTrap(
        compiler,
        List.of(firstCollision, secondCollision, firstCollision, secondCollision),
        collisionRoot);
    assertNativeTrap(
        compiler,
        List.of(
            firstCollision,
            secondCollision,
            firstCollision,
            secondCollision,
            firstCollision),
        collisionRoot);
    String threeCycleAlpha = "module examples.alpha; import examples.gamma; "
        + "classical class Alpha { public const long ALPHA = GAMMA; }";
    String threeCycleBeta = "module examples.beta; import examples.alpha; "
        + "classical class Beta { public const long BETA = ALPHA; }";
    String threeCycleGamma = "module examples.gamma; import examples.beta; "
        + "classical class Gamma { public const long GAMMA = BETA; }";
    assertNativeTrap(
        compiler,
        List.of(threeCycleBeta, threeCycleGamma, threeCycleAlpha),
        "module examples.root; import examples.gamma; classical class Root { "
            + "entry void main() { long value = GAMMA; } }");
    String cyclicAlpha = "module examples.alpha; import examples.beta; "
        + "classical class Alpha { public const long LEFT = RIGHT; }";
    String cyclicBeta = "module examples.beta; import examples.alpha; "
        + "classical class Beta { public const long RIGHT = LEFT; }";
    assertNativeTrap(
        compiler,
        List.of(cyclicAlpha, cyclicBeta),
        "module examples.root; import examples.alpha; classical class Root { "
            + "entry void main() { long value = LEFT; } }");
  }

  private static Program program() throws Exception {
    Map<String, String> modules = CompilerSources.compilerDriverModules();
    modules.put("Binary.w", CoreSources.read("encoding/Binary.w"));
    modules.put("NativeModuleCompiler.w", Files.readString(FIXTURE));
    return new WheelerCompiler().compileModuleFiles(
        modules, "examples.compiler.native_module_compiler");
  }

  private static byte[] frame(List<String> imported, String root) {
    List<byte[]> importedBytes = imported.stream()
        .map(source -> source.getBytes(StandardCharsets.UTF_8))
        .toList();
    byte[] rootBytes = root.getBytes(StandardCharsets.UTF_8);
    int length = 4 + rootBytes.length;
    for (byte[] source : importedBytes) {
      length += 4 + source.length;
    }
    byte[] frame = new byte[length];
    int cursor = writeU32(frame, 0, importedBytes.size());
    for (byte[] source : importedBytes) {
      cursor = writeU32(frame, cursor, source.length);
      System.arraycopy(source, 0, frame, cursor, source.length);
      cursor += source.length;
    }
    System.arraycopy(rootBytes, 0, frame, cursor, rootBytes.length);
    return frame;
  }

  private static int writeU32(byte[] output, int offset, int value) {
    output[offset] = (byte) value;
    output[offset + 1] = (byte) (value >>> 8);
    output[offset + 2] = (byte) (value >>> 16);
    output[offset + 3] = (byte) (value >>> 24);
    return offset + 4;
  }

  private static byte[] compileNative(Program compiler, String imported, String root) {
    return compileNative(compiler, List.of(imported), root);
  }

  private static byte[] compileNative(
      Program compiler, List<String> imported, String root) {
    VirtualMachine writer = VirtualMachine.withBinaryInput(
        compiler, frame(imported, root), OUTPUT_CAPACITY);
    CompilerMachineRunner.runWithoutRewindHistory(writer);
    assertEquals(1, writer.global("published"));
    return writer.hostOutput();
  }

  private static void assertNativeTrap(Program compiler, String imported, String root) {
    assertNativeTrap(compiler, List.of(imported), root);
  }

  private static void assertNativeTrap(
      Program compiler, List<String> imported, String root) {
    VirtualMachine writer = VirtualMachine.withBinaryInput(
        compiler, frame(imported, root), OUTPUT_CAPACITY);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(writer));
    assertArrayEquals(new byte[OUTPUT_CAPACITY], writer.hostOutput());
  }
}
