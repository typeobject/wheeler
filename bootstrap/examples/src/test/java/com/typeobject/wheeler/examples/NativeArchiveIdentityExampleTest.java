package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native canonical package-archive identities. */
final class NativeArchiveIdentityExampleTest {
  private static final Path FIXTURE = Path.of(
      "../wheeler-conformance/src/main/wheeler/packages/identity/NativeArchiveIdentity.w");

  @Test
  void validatesBeforePublishingTheCanonicalArchiveIdentity() throws Exception {
    Program program = program();
    var manifest = new PackageManifestParser().parse("""
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
        """);
    PackageArchive codec = new PackageArchive();
    byte[] archive = codec.encode(manifest, Map.of("src/Main.w", new byte[] {1, 2, 3}));
    VirtualMachine machine = vm(program, archive);
    var initial = machine.snapshot();

    machine.run();

    byte[] expected = MessageDigest.getInstance("SHA-256").digest(archive);
    assertArrayEquals(expected, machine.hostOutput());
    assertEquals(codec.identity(archive), HexFormat.of().formatHex(expected));
    assertEquals(manifest.canonicalText().getBytes(StandardCharsets.UTF_8).length,
        machine.global("manifestLength"));
    assertEquals(1, machine.global("entryCount"));
    assertEquals(archive.length, machine.global("sourceLength"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    byte[] damaged = archive.clone();
    damaged[damaged.length - 1] ^= 1;
    assertNoIdentity(program, damaged);
    assertNoIdentity(program, new byte[4097]);
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.ofEntries(
            Map.entry("NativeArchiveIdentity.w", Files.readString(FIXTURE)),
            Map.entry("Archive.w", PackageSources.read("packages/archive/Archive.w")),
            Map.entry("Binary.w", CoreSources.read("encoding/Binary.w")),
            Map.entry("ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w")),
            Map.entry("FixedBinary.w", CoreSources.read("encoding/FixedBinary.w")),
            Map.entry(
                "PackageCanonical.w",
                CompilerSources.read("compiler/packages/PackageCanonical.w")),
            Map.entry("Manifest.w", CompilerSources.read("compiler/packages/PackageManifest.w")),
            Map.entry("ManifestTokens.w", CompilerSources.read("compiler/packages/PackageManifestTokens.w")),
            Map.entry("Names.w", CompilerSources.read("compiler/packages/Names.w")),
            Map.entry("Paths.w", CompilerSources.read("compiler/packages/Paths.w")),
            Map.entry("Scanner.w", CompilerSources.read("lexer/Scanner.w")),
            Map.entry("Semver.w", CompilerSources.read("compiler/packages/Semver.w")),
            Map.entry("Sha256.w", CoreSources.read("crypto/Sha256.w"))),
        "wheeler.conformance.packages.archive_identity");
  }

  private static VirtualMachine vm(Program program, byte[] source) {
    return VirtualMachine.withBinaryInput(program, source, 32);
  }

  private static void assertNoIdentity(Program program, byte[] source) {
    VirtualMachine machine = vm(program, source);
    assertThrows(VmTrap.class, machine::run);
    assertArrayEquals(new byte[32], machine.hostOutput());
  }
}
