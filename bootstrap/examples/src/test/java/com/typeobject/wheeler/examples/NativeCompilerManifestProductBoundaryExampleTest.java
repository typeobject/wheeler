package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Closed manifest coordinates, complete word encoding, and prepublication rejection. */
final class NativeCompilerManifestProductBoundaryExampleTest {
  private static final int CAPACITY = 80;
  private static final int ROW_BYTES = 150_000;
  private static final int CONFIG_BYTES = 19 * Long.BYTES;
  private static final long WORD_LIMIT = 1L << 32;

  @Test
  void bindsSourceCoordinatesAndPreservesEveryOtherWord() throws Exception {
    long[] config = defaults();
    accept(config, null, new long[] {11, 22, 4_000_000, 0, 4_000_000, 0}, CAPACITY);
    config[1] = -1;
    config[11] = 4096;
    config[12] = 0;
    accept(config, null, new long[] {11, -1, 4_000_000, 0, 4_000_000, 0}, CAPACITY);
    config = defaults();
    config[0] = 16_383;
    config[1] = 0;
    config[7] = 511;
    config[8] = 0;
    config[9] = 16_384;
    config[10] = 16_384;
    config[11] = 4095;
    config[12] = 1;
    config[13] = 16_383;
    config[14] = 0;
    config[18] = 16_383;
    accept(config, null, new long[] {16_383, 4095, 4_000_000, 0, 4_000_000, 0}, 24);
  }

  @Test
  void encodesBothStepWordsWithoutClaimingSemanticAcceptance() throws Exception {
    for (int kind = 0; kind < 3; kind++) {
      long[] config = defaults();
      config[0] = 16_383;
      config[1] = kind == 0 ? -1 : 4095;
      config[2] = WORD_LIMIT - 1;
      config[3] = kind;
      config[4] = WORD_LIMIT - 1;
      config[5] = WORD_LIMIT - 1;
      config[6] = 1;
      accept(config, null, Arrays.copyOf(config, 6), CAPACITY);
    }
  }

  @Test
  void rejectsEveryMalformedWordBeforeChangingAnyCallerByte() throws Exception {
    for (long[] change : new long[][] {
        {0, -1}, {0, 16_384}, {0, Long.MAX_VALUE},
        {1, -2}, {1, 4096}, {1, Long.MAX_VALUE},
        {2, -1}, {2, WORD_LIMIT}, {2, Long.MAX_VALUE},
        {3, -1}, {3, 3}, {3, Long.MAX_VALUE},
        {4, -1}, {4, WORD_LIMIT}, {4, Long.MAX_VALUE},
        {5, -1}, {5, WORD_LIMIT}, {5, Long.MAX_VALUE}}) {
      long[] config = changed(change);
      config[6] = 1;
      reject(config, null, CAPACITY);
    }
  }

  @Test
  void rejectsIncompleteBindingWindowsAndNoncanonicalColumns() throws Exception {
    for (long[] change : new long[][] {
        {0, 4}, {1, 3}, {7, -1}, {7, 512}, {7, Long.MAX_VALUE},
        {8, -1}, {8, 65}, {8, Long.MAX_VALUE},
        {9, -1}, {9, 60}, {9, Long.MAX_VALUE},
        {10, -1}, {10, 16_385}, {10, Long.MAX_VALUE},
        {11, -1}, {11, 4094}, {11, 4097}, {11, Long.MAX_VALUE},
        {12, -1}, {12, 4077}, {12, Long.MAX_VALUE},
        {13, -1}, {13, 64}, {13, Long.MAX_VALUE},
        {14, -1}, {14, 57}, {14, Long.MAX_VALUE},
        {15, 16_383}, {15, 16_385}, {16, 511}, {16, 513}, {17, 511}, {17, 513}}) {
      reject(changed(change), null, CAPACITY);
    }
    long[] config = defaults();
    config[14] = 0;
    reject(config, null, 23);
    config[6] = 1;
    reject(config, null, 23);
  }

  @Test
  void retainsCompiledFactsAfterDroppingTheirArtifactStorage() throws Exception {
    for (byte[] artifact : List.of(artifact(),
        NativeCompilerProductLinkedArtifactExampleTest.artifact())) {
      long[] config = defaults();
      config[6] = 2;
      int start = manifestStart(artifact);
      long[] expected = new long[6];
      for (int word = 0; word < expected.length; word++) {
        expected[word] = Integer.toUnsignedLong(words(artifact).getInt(start + word * 4));
      }
      accept(config, artifact, expected, CAPACITY);
    }
  }

