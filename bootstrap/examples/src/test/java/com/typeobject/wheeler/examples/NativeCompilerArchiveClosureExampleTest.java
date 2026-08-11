package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for joining the physical compiler archive and module manifest. */
final class NativeCompilerArchiveClosureExampleTest {
  @Tag("closure-evidence")
  @Test
  void joinsEveryPhysicalCompilerModuleToItsDigestCheckedArchiveRange() throws Exception {
    Program program = NativeCompilerArchiveClosureProgram.metadataProgram();
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
    assertEquals(1_465, machine.global("symbolCount"));
    assertEquals(1_230, machine.global("callableCount"));
    assertTrue(machine.global("callableParameterCount") > 1_000);
    assertTrue(machine.global("borrowedParameterCount") > 0);
    assertTrue(machine.global("mutableParameterCount") > 0);
    assertEquals(0, machine.global("resultSlotCallableCount"));
    assertTrue(machine.global("firstCallableResultTypeLength") > 0);
    assertEquals(1, machine.global("rootLocalCallables"));
    assertTrue(machine.global("rootImportedCallables") > 0);
    assertTrue(machine.global("maxImportedCallables") > 0);
    assertEquals(manifest.modules().size(), machine.global("callableGeneration"));
    assertEquals(2, machine.global("lastCallableParameterCount"));
    assertEquals(1, machine.global("callableIdentitiesPublished"));
    assertTrue(machine.global("physicalModuleProductLength") > 0);
    assertTrue(machine.global("physicalModuleProductFunctions") > 3);
    assertEquals(
        NativeCompilerArchiveClosureProgram.PHYSICAL_MODULES.size(),
        machine.global("physicalModuleProductCount"));
    assertTrue(machine.global("firstCallableIdentityPrefix") != 0);
    assertTrue(
        machine.global("firstCallableIdentityPrefix")
            != machine.global("lastCallableIdentityPrefix"));
    assertTrue(machine.global("resolvedSymbolCount") > 800);
    assertEquals(0, machine.global("moduleIdentitiesPublished"));
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

  @Tag("closure-evidence")
  @Test
  void compilesPhysicalModuleProductsByteForByte() throws Exception {
    ByteArrayOutputStream expected = new ByteArrayOutputStream();
    long expectedFunctions = 0;
    for (NativeCompilerArchiveClosureProgram.PhysicalModule module
        : NativeCompilerArchiveClosureProgram.PHYSICAL_MODULES) {
      byte[] artifact = new BytecodeWriter().write(
          new WheelerCompiler().compileLibraryModuleFiles(
              CompilerSources.moduleClosure(module.name()), module.name()));
      expected.writeBytes(artifact);
      expectedFunctions += new BytecodeReader().read(artifact).functions().size();
    }
    long expectedRetainedProducts = 0;
    long expectedRetainedFunctions = 0;
    long expectedRetainedInstructions = 0;
    var retainedModules = new ArrayList<>(
        NativeCompilerArchiveClosureProgram.PHYSICAL_MODULES);
    retainedModules.addAll(NativeCompilerArchiveClosureProgram.PHYSICAL_CALLABLE_MODULES);
    for (NativeCompilerArchiveClosureProgram.PhysicalModule module : retainedModules) {
      Program compiled = new WheelerCompiler().compileLibraryModuleFiles(
          CompilerSources.moduleClosure(module.name()), module.name());
      long moduleFunctions = 0;
      for (var function : compiled.functions()) {
        if (function.name().startsWith(module.name() + "::")) {
          moduleFunctions += 1;
          expectedRetainedFunctions += 1;
          expectedRetainedInstructions += function.forward().size();
          expectedRetainedInstructions += function.inverse().size();
        }
      }
      if (0 < moduleFunctions) {
        expectedRetainedProducts += 1;
      }
    }
    var rootModule = NativeCompilerArchiveClosureProgram.PHYSICAL_MODULES.getLast();
    Program rootArtifact = new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure(rootModule.name()), rootModule.name());
    var rootEntry = rootArtifact.functions().stream()
        .filter(function -> function.name().equals("$library"))
        .findFirst()
        .orElseThrow();
    expectedRetainedFunctions += 1;
    expectedRetainedInstructions += rootEntry.forward().size();
    expectedRetainedInstructions += rootEntry.inverse().size();
    Program program = NativeCompilerArchiveClosureProgram.program();
    byte[] archive = CompilerSources.packageArchive();
    BootstrapModuleManifest manifest = CompilerSources.bootstrapModuleManifest();
    for (NativeCompilerArchiveClosureProgram.PhysicalModule module
        : NativeCompilerArchiveClosureProgram.PHYSICAL_MODULES) {
      BootstrapModuleManifest.Module manifestModule = manifest.modules().get(module.owner());
      assertEquals(module.name(), manifestModule.name());
      assertEquals("src/main/wheeler/" + module.path(), manifestModule.source());
    }
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program,
        framed(archive, manifest.canonicalBytes()),
        expected.size() + 1_048_576);

