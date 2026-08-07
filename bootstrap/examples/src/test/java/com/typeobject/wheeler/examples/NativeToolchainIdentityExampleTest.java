package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BootstrapToolchain;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential and rewind tests for Wheeler-native toolchain provenance identities. */
final class NativeToolchainIdentityExampleTest {
  private static final Path ROOT = Path.of("../wheeler-conformance/src/main/wheeler/bootstrap");

  @Test
  void acceptsOnlyCanonicalClosedToolchainProvenance() throws Exception {
    Program program = program();
    BootstrapToolchain.Kind[] kinds = BootstrapToolchain.Kind.values();
    for (int index = 0; index < kinds.length; index++) {
      byte[] canonical = toolchain(kinds[index]).canonicalBytes();
      VirtualMachine machine = vm(program, canonical);
      var initial = machine.snapshot();

      machine.run();

      assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(canonical),
          machine.hostOutput());
      assertEquals(index + 1, machine.global("kindCode"));
      assertEquals(4, machine.global("identityCount"));
      assertEquals(1, machine.global("published"));
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot());
    }

    String canonical = toolchain(BootstrapToolchain.Kind.INDEPENDENT_STAGE0).canonicalText();
    assertNoIdentity(program, new byte[513]);
    assertNoIdentity(program, canonical.replace("independent-stage0", "friendly-stage0")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, canonical.replaceFirst("aa", "AA")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, canonical.substring(0, canonical.length() - 1)
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, canonical.replace(
        "  source: \"" + "aa".repeat(32) + "\"\n"
            + "  builder: \"" + "bb".repeat(32) + "\"\n",
        "  builder: \"" + "bb".repeat(32) + "\"\n"
            + "  source: \"" + "aa".repeat(32) + "\"\n")
        .getBytes(StandardCharsets.UTF_8));
  }

  private static BootstrapToolchain toolchain(BootstrapToolchain.Kind kind) {
    return new BootstrapToolchain(
        kind, "aa".repeat(32), "bb".repeat(32), "cc".repeat(32), "dd".repeat(32));
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeToolchainIdentity.w", Files.readString(ROOT.resolve("NativeToolchainIdentity.w")),
            "BootstrapSyntax.w", Files.readString(ROOT.resolve("BootstrapSyntax.w")),
            "ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "wheeler.conformance.bootstrap.toolchain_identity");
  }

  private static VirtualMachine vm(Program program, byte[] source) {
    return VirtualMachine.withBinaryInput(program, source, 32);
  }

  private static void assertNoIdentity(Program program, byte[] source) {
    VirtualMachine machine = vm(program, source);
    assertThrows(VmTrap.class, machine::run);
    assertArrayEquals(new byte[32], machine.hostOutput());
    assertEquals(0, machine.global("published"));
  }
}
