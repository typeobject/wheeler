package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.proof.ProofRule;
import com.typeobject.wheeler.core.vm.BufferKind;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Complete-buffer evidence for semantic verification before container publication. */
final class NativeCompilerCanonicalPublicationExampleTest {
  private static final int CAPACITY = 8192;

  @Test
  void rejectsInvalidCodeWithoutPublishingAnyContainerByte() throws Exception {
    byte[] artifact = artifact();
    artifact[sectionStart(artifact, 5)] = (byte) 255;
    assertThrows(BytecodeException.class, () -> new BytecodeReader().read(artifact));
    reject(artifact, CAPACITY, "", false);
  }

  @Test
  void rejectsInvalidEntryAndLocalTypesWithoutPublishingAnyContainerByte() throws Exception {
    byte[] entry = artifact();
    words(entry).putInt(sectionStart(entry, 0) + 4, 99);
    byte[] types = artifact();
    int functions = sectionStart(types, 4);
    int firstType = functions + 4 + words(types).getInt(functions) * 40;
    words(types).putInt(firstType, 0);
    for (byte[] invalid : List.of(entry, types)) {
      assertThrows(BytecodeException.class, () -> new BytecodeReader().read(invalid));
      reject(invalid, CAPACITY, "", false);
    }
  }

  @Test
  void rejectsAnInvalidProofAfterOtherwiseValidNominalAndReversibleSections() throws Exception {
    byte[] artifact = NativeCompilerProductLinkedArtifactExampleTest.artifact();
    assertEquals(10, words(artifact).getInt(40 + 6 * 32));
    words(artifact).putInt(sectionStart(artifact, 6) + 16, 99);
    assertThrows(BytecodeException.class, () -> new BytecodeReader().read(artifact));
    reject(artifact, CAPACITY, "", false);
  }

  @Test
  void rejectsRetainedStepClaimsThatDoNotHoldForTheFinalCodeOrManifest() throws Exception {
    byte[] original = NativeCompilerProductLinkedArtifactExampleTest.artifact();
    Program program = new BytecodeReader().read(original);
    var stepProof = program.proofCertificates().stream()
        .filter(proof -> proof.rule() == ProofRule.STATIC_STEP_BOUND).findFirst().orElseThrow();
    long actual = program.function(stepProof.subjectId()).forward().size();
    for (long bound : new long[] {actual - 1, program.maxSteps() + 1}) {
      byte[] artifact = original.clone();
      int descriptor = sectionStart(artifact, 6) + Integer.BYTES + stepProof.id() * 6 * Integer.BYTES;
      words(artifact).putLong(descriptor + 4 * Integer.BYTES, bound);
      assertThrows(BytecodeException.class, () -> new BytecodeReader().read(artifact));
      reject(artifact, CAPACITY, "", false);
    }
  }

  @Test
  void checksAllDirectoryWindowsAndCapacityBeforeAllocatingArtifactStorage() throws Exception {
    byte[] artifact = artifact();
    for (String change : List.of(
        "set(starts, 5, -1);",
        "set(starts, 5, 9223372036854775807);",
        "set(lengths, 5, -1);",
        "set(lengths, 5, 9223372036854775807);",
        "set(types, 5, 5);",
        "set(lengths, 0, 23);",
        "sectionBytes = -1;",
        "sectionBytes = 9223372036854775807;",
        "sectionCount = 5;",
        "sectionCount = 11;",
        "sectionCount = 9223372036854775807;")) {
      reject(artifact, CAPACITY, change, true);
    }
    reject(artifact, artifact.length - 1, "", true);
    reject(artifact, 1, "", true);
  }

  @Test
  void publishesExactArtifactsPreservesTheUnusedTailAndRewinds() throws Exception {
    for (byte[] artifact : List.of(
        artifact(), NativeCompilerProductLinkedArtifactExampleTest.artifact())) {
      for (int capacity : new int[] {artifact.length, CAPACITY}) {
        VirtualMachine machine = machine(artifact, capacity, "");
        MachineSnapshot initial = machine.snapshot();
        while (machine.global("prepared") == 0) {
          machine.step();
        }
        List<BufferValue> directory = directory(machine.snapshot());
        while (machine.global("published") == 0) {
          machine.step();
        }
        byte[] expected = pattern(capacity);
        System.arraycopy(artifact, 0, expected, 0, artifact.length);
        assertArrayEquals(expected, machine.hostOutput());
        assertEquals(directory, directory(machine.snapshot()));
        assertEquals(artifact.length, machine.global("length"));
        assertStaging(machine.snapshot(), artifact.length, true);
        machine.run();
        assertArrayEquals(artifact, machine.hostOutput());
        Program executable = new BytecodeReader().read(machine.hostOutput());
        VirtualMachine execution = new VirtualMachine(executable);
        MachineSnapshot entry = execution.snapshot();
        execution.run();
        rewind(execution, entry);
        rewind(machine, initial);
      }
    }
  }