    runClosure(machine, program);

    byte[] physicalProducts = machine.hostOutput();
    assertArrayEquals(
        expected.toByteArray(),
        Arrays.copyOf(physicalProducts, expected.size()));
    assertEquals(
        machine.global("physicalRetainedProductLength")
            + retainedModules.size() * 6L
            + machine.global("physicalCallableRelocationCount") * 6L
            + 8,
        physicalProducts.length);
    assertEquals(expected.size(), machine.global("physicalModuleProductLength"));
    assertEquals(expectedFunctions, machine.global("physicalModuleProductFunctions"));
    assertEquals(
        NativeCompilerArchiveClosureProgram.PHYSICAL_MODULES.size(),
        machine.global("physicalModuleProductCount"));
    assertEquals(
        NativeCompilerArchiveClosureProgram.PHYSICAL_CALLABLE_MODULES.size(),
        machine.global("physicalCallableProductCount"));
    assertTrue(
        NativeCompilerArchiveClosureProgram.PHYSICAL_CALLABLE_MODULES.size()
            <= machine.global("physicalCallableRelocationCount"));
    assertEquals(
        machine.global("physicalCallableRelocationCount"),
        machine.global("physicalResolvedCallableTargetCount"));
    assertEquals(
        expectedRetainedFunctions,
        machine.global("physicalRetainedFunctionCount"));
    assertEquals(
        expectedRetainedInstructions,
        machine.global("physicalRetainedInstructionCount"));

