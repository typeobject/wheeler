package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Conformance tests for Wheeler-native canonical package archive inspection. */
class NativeArchiveExampleTest {
  @Test
  void wheelerInspectsOuterAndEntryDigestCheckedArchive() throws Exception {
    Path root = Path.of("src/main/wheeler");
    Program inspector = new WheelerCompiler().compileModuleFiles(
        Map.ofEntries(
            Map.entry("Archive.w", PackageSources.read("packages/Archive.w")),
            Map.entry("Binary.w", CompilerSources.read("packages/Binary.w")),
            Map.entry("LineEmitter.w", PackageSources.read("packages/LineEmitter.w")),
            Map.entry("Manifest.w", PackageSources.read("packages/Manifest.w")),
            Map.entry("ManifestTokens.w", PackageSources.read("packages/ManifestTokens.w")),
            Map.entry("Names.w", PackageSources.read("packages/Names.w")),
            Map.entry("NativeArchive.w", Files.readString(root.resolve("NativeArchive.w"))),
            Map.entry("Paths.w", PackageSources.read("packages/Paths.w")),
            Map.entry("Scanner.w", CompilerSources.read("lexer/Scanner.w")),
            Map.entry("Semver.w", PackageSources.read("packages/Semver.w")),
            Map.entry("Sha256.w", PackageSources.read("crypto/Sha256.w"))),
        "examples.packages.archive_main");
    String manifestText =
        "package \"demo.archive\" version \"1.0.0\" profile \"bootstrap-1\";\n"
            + "target deployable \"main\" root \"src/Main.w\";\n";
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

    String modularManifestText =
        "package \"a\" version \"1.0.0\" profile \"b\";\n"
            + "target deployable \"m\" root \"a\" module \"a.b\" "
            + "source \"a\" source \"b\";\n";
    byte[] modular = new PackageArchive().encode(
        new PackageManifestParser().parse(modularManifestText),
        Map.of("a", new byte[] {5}, "b", new byte[] {6}));
    VirtualMachine modularMachine = VirtualMachine.withBinaryInput(inspector, modular);
    modularMachine.run();
    assertEquals(2, modularMachine.global("entryCount"));
    assertEquals(1, modularMachine.global("pathLength"));
    assertEquals(1, modularMachine.global("dataLength"));
    assertEquals(1, modularMachine.global("secondPathLength"));
    assertEquals(1, modularMachine.global("secondDataLength"));
    new PackageArchive().decode(modular);

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
    noncanonicalManifest[16 + 7] = '\n';
    resignOuter(noncanonicalManifest);
    assertRejected(inspector, noncanonicalManifest);
  }

  private static void assertRejected(Program inspector, byte[] archive) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(inspector, archive);
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
