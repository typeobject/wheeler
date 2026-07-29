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
        + "public const long ANSWER = BASE + 2; public const long BASE = 40; }";
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
  }

  private static Program program() throws Exception {
    Map<String, String> modules = CompilerSources.compilerDriverModules();
    modules.put("Binary.w", CoreSources.read("encoding/Binary.w"));
    modules.put("NativeModuleCompiler.w", Files.readString(FIXTURE));
    return new WheelerCompiler().compileModuleFiles(
        modules, "examples.compiler.native_module_compiler");
  }

  private static byte[] frame(String imported, String root) {
    byte[] importedBytes = imported.getBytes(StandardCharsets.UTF_8);
    byte[] rootBytes = root.getBytes(StandardCharsets.UTF_8);
    byte[] frame = new byte[4 + importedBytes.length + rootBytes.length];
    int length = importedBytes.length;
    frame[0] = (byte) length;
    frame[1] = (byte) (length >>> 8);
    frame[2] = (byte) (length >>> 16);
    frame[3] = (byte) (length >>> 24);
    System.arraycopy(importedBytes, 0, frame, 4, importedBytes.length);
    System.arraycopy(rootBytes, 0, frame, 4 + importedBytes.length, rootBytes.length);
    return frame;
  }

  private static byte[] compileNative(Program compiler, String imported, String root) {
    VirtualMachine writer = VirtualMachine.withBinaryInput(
        compiler, frame(imported, root), OUTPUT_CAPACITY);
    CompilerMachineRunner.runWithoutRewindHistory(writer);
    assertEquals(1, writer.global("published"));
    return writer.hostOutput();
  }

  private static void assertNativeTrap(Program compiler, String imported, String root) {
    VirtualMachine writer = VirtualMachine.withBinaryInput(
        compiler, frame(imported, root), OUTPUT_CAPACITY);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(writer));
    assertArrayEquals(new byte[OUTPUT_CAPACITY], writer.hostOutput());
  }
}
