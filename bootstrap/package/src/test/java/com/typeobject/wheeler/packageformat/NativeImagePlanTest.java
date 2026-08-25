package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import org.junit.jupiter.api.Test;

/** Native image build-input identity evidence. */
final class NativeImagePlanTest {
  @Test
  void bindsEverySemanticAndToolchainInput() throws Exception {
    NativeImagePlan plan = plan("00", NativeImagePlan.RuntimeMode.EMBEDDED_VM, true, true);

    assertEquals("""
        schema: 1
        native-image:
          format: "elf"
          target: "aarch64-unknown-linux-gnu"
          runtime-mode: "embedded-vm"
          sealed: true
          stripped: true
          portable-artifact: "0000000000000000000000000000000000000000000000000000000000000000"
          platform-abi: "1111111111111111111111111111111111111111111111111111111111111111"
          capsule: "2222222222222222222222222222222222222222222222222222222222222222"
          backend: "3333333333333333333333333333333333333333333333333333333333333333"
          runtime: "4444444444444444444444444444444444444444444444444444444444444444"
          compiler: "5555555555555555555555555555555555555555555555555555555555555555"
          sysroot: "6666666666666666666666666666666666666666666666666666666666666666"
          providers: "7777777777777777777777777777777777777777777777777777777777777777"
          options: "8888888888888888888888888888888888888888888888888888888888888888"
          link-arguments: "9999999999999999999999999999999999999999999999999999999999999999"
        """, plan.canonicalText());
    assertEquals(
        HexFormat.of().formatHex(
            MessageDigest.getInstance("SHA-256").digest(plan.canonicalBytes())),
        plan.identity());
    assertEquals(
        "4e944b6b0ce56e164f22bb079e867eb951b6f60de8b676d2216431d2d35603e9",
        plan.identity());
    assertEquals(plan, NativeImagePlan.parse(plan.canonicalBytes()));
  }

  @Test
  void targetModePolicyAndPortableArtifactChangeThePlan() {
    NativeImagePlan baseline = plan("00", NativeImagePlan.RuntimeMode.EMBEDDED_VM, true, true);
    NativeImagePlan artifact = plan("aa", NativeImagePlan.RuntimeMode.EMBEDDED_VM, true, true);
    NativeImagePlan aot = plan("00", NativeImagePlan.RuntimeMode.AOT, true, true);
    NativeImagePlan unsealed = plan("00", NativeImagePlan.RuntimeMode.EMBEDDED_VM, false, true);
    NativeImagePlan unstripped = plan("00", NativeImagePlan.RuntimeMode.EMBEDDED_VM, true, false);

    assertNotEquals(baseline.identity(), artifact.identity());
    assertNotEquals(baseline.identity(), aot.identity());
    assertNotEquals(baseline.identity(), unsealed.identity());
    assertNotEquals(baseline.identity(), unstripped.identity());
  }

  @Test
  void rejectsUnboundAndNoncanonicalInputs() {
    assertThrows(
        PackageFormatException.class,
        () -> plan("GG", NativeImagePlan.RuntimeMode.EMBEDDED_VM, true, true));
    NativeImagePlan valid = plan("00", NativeImagePlan.RuntimeMode.EMBEDDED_VM, true, true);
    assertThrows(
        PackageFormatException.class,
        () -> new NativeImagePlan(
            valid.format(),
            "AArch64-linux",
            valid.runtimeMode(),
            valid.sealed(),
            valid.stripped(),
            valid.portableArtifact(),
            valid.platformAbi(),
            valid.capsule(),
            valid.backend(),
            valid.runtime(),
            valid.compiler(),
            valid.sysroot(),
            valid.providers(),
            valid.options(),
            valid.linkArguments()));
    assertThrows(
        PackageFormatException.class,
        () -> NativeImagePlan.parse(valid.canonicalText()
            .replace("runtime-mode: \"embedded-vm\"", "runtime-mode: \"jit\"")
            .getBytes(StandardCharsets.UTF_8)));
    assertThrows(
        PackageFormatException.class,
        () -> NativeImagePlan.parse((valid.canonicalText() + "# trailing\n")
            .getBytes(StandardCharsets.UTF_8)));
    assertThrows(
        PackageFormatException.class,
        () -> NativeImagePlan.parse(new byte[] {(byte) 0xc3, 0x28}));
  }

  private static NativeImagePlan plan(
      String artifactByte,
      NativeImagePlan.RuntimeMode mode,
      boolean sealed,
      boolean stripped) {
    return new NativeImagePlan(
        PlatformAbi.Format.ELF,
        "aarch64-unknown-linux-gnu",
        mode,
        sealed,
        stripped,
        artifactByte.repeat(32),
        "11".repeat(32),
        "22".repeat(32),
        "33".repeat(32),
        "44".repeat(32),
        "55".repeat(32),
        "66".repeat(32),
        "77".repeat(32),
        "88".repeat(32),
        "99".repeat(32));
  }
}