  private static void reject(byte[] artifact, int capacity, String change, boolean preflight)
      throws Exception {
    VirtualMachine machine = machine(artifact, capacity, change);
    MachineSnapshot initial = machine.snapshot();
    while (machine.global("prepared") == 0) {
      machine.step();
    }
    MachineSnapshot prepared = machine.snapshot();
    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals(-1, machine.global("length"));
    assertArrayEquals(pattern(capacity), machine.hostOutput());
    assertEquals(directory(prepared), directory(machine.snapshot()));
    if (preflight) {
      assertEquals(prepared.regions(), machine.snapshot().regions());
      assertEquals(prepared.buffers(), machine.snapshot().buffers());
    } else {
      assertStaging(machine.snapshot(), artifact.length, false);
    }
    rewind(machine, initial);
  }

  private static void assertStaging(MachineSnapshot snapshot, int length, boolean dropped) {
    var region = snapshot.regions().stream()
        .filter(r -> r.maxBytes() == 16_777_216 && r.maxObjects() == 1)
        .findFirst().orElseThrow();
    assertEquals(dropped, region.dropped());
    assertEquals(dropped ? 0 : length, region.usedBytes());
    List<BufferValue> buffers = snapshot.buffers().stream()
        .filter(b -> b.regionId() == region.id()).toList();
    assertEquals(1, buffers.size());
    assertEquals(BufferKind.BYTES, buffers.getFirst().kind());
    assertEquals(length, buffers.getFirst().length());
    assertEquals(dropped, buffers.getFirst().dropped());
  }

  private static List<BufferValue> directory(MachineSnapshot snapshot) {
    int region = snapshot.regions().stream()
        .filter(r -> r.maxBytes() == 1536 && r.maxObjects() == 3)
        .findFirst().orElseThrow().id();
    return snapshot.buffers().stream()
        .filter(b -> b.kind() == BufferKind.WORDS && b.regionId() == region).toList();
  }

  private static void rewind(VirtualMachine machine, MachineSnapshot initial) {
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  private static byte[] pattern(int capacity) {
    byte[] expected = new byte[capacity];
    for (int i = 0; i < capacity; i++) {
      expected[i] = (byte) ((i * 17 + 23) % 251);
    }
    return expected;
  }

  private static ByteBuffer words(byte[] artifact) {
    return ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
  }

  private static int sectionStart(byte[] artifact, int section) {
    return Math.toIntExact(words(artifact).getLong(40 + section * 32 + 8));
  }

  private static byte[] artifact() {
    return new BytecodeWriter().write(new WheelerCompiler().compile("""
        classical class Publication {
          state long observed = -9;
          entry void main() { observed = 7; }
        }
        """));
  }

  private static VirtualMachine machine(byte[] artifact, int capacity, String change)
      throws Exception {
    var sources = new LinkedHashMap<String, String>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.canonical_product_emitter"));
    sources.put("CanonicalPublication.w", """
        module example.canonical_publication;

        import wheeler.compiler.closure.canonical_product_emitter;
        import wheeler.core.encoding.binary;

        classical class CanonicalPublication {
          state long prepared = 0;
          state long published = 0;
          state long length = -1;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region directory = new region(/* bytes= */ 1536, /* allocations= */ 3);
            words types = allocate(directory, 64);
            words starts = allocate(directory, 64);
            words lengths = allocate(directory, 64);
            set(types, 63, 17);
            set(starts, 63, 19);
            set(lengths, 63, 23);
            long sectionCount = readUnsigned(source, 24, 4);
            long sectionBytes = bufferLength(source);
            long section = 0;
            while (section < sectionCount) limit 10 {
              long row = 40 + section * 32;
              set(types, section, readUnsigned(source, row, 4));
              set(starts, section, readUnsigned(source, row + 8, 8));
              set(lengths, section, readUnsigned(source, row + 16, 8));
              section += 1;
            }
            long outputByte = 0;
            while (outputByte < bufferLength(output)) limit 8192 {
              setByte(output, outputByte, (outputByte * 17 + 23) %% 251);
              outputByte += 1;
            }
            %s
            CanonicalProductSections sections = new CanonicalProductSections(
              sectionBytes, sectionCount
            );
            prepared = 1;
            long artifactBytes = publishCanonicalProductContainer(
              source, sections, types, starts, lengths, output
            );
            length = artifactBytes;
            published = 1;
            setOutputLength(output, artifactBytes);
            drop(lengths);
            drop(starts);
            drop(types);
            drop(directory);
          }
        }
        """.formatted(change));
    Program program = new WheelerCompiler().compileModuleFiles(
        sources, "example.canonical_publication");
    return VirtualMachine.withBinaryInput(program, artifact, capacity);
  }
}