  @Test
  void retainsAbsentEntryAndUnsignedWordsWithoutSemanticAcceptance() throws Exception {
    byte[] artifact = artifact();
    long[] fields = {0, -1, WORD_LIMIT - 1, 2, WORD_LIMIT - 1, WORD_LIMIT - 1};
    int start = manifestStart(artifact);
    for (int word = 0; word < fields.length; word++) {
      words(artifact).putInt(start + word * 4, (int) fields[word]);
    }
    assertThrows(BytecodeException.class, () -> new BytecodeReader().read(artifact));
    long[] config = defaults();
    config[6] = 2;
    accept(config, artifact, fields, CAPACITY);
  }

  @Test
  void rejectsMalformedCompiledWindowsWithoutPublishing() throws Exception {
    byte[] original = artifact();
    for (int mutation = 0; mutation < 7; mutation++) {
      byte[] artifact = original.clone();
      switch (mutation) {
        case 0 -> artifact[0] = 0;
        case 1 -> words(artifact).putLong(16, Long.MAX_VALUE);
        case 2 -> words(artifact).putInt(24, 64);
        case 3 -> words(artifact).putLong(56, 23);
        case 4 -> words(artifact).putLong(48, Long.MAX_VALUE - 7);
        case 5 -> words(artifact).putInt(manifestStart(artifact), 16_384);
        case 6 -> words(artifact).putInt(manifestStart(artifact) + 4, 4096);
        default -> throw new AssertionError(mutation);
      }
      long[] config = defaults();
      config[6] = 2;
      reject(config, artifact, CAPACITY);
    }
  }

  private static void accept(long[] config, byte[] artifact, long[] manifest, int capacity)
      throws Exception {
    VirtualMachine machine = machine(config, artifact, capacity);
    MachineSnapshot initial = machine.snapshot();
    prepare(machine);
    MachineSnapshot prepared = machine.snapshot();
    while (machine.global("published") == 0) {
      machine.step();
    }
    byte[] expected = pattern(capacity);
    int start = Math.toIntExact(config[14]);
    for (int word = 0; word < manifest.length; word++) {
      words(expected).putInt(start + word * 4, (int) manifest[word]);
    }
    assertArrayEquals(expected, machine.hostOutput());
    assertEquals(24, machine.global("length"));
    assertEquals(tables(prepared), tables(machine.snapshot()));
    if (artifact != null) {
      assertEquals(1, machine.global("captured"));
      var storage = machine.snapshot().regions().stream()
          .filter(r -> r.maxBytes() == 32_768).findFirst().orElseThrow();
      assertEquals(true, storage.dropped());
      assertEquals(0, storage.usedBytes());
    } else {
      assertEquals(prepared.regions(), machine.snapshot().regions());
    }
    machine.run();
    rewind(machine, initial);
  }

  private static void reject(long[] config, byte[] artifact, int capacity) throws Exception {
    VirtualMachine machine = machine(config, artifact, capacity);
    MachineSnapshot initial = machine.snapshot();
    prepare(machine);
    MachineSnapshot prepared = machine.snapshot();
    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals(-1, machine.global("length"));
    assertArrayEquals(pattern(capacity), machine.hostOutput());
    assertEquals(tables(prepared), tables(machine.snapshot()));
    if (artifact == null) {
      assertEquals(prepared.regions(), machine.snapshot().regions());
      assertEquals(prepared.buffers(), machine.snapshot().buffers());
    }
    rewind(machine, initial);
  }

  private static void prepare(VirtualMachine machine) {
    while (machine.global("prepared") == 0) {
      machine.step();
    }
  }

  private static List<BufferValue> tables(MachineSnapshot snapshot) {
    int region = snapshot.regions().stream().filter(r -> r.maxBytes() == ROW_BYTES)
        .findFirst().orElseThrow().id();
    return snapshot.buffers().stream().filter(b -> b.regionId() == region).toList();
  }

