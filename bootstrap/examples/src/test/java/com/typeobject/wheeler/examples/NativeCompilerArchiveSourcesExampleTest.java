package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Executable evidence for counted compiler-archive source offsets. */
final class NativeCompilerArchiveSourcesExampleTest {
  @Test
  void indexesThreeValidatedSourcesWithoutCopyingPayloads() throws Exception {
    Program indexer = indexer();
    byte[] archive = archive(Map.of(
        "a.w", new byte[] {11},
        "b/b.w", new byte[] {12, 13},
        "c.w", new byte[] {14, 15, 16}));

    VirtualMachine valid = VirtualMachine.withBinaryInput(indexer, archive, 7);
    valid.run();
    assertArrayEquals(new byte[] {3, 1, 2, 3, 'a', 'b', 'c'}, valid.hostOutput());

    byte[] damaged = archive.clone();
    damaged[damaged.length - 1] ^= 1;
    VirtualMachine invalid = VirtualMachine.withBinaryInput(indexer, damaged, 7);
    invalid.run();
    assertArrayEquals(new byte[7], invalid.hostOutput());

    byte[] damagedEntry = archive.clone();
    int manifestLength = readU32(damagedEntry, 8);
    int firstEntry = 16 + manifestLength;
    int firstPathLength = readU32(damagedEntry, firstEntry);
    int firstData = firstEntry + 12 + firstPathLength + 32;
    damagedEntry[firstData] ^= 1;
    byte[] repairedOuter = MessageDigest.getInstance("SHA-256")
        .digest(java.util.Arrays.copyOf(damagedEntry, damagedEntry.length - 32));
    System.arraycopy(repairedOuter, 0, damagedEntry, damagedEntry.length - 32, 32);
    VirtualMachine invalidEntry = VirtualMachine.withBinaryInput(indexer, damagedEntry, 7);
    invalidEntry.run();
    assertArrayEquals(new byte[7], invalidEntry.hostOutput());
  }

  @Test
  void admitsFiveHundredTwelveEntriesAndRejectsTheNextBeforePublication() throws Exception {
    Program indexer = capacityIndexer();
    VirtualMachine accepted = VirtualMachine.withBinaryInput(indexer, archive(entries(512)), 1);
    CompilerMachineRunner.runWithoutRewindHistory(accepted);
    assertArrayEquals(new byte[] {1}, accepted.hostOutput());

    VirtualMachine rejected = VirtualMachine.withBinaryInput(indexer, archive(entries(513)), 1);
    CompilerMachineRunner.runWithoutRewindHistory(rejected);
    assertArrayEquals(new byte[1], rejected.hostOutput());
  }

  private static Program indexer() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put(
        "ArchiveSources.w",
        CompilerSources.read("compiler/closure/ArchiveSources.w"));
    sources.put("ArchiveIndexExample.w", """
        module example.archive_index;

        import wheeler.compiler.closure.archive_sources;

        classical class ArchiveIndexExample {
          entry void main(borrow byteview source, borrow mut bytes output) {
            region arena = new region(/* bytes= */ 16456, /* allocations= */ 4);
            words pathStarts = allocate(arena, 512);
            words pathLengths = allocate(arena, 512);
            words dataStarts = allocate(arena, 512);
            words dataLengths = allocate(arena, 512);
            set(pathStarts, 0, 77);
            ArchiveSourceIndexResult indexed = indexArchiveSources(
              source,
              pathStarts,
              pathLengths,
              dataStarts,
              dataLengths
            );
            match (indexed) {
              case ArchiveSourceIndexResult.Value(ArchiveSourceIndex index) {
                setByte(output, 0, index.entryCount);
                setByte(output, 1, dataLengths[0]);
                setByte(output, 2, dataLengths[1]);
                setByte(output, 3, dataLengths[2]);
                setByte(output, 4, source[pathStarts[0]]);
                setByte(output, 5, source[pathStarts[1]]);
                setByte(output, 6, source[pathStarts[2]]);
              }
              case ArchiveSourceIndexResult.Error(long offset) {
                assert(pathStarts[0] == 77);
              }
            }
            drop(dataLengths);
            drop(dataStarts);
            drop(pathLengths);
            drop(pathStarts);
            drop(arena);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.archive_index");
  }

  private static Program capacityIndexer() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put(
        "ArchiveSources.w",
        CompilerSources.read("compiler/closure/ArchiveSources.w"));
    sources.put("ArchiveCapacityExample.w", """
        module example.archive_capacity;

        import wheeler.compiler.closure.archive_sources;

        classical class ArchiveCapacityExample {
          entry void main(borrow byteview source, borrow mut bytes output) {
            region arena = new region(/* bytes= */ 16456, /* allocations= */ 4);
            words pathStarts = allocate(arena, 512);
            words pathLengths = allocate(arena, 512);
            words dataStarts = allocate(arena, 512);
            words dataLengths = allocate(arena, 512);
            set(pathStarts, 0, 77);
            ArchiveSourceIndexResult indexed = indexArchiveSources(
              source,
              pathStarts,
              pathLengths,
              dataStarts,
              dataLengths
            );
            match (indexed) {
              case ArchiveSourceIndexResult.Value(ArchiveSourceIndex index) {
                assert(index.entryCount == 512);
                setByte(output, 0, 1);
              }
              case ArchiveSourceIndexResult.Error(long offset) {
                assert(pathStarts[0] == 77);
              }
            }
            drop(dataLengths);
            drop(dataStarts);
            drop(pathLengths);
            drop(pathStarts);
            drop(arena);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.archive_capacity");
  }

  private static Map<String, byte[]> entries(int count) {
    Map<String, byte[]> result = new LinkedHashMap<>();
    for (int index = 0; index < count; index++) {
      result.put("source/%03d.w".formatted(index), new byte[0]);
    }
    return result;
  }

  private static byte[] archive(Map<String, byte[]> entries) throws Exception {
    byte[] manifest = "schema: 1\n".getBytes(StandardCharsets.UTF_8);
    ByteArrayOutputStream payload = new ByteArrayOutputStream();
    payload.write(new byte[] {'W', 'P', 'K', 'G', 0, 0, 0, 1});
    writeU32(payload, manifest.length);
    writeU32(payload, entries.size());
    payload.write(manifest);
    entries.entrySet().stream().sorted(Map.Entry.comparingByKey()).forEach(entry -> {
      try {
        byte[] path = entry.getKey().getBytes(StandardCharsets.US_ASCII);
        byte[] data = entry.getValue();
        writeU32(payload, path.length);
        writeU64(payload, data.length);
        payload.write(path);
        payload.write(MessageDigest.getInstance("SHA-256").digest(data));
        payload.write(data);
      } catch (Exception failure) {
        throw new IllegalStateException(failure);
      }
    });
    byte[] encoded = payload.toByteArray();
    payload.write(MessageDigest.getInstance("SHA-256").digest(encoded));
    return payload.toByteArray();
  }

  private static int readU32(byte[] source, int offset) {
    return (source[offset] & 0xff)
        | (source[offset + 1] & 0xff) << 8
        | (source[offset + 2] & 0xff) << 16
        | (source[offset + 3] & 0xff) << 24;
  }

  private static void writeU32(ByteArrayOutputStream output, int value) {
    output.write(value);
    output.write(value >>> 8);
    output.write(value >>> 16);
    output.write(value >>> 24);
  }

  private static void writeU64(ByteArrayOutputStream output, long value) {
    for (int index = 0; index < 8; index++) {
      output.write((int) (value >>> (index * 8)));
    }
  }
}
