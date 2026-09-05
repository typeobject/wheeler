package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Callable-free archive products use the same bound class-name windows. */
final class NativeCompilerEmptyArchiveNamesExampleTest {
  private static final String MODULE = "example.empty";
  private static final String PREFIX = "classical class Outside {}\n";

  @Test
  void emitsBothCallableFreePathsWithTheLastAdmittedClassName() throws Exception {
    for (boolean imported : new boolean[] {false, true}) {
      for (String name : new String[] {"Empty", "A".repeat(256)}) {
        Fixture fixture = fixture(name, imported, null);
        VirtualMachine machine = fixture.machine();
        CompilerMachineRunner.runWithoutRewindHistory(machine);
        byte[] expected = new BytecodeWriter().write(new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("Empty.w", fixture.source()), MODULE));
        assertEquals(1, machine.global("published"));
        assertArrayEquals(expected, machine.hostOutput());
      }
    }
  }

  @Test
  void rejectsClassNamesOutsideTheirSourceAndTheFirstExcessLength() throws Exception {
    for (boolean imported : new boolean[] {false, true}) {
      Fixture valid = fixture("Empty", imported, null);
      long sourceEnd = PREFIX.length() + valid.source().length();
      assertUnpublished(fixture("A".repeat(257), imported, null));
      for (long[] range : new long[][] {{0, 1}, {PREFIX.length() - 1, 1},
          {sourceEnd, 1}, {sourceEnd - 1, 2}}) {
        assertUnpublished(fixture("Empty", imported, range));
      }
    }
  }

  private static void assertUnpublished(Fixture fixture) {
    VirtualMachine machine = fixture.machine();
    VmTrap trap = assertThrows(VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertTrue(trap.getMessage().contains("::requireArchiveSourceNames"));
    assertEquals(0, machine.global("published"));
    var snapshot = machine.snapshot();
    int region = snapshot.regions().stream()
        .filter(row -> row.maxBytes() == 32800 && row.maxObjects() == 2)
        .findFirst().orElseThrow().id();
    var buffers = snapshot.buffers().stream().filter(row -> row.regionId() == region).toList();
    assertEquals(2, buffers.size());
    for (var buffer : buffers) {
      for (long cell : buffer.elements()) {
        assertEquals(0, cell, "unpublished artifact or identity");
      }
    }
    assertArrayEquals(new byte[32768], machine.hostOutput());
  }

  private record Fixture(Program program, String input, String source) {
    VirtualMachine machine() {
      return VirtualMachine.withBinaryInput(
          program, input.getBytes(StandardCharsets.UTF_8), 32768);
    }
  }

  private static Fixture fixture(String name, boolean imported, long[] range) throws Exception {
    String source = "/* classical class Ghost {} */\nmodule " + MODULE + ";\n"
        + "classical\nclass " + name + " { public const long VALUE = 1; }\n"
        + "// classical class Last {}\n";
    String input = PREFIX + source + "outside tail\n";
    long classStart = range == null ? input.indexOf(name + " {") : range[0];
    long classLength = range == null ? name.length() : range[1];
    String prefix = "archive, SOURCE_START, SOURCE_LENGTH, 0, archive, MODULE_START, MODULE_LENGTH, "
        + "CLASS_START, CLASS_LENGTH, 0, 0, ";
    String targetView = "0, targets, targetParameters, archive, archive, archive, "
        + "qualifierStarts, qualifierLengths, qualifierRanks, ";
    String parameters = "bodyStarts, bodyLengths, 0, importedRows, archive, importedStarts, "
        + "firstParameters, parameterCounts, resultTypes, effects, parameterTypes, parameterModes, "
        + "archive, nameStarts, nameLengths, ";
    String call = imported
        ? "compileStructuredArchiveModuleWithTargetView(" + prefix + targetView + parameters
            + "relocations, relocationOwners, relocationIdentities, artifact, identity)"
        : "compileStructuredArchiveModule(" + prefix + parameters + "artifact, identity)";
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.archive_structured_source_module_compiler"));
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("EmptyArchive.w", """
        module example.empty_archive;
        import wheeler.compiler.closure.archive_structured_source_module_compiler;
        import wheeler.compiler.closure.source_product_artifact;
        classical class EmptyArchive {
          state long published = 0;
          entry void main(borrow byteview archive, borrow mut bytes output) {
            region metadata = new region(1600000, 20);
            words bodyStarts = allocate(metadata, 4096);
            words bodyLengths = allocate(metadata, 4096);
            words importedRows = allocate(metadata, 114689);
            words importedStarts = allocate(metadata, 16384);
            words firstParameters = allocate(metadata, 4096);
            words parameterCounts = allocate(metadata, 4096);
            words resultTypes = allocate(metadata, 4096);
            words effects = allocate(metadata, 4096);
            words parameterTypes = allocate(metadata, 16384);
            words parameterModes = allocate(metadata, 16384);
            words nameStarts = allocate(metadata, 4096);
            words nameLengths = allocate(metadata, 4096);
            words targets = allocate(metadata, 1);
            words targetParameters = allocate(metadata, 1);
            words qualifierStarts = allocate(metadata, 1);
            words qualifierLengths = allocate(metadata, 1);
            words qualifierRanks = allocate(metadata, 1);
            words relocations = allocate(metadata, 768);
            words relocationOwners = allocate(metadata, 256);
            bytes relocationIdentities = allocateBytes(metadata, 8192);
            region publication = new region(32800, 2);
            bytes artifact = allocateBytes(publication, 32768);
            bytes identity = allocateBytes(publication, 32);
            SourceProductArtifactPlan plan = CALL;
            long cursor = 0;
            while (cursor < plan.length) limit 32768 {
              setByte(output, cursor, artifact[cursor]);
              cursor += 1;
            }
            setOutputLength(output, cursor);
            published = 1;
            drop(identity); drop(artifact); drop(publication);
            drop(relocationIdentities); drop(relocationOwners); drop(relocations);
            drop(qualifierRanks); drop(qualifierLengths); drop(qualifierStarts);
            drop(targetParameters); drop(targets); drop(nameLengths); drop(nameStarts);
            drop(parameterModes); drop(parameterTypes); drop(effects); drop(resultTypes);
            drop(parameterCounts); drop(firstParameters); drop(importedStarts); drop(importedRows);
            drop(bodyLengths); drop(bodyStarts); drop(metadata);
          }
        }
        """.replace("CALL", call)
        .replace("SOURCE_START", Integer.toString(PREFIX.length()))
        .replace("SOURCE_LENGTH", Integer.toString(source.length()))
        .replace("MODULE_START", Integer.toString(input.indexOf(MODULE)))
        .replace("MODULE_LENGTH", Integer.toString(MODULE.length()))
        .replace("CLASS_START", Long.toString(classStart))
        .replace("CLASS_LENGTH", Long.toString(classLength)));
    return new Fixture(new WheelerCompiler().compileModuleFiles(sources, "example.empty_archive"),
        input, source);
  }
}