  private static void rewind(VirtualMachine machine, MachineSnapshot initial) {
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  private static long[] defaults() {
    return new long[] {
        3, 2, 4_000_000, 0, 4_000_000, 0, 0,
        7, 5, 4, 64, 20, 3, 11, 13, 16_384, 512, 512, 8};
  }

  private static long[] changed(long[] change) {
    long[] config = defaults();
    config[Math.toIntExact(change[0])] = change[1];
    return config;
  }

  private static byte[] pattern(int capacity) {
    byte[] bytes = new byte[capacity];
    for (int index = 0; index < capacity; index++) {
      bytes[index] = (byte) ((index * 17 + 23) % 251);
    }
    return bytes;
  }

  private static ByteBuffer words(byte[] bytes) {
    return ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN);
  }

  private static int manifestStart(byte[] artifact) {
    assertEquals(1, words(artifact).getInt(40));
    return Math.toIntExact(words(artifact).getLong(48));
  }

  private static byte[] artifact() {
    return new BytecodeWriter().write(new WheelerCompiler().compile("""
        classical class Capture {
          entry void main() {}
        }
        """));
  }

  private static VirtualMachine machine(long[] config, byte[] artifact, int capacity)
      throws Exception {
    byte[] input = new byte[CONFIG_BYTES + (artifact == null ? 0 : artifact.length)];
    for (int index = 0; index < config.length; index++) {
      words(input).putLong(index * Long.BYTES, config[index]);
    }
    if (artifact != null) {
      System.arraycopy(artifact, 0, input, CONFIG_BYTES, artifact.length);
    }
    return VirtualMachine.withBinaryInput(program(), input, capacity);
  }

  private static Program program() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_manifest_section"));
    CoreSources.addBinaryClosure(sources);
    sources.put("ManifestProduct.w", """
        module example.manifest_product;

        import wheeler.compiler.closure.linked_manifest_section;
        import wheeler.core.encoding.binary;

        classical class ManifestProduct {
          state long prepared = 0;
          state long captured = 0;
          state long published = 0;
          state long length = -1;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 150000, /* allocations= */ 3);
            words finalStrings = allocate(rows, readSigned(source, 120));
            words firstFunctions = allocate(rows, readSigned(source, 128));
            words functionCounts = allocate(rows, readSigned(source, 136));
            set(finalStrings, 0, 17);
            set(finalStrings, bufferLength(finalStrings) - 1, 19);
            set(firstFunctions, 0, 23);
            set(firstFunctions, bufferLength(firstFunctions) - 1, 29);
            set(functionCounts, 0, 31);
            set(functionCounts, bufferLength(functionCounts) - 1, 37);
            long root = readSigned(source, 56);
            if (-1 < root) {
              if (root < bufferLength(firstFunctions)) {
                set(firstFunctions, root, readSigned(source, 88));
              }
              if (root < bufferLength(functionCounts)) {
                set(functionCounts, root, readSigned(source, 96));
              }
            }
            set(finalStrings, readSigned(source, 144), readSigned(source, 104));
            long index = 0;
            while (index < bufferLength(output)) limit 80 {
              setByte(output, index, (index * 17 + 23) % 251);
              index += 1;
            }
            ModuleManifestProduct manifest = new ModuleManifestProduct(
              readSigned(source, 0), readSigned(source, 8), readSigned(source, 16),
              readSigned(source, 24), readSigned(source, 32), readSigned(source, 40)
            );
            prepared = 1;
            long mode = readSigned(source, 48);
            if (mode == 2) {
              long artifactBytes = bufferLength(source) - 152;
              region storage = new region(/* bytes= */ 32768, /* allocations= */ 1);
              bytes artifact = allocateBytes(storage, artifactBytes);
              index = 0;
              while (index < artifactBytes) limit 32768 {
                setByte(artifact, index, source[152 + index]);
                index += 1;
              }
              manifest = readCompiledModuleManifest(artifact, artifactBytes);
              drop(artifact);
              drop(storage);
              captured = 1;
            }
            if (mode == 0) {
              length = emitLinkedManifestSection(
                manifest, root, readSigned(source, 64), readSigned(source, 72),
                readSigned(source, 80), finalStrings, firstFunctions, functionCounts,
                output, readSigned(source, 112)
              );
            } else {
              length = writeModuleManifestProduct(manifest, output, readSigned(source, 112));
            }
            published = 1;
            drop(functionCounts);
            drop(firstFunctions);
            drop(finalStrings);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.manifest_product");
  }
}
