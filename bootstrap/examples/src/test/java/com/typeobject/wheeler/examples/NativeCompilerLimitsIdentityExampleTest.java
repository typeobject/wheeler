package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BootstrapCompilerLimits;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native bootstrap compiler-limit identities. */
final class NativeCompilerLimitsIdentityExampleTest {
  private static final Path ROOT = Path.of("../wheeler-conformance/src/main/wheeler/bootstrap");

  @Test
  void validatesEveryCanonicalLimitBeforePublishingItsIdentity() throws Exception {
    Program program = program();
    BootstrapCompilerLimits limits = new BootstrapCompilerLimits(
        16_777_216, 100_000, 256, 10_000, 10_000,
        1_000_000, 1_000, 268_435_456, 1_024, 10_000_000);
    byte[] canonical = limits.canonicalBytes();
    VirtualMachine machine = vm(program, canonical);
    var initial = machine.snapshot();

    machine.run();

    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(canonical), machine.hostOutput());
    assertEquals(10, machine.global("limitCount"));
    assertEquals(1, machine.global("published"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    String text = new String(canonical, StandardCharsets.UTF_8);
    assertNoIdentity(program, new byte[513]);
    assertNoIdentity(program, text.replace("tokens: 100000", "tokens: 0")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replace("tokens: 100000", "tokens: 0100000")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replace("tokens: 100000", "tokens: 1073741825")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replace("limits:\n", "limits: \n")
        .getBytes(StandardCharsets.UTF_8));
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeCompilerLimitsIdentity.w",
            Files.readString(ROOT.resolve("NativeCompilerLimitsIdentity.w")),
            "ManifestSyntax.w", CompilerSources.read("compiler/closure/ManifestSyntax.w"),
            "ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "wheeler.conformance.bootstrap.compiler_limits_identity");
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
