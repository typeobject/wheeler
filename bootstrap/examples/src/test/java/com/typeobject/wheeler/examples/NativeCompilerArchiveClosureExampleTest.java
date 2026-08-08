package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

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
import java.util.HexFormat;
import java.util.LinkedHashMap;
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

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertArrayEquals(new byte[] {1}, machine.hostOutput());
    assertEquals(manifest.modules().size(), machine.global("moduleCount"));
    assertEquals(
        manifest.modules().stream().mapToLong(module -> module.imports().size()).sum(),
        machine.global("importCount"));
    assertEquals(readU32(archive, 12), machine.global("archiveEntryCount"));
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
    byte[] smallArchive = new PackageArchive().encode(
        new PackageManifestParser().parse("""
            schema: 1
            package:
              name: "demo.archive"
              version: "1.0.0"
              profile: "bootstrap-1"
            targets:
              - kind: "library"
                name: "library"
                root: "src/Main.w"
                test: false
            dependencies: []
            capabilities: []
            """),
        Map.of("src/Main.w", smallSource));
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

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.archive_module_sources"));
    sources.put("ArchiveClosureExample.w", """
        module example.archive_closure;

        import wheeler.compiler.closure.archive_module_sources;
        import wheeler.compiler.closure.archive_sources;
        import wheeler.compiler.closure.module_manifest;

        classical class ArchiveClosureExample {
          private const long MAX_ARCHIVE_BYTES = 16777216;
          private const long MAX_EXTERNALS = 64;
          private const long MAX_IMPORTS = 3072;
          private const long MAX_MANIFEST_BYTES = 262144;
          private const long MAX_MODULES = 512;

          state long moduleCount = 0;
          state long importCount = 0;
          state long archiveEntryCount = 0;
          state long rootEntry = 0;
          state long rootDataStart = 0;
          state long rootDataLength = 0;
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

            region columns = new region(/* bytes= */ 150000, /* allocations= */ 17);
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
                long selectedRootEntry = moduleEntries[plan.rootModule];
                moduleCount = plan.moduleCount;
                importCount = manifestPlan.importCount;
                archiveEntryCount = plan.archiveEntryCount;
                rootEntry = selectedRootEntry;
                rootDataStart = archiveDataStarts[selectedRootEntry];
                rootDataLength = archiveDataLengths[selectedRootEntry];
                published = 1;
                setByte(output, 0, 1);
              }
              case ArchiveSourceIndexResult.Error(long offset) {
                assert(offset < 0);
              }
            }
            drop(expected);
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

  private record EntryRange(String path, int dataStart, int dataLength) {}
}
