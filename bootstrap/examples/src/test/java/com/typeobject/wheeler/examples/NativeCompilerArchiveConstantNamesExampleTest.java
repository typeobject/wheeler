package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Archive emission resolves constants from packed names, never guessed source uses. */
final class NativeCompilerArchiveConstantNamesExampleTest {
  private static final String MODULE = "example.constant_names";
  private static final String PREFIX = "outside archive range\n";

  @Test
  void anUnusedConstantDoesNotMasqueradeAsTheModuleHeaderPrefix() throws Exception {
    // The old missing-name fallback pointed at "mod" in the source's "module" keyword.
    assertArtifact(fixture("return mod;", "BAD", 1, 1, 1, null));
  }

  @Test
  void resolvesRepeatedUsesWithCommentDecoys() throws Exception {
    assertArtifact(fixture("""
        // café 𝄞 LIMIT LIMIT
        long value = mod + LIMIT;
        boolean bounded = value < LIMIT;
        if (bounded == true) {
          return LIMIT;
        }
        return value;
        """, "LIMIT", 1, 1, 1, null));
  }

  @Test
  void resolvesImportedLoopLimitsWithoutDependencySource() throws Exception {
    assertArtifact(fixture("""
        long index = 0;
        while (index < mod) limit LIMIT {
          index += 1;
        }
        return index;
        """, "LIMIT", 1, 1, 1, null));
  }

  @Test
  void resolvesTheLastAdmittedNameLength() throws Exception {
    String name = "A".repeat(256);
    assertArtifact(fixture("return " + name + ";", name, 1, 1, 1, null));
  }

  @Test
  void rejectsMalformedUnresolvedAndAmbiguousProductsBeforePublication() throws Exception {
    for (String body : new String[] {"return LIMIT;", """
        long index = 0;
        while (index < mod) limit LIMIT {
          index += 1;
        }
        return index;
        """}) {
      assertUnpublished(fixture(body, "LIMIT", 2, 1, 1, null));
      assertUnpublished(fixture(body, "LIMIT", 1, 0, 1, null));
      assertUnpublished(fixture(body, "LIMIT", 1, 1, 2, null));
      assertUnpublished(fixture(body, "LIMIT", 1, 1, 1, -1L));
      assertUnpublished(fixture(body, "LIMIT", 1, 1, 1, Long.MAX_VALUE));
      assertUnpublished(fixture(body, "LIMIT", 1, 1, 1, 4092L));
    }
  }

  private static void assertArtifact(Fixture fixture) throws Exception {
    VirtualMachine machine = fixture.machine();
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    String dependency = "module example.values; classical class Values { public const long "
        + fixture.name() + " = 3; }";
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Source.w", fixture.source(), "Values.w", dependency), MODULE);
    assertEquals(1, machine.global("published"));
    assertArrayEquals(new BytecodeWriter().write(expected), machine.hostOutput());
  }

  private static void assertUnpublished(Fixture fixture) {
    VirtualMachine machine = fixture.machine();
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
    var snapshot = machine.snapshot();
    int region = snapshot.regions().stream()
        .filter(row -> row.maxBytes() == 32800 && row.maxObjects() == 2)
        .findFirst().orElseThrow().id();
    var buffers = snapshot.buffers().stream().filter(row -> row.regionId() == region).toList();
    assertEquals(2, buffers.size());
    for (var buffer : buffers) {
      for (long cell : buffer.elements()) {
        assertEquals(211, cell, "rejected artifact or identity cell");
      }
    }
    assertArrayEquals(new byte[32768], machine.hostOutput());
  }

  private record Fixture(Program program, String input, String source, String name) {
    VirtualMachine machine() {
      return VirtualMachine.withBinaryInput(
          program, input.getBytes(StandardCharsets.UTF_8), 32768);
    }
  }

  private static Fixture fixture(
      String body, String name, int type, int resolved, int count, Long nameStart) throws Exception {
    String source = "module " + MODULE + ";\nimport example.values;\n"
        + "classical class ConstantNames { public long compute(long mod) {\n"
        + body + "\n} }\n";
    String input = PREFIX + source + "outside tail\n";
    int bodyStart = input.indexOf('{', input.indexOf("compute("));
    int bodyEnd = SourceRanges.matchingClose(input, bodyStart) + 1;
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.archive_structured_source_module_compiler"));
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("ArchiveConstantNames.w", """
        module example.archive_constant_names;
        import wheeler.compiler.closure.archive_structured_source_module_compiler;
        import wheeler.compiler.closure.source_product_artifact;
        classical class ArchiveConstantNames {
          state long published = 0;
          entry void main(borrow byteview archive, borrow mut bytes output) {
            region metadata = new region(1600000, 13);
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
            bytes names = allocateBytes(metadata, 4096);
            writeAscii(names, 2048, "%s");
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(nameStarts, 0, %d);
            set(nameLengths, 0, 7);
            set(parameterCounts, 0, 1);
            set(resultTypes, 0, 1);
            set(parameterTypes, 0, 1);
            long imported = 0;
            while (imported < %d) limit 2 {
              long base = 1 + imported * 7;
              set(importedStarts, imported, %d);
              set(importedRows, base + 1, %d);
              set(importedRows, base + 2, %d);
              set(importedRows, base + 3, 3);
              set(importedRows, base + 4, %d);
              imported += 1;
            }
            region publication = new region(32800, 2);
            bytes artifact = allocateBytes(publication, 32768);
            bytes identity = allocateBytes(publication, 32);
            long cell = 0;
            while (cell < 32768) limit 32768 {
              setByte(artifact, cell, 211);
              cell += 1;
            }
            cell = 0;
            while (cell < 32) limit 32 {
              setByte(identity, cell, 211);
              cell += 1;
            }
            SourceProductArtifactPlan plan = compileStructuredArchiveModule(
              archive, %d, %d, 0, archive, %d, %d, %d, 13, 0, 1,
              bodyStarts, bodyLengths, %d, importedRows, names, importedStarts,
              firstParameters, parameterCounts, resultTypes, effects, parameterTypes,
              parameterModes, archive, nameStarts, nameLengths, artifact, identity
            );
            long cursor = 0;
            while (cursor < plan.length) limit 32768 {
              setByte(output, cursor, artifact[cursor]);
              cursor += 1;
            }
            setOutputLength(output, cursor);
            published = 1;
            drop(identity); drop(artifact); drop(publication);
            drop(names); drop(nameLengths); drop(nameStarts);
            drop(parameterModes); drop(parameterTypes); drop(effects); drop(resultTypes);
            drop(parameterCounts); drop(firstParameters); drop(importedStarts); drop(importedRows);
            drop(bodyLengths); drop(bodyStarts); drop(metadata);
          }
        }
        """.formatted(
            name,
            SourceRanges.utf8Offset(input, bodyStart),
            SourceRanges.utf8Length(input, bodyStart, bodyEnd - bodyStart),
            SourceRanges.utf8Offset(input, input.indexOf("compute(")),
            count, nameStart == null ? 2048 : nameStart, name.length(), type, resolved,
            PREFIX.length(), source.getBytes(StandardCharsets.UTF_8).length,
            input.indexOf(MODULE), MODULE.length(), input.indexOf("ConstantNames {"), count));
    return new Fixture(new WheelerCompiler().compileModuleFiles(
        sources, "example.archive_constant_names"), input, source, name);
  }
}
