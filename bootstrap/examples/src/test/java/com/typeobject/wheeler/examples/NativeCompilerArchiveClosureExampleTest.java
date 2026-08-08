package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
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

/** Native evidence for joining the physical compiler archive and module manifest. */
final class NativeCompilerArchiveClosureExampleTest {
  @Test
  void joinsEveryPhysicalCompilerModuleToItsDigestCheckedArchiveRange() throws Exception {
    Program program = program();
    byte[] archive = CompilerSources.packageArchive();
    BootstrapModuleManifest manifest = CompilerSources.bootstrapModuleManifest();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program,
        framed(archive, manifest.canonicalBytes()),
        1);

    runClosure(machine, program);

    assertArrayEquals(new byte[] {1}, machine.hostOutput());
    assertEquals(manifest.modules().size(), machine.global("moduleCount"));
    assertEquals(
        manifest.modules().stream().mapToLong(module -> module.imports().size()).sum(),
        machine.global("importCount"));
    assertEquals(readU32(archive, 12), machine.global("archiveEntryCount"));
    assertEquals(manifest.modules().size() - 1, machine.global("rootOrder"));
    assertEquals(1, machine.global("rootExecutable"));
    assertTrue(machine.global("executableCount") > 0);
    assertEquals(1, machine.global("peakActiveSources"));
    assertEquals(manifest.modules().size(), machine.global("rootGeneration"));
    assertEquals(983, machine.global("symbolCount"));
    assertTrue(machine.global("resolvedSymbolCount") > 800);
    assertTrue(machine.global("maxImportedSymbols") > 0);
    assertEquals(manifest.modules().size(), machine.global("symbolGeneration"));
    assertEquals(identityPrefix(archive), machine.global("packageIdentityPrefix"));
    assertTrue(machine.global("firstSymbolIdentityPrefix") != 0);
    assertTrue(
        machine.global("firstSymbolIdentityPrefix")
            != machine.global("lastSymbolIdentityPrefix"));
    assertEquals(0, machine.global("compilerTarget"));
    int rootEntry = Math.toIntExact(machine.global("rootEntry"));
    EntryRange rootRange = entryRange(archive, rootEntry);
    assertEquals("src/main/wheeler/MinimalCompiler.w", rootRange.path());
    assertEquals(rootRange.dataStart(), machine.global("rootDataStart"));
    assertEquals(rootRange.dataLength(), machine.global("rootDataLength"));
    assertArrayEquals(
        CompilerSources.read("MinimalCompiler.w").getBytes(StandardCharsets.UTF_8),
        java.util.Arrays.copyOfRange(
            archive,
            rootRange.dataStart(),
            rootRange.dataStart() + rootRange.dataLength()));

