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

/** Differential coverage for one Wheeler-native public-constant import. */
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
