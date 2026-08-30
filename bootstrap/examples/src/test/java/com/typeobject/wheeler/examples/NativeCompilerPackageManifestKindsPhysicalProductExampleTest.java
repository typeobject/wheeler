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

/** Native evidence for package-manifest scalar token kinds. */
final class NativeCompilerPackageManifestKindsPhysicalProductExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_kinds";
  private static final String TOKEN_VALUES =
      "true false \"deployable\" \"library\" \"tool\" \"normal\" "
          + "\"development\" \"build\" \"other\" other";

  @Tag("closure-evidence")
  @Test
  void retainsManifestKindsAndRelocatesTokenPolicy() throws Exception {
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
    assertEquals(5, machine.global("physicalCallableRelocationCount"));
    assertEquals(
        machine.global("physicalCallableRelocationCount"),
        machine.global("physicalResolvedCallableTargetCount"));
  }

  @Test
  void executesEveryManifestKind() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestKindsExample.w", """
        module example.package_manifest_kinds;
        import wheeler.compiler.packages.manifest_kinds;
        classical class PackageManifestKindsExample {
          entry void main(borrow utf8 source) {
            region rows = new region(/* bytes= */ 320, /* allocations= */ 3);
            words kinds = allocate(rows, /* length= */ 10);
            words starts = allocate(rows, /* length= */ 10);
            words lengths = allocate(rows, /* length= */ 10);
            set(lengths, 0, 4);
            set(starts, 1, 5);
            set(lengths, 1, 5);
            set(starts, 2, 11);
            set(lengths, 2, 12);
            set(starts, 3, 24);
            set(lengths, 3, 9);
            set(starts, 4, 34);
            set(lengths, 4, 6);
            set(starts, 5, 41);
            set(lengths, 5, 8);
            set(starts, 6, 50);
            set(lengths, 6, 13);
            set(starts, 7, 64);
            set(lengths, 7, 7);
            set(starts, 8, 72);
            set(lengths, 8, 7);
            set(starts, 9, 80);
            set(lengths, 9, 5);
            long token = 2;
            while (token < 9) limit 7 {
              set(kinds, token, 6);
              token += 1;
            }

            assert(manifestBooleanToken(source, starts, lengths, 0) == 1);
            assert(manifestBooleanToken(source, starts, lengths, 1) == 0);
            assert(manifestBooleanToken(source, starts, lengths, 9) == -1);
            assert(manifestTargetKind(source, kinds, starts, lengths, 2) == 1);
            assert(manifestTargetKind(source, kinds, starts, lengths, 3) == 2);
            assert(manifestTargetKind(source, kinds, starts, lengths, 4) == 3);
            assert(manifestTargetKind(source, kinds, starts, lengths, 8) == 0);
            assert(manifestTargetKind(source, kinds, starts, lengths, 9) == 0);
            assert(manifestDependencyKind(source, kinds, starts, lengths, 5) == 1);
            assert(manifestDependencyKind(source, kinds, starts, lengths, 6) == 2);
            assert(manifestDependencyKind(source, kinds, starts, lengths, 7) == 3);
            assert(manifestDependencyKind(source, kinds, starts, lengths, 8) == 0);
            assert(manifestDependencyKind(source, kinds, starts, lengths, 9) == 0);
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(rows);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_manifest_kinds");
    new VirtualMachine(program, TOKEN_VALUES.getBytes(StandardCharsets.US_ASCII)).run();
  }

  private static byte[] framed(byte[] archive, byte[] manifest) {
    return ByteBuffer.allocate(Integer.BYTES + archive.length + manifest.length)
        .order(ByteOrder.LITTLE_ENDIAN).putInt(archive.length).put(archive).put(manifest).array();
  }
}
