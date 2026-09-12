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
import com.typeobject.wheeler.examples.globals.NativeGlobalExecutionAssertions;
import com.typeobject.wheeler.examples.globals.NativeGlobalRetentionAssertions;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** Archive emission resolves constants from packed names, never guessed source uses. */
final class NativeCompilerArchiveConstantNamesExampleTest {
  private static final int ARTIFACT_BYTES = 32768;
  private static final int IDENTITY_BYTES = 32;
  private static final int PUBLICATION_BYTES = ARTIFACT_BYTES + IDENTITY_BYTES;
  private static final int PUBLICATION_BUFFERS = 2;
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
  void readsADeclaredGlobalThroughItsDeclarationOrdinal() throws Exception {
    assertArtifact(fixture("return Alpha;", "LIMIT", 1, 1, 1, null, """
        state long Zulu = -9223372036854775808;
        state long Alpha = example.values::LIMIT + 5;
        """));
  }

  @Test
  void readsTheValueWrittenToADeclaredGlobal() throws Exception {
    assertArtifact(fixture("Alpha = mod; return Alpha;", "LIMIT", 1, 1, 1, null, """
        state long Zulu = -9223372036854775808;
        state long Alpha = example.values::LIMIT + 5;
        """));
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "return zulu;",
      "return alpha + mod;",
      "return mod + alpha;",
      "return alpha + zulu;",
      "long local = alpha; return local;",
      "long local = alpha + LIMIT; return local;",
      "boolean equal = alpha == mod; if (equal == true) { return alpha; } return mod;",
      "alpha = alpha + mod; return alpha;",
      "alpha = -9223372036854775808; return alpha;",
      "alpha = zulu; return alpha;",
      "alpha = LIMIT; return alpha;",
      "zulu = mod; alpha = zulu + LIMIT; return alpha;"
  })
  void composesDeclaredLocationsWithScalarValues(String body) throws Exception {
    assertArtifact(fixture(body, "LIMIT", 1, 1, 1, null, """
        state long zulu = -9223372036854775808;
        state long alpha = example.values::LIMIT + 5;
        """));
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "Alpha = mod; assert(Alpha == mod); return Alpha;",
      "Alpha = mod; assert(Alpha == Alpha); return Alpha;",
      "assert(Alpha == 8); return mod;",
      "Alpha = mod; assert(mod == Alpha); return Alpha;",
      "Alpha = mod; assert(0 < Alpha); return Alpha;",
      "assert(Zulu == -9223372036854775808); return mod;",
      "assert(-9223372036854775808 < Alpha); return mod;",
      "assert(Zulu < Alpha); return mod;",
      "assert(Zulu < LIMIT); return mod;",
      "assert(Alpha < 9); return mod;",
      "assert(0 < mod); return mod;",
      "boolean ready = true; assert(ready); return mod;",
      "boolean first = false; boolean second = false; assert(first == second); return mod;",
      "assert(true); return mod;"
  })
  void assertsRuntimeGlobalValuesThroughSharedScalarProducts(String body) throws Exception {
    assertArtifact(fixture(body, "LIMIT", 1, 1, 1, null, """
        state long Zulu = -9223372036854775808;
        state long Alpha = example.values::LIMIT + 5;
        """));
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "alpha = true; return mod;",
      "missing = mod; return alpha;",
      "alpha = mod; missing = mod; return alpha;",
      "long alpha = mod; return alpha;",
      "alpha = mod; return missing;"
  })
  void rejectsInvalidOrShadowedAccessBeforePublication(String body) throws Exception {
    assertUnpublished(fixture(body, "LIMIT", 1, 1, 1, null, """
        state long zulu = -9223372036854775808;
        state long alpha = example.values::LIMIT + 5;
        """));
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "Alpha = mod; assert(Alpha); return Alpha;",
      "Alpha = mod; assert(Alpha == true); return Alpha;",
      "boolean ready = true; assert(Alpha == ready); return mod;",
      "long Alpha = mod; assert(Alpha == mod); return mod;",
      "Alpha = mod; assert(missing == Alpha); return Alpha;",
      "Alpha = mod; assert(Alpha + mod); return Alpha;",
      "Alpha = mod; assert(Alpha = = mod); return Alpha;",
      "Alpha = mod; assert(Alpha == mod, Alpha); return Alpha;"
  })
  void rejectsInvalidAssertionsWithoutPublishingAnEarlierStore(String body) throws Exception {
    assertUnpublished(fixture(body, "LIMIT", 1, 1, 1, null, "state long Alpha = 8;"));
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "Alpha = mod; assert(Alpha < 0); return Alpha;",
      "assert(Alpha == 9); return mod;",
      "assert(false); return mod;",
      "Alpha = mod; assert(0 < Zulu); return Alpha;"
  })
  void publishesFalseAssertionsAndReplaysTheirRuntimeFailure(String body) throws Exception {
    Fixture source = fixture(body, "LIMIT", 1, 1, 1, null,
        "state long Zulu = -9223372036854775808; state long Alpha = 8;");
    assertArtifact(new Fixture(source.program(), source.input(), source.source(), source.name(), true));
  }

  @Test
  void rejectsUnjoinedLiteralLeftDeclarationsRatherThanMisencodingThem() throws Exception {
    Fixture source = fixture("Alpha = mod; boolean ready = 0 < mod; assert(ready); return Alpha;",
        "LIMIT", 1, 1, 1, null, "state long Alpha = 8;");
    new WheelerCompiler().compileLibraryModuleFiles(Map.of("Source.w", source.source(), "Values.w",
        "module example.values; classical class Values { public const long LIMIT = 3; }"), MODULE);
    assertUnpublished(source);
  }

  @Test
  void rejectsConstantStateCollisionsInsteadOfSubstitutingAnInitializer() throws Exception {
    assertUnpublished(fixture("return mod;", "LIMIT", 1, 1, 1, null,
        "state long LIMIT = 8;"));
  }

  @Test
  void retainsUnusedStatesAndTheirScopedConstantInitializers() throws Exception {
    Fixture globals = fixture("return mod;", "LIMIT", 1, 1, 1, null, """
        state long Zulu = -9223372036854775808;
        state long Alpha = example.values::LIMIT + 5;
        """);
    assertPhaseReplay(globals,
        "wheeler.compiler.closure.source_module_name_products::materializeSourceModuleNames", false);
    assertArtifact(globals);
  }

  @Test
  void retainsGlobalsWhenProofNamesReorderOrShareStrings() throws Exception {
    for (String proof : new String[] {"A", "Bound", "Zulu"}) {
      assertArtifact(fixture("return mod;", "LIMIT", 1, 1, 1, null,
          "state long Bound = -9223372036854775808; state long ConstantNames = 9;\n"
              + "theorem " + proof + " proves steps(compute, example.values::LIMIT + 5);"));
    }
  }

  @Test
  void rejectsInvalidStatesBeforePublishingCallableArtifacts() throws Exception {
    for (String declarations : new String[] {
        "state long first = 1; state long first = 2;",
        "state long first = 1; state long second = true;",
        "state long first = 1; state long second = missing;",
        "state long first = 1; state long second = 9223372036854775807 + 1;"
    }) {
      assertUnpublished(fixture("return mod;", "LIMIT", 1, 1, 1, null, declarations));
    }
  }

  @Test
  void retainsQualifiedStepClaimsWithoutDependencySource() throws Exception {
    Fixture accepted = fixture("return mod;", "LIMIT", 1, 1, 1, null,
        "theorem Bound proves steps(compute, example.values::LIMIT + 5);");
    assertCoverageReplay(accepted, false);
    assertArtifact(accepted);
    assertUnpublished(fixture("return mod;", "LIMIT", 1, 1, 1, null,
        "theorem Bound proves steps(compute, example.values::LIMIT + 4294967301);"));
  }

  @Test
  void replaysClaimRejectionAndTheAbsencePathWithoutNewBuffers() throws Exception {
    Fixture absent = fixture("return mod;", "LIMIT", 1, 1, 1, null);
    assertCoverageReplay(absent, true);
    assertArtifact(absent);
    Fixture rejected = fixture("return mod;", "LIMIT", 1, 1, 1, null,
        "theorem Bound proves steps(unknown, example.values::LIMIT + 5);");
    assertCoverageReplay(rejected, false);
    assertUnpublished(rejected);
  }

  @Test
  void rejectsMalformedDetachedProductsEvenWhenTheConstantIsUnused() throws Exception {
    for (String mutation : new String[] {
        "set(scopedRows, 0, 0);",
        "set(importedStarts, 0, PREFIX_BYTES + 1);",
        "set(scopedRows, CONSTANT_PRODUCT_HEADER_ROWS + CONSTANT_MODULE_START, NAME_BYTES);",
        "set(scopedRows, CONSTANT_PRODUCT_HEADER_ROWS + CONSTANT_TYPE, 3);",
        "set(scopedRows, CONSTANT_PRODUCT_HEADER_ROWS + CONSTANT_RESOLVED, 2);",
        "setByte(scopedNames, PREFIX_BYTES, 0);"
    }) {
      assertUnpublished(fixture("return mod;", "LIMIT", 1, 1, 1, null, "", mutation));
    }
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

  private static void assertCoverageReplay(Fixture fixture, boolean absent) {
    assertPhaseReplay(fixture,
        "wheeler.compiler.closure.source_classical_coverage::materializeSourceClassicalCoverage", absent);
  }

  private static void assertPhaseReplay(Fixture fixture, String name, boolean absent) {
    int function = fixture.program().functions().stream().filter(row -> row.name().equals(name))
        .findFirst().orElseThrow().id();
    VirtualMachine machine = fixture.machine();
    long budget = fixture.program().maxSteps();
    boolean entered = false;
    for (long step = 0; step < budget; step++) {
      var frame = machine.snapshot().selectedFrames().getLast();
      if (frame.functionId() == function && frame.programCounter() == 0) {
        entered = true;
        break;
      }
      machine.stepWithoutRewindHistory();
    }
    assertTrue(entered, "phase entry must be reached within the fixture manifest");
    var before = machine.snapshot();
    int depth = before.selectedFrames().size();
    while (machine.snapshot().selectedFrames().size() >= depth) {
      assertTrue(machine.historySize() < budget, "phase must return within its work budget");
      machine.step();
    }
    var after = machine.snapshot();
    int transitions = machine.historySize();
    if (absent) {
      assertEquals(before.buffers().size(), after.buffers().size());
      assertEquals(before.regions().size(), after.regions().size());
    }
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
    for (int replay = 0; replay < transitions; replay++) machine.step();
    assertEquals(after, machine.snapshot());
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
  }

  private static void assertArtifact(Fixture fixture) throws Exception {
    String dependency = "module example.values; classical class Values { public const long "
        + fixture.name() + " = 3; }";
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Source.w", fixture.source(), "Values.w", dependency), MODULE);
    VirtualMachine machine = fixture.machine();
    long transitions = 0;
    while (machine.global("published") == 0 && transitions < fixture.program().maxSteps()) {
      machine.stepWithoutRewindHistory();
      transitions++;
    }
    assertEquals(1, machine.global("published"));
    byte[] expectedBytes = new BytecodeWriter().write(expected);
    var snapshot = machine.snapshot();
    int publication = snapshot.regions().stream()
        .filter(row -> row.maxBytes() == PUBLICATION_BYTES && row.maxObjects() == PUBLICATION_BUFFERS)
        .findFirst().orElseThrow().id();
    var buffers = snapshot.buffers().stream().filter(row -> row.regionId() == publication).toList();
    assertEquals(2, buffers.size());
    for (int index = 0; index < expectedBytes.length; index++) {
      assertEquals(Byte.toUnsignedInt(expectedBytes[index]), buffers.getFirst().elements().get(index));
    }
    for (int index = expectedBytes.length; index < ARTIFACT_BYTES; index++) {
      assertEquals(211, buffers.getFirst().elements().get(index));
    }
    byte[] digest = MessageDigest.getInstance("SHA-256").digest(expectedBytes);
    assertEquals(digest.length, buffers.getLast().elements().size());
    for (int index = 0; index < digest.length; index++) {
      assertEquals(Byte.toUnsignedInt(digest[index]), buffers.getLast().elements().get(index));
    }
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(expectedBytes, machine.hostOutput());
    if (!expected.globals().isEmpty()) {
      NativeGlobalRetentionAssertions.assertRetained(machine.hostOutput(), expected);
      NativeGlobalExecutionAssertions.assertExecution(machine.hostOutput(), expected, fixture.assertionFails());
    }
  }

  private static void assertUnpublished(Fixture fixture) {
    VirtualMachine machine = fixture.machine();
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
    var snapshot = machine.snapshot();
    int region = snapshot.regions().stream()
        .filter(row -> row.maxBytes() == PUBLICATION_BYTES && row.maxObjects() == PUBLICATION_BUFFERS)
        .findFirst().orElseThrow().id();
    var buffers = snapshot.buffers().stream().filter(row -> row.regionId() == region).toList();
    assertEquals(2, buffers.size());
    for (var buffer : buffers) {
      for (long cell : buffer.elements()) {
        assertEquals(211, cell, "rejected artifact or identity cell");
      }
    }
    assertArrayEquals(new byte[ARTIFACT_BYTES], machine.hostOutput());
  }

  private record Fixture(Program program, String input, String source, String name, boolean assertionFails) {
    VirtualMachine machine() {
      return VirtualMachine.withBinaryInput(
          program, input.getBytes(StandardCharsets.UTF_8), ARTIFACT_BYTES);
    }
  }

  private static Fixture fixture(
      String body, String name, int type, int resolved, int count, Long nameStart) throws Exception {
    return fixture(body, name, type, resolved, count, nameStart, "");
  }

  private static Fixture fixture(String body, String name, int type, int resolved, int count,
      Long nameStart, String claims) throws Exception {
    return fixture(body, name, type, resolved, count, nameStart, claims, "");
  }

  private static Fixture fixture(String body, String name, int type, int resolved, int count,
      Long nameStart, String claims, String productMutation) throws Exception {
    String source = "module " + MODULE + ";\nimport example.values;\n"
        + "classical class ConstantNames { public long compute(long mod) {\n"
        + body + "\n}\n" + claims + "\n}\n";
    String input = PREFIX + source + "outside tail\n";
    int bodyStart = input.indexOf('{', input.indexOf("compute("));
    int bodyEnd = SourceRanges.matchingClose(input, bodyStart) + 1;
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.archive_structured_source_module_compiler"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.scoped_constant_products"));
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("ArchiveConstantNames.w", """
        module example.archive_constant_names;
        import wheeler.compiler.closure.archive_structured_source_module_compiler;
        import wheeler.compiler.closure.scoped_constant_products;
        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.compiler.constant_product_schema;
        classical class ArchiveConstantNames {
          private const long NAME_BYTES = 4096;
          private const long QUALIFIER_START = MAX_CONSTANT_NAME_BYTES / 2;
          private const long QUALIFIER_LENGTH = 14;
          private const long PREFIX_BYTES = 7;
          private const long WORD_BYTES = 8;
          private const long MAX_CALLABLES = 4096;
          private const long MAX_PARAMETERS = 16384;
          private const long BODY_COLUMNS = 2;
          private const long SIGNATURE_COLUMNS = 4;
          private const long CALLABLE_NAME_COLUMNS = 2;
          private const long CALLABLE_COLUMNS = BODY_COLUMNS + SIGNATURE_COLUMNS
            + CALLABLE_NAME_COLUMNS;
          private const long PARAMETER_COLUMNS = 2;
          private const long ROW_BUFFERS = 1;
          private const long START_BUFFERS = 1;
          private const long NAME_BUFFERS = 1;
          private const long QUALIFIER_BUFFERS = 1;
          private const long METADATA_WORDS = MAX_CALLABLES * CALLABLE_COLUMNS
            + MAX_PARAMETERS * PARAMETER_COLUMNS + MAX_CONSTANT_PRODUCTS + CONSTANT_PRODUCT_ROWS;
          private const long METADATA_BYTES = METADATA_WORDS * WORD_BYTES + NAME_BYTES;
          private const long METADATA_BUFFERS = CALLABLE_COLUMNS + PARAMETER_COLUMNS
            + ROW_BUFFERS + START_BUFFERS + NAME_BUFFERS;
          private const long SCOPED_BUFFERS = ROW_BUFFERS + NAME_BUFFERS + QUALIFIER_BUFFERS;
          private const long SCOPED_BYTES = CONSTANT_PRODUCT_ROWS * WORD_BYTES + NAME_BYTES
            + MAX_CONSTANT_NAME_BYTES;
          state long published = 0;
          entry void main(borrow byteview archive, borrow mut bytes output) {
            region metadata = new region(METADATA_BYTES, METADATA_BUFFERS);
            words bodyStarts = allocate(metadata, MAX_CALLABLES);
            words bodyLengths = allocate(metadata, MAX_CALLABLES);
            words importedRows = allocate(metadata, CONSTANT_PRODUCT_ROWS);
            words importedStarts = allocate(metadata, MAX_CONSTANT_PRODUCTS);
            words firstParameters = allocate(metadata, MAX_CALLABLES);
            words parameterCounts = allocate(metadata, MAX_CALLABLES);
            words resultTypes = allocate(metadata, MAX_CALLABLES);
            words effects = allocate(metadata, MAX_CALLABLES);
            words parameterTypes = allocate(metadata, MAX_PARAMETERS);
            words parameterModes = allocate(metadata, MAX_PARAMETERS);
            words nameStarts = allocate(metadata, MAX_CALLABLES);
            words nameLengths = allocate(metadata, MAX_CALLABLES);
            bytes names = allocateBytes(metadata, NAME_BYTES);
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
              long base = CONSTANT_PRODUCT_HEADER_ROWS + imported * CONSTANT_PRODUCT_COLUMNS;
              set(importedStarts, imported, %d);
              set(importedRows, base + CONSTANT_NAME_START, importedStarts[imported]);
              set(importedRows, base + CONSTANT_MODULE_START, QUALIFIER_START);
              set(importedRows, base + CONSTANT_MODULE_LENGTH, QUALIFIER_LENGTH);
              set(importedRows, base + CONSTANT_NAME_LENGTH, %d);
              set(importedRows, base + CONSTANT_TYPE, %d);
              set(importedRows, base + CONSTANT_VALUE, 3);
              set(importedRows, base + CONSTANT_RESOLVED, %d);
              imported += 1;
            }
            set(importedRows, 0, imported);
            region scoped = new region(SCOPED_BYTES, SCOPED_BUFFERS);
            words scopedRows = allocate(scoped, CONSTANT_PRODUCT_ROWS);
            bytes scopedNames = allocateBytes(scoped, NAME_BYTES);
            bytes qualifiers = allocateBytes(scoped, MAX_CONSTANT_NAME_BYTES);
            writeAscii(qualifiers, QUALIFIER_START, "example.values");
            writeAscii(scopedNames, 0, "prefix.");
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
            ScopedConstantProductPlan copied = copyScopedConstantProducts(
              names, qualifiers, imported, importedRows, PREFIX_BYTES, scopedNames, scopedRows);
            assert(copied.productCount == imported);
            long detached = 0;
            while (detached < imported) limit 2 {
              long row = CONSTANT_PRODUCT_HEADER_ROWS + detached * CONSTANT_PRODUCT_COLUMNS;
              set(importedStarts, detached, scopedRows[row + CONSTANT_NAME_START]);
              detached += 1;
            }
            PRODUCT_MUTATION
            SourceProductArtifactPlan plan = compileStructuredArchiveModule(
              archive, %d, %d, 0, archive, %d, %d, %d, 13, 0, 1,
              bodyStarts, bodyLengths, %d, scopedRows, scopedNames, importedStarts,
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
            drop(qualifiers); drop(scopedNames); drop(scopedRows); drop(scoped);
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
            input.indexOf(MODULE), MODULE.length(), input.indexOf("ConstantNames {"), count)
        .replace("PRODUCT_MUTATION", productMutation));
    return new Fixture(new WheelerCompiler().compileModuleFiles(
        sources, "example.archive_constant_names"), input, source, name, false);
  }
}
