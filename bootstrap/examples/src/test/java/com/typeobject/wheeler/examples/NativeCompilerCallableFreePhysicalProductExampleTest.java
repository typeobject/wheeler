package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.NativeCompilerArchiveClosureProgram.PhysicalModule;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/** Compares every callable-free owner in the rooted compiler target, not just its first authority. */
final class NativeCompilerCallableFreePhysicalProductExampleTest {
  private record Reference(PhysicalModule module, int owner, byte[] artifact) {}

  @Tag("closure-evidence")
  @Test
  void compilesEveryCallableFreeCompilerTargetOwnerByteForByte() throws Exception {
    var manifest = CompilerSources.bootstrapModuleManifest();
    assertEquals("wheeler.compiler.main", manifest.root());
    List<Reference> references = references(manifest);
    assertEquals(21, references.size(), "complete current compiler-target callable-free inventory");
    byte[] expected = transport(references);
    var selected = references.stream().map(Reference::module).toList();
    var productProgram = NativeCompilerArchiveClosureProgram.program(true, selected, List.of());
    byte[] archive = CompilerSources.packageArchive();
    byte[] input = framed(archive, manifest.canonicalBytes());
    int outputCapacity = expected.length + 17;
    VirtualMachine machine = VirtualMachine.withBinaryInput(productProgram, input, outputCapacity);
    var initial = machine.snapshot();
    assertEquals(2, initial.buffers().size());

    // The full archive pass is history-free. Each emitted entry is rewound separately below.
    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertEquals(references.size(), machine.global("physicalModuleProductCount"));
    assertEquals(references.size(), machine.global("physicalModuleProductFunctions"));
    assertEquals(0, machine.global("physicalCallableProductCount"));
    assertEquals(0, machine.global("physicalCallableRelocationCount"));
    assertEquals(0, machine.historySize());
    assertArrayEquals(expected, machine.hostOutput());
    var after = machine.snapshot();
    assertEquals(initial.buffers().getFirst(), after.buffers().getFirst());
    var output = after.buffers().get(1);
    assertEquals(outputCapacity, output.length());
    byte[] completeOutput = new byte[outputCapacity];
    for (int index = 0; index < outputCapacity; index++) {
      completeOutput[index] = output.elements().get(index).byteValue();
    }
    assertArrayEquals(Arrays.copyOf(expected, outputCapacity), completeOutput);

    int start = 0;
    for (Reference reference : references) {
      byte[] actual = Arrays.copyOfRange(machine.hostOutput(),
          start, start + reference.artifact().length);
      runEntryAndRewind(new BytecodeReader().read(actual));
      start += actual.length;
    }
    assertEquals(start, machine.global("physicalModuleProductLength"));
  }

  private static List<Reference> references(BootstrapModuleManifest manifest) throws Exception {
    // Derive absence from the complete compiler target, not the hand-selected product list.
    Program complete = CompilerSources.minimalCompilerProgram();
    List<Reference> references = new ArrayList<>();
    for (int owner = 0; owner < manifest.modules().size(); owner++) {
      var module = manifest.modules().get(owner);
      boolean callable = complete.functions().stream()
          .anyMatch(function -> function.name().startsWith(module.name() + "::"));
      if (callable) { continue; }
      var oracle = new WheelerCompiler().compileLibraryModuleFiles(
          CompilerSources.moduleClosure(module.name()), module.name());
      assertEquals(1, oracle.functions().size(), module.name());
      // These physical owners are constant authorities, not nominal descriptor evidence.
      assertTrue(module.imports().isEmpty(), module.name());
      assertTrue(oracle.globals().isEmpty(), module.name());
      assertTrue(oracle.recordTypes().isEmpty(), module.name());
      assertTrue(oracle.variantTypes().isEmpty(), module.name());
      assertTrue(oracle.arrayTypes().isEmpty(), module.name());
      assertTrue(oracle.sliceTypes().isEmpty(), module.name());
      String path = module.source().substring("src/main/wheeler/".length());
      references.add(new Reference(new PhysicalModule(path, module.name()), owner,
          new BytecodeWriter().write(oracle)));
    }
    return List.copyOf(references);
  }

  private static byte[] transport(List<Reference> references) {
    ByteArrayOutputStream bytes = new ByteArrayOutputStream();
    references.forEach(reference -> bytes.writeBytes(reference.artifact()));
    for (int row = 0; row < references.size(); row++) {
      Reference reference = references.get(row);
      bytes.write(reference.owner() >>> 8);
      bytes.write(reference.owner());
      int length = reference.artifact().length;
      bytes.write(length >>> 16);
      bytes.write(length >>> 8);
      bytes.write(length);
      // The retained closure keeps only the final synthetic library entry.
      bytes.write(row + 1 == references.size() ? 1 : 0);
    }
    bytes.writeBytes(ByteBuffer.allocate(8).putInt(0x57504601)
        .putShort((short) references.size()).putShort((short) 0).array());
    return bytes.toByteArray();
  }

  private static void runEntryAndRewind(Program program) {
    VirtualMachine machine = new VirtualMachine(program);
    var initial = machine.snapshot();
    machine.run();
    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(1, machine.historySize());
    machine.rewindOne();
    assertEquals(initial, machine.snapshot());
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
