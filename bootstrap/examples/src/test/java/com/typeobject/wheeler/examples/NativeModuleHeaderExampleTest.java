package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential coverage for bounded native module and direct-import headers. */
class NativeModuleHeaderExampleTest {
  private static final int OUTPUT_CAPACITY = 1_024;
  private static final int MAX_NATIVE_IMPORTS = 64;

  @Test
  void compilesAZeroImportFrameByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String source = CompilerSources.read("compiler/backend/EncodingWidths.w");
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("compiler/backend/EncodingWidths.w", source),
            "wheeler.compiler.encoding_widths"));
    assertArrayEquals(
        expected,
        NativeModuleCompilerHarness.compile(compiler, List.of(), source));

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(),
        source.replace("module wheeler.compiler.encoding_widths;", "module ;"));
  }

  @Test
  void acceptsSortedDirectImportsWithoutChangingRootArtifactIdentity() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String root = "module examples.root; import examples.alpha; import examples.beta; "
        + "classical class ImportedHeader { const long ANSWER = 42; "
        + "entry void main() { long answer = ANSWER; assert(answer == 42); } }";
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put(
        "Alpha.w",
        "module examples.alpha; classical class Alpha { public const long VALUE = 1; }");
    sources.put(
        "Beta.w",
        "module examples.beta; classical class Beta { public const long VALUE = 2; }");
    sources.put("Root.w", root);

    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileModuleFiles(sources, "examples.root"));
    assertArrayEquals(expected, compileNative(compiler, root));
  }

  @Test
  void acceptsTheExactDirectImportLimit() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    StringBuilder root = new StringBuilder("module examples.root; ");
    Map<String, String> sources = new LinkedHashMap<>();
    for (int index = 0; index < MAX_NATIVE_IMPORTS; index++) {
      String suffix = String.format(Locale.ROOT, "%02d", index);
      String module = "examples.module_" + suffix;
      root.append("import ").append(module).append("; ");
      sources.put(
          "Module" + suffix + ".w",
          "module " + module + "; classical class Module" + suffix + " { }");
    }
    root.append("classical class ImportLimit { entry void main() { } }");
    sources.put("Root.w", root.toString());

    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileModuleFiles(sources, "examples.root"));
    assertArrayEquals(expected, compileNative(compiler, root.toString()));
  }

  @Test
  void rejectsMalformedUnsortedDuplicateAndExcessImportsBeforePublication() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String body = " classical class InvalidImports { entry void main() { } }";
    assertNativeTrap(
        compiler,
        "module examples.root; import examples.beta; import examples.alpha;" + body);
    assertNativeTrap(
        compiler,
        "module examples.root; import examples.alpha; import examples.alpha;" + body);
    assertNativeTrap(
        compiler,
        "module examples.root; import examples.;" + body);

    StringBuilder excess = new StringBuilder("module examples.root; ");
    for (int index = 0; index <= MAX_NATIVE_IMPORTS; index++) {
      excess.append("import examples.module_")
          .append(String.format(Locale.ROOT, "%02d", index))
          .append("; ");
    }
    excess.append("classical class ExcessImports { entry void main() { } }");
    assertNativeTrap(compiler, excess.toString());
  }

  private static byte[] compileNative(Program compiler, String source) {
    VirtualMachine writer = new VirtualMachine(
        compiler, source.getBytes(StandardCharsets.UTF_8), OUTPUT_CAPACITY);
    CompilerMachineRunner.runWithoutRewindHistory(writer);
    return writer.hostOutput();
  }

  private static void assertNativeTrap(Program compiler, String source) {
    VirtualMachine writer = new VirtualMachine(
        compiler, source.getBytes(StandardCharsets.UTF_8), OUTPUT_CAPACITY);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(writer));
    assertArrayEquals(new byte[OUTPUT_CAPACITY], writer.hostOutput());
  }
}