    Program functionClosure = NativeCompilerPhysicalFunctionClosureProgram.program(
        retainedModules.size(),
        NativeCompilerArchiveClosureProgram.PHYSICAL_MODULES.size() - 1);
    VirtualMachine functionMachine = VirtualMachine.withBinaryInput(
        functionClosure, physicalProducts, 4_194_304);
    CompilerMachineRunner.runWithoutRewindHistory(functionMachine);
    assertEquals(1, functionMachine.global("published"));
    assertEquals(expectedRetainedProducts, functionMachine.global("productCount"));
    assertEquals(expectedRetainedFunctions, functionMachine.global("functionCount"));
    assertEquals(expectedRetainedInstructions, functionMachine.global("instructionCount"));
    assertEquals(
        machine.global("physicalCallableRelocationCount"),
        functionMachine.global("validatedRelocationCount"));
    assertEquals(
        machine.global("physicalCallableRelocationCount"),
        functionMachine.global("unresolvedTargetCount"));
    assertEquals(
        machine.global("physicalCallableRelocationCount"),
        functionMachine.global("relocatedTargetCount"));
    assertEquals(
        functionMachine.hostOutput().length,
        functionMachine.global("linkedContainerLength"));
    assertTrue(0 < functionMachine.global("linkedCodeLength"));
    assertTrue(0 < functionMachine.global("linkedLocalTypeCount"));
    assertEquals(
        4
            + expectedRetainedFunctions * 40
            + functionMachine.global("linkedLocalTypeCount") * 4,
        functionMachine.global("linkedFunctionSectionLength"));
    assertTrue(
        functionMachine.global("linkedUniqueStringCount")
            < functionMachine.global("linkedSourceStringCount"));
    assertTrue(0 < functionMachine.global("linkedStringSectionLength"));
    assertEquals(24, functionMachine.global("linkedManifestLength"));
    assertEquals(1_029_869_779L, functionMachine.global("linkedIdentityPrefix"));
    String linkedIdentity = HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(functionMachine.hostOutput()));
    assertEquals(
        "3d6290d3f11b55960f686eeec24ff8139c732911f4358860abb96208d22e7947",
        linkedIdentity,
        () -> "code=" + functionMachine.global("linkedCodeLength")
            + " functions=" + functionMachine.global("functionCount")
            + " instructions=" + functionMachine.global("instructionCount")
            + " sourceStrings=" + functionMachine.global("linkedSourceStringCount")
            + " uniqueStrings=" + functionMachine.global("linkedUniqueStringCount")
            + " localTypes=" + functionMachine.global("linkedLocalTypeCount")
            + " container=" + functionMachine.global("linkedContainerLength"));
    Program linkedClosure = new BytecodeReader().read(functionMachine.hostOutput());
    assertEquals(ProgramKind.CLASSICAL, linkedClosure.kind());
    assertEquals(
        "$library",
        linkedClosure.function(linkedClosure.entryFunctionId()).name());
    assertEquals(expectedRetainedFunctions, linkedClosure.functions().size());
    assertEquals(0, linkedClosure.globals().size());
    assertEquals(0, linkedClosure.recordTypes().size());
    assertEquals(0, linkedClosure.variantTypes().size());
    assertEquals(0, linkedClosure.arrayTypes().size());
    assertEquals(0, linkedClosure.sliceTypes().size());
    CompilerMachineRunner.runWithoutRewindHistory(new VirtualMachine(linkedClosure));

    VirtualMachine repeatedFunctionMachine = VirtualMachine.withBinaryInput(
        functionClosure, physicalProducts, 4_194_304);
    CompilerMachineRunner.runWithoutRewindHistory(repeatedFunctionMachine);
    assertEquals(1, repeatedFunctionMachine.global("published"));
    assertEquals(1_029_869_779L, repeatedFunctionMachine.global("linkedIdentityPrefix"));
    assertArrayEquals(
        functionMachine.hostOutput(), repeatedFunctionMachine.hostOutput());

    byte[] malformedFooter = physicalProducts.clone();
    malformedFooter[malformedFooter.length - 8] = 0;
    VirtualMachine malformedFooterMachine = VirtualMachine.withBinaryInput(
        functionClosure, malformedFooter, 4_194_304);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(malformedFooterMachine));
    assertEquals(0, malformedFooterMachine.global("published"));
    assertEquals(0, malformedFooterMachine.global("productCount"));

    byte[] malformedProducts = physicalProducts.clone();
    int firstRelocation = Math.toIntExact(
        machine.global("physicalRetainedProductLength") + retainedModules.size() * 6L);
    malformedProducts[firstRelocation + 3] = (byte) 0xff;
    malformedProducts[firstRelocation + 4] = (byte) 0xff;
    VirtualMachine malformedFunctionMachine = VirtualMachine.withBinaryInput(
        functionClosure, malformedProducts, 4_194_304);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(malformedFunctionMachine));
    assertEquals(0, malformedFunctionMachine.global("published"));
    assertEquals(0, malformedFunctionMachine.global("relocatedTargetCount"));
    assertEquals(0, malformedFunctionMachine.global("linkedCodeLength"));
    assertEquals(0, malformedFunctionMachine.global("linkedIdentityPrefix"));
  }

  @Test
  void rejectsNoncanonicalPackageMetadataWrongTargetAndMalformedSymbols() throws Exception {
    Program closureProgram = NativeCompilerArchiveClosureProgram.program();
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
    Program closureProgram = NativeCompilerArchiveClosureProgram.program();
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
        NativeCompilerArchiveClosureProgram.program(),
        framed(fixture.archive(), fixture.manifest().canonicalBytes()),
        1);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(new byte[] {1}, machine.hostOutput());
    assertEquals(8, machine.global("symbolCount"));
    assertEquals(8, machine.global("resolvedSymbolCount"));
    assertEquals(0, machine.global("callableCount"));
    assertEquals(1, machine.global("lastSymbolValue"));
  }

  @Test
  void leavesAnAmbiguousUnqualifiedProductUnresolved() throws Exception {
    NativeCompilerProductFixtures.Fixture fixture = NativeCompilerProductFixtures.ambiguous();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        NativeCompilerArchiveClosureProgram.program(),
        framed(fixture.archive(), fixture.manifest().canonicalBytes()),
        1);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(new byte[] {1}, machine.hostOutput());
    assertEquals(3, machine.global("symbolCount"));
    assertEquals(2, machine.global("resolvedSymbolCount"));
    assertEquals(0, machine.global("lastSymbolResolved"));
  }

  @Test
  void indexesCallableProductsAcrossAChain() throws Exception {
    NativeCompilerProductFixtures.Fixture fixture = NativeCompilerProductFixtures.callableChain();
    String compiledModuleSource = "module wheeler.callable.product; "
        + "classical class CallableProduct { "
        + "private void clear(borrow mut bytes output) {} "
        + "private boolean inspect(borrow byteview source) { return true; } "
        + "public boolean readable(borrow byteview source) { return inspect(source); } }";
    byte[] compiledModule = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("CallableProduct.w", compiledModuleSource),
            "wheeler.callable.product"));
    Program program = NativeCompilerArchiveClosureProgram.program();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program,
        framed(fixture.archive(), fixture.manifest().canonicalBytes()),
        compiledModule.length);
    runClosure(machine, program);
    Program compiledModuleProgram = new BytecodeReader().read(compiledModule);
    assertEquals(
        compiledModuleProgram.functions(),
        new BytecodeReader().read(machine.hostOutput()).functions());
    assertEquals(
        compiledModuleProgram.functions().size(),
        machine.global("compiledCallableFunctionCount"));
    assertEquals(
        compiledModuleProgram.functions().stream()
            .mapToInt(function -> function.localTypes().size())
            .max()
            .orElseThrow(),
        machine.global("compiledCallableMaxLocalCount"));
    assertArrayEquals(compiledModule, machine.hostOutput());
    assertEquals(6, machine.global("callableCount"));
    assertEquals(5, machine.global("callableParameterCount"));
    assertEquals(3, machine.global("borrowedParameterCount"));
    assertEquals(1, machine.global("mutableParameterCount"));
    assertEquals(1, machine.global("resultSlotCallableCount"));
    assertEquals(1, machine.global("rootLocalCallables"));
    assertEquals(1, machine.global("rootImportedCallables"));
    assertEquals(1, machine.global("maxImportedCallables"));
    assertEquals(3, machine.global("callableGeneration"));
    assertTrue(machine.global("firstCallableSignatureLength") > 0);
    assertTrue(machine.global("firstCallableBodyLength") > 0);
    assertTrue(machine.global("firstCallableResultTypeLength") > 0);
    assertEquals(0, machine.global("lastCallableParameterCount"));
    assertEquals(1, machine.global("lastCallableEffects"));
    assertEquals(
        callableIdentityPrefix(
            fixture,
            "callable.leaf",
            "identity",
            1,
            0,
            "long",
            List.of("long"),
            List.of(0)),
        machine.global("firstCallableIdentityPrefix"));
    assertEquals(
        callableIdentityPrefix(
            fixture,
            "callable.root",
            "main",
            0,
            1,
            "void",
            List.of(),
            List.of()),
        machine.global("lastCallableIdentityPrefix"));
    assertEquals(1, machine.global("callableIdentitiesPublished"));
    assertEquals(1, machine.global("invalidCallableIdentityRejected"));
    String compiledCallableSource = "module wheeler.callable.product; "
        + "classical class CallableProduct { "
        + "public long identity(long value) { return value; } }";
    byte[] compiledCallable = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("CallableProduct.w", compiledCallableSource),
            "wheeler.callable.product"));
    assertEquals(compiledCallable.length, machine.global("compiledCallableBodyLength"));
    assertEquals(
        identityPrefix(compiledCallable),
        machine.global("compiledCallableBodyIdentityPrefix"));
    assertEquals(compiledModule.length, machine.global("compiledCallableModuleLength"));
    assertEquals(
        identityPrefix(compiledModule),
        machine.global("compiledCallableModuleIdentityPrefix"));
  }

  @Test
  void resolvesTwoHundredFiftySixImportedConstantProducts() throws Exception {
    NativeCompilerProductFixtures.Fixture fixture = NativeCompilerProductFixtures.forwardingChain(257);
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        NativeCompilerArchiveClosureProgram.program(),
        framed(fixture.archive(), fixture.manifest().canonicalBytes()),
        1);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(new byte[] {1}, machine.hostOutput());
    assertEquals(257, machine.global("symbolCount"));
    assertEquals(257, machine.global("resolvedSymbolCount"));
    assertEquals(41, machine.global("lastSymbolValue"));
    assertEquals(1, machine.global("maxImportedSymbols"));
    assertEquals(257, machine.global("symbolGeneration"));
    long[] modulePrefixes = scalarModuleIdentityPrefixes(fixture);
    assertEquals(modulePrefixes[0], machine.global("firstModuleIdentityPrefix"));
    assertEquals(modulePrefixes[1], machine.global("lastModuleIdentityPrefix"));
    assertEquals(1, machine.global("moduleIdentitiesPublished"));
  }

  @Test
  void compilesQualifiedBooleanAndNegativeProducts() throws Exception {
    NativeCompilerProductFixtures.Fixture fixture =
        NativeCompilerProductFixtures.executableQualifiedValues();
    byte[] expected = new WheelerCompiler().compileToBytecode(
        "classical class Root { state long outcome = 0; "
            + "entry void main() { outcome += -42; assert(true); } }");
    Program compiler = NativeCompilerArchiveClosureProgram.program();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        compiler,
        framed(fixture.archive(), fixture.manifest().canonicalBytes()),
        expected.length);
    try {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    } catch (VmTrap trap) {
      throw new AssertionError(
          machine.snapshot().selectedFrames().stream()
              .map(frame -> compiler.function(frame.functionId()).name()
                  + "@" + frame.programCounter())
              .toList()
              .toString(),
          trap);
    }
    assertArrayEquals(expected, machine.hostOutput());
    assertEquals(2, machine.global("symbolCount"));
    assertEquals(2, machine.global("resolvedSymbolCount"));
    assertEquals(1, machine.global("lastSymbolValue"));
  }

  @Test
  void compilesA257ModuleExecutableDirectlyFromCountedProducts() throws Exception {
    NativeCompilerProductFixtures.Fixture fixture =
        NativeCompilerProductFixtures.executableForwardingChain(256);
    byte[] expected = new WheelerCompiler().compileToBytecode(
        "classical class Root { state long outcome = 0; "
            + "entry void main() { outcome += 41; } }");
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        NativeCompilerArchiveClosureProgram.program(),
        framed(fixture.archive(), fixture.manifest().canonicalBytes()),
        expected.length);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(expected, machine.hostOutput());
    assertEquals(257, machine.global("moduleCount"));
    assertEquals(256, machine.global("symbolCount"));
    assertEquals(256, machine.global("resolvedSymbolCount"));
    assertEquals(41, machine.global("lastSymbolValue"));
    assertEquals(257, machine.global("symbolGeneration"));
    assertEquals(1, machine.global("callableCount"));
    assertEquals(1, machine.global("rootLocalCallables"));
    assertEquals(0, machine.global("rootImportedCallables"));
    assertEquals(257, machine.global("callableGeneration"));
  }

  @Test
  void plansAndClassifiesAChainOfTwoHundredFiftySevenModules() throws Exception {
    ChainFixture fixture = chainFixture(257);
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        NativeCompilerArchiveClosureProgram.program(),
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
      throw new AssertionError(
          "Counted closure trapped for physical owner "
              + machine.global("physicalModuleOwner") + " in " + frames,
          trap);
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

  private static long[] scalarModuleIdentityPrefixes(
      NativeCompilerProductFixtures.Fixture fixture) throws Exception {
    MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
    byte[] packageIdentity = sha256.digest(fixture.archive());
    byte[] dependencyIdentity = null;
    long firstPrefix = 0;
    for (int index = 0; index < fixture.manifest().modules().size(); index++) {
      BootstrapModuleManifest.Module module = fixture.manifest().modules().get(index);
      String symbolName = "V%03d".formatted(index);
      ByteArrayOutputStream input = new ByteArrayOutputStream();
      input.writeBytes("wheeler-scalar-module-product-1".getBytes(StandardCharsets.US_ASCII));
      input.writeBytes(packageIdentity);
      input.writeBytes(HexFormat.of().parseHex(module.identity()));
      writeU16(input, module.name().length());
      input.writeBytes(module.name().getBytes(StandardCharsets.US_ASCII));
      writeU16(input, dependencyIdentity == null ? 0 : 1);
      if (dependencyIdentity != null) {
        input.writeBytes(dependencyIdentity);
      }
      writeU16(input, 1);
      input.writeBytes(symbolIdentity(fixture, module, symbolName));
      input.write(1);
      long value = 41;
      for (int octet = 0; octet < 8; octet++) {
        input.write((int) (value >>> octet * 8) & 0xff);
      }
      dependencyIdentity = sha256.digest(input.toByteArray());
      if (index == 0) {
        firstPrefix = digestPrefix(dependencyIdentity);
      }
    }
    return new long[] {firstPrefix, digestPrefix(dependencyIdentity)};
  }

  private static byte[] symbolIdentity(
      NativeCompilerProductFixtures.Fixture fixture,
      BootstrapModuleManifest.Module module,
      String symbolName) throws Exception {
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
    return sha256.digest(input.toByteArray());
  }

  private static long callableIdentityPrefix(
      NativeCompilerProductFixtures.Fixture fixture,
      String moduleName,
      String name,
      int visibility,
      int effects,
      String resultType,
      List<String> parameterTypes,
      List<Integer> parameterModes) throws Exception {
    BootstrapModuleManifest.Module module = fixture.manifest().modules().stream()
        .filter(candidate -> candidate.name().equals(moduleName))
        .findFirst()
        .orElseThrow();
    MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
    ByteArrayOutputStream input = new ByteArrayOutputStream();
    input.writeBytes("wheeler-callable-signature-1".getBytes(StandardCharsets.US_ASCII));
    input.writeBytes(sha256.digest(fixture.archive()));
    input.writeBytes(HexFormat.of().parseHex(module.identity()));
    input.write(visibility);
    input.write(effects);
    writeU16(input, name.length());
    input.writeBytes(name.getBytes(StandardCharsets.US_ASCII));
    writeU16(input, resultType.length());
    input.writeBytes(resultType.getBytes(StandardCharsets.US_ASCII));
    writeU16(input, parameterTypes.size());
    for (int index = 0; index < parameterTypes.size(); index++) {
      String type = parameterTypes.get(index);
      input.write(parameterModes.get(index));
      writeU16(input, type.length());
      input.writeBytes(type.getBytes(StandardCharsets.US_ASCII));
    }
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

  private static void writeU16(ByteArrayOutputStream output, int value) {
    output.write(value & 0xff);
    output.write(value >>> 8 & 0xff);
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
