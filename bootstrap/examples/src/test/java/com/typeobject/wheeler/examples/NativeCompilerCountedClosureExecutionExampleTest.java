package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.SourceModuleInspection;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for counted package-closure execution. */
final class NativeCompilerCountedClosureExecutionExampleTest {
  @Test
  void reproducesASevenImportArtifactFromCountedArchiveColumns() throws Exception {
    assertCountedFixture(directFixture(), 58);
  }

  @Test
  void reproducesARedundantSevenModuleDagFromCountedColumns() throws Exception {
    assertCountedFixture(dagFixture(), 7);
  }

  @Test
  void reproducesThreeExecutableOwnersBesideFourConstants() throws Exception {
    assertCountedFixture(mixedFixture(), -1);
  }

  @Test
  void reproducesPrivateHelperEdgesBesideFourConstants() throws Exception {
    assertCountedFixture(privateHelperFixture(), -1);
  }

  private static void assertCountedFixture(Fixture fixture, long outcome) throws Exception {
    VirtualMachine writer = VirtualMachine.withBinaryInput(
        program(),
        framed(fixture.archive(), fixture.manifest().canonicalBytes()),
        32_768);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expectedProgram;
    if (outcome < 0) {
      expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
          fixture.sources(),
          "examples.root");
    } else {
      expectedProgram = new WheelerCompiler().compileModuleFiles(
          fixture.sources(),
          "examples.root");
    }
    byte[] expected = new BytecodeWriter().write(expectedProgram);
    assertArrayEquals(expected, writer.hostOutput());
    assertEquals(1, writer.global("published"));
    if (-1 < outcome) {
      VirtualMachine artifact = new VirtualMachine(
          new BytecodeReader().read(writer.hostOutput()));
      artifact.run();
      assertEquals(outcome, artifact.global("outcome"));
    }
  }

  private static Fixture directFixture() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put(
        "src/Two.w",
        "module examples.two; classical class Two { public const long TWO = 2; }");
    sources.put(
        "src/Three.w",
        "module examples.three; classical class Three { public const long THREE = 3; }");
    sources.put(
        "src/Five.w",
        "module examples.five; classical class Five { public const long FIVE = 5; }");
    sources.put(
        "src/Seven.w",
        "module examples.seven; classical class Seven { public const long SEVEN = 7; }");
    sources.put(
        "src/Eleven.w",
        "module examples.eleven; classical class Eleven { public const long ELEVEN = 11; }");
    sources.put(
        "src/Thirteen.w",
        "module examples.thirteen; classical class Thirteen { "
            + "public const long THIRTEEN = 13; }");
    sources.put(
        "src/Seventeen.w",
        "module examples.seventeen; classical class Seventeen { "
            + "public const long SEVENTEEN = 17; }");
    sources.put(
        "src/Root.w",
        "module examples.root; import examples.eleven; import examples.five; "
            + "import examples.seven; import examples.seventeen; "
            + "import examples.thirteen; import examples.three; import examples.two; "
            + "classical class Root { state long outcome = 0; entry void main() { "
            + "outcome += TWO; outcome += THREE; outcome += FIVE; outcome += SEVEN; "
            + "outcome += ELEVEN; outcome += THIRTEEN; outcome += SEVENTEEN; } }");

    return fixture(sources);
  }

  private static Fixture dagFixture() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put(
        "src/Alpha.w",
        "module examples.alpha; classical class Alpha { public const long ALPHA = 1; }");
    sources.put(
        "src/Beta.w",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public const long BETA = ALPHA + 1; }");
    sources.put(
        "src/Gamma.w",
        "module examples.gamma; import examples.beta; classical class Gamma { "
            + "public const long GAMMA = BETA + 1; }");
    sources.put(
        "src/Delta.w",
        "module examples.delta; import examples.gamma; classical class Delta { "
            + "public const long DELTA = GAMMA + 1; }");
    sources.put(
        "src/Epsilon.w",
        "module examples.epsilon; import examples.delta; classical class Epsilon { "
            + "public const long EPSILON = DELTA + 1; }");
    sources.put(
        "src/Zeta.w",
        "module examples.zeta; import examples.epsilon; classical class Zeta { "
            + "public const long ZETA = EPSILON + 1; }");
    sources.put(
        "src/Eta.w",
        "module examples.eta; import examples.alpha; import examples.zeta; "
            + "classical class Eta { public const long ETA = ALPHA + ZETA; }");
    sources.put(
        "src/Root.w",
        "module examples.root; import examples.eta; classical class Root { "
            + "state long outcome = 0; entry void main() { outcome += ETA; } }");
    return fixture(sources);
  }

  private static Fixture privateHelperFixture() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put(
        "src/Alpha.w",
        "module examples.alpha; classical class Alpha { "
            + "public boolean alpha(long value) { return value == 1; } }");
    sources.put(
        "src/Beta.w",
        "module examples.beta; import examples.alpha; classical class Beta { "
            + "public boolean beta(long value) { return alpha(value); } }");
    sources.put(
        "src/Gamma.w",
        "module examples.gamma; import examples.beta; classical class Gamma { "
            + "public boolean gamma(long value) { return beta(value); } }");
    for (int index = 0; index < 4; index++) {
      sources.put(
          "src/C%d.w".formatted(index),
          "module examples.c%d; classical class C%d { public const long C%d = %d; }"
              .formatted(index, index, index, index + 2));
    }
    sources.put(
        "src/Root.w",
        "module examples.root; import examples.c0; import examples.c1; "
            + "import examples.c2; import examples.c3; import examples.gamma; "
            + "classical class Root { public boolean accepted(long value) { "
            + "if (value == C0) { return false; } if (value == C1) { return true; } "
            + "if (value == C2) { return false; } if (value == C3) { return true; } "
            + "return gamma(value); } }");
    return fixture(sources);
  }

  private static Fixture mixedFixture() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put(
        "src/Alpha.w",
        "module examples.alpha; classical class Alpha { "
            + "public boolean alpha(long value) { return value == 1; } }");
    sources.put(
        "src/Beta.w",
        "module examples.beta; classical class Beta { public const long BETA = 2; }");
    sources.put(
        "src/Delta.w",
        "module examples.delta; classical class Delta { public const long DELTA = 4; }");
    sources.put(
        "src/Epsilon.w",
        "module examples.epsilon; classical class Epsilon { "
            + "public boolean epsilon(long value) { return value == 5; } }");
    sources.put(
        "src/Gamma.w",
        "module examples.gamma; classical class Gamma { public const long GAMMA = 3; }");
    sources.put(
        "src/Theta.w",
        "module examples.theta; classical class Theta { "
            + "public boolean theta(long value) { return value == 8; } }");
    sources.put(
        "src/Zeta.w",
        "module examples.zeta; classical class Zeta { public const long ZETA = 6; }");
    sources.put(
        "src/Root.w",
        "module examples.root; import examples.alpha; import examples.beta; "
            + "import examples.delta; import examples.epsilon; import examples.gamma; "
            + "import examples.theta; import examples.zeta; classical class Root { "
            + "public boolean accepted(long value) { if (alpha(value)) { return true; } "
            + "if (epsilon(value)) { return false; } if (theta(value)) { return true; } "
            + "if (value == BETA) { return false; } if (value == DELTA) { return true; } "
            + "if (value == GAMMA) { return false; } return value == ZETA; } }");
    return fixture(sources);
  }

  private static Fixture fixture(Map<String, String> sources) throws Exception {
    MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
    List<BootstrapModuleManifest.Module> modules = new ArrayList<>();
    Map<String, byte[]> archiveSources = new LinkedHashMap<>();
    for (Map.Entry<String, String> entry : sources.entrySet()) {
      byte[] source = entry.getValue().getBytes(StandardCharsets.UTF_8);
      SourceModuleInspection.Header header = SourceModuleInspection.inspect(source);
      modules.add(new BootstrapModuleManifest.Module(
          header.name(),
          entry.getKey(),
          HexFormat.of().formatHex(sha256.digest(source)),
          header.imports()));
      archiveSources.put(entry.getKey(), source);
    }

    BootstrapModuleManifest manifest = new BootstrapModuleManifest(
        "bootstrap-1",
        "examples.root",
        List.of(),
        modules);
    byte[] archive = new PackageArchive().encode(
        new PackageManifestParser().parse("""
            schema: 1
            package:
              name: "examples.counted"
              version: "1.0.0"
              profile: "bootstrap-1"
            targets:
              - kind: "tool"
                name: "compiler"
                root: "src/Root.w"
                module: "examples.root"
                sources:
                  - "src"
                test: false
            dependencies: []
            capabilities: []
            """),
        archiveSources);
    return new Fixture(archive, manifest, sources);
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.archive_module_sources"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.package_target"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.plan"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.small_executor"));
    sources.put("CountedClosureExecutionExample.w", """
        module example.counted_closure_execution;

        import wheeler.compiler.closure.archive_module_sources;
        import wheeler.compiler.closure.archive_sources;
        import wheeler.compiler.closure.module_manifest;
        import wheeler.compiler.closure.package_target;
        import wheeler.compiler.closure.plan;
        import wheeler.compiler.closure.small_executor;
        import wheeler.compiler.graphs.executor;

        classical class CountedClosureExecutionExample {
          private const long MAX_ARCHIVE_BYTES = 16777216;
          private const long MAX_ARCHIVE_ENTRIES = 1024;
          private const long MAX_EXTERNALS = 64;
          private const long MAX_IMPORTS = 3072;
          private const long MAX_MANIFEST_BYTES = 262144;
          private const long MAX_MODULES = 512;

          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            long archiveLength = source[0]
              + source[1] * 256
              + source[2] * 65536
              + source[3] * 16777216;
            assert(archiveLength < MAX_ARCHIVE_BYTES + 1);
            long manifestLength = bufferLength(source) - archiveLength - 4;
            assert(0 < manifestLength);
            assert(manifestLength < MAX_MANIFEST_BYTES + 1);
            region inputArena = new region(/* bytes= */ 17039360, /* allocations= */ 2);
            bytes archive = allocateBytes(inputArena, archiveLength);
            bytes manifest = allocateBytes(inputArena, manifestLength);
            long cursor = 0;
            while (cursor < archiveLength) limit MAX_ARCHIVE_BYTES {
              setByte(archive, cursor, source[cursor + 4]);
              cursor += 1;
            }
            cursor = 0;
            while (cursor < manifestLength) limit MAX_MANIFEST_BYTES {
              setByte(manifest, cursor, source[archiveLength + cursor + 4]);
              cursor += 1;
            }

            region columns = new region(/* bytes= */ 202384, /* allocations= */ 23);
            words archivePathStarts = allocate(columns, MAX_ARCHIVE_ENTRIES);
            words archivePathLengths = allocate(columns, MAX_ARCHIVE_ENTRIES);
            words archiveDataStarts = allocate(columns, MAX_ARCHIVE_ENTRIES);
            words archiveDataLengths = allocate(columns, MAX_ARCHIVE_ENTRIES);
            words externalStarts = allocate(columns, MAX_EXTERNALS);
            words externalLengths = allocate(columns, MAX_EXTERNALS);
            words moduleStarts = allocate(columns, MAX_MODULES);
            words moduleLengths = allocate(columns, MAX_MODULES);
            words sourceStarts = allocate(columns, MAX_MODULES);
            words sourceLengths = allocate(columns, MAX_MODULES);
            words identityStarts = allocate(columns, MAX_MODULES);
            words edgeOwners = allocate(columns, MAX_IMPORTS);
            words edgeStarts = allocate(columns, MAX_IMPORTS);
            words edgeLengths = allocate(columns, MAX_IMPORTS);
            words edgeTargets = allocate(columns, MAX_IMPORTS);
            words moduleEntries = allocate(columns, MAX_MODULES);
            words archiveSourceStarts = allocate(columns, MAX_MODULES);
            words archiveSourceLengths = allocate(columns, MAX_MODULES);
            words firstImports = allocate(columns, MAX_MODULES);
            words directImportCounts = allocate(columns, MAX_MODULES);
            words importRanks = allocate(columns, MAX_IMPORTS);
            words leafFirstOrder = allocate(columns, MAX_MODULES);
            bytes expected = allocateBytes(columns, /* length= */ 256);
            ArchiveSourceIndexResult indexed = indexArchiveSources(
              archive,
              archivePathStarts,
              archivePathLengths,
              archiveDataStarts,
              archiveDataLengths
            );
            match (indexed) {
              case ArchiveSourceIndexResult.Value(ArchiveSourceIndex archiveIndex) {
                BootstrapModuleManifestPlan manifestPlan = parseBootstrapModuleManifest(
                  manifest,
                  expected,
                  externalStarts,
                  externalLengths,
                  moduleStarts,
                  moduleLengths,
                  sourceStarts,
                  sourceLengths,
                  identityStarts,
                  edgeOwners,
                  edgeStarts,
                  edgeLengths,
                  edgeTargets
                );
                long compilerTarget = -1;
                CompilerToolTargetResult selectedTarget = validateCompilerToolTarget(
                  archive,
                  archiveIndex,
                  manifest,
                  manifestPlan,
                  moduleStarts,
                  moduleLengths,
                  sourceStarts,
                  sourceLengths
                );
                match (selectedTarget) {
                  case CompilerToolTargetResult.Value(CompilerToolTarget target) {
                    compilerTarget = target.target;
                  }
                  case CompilerToolTargetResult.Error(long targetOffset) {
                    assert(targetOffset < 0);
                  }
                }
                assert(-1 < compilerTarget);
                ArchiveModuleSourcePlan joined = joinArchiveModuleSources(
                  archive,
                  archiveIndex,
                  archivePathStarts,
                  archivePathLengths,
                  archiveDataStarts,
                  archiveDataLengths,
                  manifest,
                  manifestPlan,
                  sourceStarts,
                  sourceLengths,
                  identityStarts,
                  moduleEntries
                );
                assert(joined.moduleCount == 8);
                CountedClosurePlan plan = planClosureStructure(
                  archive,
                  manifest,
                  manifestPlan,
                  edgeOwners,
                  edgeTargets,
                  moduleEntries,
                  archiveDataStarts,
                  archiveDataLengths,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  firstImports,
                  directImportCounts,
                  importRanks,
                  leafFirstOrder
                );
                GraphPlanExecution execution = executeSmallCountedClosure(
                  archive,
                  manifest,
                  plan,
                  firstImports,
                  directImportCounts,
                  edgeTargets,
                  importRanks,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  output
                );
                assert(0 < execution.length);
                setOutputLength(output, execution.length);
                published = 1;
              }
              case ArchiveSourceIndexResult.Error(long offset) {
                assert(offset < 0);
              }
            }
            drop(expected);
            drop(leafFirstOrder);
            drop(importRanks);
            drop(directImportCounts);
            drop(firstImports);
            drop(archiveSourceLengths);
            drop(archiveSourceStarts);
            drop(moduleEntries);
            drop(edgeTargets);
            drop(edgeLengths);
            drop(edgeStarts);
            drop(edgeOwners);
            drop(identityStarts);
            drop(sourceLengths);
            drop(sourceStarts);
            drop(moduleLengths);
            drop(moduleStarts);
            drop(externalLengths);
            drop(externalStarts);
            drop(archiveDataLengths);
            drop(archiveDataStarts);
            drop(archivePathLengths);
            drop(archivePathStarts);
            drop(columns);
            drop(manifest);
            drop(archive);
            drop(inputArena);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources,
        "example.counted_closure_execution");
  }

  private static byte[] framed(byte[] archive, byte[] manifest) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    writeU32(output, archive.length);
    output.writeBytes(archive);
    output.writeBytes(manifest);
    return output.toByteArray();
  }

  private static void writeU32(ByteArrayOutputStream output, int value) {
    output.write(value & 0xff);
    output.write(value >>> 8 & 0xff);
    output.write(value >>> 16 & 0xff);
    output.write(value >>> 24 & 0xff);
  }

  private record Fixture(
      byte[] archive,
      BootstrapModuleManifest manifest,
      Map<String, String> sources) {}
}
