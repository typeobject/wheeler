package com.typeobject.wheeler.runtime;

import static com.typeobject.wheeler.runtime.ScalarAotArtifacts.artifact;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleRoot;
import com.typeobject.wheeler.packageformat.ElfImage;
import com.typeobject.wheeler.packageformat.NativeImagePlan;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;

/** Exact mapped-capsule binding evidence for native scalar startup. */
final class LinuxX8664BoundCapsuleTest extends ScalarAotNativeTest {
  @Test
  void bindsTheCompleteVerifiedCapsuleBeforeExecution() throws Exception {
    byte[] portable = artifact(73);
    ApplicationCapsule capsule = capsule(portable);
    var lowered = LinuxX8664ScalarAotCompiler.lower(portable, capsule);
    Fixture fixture = fixture(portable, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());

    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(artifact(72), capsule));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(
            portable,
            withRoot(capsule, NativeImagePlan.RuntimeMode.AOT, List.of("io:stdout/1"))));
    assertThrows(
        IllegalArgumentException.class,
        () -> LinuxX8664ScalarAotCompiler.lower(
            portable,
            withRoot(capsule, NativeImagePlan.RuntimeMode.EMBEDDED_VM, List.of())));
    assertEquals(
        "c550a0d2a1860a96f566263e67b567d2886e511c30190dd6c83faac0b4041e47",
        lowered.runtimeIdentity());
    assertEquals(
        "c8af845b4cc1722d55e807211f2320fbf83a66a5332537cc57d2171cbf1243f3",
        identity(portable));
    assertEquals(
        "a0f55d2ba640f4038b4b4fb9bd9fb8517cfc4bd0e98c19782a977af1d57ebe0c",
        capsule.identity());
    assertEquals(capsule.identity(), lowered.capsuleIdentity());
    assertEquals(
        "92df2ecf69b0b18bc7dd9abc2da9257e8ed899ef5b31ef8275936eec75d487a8",
        fixture.plan().identity());
    assertEquals(
        "88ed49c3fb6b55424aae6acab92271d813f11ce6189b2cdcd066499e97486e34",
        verified.prev());
    if (nativeLinuxHost()) {
      Launch accepted = launch(image);
      assertEquals(73, accepted.status());
      assertArrayEquals(LinuxX8664EntryShim.successOutput(), accepted.output());
      assertEquals(0, accepted.error().length);

      byte[] changedContent = image.clone();
      changedContent[changedContent.length - 1] ^= 1;
      assertRejected(changedContent);

      byte[] changedLength = image.clone();
      int totalLength = verified.capsuleOffset() + ApplicationCapsule.totalLengthOffset();
      changedLength[totalLength] ^= 1;
      assertRejected(changedLength);
    }
  }

  private static ApplicationCapsule withRoot(
      ApplicationCapsule capsule,
      NativeImagePlan.RuntimeMode mode,
      List<String> capabilities) {
    CapsuleRoot root = capsule.root();
    CapsuleRoot changed = new CapsuleRoot(
        root.packageInstance(),
        root.target(),
        root.rootWbc(),
        root.entryFunction(),
        root.runtimeProfile(),
        root.bytecodeProfile(),
        root.proofProfile(),
        root.targetProfile(),
        root.platformAbi(),
        root.executionLimits(),
        mode,
        capabilities);
    return new ApplicationCapsule(changed, capsule.receipts(), capsule.entries());
  }

  private void assertRejected(byte[] image) throws Exception {
    Launch launch = launch(image);
    assertEquals(LinuxX8664EntryShim.MALFORMED_IMAGE_STATUS, launch.status());
    assertEquals(0, launch.output().length);
    assertEquals(0, launch.error().length);
  }

  private Launch launch(byte[] image) throws Exception {
    Process process = new ProcessBuilder(writeExecutable(image).toString()).start();
    assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
    return new Launch(
        process.exitValue(),
        process.getInputStream().readAllBytes(),
        process.getErrorStream().readAllBytes());
  }

  private record Launch(int status, byte[] output, byte[] error) {
    Launch {
      output = output.clone();
      error = error.clone();
    }
  }
}
