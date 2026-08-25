package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Canonical PE32+ header, section, locator, permission, and PREV evidence. */
final class PeImageTest {
  private static final byte[] RUNTIME = {
      (byte) 0xb8, 0x2a, 0, 0, 0,
      (byte) 0xc3
  };

  @Test
  void buildsOneReadOnlyCapsuleImage() {
    Fixture fixture = fixture("x86_64", RUNTIME);
    byte[] first = PeImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME, 0);
    byte[] second = PeImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME.clone(), 0);
    PeImage.VerifiedImage verified = PeImage.verify(first, fixture.plan(), fixture.abi());
    ByteBuffer image = ByteBuffer.wrap(first).order(ByteOrder.LITTLE_ENDIAN);

    assertArrayEquals(first, second);
    assertEquals(0x5a4d, Short.toUnsignedInt(image.getShort(0)));
    assertEquals(128, image.getInt(60));
    assertEquals(0x0000_4550, image.getInt(128));
    assertEquals(0x8664, Short.toUnsignedInt(image.getShort(132)));
    assertEquals(2, Short.toUnsignedInt(image.getShort(134)));
    assertEquals(4192, image.getInt(168));
    assertEquals(0x6000_0020, image.getInt(428));
    assertEquals(0x4000_0040, image.getInt(468));
    assertEquals(2048, first.length);
    assertEquals(1024, verified.capsuleOffset());
    assertEquals(fixture.plan().identity(), verified.planIdentity());
    assertEquals(fixture.capsule().identity(), verified.capsule().identity());
    assertArrayEquals(RUNTIME, verified.runtimeText());
    assertEquals(0, verified.runtimeEntryOffset());
    assertEquals(
        "6957c713e33f7d273b0b39e39d2e3136128468f2c6f6efefafd5adcdc2befca7",
        verified.prev());

    byte[] returnedRuntime = verified.runtimeText();
    returnedRuntime[0] ^= 1;
    assertArrayEquals(RUNTIME, verified.runtimeText());
  }

  @Test
  void emitsTheExplicitArm64MachineProfile() {
    byte[] runtime = {0x00, 0x00, (byte) 0x80, (byte) 0xd2};
    Fixture fixture = fixture("aarch64", runtime);
    byte[] image = PeImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), runtime, 0);

    assertEquals(0xaa64, Short.toUnsignedInt(
        ByteBuffer.wrap(image).order(ByteOrder.LITTLE_ENDIAN).getShort(132)));
    assertArrayEquals(runtime,
        PeImage.verify(image, fixture.plan(), fixture.abi()).runtimeText());
  }

  @Test
  void rejectsHeaderSectionLocatorRuntimePaddingAndCapsuleDamage() {
    Fixture fixture = fixture("x86_64", RUNTIME);
    byte[] canonical = PeImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME, 0);

    assertRejected(damaged(canonical, 0), fixture);
    assertRejected(damaged(canonical, 136), fixture);
    assertRejected(damaged(canonical, 428), fixture);
    assertRejected(damaged(canonical, 468), fixture);
    assertRejected(damaged(canonical, 512), fixture);
    assertRejected(damaged(canonical, 608), fixture);
    assertRejected(damaged(canonical, 800), fixture);
    assertRejected(damaged(canonical, 1024), fixture);
    assertRejected(damaged(canonical, canonical.length - 1), fixture);
  }

  @Test
  void rejectsPlanAbiArtifactAndEntryDisagreementBeforeOutput() {
    Fixture fixture = fixture("x86_64", RUNTIME);
    NativeImagePlan wrongRuntime = plan(
        fixture.abi(), fixture.capsule(), hash(99), fixture.rootWbcIdentity(), true);
    NativeImagePlan unstripped = plan(
        fixture.abi(), fixture.capsule(), identity(RUNTIME), fixture.rootWbcIdentity(), false);
    NativeImagePlan wrongArtifact = plan(
        fixture.abi(), fixture.capsule(), identity(RUNTIME), hash(98), true);
    PlatformAbi wrongFormat = abi(PlatformAbi.Format.ELF, "x86_64", "linux-gnu");

    assertThrows(PackageFormatException.class,
        () -> PeImage.build(wrongRuntime, fixture.abi(), fixture.capsule(), RUNTIME, 0));
    assertThrows(PackageFormatException.class,
        () -> PeImage.build(unstripped, fixture.abi(), fixture.capsule(), RUNTIME, 0));
    assertThrows(PackageFormatException.class,
        () -> PeImage.build(wrongArtifact, fixture.abi(), fixture.capsule(), RUNTIME, 0));
    assertThrows(PackageFormatException.class,
        () -> PeImage.build(fixture.plan(), wrongFormat, fixture.capsule(), RUNTIME, 0));
    assertThrows(PackageFormatException.class,
        () -> PeImage.build(fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME, 6));
    assertThrows(PackageFormatException.class,
        () -> PeImage.build(fixture.plan(), fixture.abi(), fixture.capsule(), new byte[0], 0));
  }

  private static void assertRejected(byte[] image, Fixture fixture) {
    assertThrows(PackageFormatException.class,
        () -> PeImage.verify(image, fixture.plan(), fixture.abi()));
  }

  private static byte[] damaged(byte[] source, int offset) {
    byte[] result = source.clone();
    result[offset] ^= 1;
    return result;
  }

  private static Fixture fixture(String architecture, byte[] runtime) {
    PlatformAbi abi = abi(PlatformAbi.Format.PE_COFF, architecture, "windows-msvc");
    CapsuleEntry wbc = new CapsuleEntry(
        CapsuleEntry.Kind.WBC,
        "bin/app.wbc",
        8,
        CapsuleEntry.REQUIRED | CapsuleEntry.STARTUP,
        new byte[] {'W', 'B', 'C', 1});
    CapsuleRoot root = new CapsuleRoot(
        hash(1),
        "app",
        wbc.name(),
        "example.app::main",
        hash(2),
        hash(3),
        hash(4),
        hash(5),
        abi.identity(),
        hash(7),
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        List.of());
    CapsulePackageReceipt receipt = new CapsulePackageReceipt(
        hash(8),
        "wheeler.app@1.0.0",
        hash(9),
        "release",
        hash(10),
        hash(11),
        "app",
        hash(1));
    ApplicationCapsule capsule =
        new ApplicationCapsule(root, List.of(receipt), List.of(wbc));
    NativeImagePlan plan = plan(
        abi, capsule, identity(runtime), wbc.identity(), true);
    return new Fixture(abi, capsule, plan, wbc.identity());
  }

  private static NativeImagePlan plan(
      PlatformAbi abi,
      ApplicationCapsule capsule,
      String runtime,
      String artifact,
      boolean stripped) {
    return new NativeImagePlan(
        PlatformAbi.Format.PE_COFF,
        abi.architecture() + "-pc-windows-msvc",
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        true,
        stripped,
        artifact,
        abi.identity(),
        capsule.identity(),
        hash(12),
        runtime,
        hash(13),
        hash(14),
        hash(15),
        hash(16),
        hash(17));
  }

  private static PlatformAbi abi(
      PlatformAbi.Format format,
      String architecture,
      String osAbi) {
    return new PlatformAbi(
        format,
        architecture,
        osAbi,
        64,
        PlatformAbi.Endianness.LITTLE,
        4096,
        16,
        256,
        1024 * 1024,
        4096,
        1024,
        64L * 1024 * 1024,
        List.of("baseline"),
        List.of("kernel32"),
        requiredServices());
  }

  private static List<PlatformAbi.Service> requiredServices() {
    return List.of(
        PlatformAbi.Service.CAPABILITY_FILE_OPEN,
        PlatformAbi.Service.DIRECTORY_MANIFEST,
        PlatformAbi.Service.FILE_ATOMIC_REPLACE,
        PlatformAbi.Service.FILE_READ_AT,
        PlatformAbi.Service.MEMORY_PROTECT,
        PlatformAbi.Service.MEMORY_RELEASE,
        PlatformAbi.Service.MEMORY_RESERVE,
        PlatformAbi.Service.PROCESS_ARGUMENTS,
        PlatformAbi.Service.PROCESS_EXIT,
        PlatformAbi.Service.STDERR_WRITE,
        PlatformAbi.Service.STDIN_READ,
        PlatformAbi.Service.STDOUT_WRITE);
  }

  private static String hash(int value) {
    return "%064x".formatted(value);
  }

  private static String identity(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException(exception);
    }
  }

  private record Fixture(
      PlatformAbi abi,
      ApplicationCapsule capsule,
      NativeImagePlan plan,
      String rootWbcIdentity) {}
}
