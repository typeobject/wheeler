package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BootstrapFeatureManifest;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native bootstrap feature-manifest identities. */
final class NativeBootstrapFeaturesIdentityExampleTest {
  private static final Path ROOT = Path.of("src/main/wheeler/native/bootstrap");

  @Test
  void requiresTheCompleteClosedVocabularyBeforePublishing() throws Exception {
    Program program = program();
    byte[] canonical = BootstrapFeatureManifest.bootstrap1().canonicalBytes();
    VirtualMachine machine = vm(program, canonical);
    var initial = machine.snapshot();

    machine.run();

    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(canonical), machine.hostOutput());
    assertEquals(17, machine.global("featureCount"));
    assertEquals(canonical.length, machine.global("manifestLength"));
    assertEquals(1, machine.global("published"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    String text = new String(canonical, StandardCharsets.UTF_8);
    assertNoIdentity(program, new byte[2_049]);
    assertNoIdentity(program, text.replace("affine-borrows", "affine-borrowz")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replaceFirst("version: 1", "version: 2")
        .getBytes(StandardCharsets.UTF_8));
    assertNoIdentity(program, text.replace("  - name: \"word-buffers\"\n    version: 1\n", "")
        .getBytes(StandardCharsets.UTF_8));
  }

  private static Program program() throws Exception {
    return new WheelerCompiler().compileModuleFiles(
        Map.of(
            "NativeBootstrapFeaturesIdentity.w",
            Files.readString(ROOT.resolve("NativeBootstrapFeaturesIdentity.w")),
            "BootstrapSyntax.w", Files.readString(ROOT.resolve("BootstrapSyntax.w")),
            "ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"),
            "Sha256.w", CoreSources.read("crypto/Sha256.w")),
        "examples.bootstrap.features_identity");
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
