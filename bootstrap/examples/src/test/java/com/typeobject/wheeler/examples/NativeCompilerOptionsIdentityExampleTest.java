package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BootstrapCompilerOptions;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native bootstrap compiler-option identities. */
final class NativeCompilerOptionsIdentityExampleTest {
  private static final Path ROOT = Path.of("../wheeler-conformance/src/main/wheeler/bootstrap");

  @Test
  void validatesCanonicalOptionsBeforePublishingTheirIdentity() throws Exception {
    Program program = program();
    BootstrapCompilerOptions options = new BootstrapCompilerOptions("bootstrap-1", false);
    byte[] canonical = options.canonicalBytes();
    VirtualMachine machine = vm(program, canonical);
    var initial = machine.snapshot();

    machine.run();

    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(canonical), machine.hostOutput());
    assertEquals("bootstrap-1".length(), machine.global("profileLength"));
    assertEquals(0, machine.global("sourceMaps"));
    assertEquals(1, machine.global("published"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    BootstrapCompilerOptions mapped = new BootstrapCompilerOptions("native.test_2", true);
    VirtualMachine mappedMachine = vm(program, mapped.canonicalBytes());
    mappedMachine.run();
    assertArrayEquals(
        MessageDigest.getInstance("SHA-256").digest(mapped.canonicalBytes()),
        mappedMachine.hostOutput());
    assertEquals(1, mappedMachine.global("sourceMaps"));

    assertNoIdentity(program, new byte[257]);
    String canonicalText = new String(canonical, StandardCharsets.UTF_8);
    assertNoIdentity(program, canonicalText
        .replace("bootstrap-1", "-bootstrap")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, canonicalText
        .replace("source-maps: false", "source-maps: perhaps")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, canonicalText
        .replace("compiler:\n", "compiler: \n")
        .getBytes(StandardCharsets.UTF_8));
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeCompilerOptionsIdentity.w",
            Files.readString(ROOT.resolve("NativeCompilerOptionsIdentity.w")),
            "ManifestAssertions.w",
                CompilerSources.read("compiler/closure/syntax/ManifestAssertions.w"),
            "ManifestProfile.w",
                CompilerSources.read("compiler/closure/syntax/ManifestProfile.w"),
            "ManifestSyntax.w", CompilerSources.read("compiler/closure/ManifestSyntax.w"),
            "ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "wheeler.conformance.bootstrap.compiler_options_identity");
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
