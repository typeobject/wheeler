package com.typeobject.wheeler.runtime;

import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.occupiedResultSlotArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.resultSlotArtifact;
import static com.typeobject.wheeler.runtime.ScalarAotCallArtifacts.wideResultSlotArtifact;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.ElfImage;
import java.time.Duration;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;

/** Native forward and inverse evidence for the scalar AOT leaf. */
final class LinuxX8664ScalarAotReversibleTest extends ScalarAotNativeTest {
  @Test
  void lowersReversibleScalarResultSlots() throws Exception {
    byte[] artifact = resultSlotArtifact();
    var lowered = lower(artifact);

    assertEquals(42, lowered.processStatus());
    IllegalArgumentException occupied = assertThrows(
        IllegalArgumentException.class,
        () -> lower(occupiedResultSlotArtifact()));
    assertEquals("Scalar AOT arithmetic traps", occupied.getMessage());
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "961b66d9f5e73540a95f9425f6403f7697e513eef64c7c2f907a9d678a5db34a",
        identity(artifact));
    assertEquals(
        "a395cc0e14f299865aa6d0b55f57a7584be001a55a25c1fb194426658b71bb38",
        lowered.runtimeIdentity());
    assertEquals(
        "d88799a39344339e1e9210b814fb2a9b6c2154fb19b63c2fcc690a0771413156",
        fixture.capsule().identity());
    assertEquals(
        "3b65ab91ce786ba05aac0aa5c90d503a0570341882726274fdbf8934658c5d86",
        fixture.plan().identity());
    assertEquals(
        "1eb690345b06700c95722565a516b8c0d5e72ba91c09fd8dd07242564a73c6f5",
        verified.prev());
    if (nativeLinuxHost()) {
      Process process = new ProcessBuilder(writeExecutable(image).toString()).start();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(42, process.exitValue());
      assertArrayEquals(
          LinuxX8664EntryShim.successOutput(), process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }
  }

  @Test
  void lowersSixteenArgumentResultSlots() throws Exception {
    byte[] artifact = wideResultSlotArtifact(16);
    var lowered = lower(artifact);

    assertEquals(42, lowered.processStatus());
    assertThrows(
        IllegalArgumentException.class,
        () -> lower(wideResultSlotArtifact(17)));
    Fixture fixture = fixture(artifact, lowered.runtimeText());
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), lowered.runtimeText(), 0);
    ElfImage.verify(image, fixture.plan(), fixture.abi());
    assertEquals(
        "8307662a8e1ed6723fc39266911cc2ca444897e43d35d787eaa6ae32e937ace9",
        identity(artifact));
    assertEquals(
        "31d088538869046de4274c6b3c6e654ac574cd7708b19e981a60a8cc24682ba0",
        lowered.runtimeIdentity());
    if (nativeLinuxHost()) {
      Process process = new ProcessBuilder(writeExecutable(image).toString()).start();
      assertTrue(process.waitFor(Duration.ofSeconds(5).toMillis(), TimeUnit.MILLISECONDS));
      assertEquals(42, process.exitValue());
      assertArrayEquals(
          LinuxX8664EntryShim.successOutput(), process.getInputStream().readAllBytes());
      assertEquals(0, process.getErrorStream().readAllBytes().length);
    }
  }
}
