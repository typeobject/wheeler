package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BootstrapManifest;
import com.typeobject.wheeler.packageformat.BootstrapManifest.DiverseDerivation;
import com.typeobject.wheeler.packageformat.BootstrapManifest.OrdinaryDerivation;
import com.typeobject.wheeler.packageformat.BootstrapManifest.Source;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native recovery-manifest validation and identity. */
final class NativeBootstrapManifestIdentityExampleTest {
  private static final Path ROOT = Path.of("../wheeler-conformance/src/main/wheeler/bootstrap");
  private static final String A = "00".repeat(32);
  private static final String B = "11".repeat(32);
  private static final String C = "22".repeat(32);
  private static final String D = "33".repeat(32);
  private static final String E = "44".repeat(32);
  private static final String F = "55".repeat(32);
  private static final String G = "66".repeat(32);
  private static final String H = "77".repeat(32);
  private static final String I = "88".repeat(32);
  private static final String J = "99".repeat(32);
  private static final String K = "aa".repeat(32);
  private static final String L = "bb".repeat(32);
  private static final String M = "cc".repeat(32);
  private static final String N = "dd".repeat(32);

  @Test
  void validatesFixedPointAndDiverseEvidenceBeforePublishing() throws Exception {
    Program program = program();
    byte[] canonical = manifest().canonicalBytes();
    VirtualMachine machine = vm(program, canonical);
    var initial = machine.snapshot();

    machine.run();

    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(canonical),
        machine.hostOutput());
    assertEquals(21, machine.global("identityCount"));
    assertEquals(5, machine.global("semanticChecks"));
    assertEquals(1, machine.global("published"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    String text = new String(canonical, StandardCharsets.UTF_8);
    assertNoIdentity(program, new byte[2_049]);
    assertNoIdentity(program, text.replace("  stage-2: \"" + J, "  stage-2: \"" + L)
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replace("  output: \"" + J, "  output: \"" + L)
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replace("  toolchain: \"" + L, "  toolchain: \"" + F)
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replace("  compiler: \"" + M, "  compiler: \"" + G)
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replace(
        "  archive: \"" + A + "\"\n  manifest: \"" + B + "\"\n",
        "  manifest: \"" + B + "\"\n  archive: \"" + A + "\"\n")
        .getBytes(StandardCharsets.UTF_8));
  }

  private static BootstrapManifest manifest() {
    return new BootstrapManifest(
        new Source(A, B, C, "bootstrap-1", D, E, F, A),
        new OrdinaryDerivation(F, G, H, I, J, J, K),
        new DiverseDerivation(L, M, H, I, J, K),
        N);
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeBootstrapManifestIdentity.w",
            Files.readString(ROOT.resolve("NativeBootstrapManifestIdentity.w")),
            "ManifestAssertions.w",
                CompilerSources.read("compiler/closure/syntax/ManifestAssertions.w"),
            "ManifestProfile.w",
                CompilerSources.read("compiler/closure/syntax/ManifestProfile.w"),
            "ManifestSyntax.w", CompilerSources.read("compiler/closure/ManifestSyntax.w"),
            "ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "wheeler.conformance.bootstrap.manifest_identity");
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
