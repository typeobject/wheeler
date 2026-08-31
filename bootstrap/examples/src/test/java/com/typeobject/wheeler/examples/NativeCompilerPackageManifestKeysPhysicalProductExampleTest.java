package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for package-manifest mapping keys. */
final class NativeCompilerPackageManifestKeysPhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_keys";

  @Tag("closure-evidence")
  @Test
  void retainsManifestKeysAndRelocatesTokenPolicy() throws Exception {
    var module = NativeCompilerPhysicalSelection.callable(MODULE);
    var expected = new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(module.name()), module.name());
    long expectedFunctions = 0;
    long expectedInstructions = 0;
    for (var function : expected.functions()) {
      if (function.name().startsWith(module.name() + "::")) {
        expectedFunctions += 1;
        expectedInstructions += function.forward().size();
        expectedInstructions += function.inverse().size();
      }
    }
    var machine = VirtualMachine.withBinaryInput(
        NativeCompilerPhysicalPrograms.callable(module),
        framed(
            CompilerSources.packageArchive(),
            CompilerSources.bootstrapModuleManifest().canonicalBytes()),
        1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(expectedFunctions, machine.global("physicalRetainedFunctionCount"));
    assertEquals(expectedInstructions, machine.global("physicalRetainedInstructionCount"));
    assertEquals(2, machine.global("physicalCallableRelocationCount"));
    assertEquals(
        machine.global("physicalCallableRelocationCount"),
        machine.global("physicalResolvedCallableTargetCount"));
  }

  @Test
  void executesKeywordColonHashAndBoundsChecks() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestKeysExample.w", """
        module example.package_manifest_keys;

        import wheeler.compiler.packages.manifest_keys;

        classical class PackageManifestKeysExample {
          entry void main(borrow utf8 source) {
            region tokens = new region(/* bytes= */ 192, /* allocations= */ 3);
            words kinds = allocate(tokens, /* length= */ 5);
            words starts = allocate(tokens, /* length= */ 5);
            words lengths = allocate(tokens, /* length= */ 5);
            set(kinds, 1, 3);
            set(kinds, 4, 3);
            set(starts, 1, 4);
            set(starts, 2, 6);
            set(starts, 3, 12);
            set(starts, 4, 13);
            set(lengths, 0, 4);
            set(lengths, 1, 1);
            set(lengths, 2, 5);
            set(lengths, 3, 1);
            set(lengths, 4, 1);
            assert(manifestKeyAt(source, kinds, starts, lengths, 5, 0, 3373707));
            assert(manifestKeyAt(source, kinds, starts, lengths, 5, 0, 3292052) == false);
            assert(manifestKeyAt(source, kinds, starts, lengths, 5, 2, 3373707) == false);
            assert(manifestKeyAt(source, kinds, starts, lengths, 5, 3, 120));
            assert(manifestKeyAt(source, kinds, starts, lengths, 5, 4, 58) == false);
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(tokens);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_manifest_keys");

    new VirtualMachine(program, "name: wrong x:".getBytes(StandardCharsets.US_ASCII)).run();
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