    byte[] smallSource = "module demo.main;\n\nclassical class Main {}\n"
        .getBytes(StandardCharsets.UTF_8);
    byte[] smallArchive = smallArchive(smallSource, true);
    byte[] damagedManifest = smallManifest(smallSource);
    int identity = indexOf(damagedManifest, "identity: \"".getBytes(StandardCharsets.US_ASCII));
    int scalar = identity + "identity: \"".length();
    damagedManifest[scalar] = damagedManifest[scalar] == '0' ? (byte) '1' : (byte) '0';
    VirtualMachine rejected = VirtualMachine.withBinaryInput(
        program,
        framed(smallArchive, damagedManifest),
        1);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(rejected));
    assertArrayEquals(new byte[1], rejected.hostOutput());
    assertEquals(0, rejected.global("published"));
  }

  @Test
  void rejectsNoncanonicalPackageMetadataWrongTargetAndMalformedSymbols() throws Exception {
    Program closureProgram = program();
    byte[] source = "module demo.main; classical class Main {}"
        .getBytes(StandardCharsets.UTF_8);
    byte[] manifest = smallManifest(source);

    byte[] noncanonical = smallArchive(source, true);
    noncanonical[16 + "schema: 1".length()] = ' ';
    repairOuterDigest(noncanonical);
    VirtualMachine malformed = VirtualMachine.withBinaryInput(
        closureProgram, framed(noncanonical, manifest), 1);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(malformed));
    assertEquals(0, malformed.global("published"));
    assertEquals(-1, malformed.global("compilerTarget"));

    VirtualMachine wrongKind = VirtualMachine.withBinaryInput(
        closureProgram, framed(smallArchive(source, false), manifest), 1);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(wrongKind));
    assertEquals(0, wrongKind.global("published"));
    assertEquals(-1, wrongKind.global("compilerTarget"));

    byte[] malformedSource = (
        "module demo.main; classical class Main { public const long BAD = ; }")
        .getBytes(StandardCharsets.UTF_8);
    VirtualMachine malformedSymbols = VirtualMachine.withBinaryInput(
        closureProgram,
        framed(smallArchive(malformedSource, true), smallManifest(malformedSource)),
        1);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(malformedSymbols));
    assertEquals(0, malformedSymbols.global("published"));
    assertEquals(0, malformedSymbols.global("symbolCount"));
  }

  @Test
  void indexesTwoHundredFiftySixScalarProductsAndRejectsTheNext() throws Exception {
    Program closureProgram = program();
    byte[] exactSource = constantSource(256);
    VirtualMachine exact = VirtualMachine.withBinaryInput(
        closureProgram,
        framed(smallArchive(exactSource, true), smallManifest(exactSource)),
        1);
    CompilerMachineRunner.runWithoutRewindHistory(exact);
    assertArrayEquals(new byte[] {1}, exact.hostOutput());
    assertEquals(256, exact.global("symbolCount"));
    assertEquals(256, exact.global("rootLocalSymbols"));
    assertEquals(256, exact.global("resolvedSymbolCount"));
    assertEquals(1, exact.global("symbolGeneration"));

    byte[] oversizedSource = constantSource(257);
    VirtualMachine oversized = VirtualMachine.withBinaryInput(
        closureProgram,
        framed(smallArchive(oversizedSource, true), smallManifest(oversizedSource)),
        1);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(oversized));
    assertEquals(0, oversized.global("published"));
    assertEquals(0, oversized.global("symbolCount"));
  }

  @Test
  void resolvesGeneralExpressionsAcrossImportedProducts() throws Exception {
    NativeCompilerProductFixtures.Fixture fixture = NativeCompilerProductFixtures.expressions();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(),
        framed(fixture.archive(), fixture.manifest().canonicalBytes()),
        1);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(new byte[] {1}, machine.hostOutput());
    assertEquals(8, machine.global("symbolCount"));
    assertEquals(8, machine.global("resolvedSymbolCount"));
    assertEquals(1, machine.global("lastSymbolValue"));
  }

  @Test
  void leavesAnAmbiguousUnqualifiedProductUnresolved() throws Exception {
    NativeCompilerProductFixtures.Fixture fixture = NativeCompilerProductFixtures.ambiguous();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(),
        framed(fixture.archive(), fixture.manifest().canonicalBytes()),
        1);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(new byte[] {1}, machine.hostOutput());
    assertEquals(3, machine.global("symbolCount"));
    assertEquals(2, machine.global("resolvedSymbolCount"));
    assertEquals(0, machine.global("lastSymbolResolved"));
  }

  @Test
  void resolvesTwoHundredFiftySixImportedConstantProducts() throws Exception {
    NativeCompilerProductFixtures.Fixture fixture = NativeCompilerProductFixtures.forwardingChain(257);
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(),
        framed(fixture.archive(), fixture.manifest().canonicalBytes()),
        1);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(new byte[] {1}, machine.hostOutput());
    assertEquals(257, machine.global("symbolCount"));
    assertEquals(257, machine.global("resolvedSymbolCount"));
    assertEquals(41, machine.global("lastSymbolValue"));
    assertEquals(1, machine.global("maxImportedSymbols"));
    assertEquals(257, machine.global("symbolGeneration"));
  }

  @Test
  void plansAndClassifiesAChainOfTwoHundredFiftySevenModules() throws Exception {
    ChainFixture fixture = chainFixture(257);
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(),
        framed(fixture.archive(), fixture.manifest().canonicalBytes()),
        1);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertArrayEquals(new byte[] {1}, machine.hostOutput());
    assertEquals(257, machine.global("moduleCount"));
    assertEquals(256, machine.global("importCount"));
    assertEquals(256, machine.global("rootOrder"));
    assertEquals(0, machine.global("rootExecutable"));
    assertEquals(0, machine.global("executableCount"));
    assertEquals(1, machine.global("peakActiveSources"));
    assertEquals(257, machine.global("rootGeneration"));
    assertEquals(257, machine.global("symbolCount"));
    assertEquals(257, machine.global("resolvedSymbolCount"));
    assertEquals(1, machine.global("rootLocalSymbols"));
    assertEquals(1, machine.global("rootImportedSymbols"));
    assertEquals(1, machine.global("maxImportedSymbols"));
    assertEquals(257, machine.global("symbolGeneration"));
    assertEquals(identityPrefix(fixture.archive()), machine.global("packageIdentityPrefix"));
    assertEquals(
        symbolIdentityPrefix(fixture, "chain.n000", "VALUE"),
        machine.global("firstSymbolIdentityPrefix"));
    assertEquals(
        symbolIdentityPrefix(fixture, "chain.n256", "VALUE"),
        machine.global("lastSymbolIdentityPrefix"));
  }

  @Test
  void classifiesEveryPhysicalCompilerSourceWithinTheNativeWindow() throws Exception {
    Program classifier = classifierProgram();
    for (BootstrapModuleManifest.Module module
        : CompilerSources.bootstrapModuleManifest().modules()) {
      String logicalPath = module.source().substring("src/main/wheeler/".length());
      byte[] source = CompilerSources.read(logicalPath).getBytes(StandardCharsets.UTF_8);
      VirtualMachine machine = VirtualMachine.withBinaryInput(classifier, source, 2);
      CompilerMachineRunner.runWithoutRewindHistory(machine);
      assertEquals(1, machine.hostOutput()[0], module.name());
    }
  }

  private static Program classifierProgram() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.graphs.executable_owner_kinds"));
    sources.put("ClosureClassifierExample.w", """
        module example.closure_classifier;

        import wheeler.compiler.graphs.executable_owner_kinds;

        classical class ClosureClassifierExample {
          entry void main(borrow byteview input, borrow mut bytes output) {
            region arena = new region(/* bytes= */ 32768, /* allocations= */ 1);
            bytes sourceBytes = allocateBytes(arena, bufferLength(input));
            long cursor = 0;
            while (cursor < bufferLength(input)) limit 32768 {
              setByte(sourceBytes, cursor, input[cursor]);
              cursor += 1;
            }
            utf8 source = freezeUtf8(sourceBytes);
            ExecutableOwnerKind kind = classifyExecutableOwner(source);
            if (kind.valid) {
              setByte(output, 0, 1);
            }
            if (kind.executable) {
              setByte(output, 1, 1);
            }
            drop(source);
            drop(arena);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources,
        "example.closure_classifier");
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.archive_module_sources"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.module_symbols"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.package_target"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.plan"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.closure.schedule"));
    sources.put("ArchiveClosureExample.w", """
        module example.archive_closure;

        import wheeler.compiler.closure.archive_module_sources;
        import wheeler.compiler.closure.archive_sources;
        import wheeler.compiler.closure.module_manifest;
        import wheeler.compiler.closure.module_symbols;
        import wheeler.compiler.closure.package_target;
        import wheeler.compiler.closure.plan;
        import wheeler.compiler.closure.schedule;
        import wheeler.compiler.closure.symbol_identities;

        classical class ArchiveClosureExample {
          private const long MAX_ARCHIVE_BYTES = 16777216;
          private const long MAX_EXTERNALS = 64;
          private const long MAX_IMPORTS = 3072;
          private const long MAX_MANIFEST_BYTES = 262144;
          private const long MAX_MODULES = 512;
          private const long MAX_SYMBOLS = 16384;

          state long moduleCount = 0;
          state long importCount = 0;
          state long archiveEntryCount = 0;
          state long rootEntry = 0;
          state long rootDataStart = 0;
          state long rootDataLength = 0;
          state long rootOrder = 0;
          state long rootExecutable = 0;
          state long executableCount = 0;
          state long peakActiveSources = 0;
          state long rootGeneration = 0;
          state long compilerTarget = -1;
          state long symbolCount = 0;
          state long resolvedSymbolCount = 0;
          state long rootLocalSymbols = 0;
          state long rootImportedSymbols = 0;
          state long maxImportedSymbols = 0;
          state long symbolGeneration = 0;
          state long packageIdentityPrefix = 0;
          state long firstSymbolIdentityPrefix = 0;
          state long lastSymbolIdentityPrefix = 0;
          state long lastSymbolValue = 0;
          state long lastSymbolResolved = 0;
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

            region columns = new region(/* bytes= */ 1920000, /* allocations= */ 40);
            words archivePathStarts = allocate(columns, MAX_MODULES);
            words archivePathLengths = allocate(columns, MAX_MODULES);
            words archiveDataStarts = allocate(columns, MAX_MODULES);
            words archiveDataLengths = allocate(columns, MAX_MODULES);
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
            words executableOwners = allocate(columns, MAX_MODULES);
            words moduleSlots = allocate(columns, MAX_MODULES);
            words moduleGenerations = allocate(columns, MAX_MODULES);
            words moduleFirstSymbols = allocate(columns, MAX_MODULES);
            words moduleSymbolCounts = allocate(columns, MAX_MODULES);
            words moduleImportedSymbolCounts = allocate(columns, MAX_MODULES);
            words edgeSymbolCounts = allocate(columns, MAX_IMPORTS);
            words symbolOwners = allocate(columns, MAX_SYMBOLS);
            words symbolStarts = allocate(columns, MAX_SYMBOLS);
            words symbolLengths = allocate(columns, MAX_SYMBOLS);
            words symbolKinds = allocate(columns, MAX_SYMBOLS);
            words symbolVisibilities = allocate(columns, MAX_SYMBOLS);
            words symbolTypes = allocate(columns, MAX_SYMBOLS);
            words symbolValues = allocate(columns, MAX_SYMBOLS);
            words symbolResolved = allocate(columns, MAX_SYMBOLS);
            bytes packageIdentity = allocateBytes(columns, /* length= */ 32);
            bytes symbolIdentities = allocateBytes(columns, MAX_SYMBOLS * 32);
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
                long selectedCompilerTarget = -1;
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
                    selectedCompilerTarget = target.target;
                  }
                  case CompilerToolTargetResult.Error(long targetOffset) {
                    assert(targetOffset < 0);
                  }
                }
                assert(-1 < selectedCompilerTarget);
                ArchiveModuleSourcePlan plan = joinArchiveModuleSources(
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
                CountedClosurePlan closure = planClosureStructure(
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
                CountedModuleSymbolPlan symbols = indexCountedModuleSymbols(
                  archive,
                  manifest,
                  closure,
                  edgeTargets,
                  firstImports,
                  directImportCounts,
                  importRanks,
                  leafFirstOrder,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  moduleFirstSymbols,
                  moduleSymbolCounts,
                  moduleImportedSymbolCounts,
                  edgeSymbolCounts,
                  symbolOwners,
                  symbolStarts,
                  symbolLengths,
                  symbolKinds,
                  symbolVisibilities,
                  symbolTypes,
                  symbolValues,
                  symbolResolved
                );
                publishCountedSymbolIdentities(
                  archive,
                  manifest,
                  closure,
                  symbols.symbolCount,
                  identityStarts,
                  symbolOwners,
                  symbolStarts,
                  symbolLengths,
                  symbolKinds,
                  symbolVisibilities,
                  symbolTypes,
                  packageIdentity,
                  symbolIdentities
                );
                classifyClosureExecutableOwners(
                  archive,
                  manifest,
                  closure,
                  moduleStarts,
                  moduleLengths,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  executableOwners
                );
                ClosureSourceSchedule schedule = stageClosureSources(
                  archive,
                  manifest,
                  closure,
                  leafFirstOrder,
                  archiveSourceStarts,
                  archiveSourceLengths,
                  moduleSlots,
                  moduleGenerations
                );
                long selectedRootEntry = moduleEntries[plan.rootModule];
                long executableModule = 0;
                long parsedExecutables = 0;
                long largestImportedSymbols = 0;
                while (executableModule < closure.moduleCount) limit MAX_MODULES {
                  parsedExecutables += executableOwners[executableModule];
                  if (
                    largestImportedSymbols < moduleImportedSymbolCounts[executableModule]
                  ) {
                    largestImportedSymbols = moduleImportedSymbolCounts[executableModule];
                  }

                  executableModule += 1;
                }
                long parsedResolvedSymbols = 0;
                long resolvedSymbol = 0;
                while (resolvedSymbol < symbols.symbolCount) limit MAX_SYMBOLS {
                  parsedResolvedSymbols += symbolResolved[resolvedSymbol];
                  resolvedSymbol += 1;
                }

                long selectedRootOrder = 0;
                while (
                  leafFirstOrder[selectedRootOrder] != closure.rootModule
                ) limit MAX_MODULES {
                  selectedRootOrder += 1;
                }
                moduleCount = plan.moduleCount;
                importCount = manifestPlan.importCount;
                archiveEntryCount = plan.archiveEntryCount;
                rootEntry = selectedRootEntry;
                rootDataStart = archiveDataStarts[selectedRootEntry];
                rootDataLength = archiveDataLengths[selectedRootEntry];
                rootOrder = selectedRootOrder;
                rootExecutable = executableOwners[closure.rootModule];
                executableCount = parsedExecutables;
                peakActiveSources = schedule.peakActiveSources;
                rootGeneration = moduleGenerations[closure.rootModule];
                compilerTarget = selectedCompilerTarget;
                symbolCount = symbols.symbolCount;
                resolvedSymbolCount = parsedResolvedSymbols;
                rootLocalSymbols = moduleSymbolCounts[closure.rootModule];
                rootImportedSymbols = moduleImportedSymbolCounts[closure.rootModule];
                maxImportedSymbols = largestImportedSymbols;
                symbolGeneration = symbols.finalGeneration;
                packageIdentityPrefix = packageIdentity[0] * 16777216
                  + packageIdentity[1] * 65536
                  + packageIdentity[2] * 256
                  + packageIdentity[3];
                firstSymbolIdentityPrefix = symbolIdentities[0] * 16777216
                  + symbolIdentities[1] * 65536
                  + symbolIdentities[2] * 256
                  + symbolIdentities[3];
                long finalIdentity = (symbols.symbolCount - 1) * 32;
                lastSymbolIdentityPrefix = symbolIdentities[finalIdentity] * 16777216
                  + symbolIdentities[finalIdentity + 1] * 65536
                  + symbolIdentities[finalIdentity + 2] * 256
                  + symbolIdentities[finalIdentity + 3];
                lastSymbolValue = symbolValues[symbols.symbolCount - 1];
                lastSymbolResolved = symbolResolved[symbols.symbolCount - 1];
                published = 1;
                setByte(output, 0, 1);
              }
              case ArchiveSourceIndexResult.Error(long offset) {
                assert(offset < 0);
              }
            }
            drop(expected);
            drop(symbolIdentities);
            drop(packageIdentity);
            drop(symbolResolved);
            drop(symbolValues);
            drop(symbolTypes);
            drop(symbolVisibilities);
            drop(symbolKinds);
            drop(symbolLengths);
            drop(symbolStarts);
            drop(symbolOwners);
            drop(edgeSymbolCounts);
            drop(moduleImportedSymbolCounts);
            drop(moduleSymbolCounts);
            drop(moduleFirstSymbols);
            drop(moduleGenerations);
            drop(moduleSlots);
            drop(executableOwners);
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
    return new WheelerCompiler().compileModuleFiles(sources, "example.archive_closure");
  }

  private static byte[] framed(byte[] archive, byte[] manifest) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    writeU32(output, archive.length);
    output.writeBytes(archive);
    output.writeBytes(manifest);
    return output.toByteArray();
  }

  private static EntryRange entryRange(byte[] archive, int selected) {
    int cursor = 16 + readU32(archive, 8);
    int count = readU32(archive, 12);
    for (int index = 0; index < count; index++) {
      int pathLength = readU32(archive, cursor);
      int dataLength = readU32(archive, cursor + 4);
      int pathStart = cursor + 12;
      int dataStart = pathStart + pathLength + 32;
      if (index == selected) {
        return new EntryRange(
            new String(archive, pathStart, pathLength, StandardCharsets.US_ASCII),
            dataStart,
            dataLength);
      }
      cursor = dataStart + dataLength;
    }
    throw new IllegalArgumentException("No archive entry " + selected);
  }

  private static ChainFixture chainFixture(int count) throws Exception {
    var modules = new ArrayList<BootstrapModuleManifest.Module>();
    Map<String, byte[]> sources = new LinkedHashMap<>();
    MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
    for (int index = 0; index < count; index++) {
      String name = "chain.n%03d".formatted(index);
      String path = "src/chain/n%03d.w".formatted(index);
      String imported = index == 0 ? "" : "\nimport chain.n%03d;".formatted(index - 1);
      byte[] source = ("module " + name + ";" + imported
          + "\n\nclassical class Node%03d {\n".formatted(index)
          + "  public const long VALUE = %d;\n}\n".formatted(index))
          .getBytes(StandardCharsets.UTF_8);
      sources.put(path, source);
      modules.add(new BootstrapModuleManifest.Module(
          name,
          path,
          HexFormat.of().formatHex(sha256.digest(source)),
          index == 0 ? List.of() : List.of("chain.n%03d".formatted(index - 1))));
    }

    BootstrapModuleManifest manifest = new BootstrapModuleManifest(
        "bootstrap-1",
        "chain.n%03d".formatted(count - 1),
        List.of(),
        modules);
    byte[] archive = new PackageArchive().encode(
        new PackageManifestParser().parse("""
            schema: 1
            package:
              name: "demo.chain"
              version: "1.0.0"
              profile: "bootstrap-1"
            targets:
              - kind: "tool"
                name: "compiler"
                root: "src/chain/n256.w"
                module: "chain.n256"
                sources:
                  - "src/chain"
                test: false
            dependencies: []
            capabilities: []
            """),
        sources);
    return new ChainFixture(archive, manifest);
  }

  private static void runClosure(VirtualMachine machine, Program program) {
    try {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    } catch (VmTrap trap) {
      var frames = machine.snapshot().selectedFrames().stream()
          .map(frame -> program.function(frame.functionId()).name()
              + "@" + frame.programCounter())
          .toList();
      throw new AssertionError("Counted closure trapped in " + frames, trap);
    }
  }

  private static long identityPrefix(byte[] source) throws Exception {
    return digestPrefix(MessageDigest.getInstance("SHA-256").digest(source));
  }

  private static long symbolIdentityPrefix(
      ChainFixture fixture, String moduleName, String symbolName) throws Exception {
    BootstrapModuleManifest.Module module = fixture.manifest().modules().stream()
        .filter(candidate -> candidate.name().equals(moduleName))
        .findFirst()
        .orElseThrow();
    MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
    ByteArrayOutputStream input = new ByteArrayOutputStream();
    input.writeBytes("wheeler-module-symbol-1".getBytes(StandardCharsets.US_ASCII));
    input.writeBytes(sha256.digest(fixture.archive()));
    input.writeBytes(HexFormat.of().parseHex(module.identity()));
    input.write(1);
    input.write(1);
    input.write(1);
    writeU32(input, symbolName.length());
    input.writeBytes(symbolName.getBytes(StandardCharsets.US_ASCII));
    return digestPrefix(sha256.digest(input.toByteArray()));
  }

  private static long digestPrefix(byte[] digest) {
    return (long) (digest[0] & 0xff) << 24
        | (long) (digest[1] & 0xff) << 16
        | (long) (digest[2] & 0xff) << 8
        | digest[3] & 0xffL;
  }

  private static byte[] constantSource(int count) {
    StringBuilder source = new StringBuilder(
        "module demo.main; classical class Main {");
    for (int index = 0; index < count; index++) {
      source.append(" public const long C%03d = %d;".formatted(index, index));
    }
    source.append(" }");
    return source.toString().getBytes(StandardCharsets.UTF_8);
  }

  private static byte[] smallArchive(byte[] source, boolean compilerTarget) {
    String target = compilerTarget
        ? """
              - kind: "tool"
                name: "compiler"
                root: "src/Main.w"
                module: "demo.main"
                sources:
                  - "src/Main.w"
                test: false
            """
        : """
              - kind: "library"
                name: "library"
                root: "src/Main.w"
                test: false
            """;
    return new PackageArchive().encode(
        new PackageManifestParser().parse("""
            schema: 1
            package:
              name: "demo.archive"
              version: "1.0.0"
              profile: "bootstrap-1"
            targets:
            %sdependencies: []
            capabilities: []
            """.formatted(target)),
        Map.of("src/Main.w", source));
  }

  private static void repairOuterDigest(byte[] archive) throws Exception {
    int payloadLength = archive.length - 32;
    byte[] digest = MessageDigest.getInstance("SHA-256").digest(
        java.util.Arrays.copyOf(archive, payloadLength));
    System.arraycopy(digest, 0, archive, payloadLength, digest.length);
  }

  private static byte[] smallManifest(byte[] source) throws Exception {
    String identity = HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(source));
    return ("""
        schema: 1
        profile: "bootstrap-1"
        root: "demo.main"
        externals: []
        modules:
          - name: "demo.main"
            source: "src/Main.w"
            identity: "%s"
            imports: []
        """.formatted(identity)).getBytes(StandardCharsets.UTF_8);
  }

  private static int indexOf(byte[] source, byte[] expected) {
    for (int offset = 0; offset <= source.length - expected.length; offset++) {
      int index = 0;
      while (index < expected.length && source[offset + index] == expected[index]) {
        index += 1;
      }
      if (index == expected.length) {
        return offset;
      }
    }
    throw new IllegalArgumentException("Manifest has no module identity");
  }

  private static int readU32(byte[] source, int offset) {
    return (source[offset] & 0xff)
        | (source[offset + 1] & 0xff) << 8
        | (source[offset + 2] & 0xff) << 16
        | (source[offset + 3] & 0xff) << 24;
  }

  private static void writeU32(ByteArrayOutputStream output, int value) {
    output.write(value & 0xff);
    output.write(value >>> 8 & 0xff);
    output.write(value >>> 16 & 0xff);
    output.write(value >>> 24 & 0xff);
  }

  private record ChainFixture(byte[] archive, BootstrapModuleManifest manifest) {}

  private record EntryRange(String path, int dataStart, int dataLength) {}
}
