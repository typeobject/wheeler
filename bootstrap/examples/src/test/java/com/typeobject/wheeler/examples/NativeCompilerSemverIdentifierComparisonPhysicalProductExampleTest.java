package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for semantic-version identifier comparison over core helpers. */
final class NativeCompilerSemverIdentifierComparisonPhysicalProductExampleTest {
  private static final String MODULE =
      "wheeler.compiler.packages.semver_identifier_comparison";

  @Tag("closure-evidence")
  @Test
  void retainsIdentifierComparisonAndRelocatesCoreCalls() throws Exception {
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

    var productProgram = NativeCompilerPhysicalPrograms.callable(module);
    byte[] archive = CompilerSources.packageArchive();
    byte[] manifest = CompilerSources.bootstrapModuleManifest().canonicalBytes();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        productProgram,
        framed(archive, manifest),
        1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(expectedFunctions, machine.global("physicalRetainedFunctionCount"));
    byte[] output = machine.hostOutput();
    int metadata = output.length - 14
        - Math.toIntExact(machine.global("physicalCallableRelocationCount")) * 6;
    int artifactLength = (output[metadata + 2] & 0xff) << 16
        | (output[metadata + 3] & 0xff) << 8
        | output[metadata + 4] & 0xff;
    var actual = new BytecodeReader().read(Arrays.copyOf(output, artifactLength));
    for (var function : expected.functions()) {
      if (function.name().startsWith(module.name() + "::")) {
        var actualFunction = actual.functions().stream()
            .filter(candidate -> candidate.name().equals(function.name()))
            .findFirst()
            .orElseThrow();
        assertEquals(
            function.forward().size() + function.inverse().size(),
            actualFunction.forward().size() + actualFunction.inverse().size(),
            function.name());
      }
    }
    assertEquals(expectedInstructions, machine.global("physicalRetainedInstructionCount"));
    assertEquals(1, machine.global("physicalCallableProductCount"));
    assertTrue(0 < machine.global("physicalCallableRelocationCount"));
    assertEquals(
        machine.global("physicalCallableRelocationCount"),
        machine.global("physicalResolvedCallableTargetCount"));
  }

  @Test
  void executesIdentifierPrecedence() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("SemverIdentifierComparisonExample.w", """
        module example.semver_identifier_comparison;

        import wheeler.compiler.packages.semver_identifier_comparison;

        classical class SemverIdentifierComparisonExample {
          entry void main(borrow utf8 source) {
            assert(semverNumericIdentifier(source, 0, 1));
            assert(semverNumericIdentifier(source, 2, 3) == false);
            assert(semverCompareIdentifier(source, 0, 1, 2, 3) == -1);
            assert(semverCompareIdentifier(source, 4, 5, 6, 8) == -1);
            assert(semverCompareIdentifier(source, 9, 13, 14, 19) == 1);
            assert(semverCompareIdentifier(source, 14, 19, 20, 26) == -1);
            assert(semverCompareIdentifier(source, 14, 19, 14, 19) == 0);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.semver_identifier_comparison");
    var machine = new VirtualMachine(
        program, "1.a.2.10.beta.alpha.alpha1".getBytes(StandardCharsets.US_ASCII));

    machine.run();
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
