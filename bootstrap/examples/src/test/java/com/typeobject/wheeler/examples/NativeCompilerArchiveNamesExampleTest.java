package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Archive emission consumes bound declaration names instead of rediscovering raw text. */
final class NativeCompilerArchiveNamesExampleTest {
  private static final String MODULE = "wheeler.compiler.core_parsing";

  @Test
  void ignoresDeclarationWordsInCommentsAndHeaderWhitespace() throws Exception {
    String source = "// café 𝄞 module misleading.name; classical class Ghost {}\n"
        + "/* module other.name; classical class Other {} */\n"
        + CompilerSources.read("compiler/backend/core/CoreParsing.w")
            .replace("module " + MODULE, "module\n" + MODULE)
            .replace("classical class CoreParsing", "classical\n/* header */ class\tCoreParsing")
        + "\n// module trailing.name; classical class Last {}\n";
    var machine = VirtualMachine.withBinaryInput(
        NativeCompilerCoreParsingSourceProductsProgram.program(source),
        source.getBytes(StandardCharsets.UTF_8), 262_144);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertEquals(1, machine.global("archiveArtifactValid"));
    byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(MODULE), MODULE));
    int start = Math.toIntExact(machine.global("artifactOutputStart"));
    assertArrayEquals(expected, Arrays.copyOfRange(machine.hostOutput(), start, start + expected.length));
  }

  @Test
  void rejectsInvalidModuleNameWindowsBeforeArchivePublication() throws Exception {
    String source = CompilerSources.read("compiler/backend/core/CoreParsing.w");
    for (long[] range : new long[][] {{-1, 1}, {Long.MAX_VALUE, 1}, {0, 0}, {0, 257}, {32768, 1}}) {
      var machine = VirtualMachine.withBinaryInput(NativeCompilerCoreParsingSourceProductsProgram.program(
          source, range[0], range[1]), source.getBytes(StandardCharsets.UTF_8), 262_144);
      assertUnpublished(machine);
    }
  }

  @Test
  void rejectsInvalidClassNameWindowsBeforeArchivePublication() throws Exception {
    String source = CompilerSources.read("compiler/backend/core/CoreParsing.w");
    int moduleStart = SourceRanges.utf8Offset(source, source.indexOf(MODULE));
    int bytes = source.getBytes(StandardCharsets.UTF_8).length;
    long[][] rejected = {{-1, 1}, {Long.MIN_VALUE, 1}, {Long.MAX_VALUE, 1},
        {0, 0}, {0, -1}, {0, Long.MAX_VALUE}, {0, 257}, {bytes, 1}, {bytes - 1, 2}};
    for (long[] range : rejected) {
      var machine = VirtualMachine.withBinaryInput(NativeCompilerCoreParsingSourceProductsProgram.program(
          source, moduleStart, MODULE.length(), range[0], range[1]),
          source.getBytes(StandardCharsets.UTF_8), 262_144);
      assertUnpublished(machine);
    }
  }

  private static void assertUnpublished(VirtualMachine machine) {
    VmTrap trap = assertThrows(VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertTrue(trap.getMessage().contains("::requireArchiveSourceNames"));
    assertEquals(0, machine.global("archiveArtifactValid"));
    assertEquals(0, machine.global("archivedArtifactCount"));
    var snapshot = machine.snapshot();
    int region = snapshot.regions().stream()
        .filter(row -> row.maxBytes() == 32800 && row.maxObjects() == 2)
        .findFirst().orElseThrow().id();
    var publication = snapshot.buffers().stream().filter(row -> row.regionId() == region).toList();
    assertEquals(List.of(32768, 32), publication.stream().map(row -> row.length()).toList());
    for (var buffer : publication) {
      assertFalse(buffer.dropped());
      for (long cell : buffer.elements()) {
        assertEquals(0, cell, "unpublished artifact or identity");
      }
    }
  }
}
