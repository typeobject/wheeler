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
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HexFormat;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Native evidence for exact physical compiler products and linked closure bytes. */
final class NativeCompilerPhysicalClosureExampleTest {
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
    assertPhysicalProductOwners(manifest);
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
    String linkedIdentity = HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(functionMachine.hostOutput()));
    assertEquals(
        146_118_539L,
        functionMachine.global("linkedIdentityPrefix"),
        () -> "sha256=" + linkedIdentity
            + " code=" + functionMachine.global("linkedCodeLength")
            + " functions=" + functionMachine.global("functionCount")
            + " instructions=" + functionMachine.global("instructionCount")
            + " sourceStrings=" + functionMachine.global("linkedSourceStringCount")
            + " uniqueStrings=" + functionMachine.global("linkedUniqueStringCount")
            + " localTypes=" + functionMachine.global("linkedLocalTypeCount")
            + " container=" + functionMachine.global("linkedContainerLength"));
    assertEquals(
        "08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac",
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
    assertEquals(146_118_539L, repeatedFunctionMachine.global("linkedIdentityPrefix"));
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

  private static byte[] framed(byte[] archive, byte[] manifest) {
    return ByteBuffer.allocate(Integer.BYTES + archive.length + manifest.length)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putInt(archive.length)
        .put(archive)
        .put(manifest)
        .array();
  }

  private static void assertPhysicalProductOwners(BootstrapModuleManifest manifest) {
    var modules = new ArrayList<>(NativeCompilerArchiveClosureProgram.PHYSICAL_MODULES);
    modules.addAll(NativeCompilerArchiveClosureProgram.PHYSICAL_CALLABLE_MODULES);
    for (NativeCompilerArchiveClosureProgram.PhysicalModule module : modules) {
      int owner = NativeCompilerPhysicalSelection.owner(module);
      BootstrapModuleManifest.Module manifestModule = manifest.modules().get(owner);
      assertEquals(module.name(), manifestModule.name());
      assertEquals("src/main/wheeler/" + module.path(), manifestModule.source());
    }
  }

  private static void runClosure(VirtualMachine machine, Program program) {
    try {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    } catch (VmTrap trap) {
      var frames = machine.snapshot().selectedFrames().stream()
          .map(frame -> program.function(frame.functionId()).name() + "@" + frame.programCounter())
          .toList();
      throw new AssertionError(
          "Counted closure trapped for physical owner "
              + machine.global("physicalModuleOwner") + " in " + frames,
          trap);
    }
  }
}
