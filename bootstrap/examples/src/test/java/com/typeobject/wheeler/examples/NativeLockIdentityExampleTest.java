package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.PackageLockParser;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native dependency-lock identities. */
final class NativeLockIdentityExampleTest {
  private static final Path FIXTURE = Path.of(
      "../wheeler-conformance/src/main/wheeler/packages/identity/NativeLockIdentity.w");
  private static final String A = "a".repeat(64);
  private static final String B = "b".repeat(64);
  private static final String C = "c".repeat(64);
  private static final String D = "d".repeat(64);

  @Test
  void validatesBeforePublishingTheCanonicalLockIdentity() throws Exception {
    Program program = program();
    String canonical = lock(1);
    byte[] input = canonical.getBytes(StandardCharsets.UTF_8);
    VirtualMachine machine = vm(program, input);
    var initial = machine.snapshot();

    machine.run();

    byte[] expected = MessageDigest.getInstance("SHA-256").digest(input);
    assertArrayEquals(expected, machine.hostOutput());
    assertEquals(new PackageLockParser().parse(canonical).identity(), HexFormat.of().formatHex(expected));
    assertEquals(1, machine.global("packageCount"));
    assertEquals(0, machine.global("edgeCount"));
    assertEquals(input.length, machine.global("sourceLength"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    String empty = "schema: 3\nroot: \"" + A + "\"\npackages: []\n";
    VirtualMachine emptyMachine = vm(program, empty.getBytes(StandardCharsets.UTF_8));
    emptyMachine.run();
    assertEquals(
        new PackageLockParser().parse(empty).identity(),
        HexFormat.of().formatHex(emptyMachine.hostOutput()));
    assertEquals(0, emptyMachine.global("packageCount"));

    assertNoIdentity(program, canonical.replace("schema: 3", "schema: 2").getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, lock(2).getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, new byte[2049]);
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeLockIdentity.w", Files.readString(FIXTURE),
            "ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"),
            "Lock.w", PackageSources.read("packages/resolution/Lock.w"),
            "Semver.w", CompilerSources.read("compiler/packages/Semver.w"),
            "Names.w", CompilerSources.read("compiler/packages/Names.w"),
            "ManifestTokens.w", CompilerSources.read("compiler/packages/PackageManifestTokens.w"),
            "Scanner.w", CompilerSources.read("lexer/Scanner.w"),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "wheeler.conformance.packages.lock_identity");
  }

  private static String lock(int count) {
    StringBuilder source = new StringBuilder()
        .append("schema: 3\nroot: \"").append(A).append("\"\npackages:");
    if (count == 0) {
      return source.append(" []\n").toString();
    }
    source.append('\n');
    for (int index = 0; index < count; index++) {
      source.append("  - name: \"demo.p0").append(index).append("\"\n")
          .append("    version: \"1.0.").append(index).append("\"\n")
          .append("    repository: \"").append(A).append("\"\n")
          .append("    snapshot: \"").append(B).append("\"\n")
          .append("    archive: \"").append(C).append("\"\n")
          .append("    manifest: \"").append(D).append("\"\n")
          .append("    dependencies: []\n");
    }
    return source.toString();
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
