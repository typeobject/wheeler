package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native byte parity for the direct manifest-syntax product. */
final class NativeCompilerManifestProductExampleTest {
  private static final String ASSERTIONS =
      "compiler/closure/syntax/ManifestAssertions.w";
  private static final String ASSERTIONS_MODULE =
      "wheeler.compiler.closure.manifest_assertions";
  private static final String PROFILE = "compiler/closure/syntax/ManifestProfile.w";
  private static final String PROFILE_MODULE = "wheeler.compiler.closure.manifest_profile";

  @Test
  void compilesPhysicalManifestAssertionsByteForByte() throws Exception {
    assertPhysicalLibrary(ASSERTIONS, ASSERTIONS_MODULE, "requireMetadata");
  }

  @Test
  void compilesPhysicalManifestProfileByteForByte() throws Exception {
    assertPhysicalLibrary(PROFILE, PROFILE_MODULE, "profileByte");
  }

  private static void assertPhysicalLibrary(
      String path, String module, String function) throws Exception {
    String source = CompilerSources.read(path);
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(Map.of(path, source), module));

    assertArrayEquals(expected, actual);
    var decoded = new BytecodeReader().read(actual);
    assertEquals(module + "::" + function, decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Tag("closure-evidence")
  @Test
  void compilesManifestSyntaxThroughDirectProducts() throws Exception {
    var module = NativeCompilerArchiveClosureProgram.PHYSICAL_MANIFEST_MODULE;
    Program productProgram = NativeCompilerPhysicalPrograms.comparable(
        NativeCompilerArchiveClosureProgram.PHYSICAL_MANIFEST_MODULE);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            CompilerSources.moduleClosure(module.name()), module.name()));
    byte[] archive = CompilerSources.packageArchive();
    byte[] manifest = CompilerSources.bootstrapModuleManifest().canonicalBytes();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(archive, manifest),
        expected.length + 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals("wheeler.compiler.closure.manifest_syntax", module.name());
    assertArrayEquals(expected, Arrays.copyOf(machine.hostOutput(), expected.length));
    assertEquals(expected.length, machine.global("physicalModuleProductLength"));
  }

  private static byte[] framed(byte[] archive, byte[] manifest) {
    return ByteBuffer.allocate(Integer.BYTES + archive.length + manifest.length)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putInt(archive.length)
        .put(archive)
        .put(manifest)
        .array();
  }
}
