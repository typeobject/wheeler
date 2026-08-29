package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Conformance tests for Wheeler-native canonical package archive inspection. */
class NativeArchiveExampleTest {
  @Test
  void wheelerInspectsOuterAndEntryDigestCheckedArchive() throws Exception {
    Path root = Path.of("../wheeler-conformance/src/main/wheeler/packages");
    Map<String, String> modules = Map.ofEntries(
            Map.entry("Archive.w", PackageSources.read("packages/archive/Archive.w")),
            Map.entry("Binary.w", CoreSources.read("encoding/Binary.w")),
            Map.entry("FixedBinary.w", CoreSources.read("encoding/FixedBinary.w")),
            Map.entry(
                "PackageCanonical.w",
                CompilerSources.read("compiler/packages/PackageCanonical.w")),
            Map.entry("Manifest.w", CompilerSources.read("compiler/packages/PackageManifest.w")),
            Map.entry("ManifestTokens.w", CompilerSources.read("compiler/packages/PackageManifestTokens.w")),
            Map.entry("Names.w", CompilerSources.read("compiler/packages/Names.w")),
            Map.entry("NativeArchive.w", Files.readString(root.resolve("NativeArchive.w"))),
            Map.entry("Paths.w", CompilerSources.read("compiler/packages/Paths.w")),
            Map.entry("Scanner.w", CompilerSources.read("lexer/Scanner.w")),
            Map.entry("Semver.w", CompilerSources.read("compiler/packages/semver/Semver.w")),
            Map.entry("Sha256.w", CoreSources.read("crypto/Sha256.w")));
    Program inspector = new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.packages.archive_main");
    Map<String, String> provenanceModules = new HashMap<>(modules);
    provenanceModules.remove("NativeArchive.w");
    provenanceModules.put(
        "ArchiveProvenance.w",
        PackageSources.read("packages/archive/ArchiveProvenance.w"));
    provenanceModules.put(
        "NativeLockedArchiveProvenance.w",
        Files.readString(root.resolve("NativeLockedArchiveProvenance.w")));
    provenanceModules.put(
        "TestPackageLock.w",
        RuntimeSources.read("runtime/testing/runners/package/TestPackageLock.w"));
    Program provenance = new WheelerCompiler().compileModuleFiles(
        provenanceModules, "wheeler.conformance.packages.locked_archive_provenance");
    Map<String, String> sourceModules = new HashMap<>(provenanceModules);
    sourceModules.remove("NativeLockedArchiveProvenance.w");
    sourceModules.put(
        "NativeLockedArchiveSource.w",
        Files.readString(root.resolve("NativeLockedArchiveSource.w")));
    Program sourceProjection = new WheelerCompiler().compileModuleFiles(
        sourceModules, "wheeler.conformance.packages.locked_archive_source");
    Map<String, String> sourcePlanModules = new HashMap<>(provenanceModules);
    sourcePlanModules.remove("NativeLockedArchiveProvenance.w");
    sourcePlanModules.put(
        "NativeExternalSourcePlan.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/runners/NativeExternalSourcePlan.w")));
    sourcePlanModules.put(
        "TestExternalSourcePlan.w",
        RuntimeSources.read("runtime/testing/runners/TestExternalSourcePlan.w"));
    sourcePlanModules.put(
        "TestSourceModules.w",
        RuntimeSources.read("runtime/testing/runners/TestSourceModules.w"));
    sourcePlanModules.put(
        "TestSourcePlan.w",
        RuntimeSources.read("runtime/testing/runners/TestSourcePlan.w"));
    Program sourcePlanComposer = new WheelerCompiler().compileModuleFiles(
        sourcePlanModules, "wheeler.conformance.testing.runners.native_external_source_plan");
    String manifestText = """
        schema: 1
        package:
          name: "demo.archive"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "deployable"
            name: "main"
            root: "src/Main.w"
            test: false
        dependencies:
          - kind: "normal"
            name: "demo.base"
            version: "=1.0.0"
        capabilities:
          - name: "build.read"
            path: "src/**"
        """;
    var manifest = new PackageManifestParser().parse(manifestText);
    byte[] encoded = new PackageArchive().encode(
        manifest, Map.of("src/Main.w", new byte[] {1, 2, 3, (byte) 255}));
    VirtualMachine machine = VirtualMachine.withBinaryInput(inspector, encoded);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(
        manifest.canonicalText().getBytes(StandardCharsets.UTF_8).length,
        machine.global("manifestLength"));
    assertEquals(1, machine.global("entryCount"));
    assertEquals(10, machine.global("pathLength"));
    assertEquals(4, machine.global("dataLength"));
    assertEquals(12, machine.global("packageLength"));
    assertEquals(1, machine.global("targetCount"));
    assertEquals(encoded.length, machine.global("finalLength"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
    new PackageArchive().decode(encoded);

    String rootIdentity = "1".repeat(64);
    String archiveIdentity = new PackageArchive().identity(encoded);
    String lock = lockedArchive(rootIdentity, manifest.identity(), archiveIdentity);
    byte[] provenanceInput = provenanceInput(
        rootIdentity, lock, manifest.name(), encoded);
    VirtualMachine provenanceMachine = VirtualMachine.withBinaryInput(
        provenance, provenanceInput, /* outputCapacity= */ 1);
    provenanceMachine.run();
    assertEquals(1, provenanceMachine.hostOutput()[0]);
    assertProvenanceRejected(
        provenance,
        provenanceInput(
            rootIdentity,
            lock.replace("demo.base", "demo.basa"),
            manifest.name(),
            encoded));
    assertProvenanceRejected(
        provenance,
        provenanceInput(
            rootIdentity,
            lock.replace("    dependencies:\n      - \"demo.base\"", "    dependencies: []"),
            manifest.name(),
            encoded));
    String extraEdgeLock = lock.replace(
        "      - \"demo.base\"\n  - name: \"demo.base\"",
        "      - \"demo.base\"\n      - \"demo.extra\"\n  - name: \"demo.base\"") + """
          - name: "demo.extra"
            version: "1.0.0"
            repository: "%s"
            snapshot: "%s"
            archive: "%s"
            manifest: "%s"
            dependencies: []
        """.formatted("8".repeat(64), "9".repeat(64), "a".repeat(64), "b".repeat(64));
    assertProvenanceRejected(
        provenance,
        provenanceInput(rootIdentity, extraEdgeLock, manifest.name(), encoded));

    VirtualMachine sourceMachine = VirtualMachine.withBinaryInput(
        sourceProjection,
        sourceInput(rootIdentity, lock, manifest.name(), encoded, /* ordinal= */ 0),
        /* outputCapacity= */ 32);
    sourceMachine.run();
    ByteBuffer projected = ByteBuffer.wrap(sourceMachine.hostOutput()).order(ByteOrder.LITTLE_ENDIAN);
    byte[] projectedPath = new byte[projected.getInt()];
    projected.get(projectedPath);
    byte[] projectedSource = new byte[projected.getInt()];
    projected.get(projectedSource);
    assertEquals("src/Main.w", new String(projectedPath, StandardCharsets.UTF_8));
    assertEquals(ByteBuffer.wrap(new byte[] {1, 2, 3, (byte) 255}), ByteBuffer.wrap(projectedSource));
    assertProvenanceRejected(
        sourceProjection,
        sourceInput(rootIdentity, lock, manifest.name(), encoded, /* ordinal= */ 1));

    byte[] externalSource = "module demo.external;\nclassical class External {}\n"
        .getBytes(StandardCharsets.UTF_8);
    byte[] externalArchive = new PackageArchive().encode(
        manifest, Map.of("src/Main.w", externalSource));
    String externalLock = lockedArchive(
        rootIdentity, manifest.identity(), new PackageArchive().identity(externalArchive));
    byte[] localSource = "module demo.local;\nclassical class Local {}\n"
        .getBytes(StandardCharsets.UTF_8);
    byte[] localPlan = sourcePlan(Map.of("src/Root.w", localSource));
    VirtualMachine planMachine = VirtualMachine.withBinaryInput(
        sourcePlanComposer,
        externalPlanInput(
            rootIdentity,
            externalLock,
            manifest.name(),
            externalArchive,
            /* ordinal= */ 0,
            localPlan),
        /* outputCapacity= */ 32768);
    planMachine.run();
    assertEquals(
        ByteBuffer.wrap(sourcePlan(Map.of(
            "dependencies/demo.archive/src/Main.w", externalSource,
            "src/Root.w", localSource))),
        ByteBuffer.wrap(planMachine.hostOutput()));

    byte[] changedArchive = encoded.clone();
    changedArchive[changedArchive.length - 1] ^= 1;
    assertProvenanceRejected(
        provenance,
        provenanceInput(rootIdentity, lock, manifest.name(), changedArchive));
    assertProvenanceRejected(
        provenance,
        provenanceInput(
            rootIdentity,
            lockedArchive(rootIdentity, manifest.identity(), "0".repeat(64)),
            manifest.name(),
            encoded));
    assertProvenanceRejected(
        provenance,
        provenanceInput(
            rootIdentity,
            lockedArchive(rootIdentity, "0".repeat(64), archiveIdentity),
            manifest.name(),
            encoded));

    String modularManifestText = """
        schema: 1
        package:
          name: "a"
          version: "1.0.0"
          profile: "b"
        targets:
          - kind: "deployable"
            name: "m"
            root: "a"
            module: "a.b"
            sources:
              - "a"
              - "b"
              - "c"
              - "d"
            test: false
        dependencies:
          - kind: "normal"
            name: "b"
            version: "=1.0.0"
        capabilities:
          - name: "read"
            path: "a"
        """;
    byte[] modular = new PackageArchive().encode(
        new PackageManifestParser().parse(modularManifestText),
        Map.of(
            "a", new byte[] {5},
            "b", new byte[] {6},
            "c", new byte[] {7},
            "d", new byte[] {8}));
    VirtualMachine modularMachine = VirtualMachine.withBinaryInput(inspector, modular);
    modularMachine.run();
    assertEquals(4, modularMachine.global("entryCount"));
    assertEquals(1, modularMachine.global("pathLength"));
    assertEquals(1, modularMachine.global("dataLength"));
    assertEquals(1, modularMachine.global("secondPathLength"));
    assertEquals(1, modularMachine.global("secondDataLength"));
    new PackageArchive().decode(modular);
    String oversizedManifestText = modularManifestText.replace(
        "              - \"d\"\n",
        "              - \"d\"\n              - \"e\"\n");
    byte[] oversized = new PackageArchive().encode(
        new PackageManifestParser().parse(oversizedManifestText),
        Map.of(
            "a", new byte[] {5},
            "b", new byte[] {6},
            "c", new byte[] {7},
            "d", new byte[] {8},
            "e", new byte[] {9}));
    assertRejected(inspector, oversized);

    byte[] badOuterDigest = encoded.clone();
    badOuterDigest[badOuterDigest.length - 1] ^= 1;
    assertRejected(inspector, badOuterDigest);
    byte[] badEntryData = encoded.clone();
    badEntryData[dataStart(badEntryData)] ^= 1;
    resignOuter(badEntryData);
    assertRejected(inspector, badEntryData);
    byte[] badPath = encoded.clone();
    int path = pathStart(badPath);
    badPath[path] = '.';
    badPath[path + 1] = '.';
    badPath[path + 2] = '/';
    resignOuter(badPath);
    assertRejected(inspector, badPath);
    byte[] wrongSource = encoded.clone();
    int wrongPath = pathStart(wrongSource);
    byte[] replacement = "src/Else.w".getBytes(java.nio.charset.StandardCharsets.US_ASCII);
    System.arraycopy(replacement, 0, wrongSource, wrongPath, replacement.length);
    resignOuter(wrongSource);
    assertRejected(inspector, wrongSource);
    byte[] noncanonicalManifest = encoded.clone();
    noncanonicalManifest[16] = 'x';
    resignOuter(noncanonicalManifest);
    assertRejected(inspector, noncanonicalManifest);
  }

  private static String lockedArchive(
      String rootIdentity, String manifestIdentity, String archiveIdentity) {
    return ("""
        schema: 3
        root: "%s"
        packages:
          - name: "demo.archive"
            version: "1.0.0"
            repository: "%s"
            snapshot: "%s"
            archive: "%s"
            manifest: "%s"
            dependencies:
              - "demo.base"
          - name: "demo.base"
            version: "1.0.0"
            repository: "%s"
            snapshot: "%s"
            archive: "%s"
            manifest: "%s"
            dependencies: []
        """).formatted(
            rootIdentity,
            "2".repeat(64),
            "3".repeat(64),
            archiveIdentity,
            manifestIdentity,
            "4".repeat(64),
            "5".repeat(64),
            "6".repeat(64),
            "7".repeat(64));
  }

  private static byte[] provenanceInput(
      String rootIdentity, String lock, String packageName, byte[] archive) {
    byte[] lockBytes = lock.getBytes(StandardCharsets.UTF_8);
    byte[] nameBytes = packageName.getBytes(StandardCharsets.UTF_8);
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    output.writeBytes(rootIdentity.getBytes(StandardCharsets.US_ASCII));
    writeLittle32(output, lockBytes.length);
    output.writeBytes(lockBytes);
    output.write(nameBytes.length);
    output.writeBytes(nameBytes);
    writeLittle32(output, archive.length);
    output.writeBytes(archive);
    return output.toByteArray();
  }

  private static byte[] sourceInput(
      String rootIdentity,
      String lock,
      String packageName,
      byte[] archive,
      int ordinal) {
    byte[] provenance = provenanceInput(rootIdentity, lock, packageName, archive);
    byte[] result = java.util.Arrays.copyOf(provenance, provenance.length + 1);
    result[result.length - 1] = (byte) ordinal;
    return result;
  }

  private static byte[] externalPlanInput(
      String rootIdentity,
      String lock,
      String packageName,
      byte[] archive,
      int ordinal,
      byte[] localPlan) {
    byte[] source = sourceInput(rootIdentity, lock, packageName, archive, ordinal);
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    output.writeBytes(source);
    writeLittle32(output, localPlan.length);
    output.writeBytes(localPlan);
    return output.toByteArray();
  }

  private static byte[] sourcePlan(Map<String, byte[]> sources) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    writeBig32(output, sources.size());
    sources.entrySet().stream().sorted(Map.Entry.comparingByKey()).forEach(entry -> {
      byte[] path = entry.getKey().getBytes(StandardCharsets.UTF_8);
      writeBig32(output, path.length);
      output.writeBytes(path);
      writeBig32(output, entry.getValue().length);
      output.writeBytes(entry.getValue());
    });
    return output.toByteArray();
  }

  private static void writeLittle32(ByteArrayOutputStream output, int value) {
    output.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(value).array());
  }

  private static void writeBig32(ByteArrayOutputStream output, int value) {
    output.writeBytes(ByteBuffer.allocate(4).putInt(value).array());
  }

  private static void assertRejected(Program inspector, byte[] archive) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(inspector, archive);
    assertThrows(VmTrap.class, machine::run);
  }

  private static void assertProvenanceRejected(Program provenance, byte[] input) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        provenance, input, /* outputCapacity= */ 1);
    assertThrows(VmTrap.class, machine::run);
  }

  private static int pathStart(byte[] archive) {
    ByteBuffer bytes = ByteBuffer.wrap(archive).order(ByteOrder.LITTLE_ENDIAN);
    return 16 + bytes.getInt(8) + 12;
  }

  private static int dataStart(byte[] archive) {
    ByteBuffer bytes = ByteBuffer.wrap(archive).order(ByteOrder.LITTLE_ENDIAN);
    int path = pathStart(archive);
    return path + bytes.getInt(path - 12) + 32;
  }

  private static void resignOuter(byte[] archive) throws Exception {
    int payloadLength = archive.length - 32;
    byte[] digest = MessageDigest.getInstance("SHA-256")
        .digest(java.util.Arrays.copyOf(archive, payloadLength));
    System.arraycopy(digest, 0, archive, payloadLength, digest.length);
  }
}
