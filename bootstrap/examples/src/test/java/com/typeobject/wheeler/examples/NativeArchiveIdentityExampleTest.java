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
import java.util.LinkedHashMap;
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
    Map<String, String> modules = new LinkedHashMap<>(
        CompilerSources.moduleClosure("wheeler.compiler.packages.canonical"));
    modules.putAll(CompilerSources.moduleClosure("wheeler.compiler.packages.manifest"));
    modules.put("Archive.w", PackageSources.read("packages/archive/Archive.w"));
    modules.put("Binary.w", CoreSources.read("encoding/Binary.w"));
    modules.put("ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"));
    modules.put("FixedBinary.w", CoreSources.read("encoding/FixedBinary.w"));
    modules.put("NativeArchiveIdentity.w", Files.readString(FIXTURE));
    modules.put("Scanner.w", CompilerSources.read("lexer/Scanner.w"));
    modules.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.packages.archive_identity");
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
