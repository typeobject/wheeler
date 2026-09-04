package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
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
import java.util.LinkedHashMap;
import java.util.Map;
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
        2_976_452_002L,
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
        "b1690da2b44c4580bf783671cda6cd8d190d3c089663dfb8bc9a4600125c94a8",
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
  }

  @Tag("closure-evidence")
  @Test
  void rejectsMalformedBoundedFunctionClosureTransports() throws Exception {
    byte[] validTransport = smallTransport(false);
    Program functionClosure = NativeCompilerPhysicalFunctionClosureProgram.program(1, 0);
    VirtualMachine valid = VirtualMachine.withBinaryInput(
        functionClosure, validTransport, 1_048_576);
    CompilerMachineRunner.runWithoutRewindHistory(valid);
    assertEquals(1, valid.global("published"));
    assertEquals(0, valid.global("validatedRelocationCount"));

    byte[] malformedFooter = validTransport.clone();
    malformedFooter[malformedFooter.length - 8] = 0;
    assertMalformedTransport(functionClosure, malformedFooter);
    assertMalformedTransport(functionClosure, smallTransport(true));
  }

  private static byte[] smallTransport(boolean malformedRelocation) throws Exception {
    String dependency = """
        //! Supplies one imported scalar helper.

        module example.physical_dependency;

        classical class PhysicalDependency {
          public long dependency(long value) {
            return value;
          }
        }
        """;
    String caller = """
        //! Calls one imported scalar helper.

        module example.physical_caller;

        import example.physical_dependency;

        classical class PhysicalCaller {
          public long caller(long value) {
            return dependency(value);
          }
        }
        """;
    Map<String, String> callerSources = new LinkedHashMap<>();
    callerSources.put("Caller.w", caller);
    callerSources.put("Dependency.w", dependency);
    WheelerCompiler compiler = new WheelerCompiler();
    Program callerProgram = compiler.compileLibraryModuleFiles(
        callerSources, "example.physical_caller");
    byte[] callerArtifact = new BytecodeWriter().write(callerProgram);
    int retainedFunctions = 3;
    int relocationInstruction = -1;
    int instruction = 0;
    for (var function : callerProgram.functions().subList(0, retainedFunctions)) {
      for (var candidate : function.forward()) {
        if (candidate.opcode() == Opcode.CALL_VALUE) {
          relocationInstruction = instruction;
        }
        instruction += 1;
      }
    }
    assertTrue(0 <= relocationInstruction);

    ByteArrayOutputStream output = new ByteArrayOutputStream();
    output.writeBytes(callerArtifact);
    writeProductMetadata(output, 0, callerArtifact.length, retainedFunctions);
    if (malformedRelocation) {
      output.write(0);
      writeU16(output, relocationInstruction);
      writeU16(output, 0);
      output.write(0);
    }
    output.writeBytes(new byte[] {87, 80, 70, 1});
    writeU16(output, 1);
    writeU16(output, malformedRelocation ? 1 : 0);
    return output.toByteArray();
  }

  private static void writeProductMetadata(
      ByteArrayOutputStream output, int owner, int length, int functions) {
    writeU16(output, owner);
    output.write((length >>> 16) & 0xff);
    output.write((length >>> 8) & 0xff);
    output.write(length & 0xff);
    output.write(functions);
  }

  private static void writeU16(ByteArrayOutputStream output, int value) {
    output.write((value >>> 8) & 0xff);
    output.write(value & 0xff);
  }

  private static void assertMalformedTransport(Program program, byte[] transport) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program, transport, 1_048_576);
    assertThrows(
        VmTrap.class,
        () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
    assertEquals(0, machine.global("linkedCodeLength"));
    assertEquals(0, machine.global("linkedIdentityPrefix"));
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
    assertTrue(128 < modules.size());
    assertTrue(modules.size() <= 256);
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
