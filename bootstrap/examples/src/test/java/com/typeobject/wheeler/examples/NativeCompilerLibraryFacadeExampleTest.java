package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.SourceModuleInspection;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** The physical facade owns an empty local artifact, not its imported compiler closure. */
final class NativeCompilerLibraryFacadeExampleTest {
  @Test
  void compilesTheUnmodifiedPhysicalFacadeAndRewindsPublication() throws Exception {
    String source = CompilerSources.read("CompilerLibrary.w");
    var header = SourceModuleInspection.inspect(source.getBytes(StandardCharsets.UTF_8));
    assertEquals(NativeLibraryFacadeFixture.MODULE, header.name());
    assertEquals(List.of("wheeler.compiler.codec", "wheeler.compiler.codegen",
        "wheeler.compiler.driver", "wheeler.compiler.parser", "wheeler.compiler.string_table",
        "wheeler.compiler.verifier"), header.imports());
    var referenceSources = new LinkedHashMap<>(
        CompilerSources.moduleClosure(NativeLibraryFacadeFixture.MODULE));
    CoreSources.addBinaryClosure(referenceSources);
    referenceSources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    Program reference = new WheelerCompiler().compileLibraryModuleFiles(
        referenceSources, NativeLibraryFacadeFixture.MODULE);
    assertTrue(reference.functions().size() > 1, "the facade is not the linked library");
    assertFalse(reference.functions().stream().anyMatch(function ->
        function.name().startsWith(NativeLibraryFacadeFixture.MODULE + "::")),
        "the physical facade must still own zero authored callables");
    FunctionBody entry = reference.functions().get(reference.entryFunctionId());
    assertEquals("$library", entry.name());
    FunctionBody localEntry = new FunctionBody(0, entry.name(), entry.coherent(),
        entry.parameterCount(), entry.localTypes(), entry.resultType(), entry.implicitResultSlot(),
        entry.forward(), entry.inverse());
    Program expected = new Program(reference.name(), 0, List.of(), List.of(localEntry));
    assertEquals(NativeLibraryFacadeFixture.CLASS, expected.name());
    byte[] artifact = new BytecodeWriter().write(expected);
    byte[] digest = MessageDigest.getInstance("SHA-256").digest(artifact);
    VirtualMachine machine = NativeLibraryFacadeFixture.prepare(
        NativeLibraryFacadeFixture.ARTIFACT_BYTES, NativeLibraryFacadeFixture.IDENTITY_BYTES, false);
    var prepared = machine.snapshot();
    assertEquals(0, machine.historySize());
    while (machine.global("published") == 0) {
      machine.step();
    }
    assertEquals(artifact.length, machine.global("artifactLength"));
    assertEquals(1, machine.global("functionCount"));
    assertEquals(0, machine.global("maxLocalCount"));
    assertEquals(0, machine.global("relocationCount"));
    var published = machine.snapshot();
    List<BufferValue> caller = prepared.buffers();
    int artifactIndex = caller.size() - 2;
    int identityIndex = caller.size() - 1;
    for (int index = 0; index < caller.size(); index++) {
      BufferValue before = caller.get(index);
      BufferValue after = find(published.buffers(), before.id());
      if (index == artifactIndex) {
        assertBytes(before, after, artifact, NativeLibraryFacadeFixture.SENTINEL);
      } else if (index == identityIndex) {
        assertBytes(before, after, digest, NativeLibraryFacadeFixture.SENTINEL);
      } else {
        assertEquals(before, after, "caller buffer " + before.id());
      }
    }
    machine.run();
    assertEquals(MachineStatus.HALTED, machine.status());
    byte[] transport = Arrays.copyOf(artifact, artifact.length + digest.length);
    System.arraycopy(digest, 0, transport, artifact.length, digest.length);
    assertArrayEquals(transport, machine.hostOutput());
    assertBytes(prepared.buffers().get(1), machine.snapshot().buffers().get(1), transport, 0);
    var completed = machine.snapshot();
    assertEquals(2L, completed.buffers().stream().filter(buffer -> !buffer.dropped()).count());
    rewind(machine);
    assertEquals(prepared, machine.snapshot(), "compilation, publication, and cleanup rewind");
    machine.run();
    assertArrayEquals(transport, machine.hostOutput());
    assertEquals(completed, machine.snapshot(), "publication replay");
    rewind(machine);
    assertEquals(prepared, machine.snapshot());

    Program emitted = new BytecodeReader().read(Arrays.copyOf(transport, artifact.length));
    assertTrue(emitted.globals().isEmpty());
    assertTrue(emitted.recordTypes().isEmpty());
    assertTrue(emitted.variantTypes().isEmpty());
    assertTrue(emitted.arrayTypes().isEmpty());
    assertTrue(emitted.sliceTypes().isEmpty());
    assertEquals(1, emitted.functions().size());
    VirtualMachine executable = new VirtualMachine(emitted);
    var initial = executable.snapshot();
    executable.run();
    assertEquals(MachineStatus.HALTED, executable.status());
    rewind(executable);
    assertEquals(initial, executable.snapshot());
  }

  @Test
  void rejectsWrongPublicationExtentsAndOutsideNamesWithoutChangingCallerStorage()
      throws Exception {
    int artifactBytes = NativeLibraryFacadeFixture.ARTIFACT_BYTES;
    int identityBytes = NativeLibraryFacadeFixture.IDENTITY_BYTES;
    for (int[] extents : new int[][] {
        {artifactBytes - 1, identityBytes}, {artifactBytes + 1, identityBytes},
        {artifactBytes, identityBytes - 1}, {artifactBytes, identityBytes + 1}
    }) {
      rejects(extents[0], extents[1], false);
    }
    rejects(artifactBytes, identityBytes, true);
  }

  private static void rejects(int artifactBytes, int identityBytes, boolean outsideName)
      throws Exception {
    VirtualMachine machine = NativeLibraryFacadeFixture.prepare(
        artifactBytes, identityBytes, outsideName);
    var before = machine.snapshot();
    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals(0, machine.global("artifactLength"));
    assertEquals(0, machine.global("functionCount"));
    assertEquals(0, machine.global("maxLocalCount"));
    assertEquals(0, machine.global("relocationCount"));
    for (BufferValue buffer : before.buffers()) {
      assertEquals(buffer, find(machine.snapshot().buffers(), buffer.id()));
    }
    assertArrayEquals(new byte[NativeLibraryFacadeFixture.ARTIFACT_BYTES
        + NativeLibraryFacadeFixture.IDENTITY_BYTES], machine.hostOutput());
    rewind(machine);
    assertEquals(before, machine.snapshot());
  }

  private static BufferValue find(List<BufferValue> buffers, int id) {
    return buffers.stream().filter(buffer -> buffer.id() == id).findFirst().orElseThrow();
  }

  private static void assertBytes(BufferValue before, BufferValue after, byte[] prefix, int tail) {
    assertEquals(before.id(), after.id());
    assertEquals(before.length(), after.length());
    assertFalse(after.dropped());
    byte[] expected = new byte[before.length()];
    Arrays.fill(expected, (byte) tail);
    System.arraycopy(prefix, 0, expected, 0, prefix.length);
    byte[] actual = new byte[after.length()];
    for (int index = 0; index < actual.length; index++) {
      actual[index] = after.elements().get(index).byteValue();
    }
    assertArrayEquals(expected, actual, "buffer " + before.id());
  }

  private static void rewind(VirtualMachine machine) {
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
  }
}
