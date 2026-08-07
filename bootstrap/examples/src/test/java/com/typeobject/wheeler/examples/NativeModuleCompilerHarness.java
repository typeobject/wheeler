package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;

/** Shared binary-frame harness for Wheeler-native module compiler fixtures. */
final class NativeModuleCompilerHarness {
  private static final Path FIXTURE = Path.of(
      "../wheeler-conformance/src/main/wheeler/compiler/NativeModuleCompiler.w");
  private static final int OUTPUT_CAPACITY = 32_768;

  private NativeModuleCompilerHarness() {}

  static Program program() throws Exception {
    Map<String, String> modules = CompilerSources.compilerDriverModules();
    CoreSources.addBinaryClosure(modules);
    modules.put("NativeModuleCompiler.w", Files.readString(FIXTURE));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.compiler.native_module_compiler");
  }

  static byte[] compile(Program compiler, String imported, String root) {
    return compile(compiler, List.of(imported), root);
  }

  static byte[] compile(Program compiler, List<String> imported, String root) {
    VirtualMachine writer = VirtualMachine.withBinaryInput(
        compiler, frame(imported, root), OUTPUT_CAPACITY);
    CompilerMachineRunner.runWithoutRewindHistory(writer);
    assertEquals(1, writer.global("published"));
    return writer.hostOutput();
  }

  static void assertTrap(Program compiler, String imported, String root) {
    assertTrap(compiler, List.of(imported), root);
  }

  static void assertTrap(Program compiler, List<String> imported, String root) {
    VirtualMachine writer = VirtualMachine.withBinaryInput(
        compiler, frame(imported, root), OUTPUT_CAPACITY);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(writer));
    assertArrayEquals(new byte[OUTPUT_CAPACITY], writer.hostOutput());
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
}
