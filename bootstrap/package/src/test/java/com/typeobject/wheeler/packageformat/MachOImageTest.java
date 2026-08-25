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

/** Canonical arm64 Mach-O segment, entry-state, locator, and PREV evidence. */
final class MachOImageTest {
  private static final byte[] RUNTIME = {
      0x00, 0x00, (byte) 0x80, (byte) 0xd2,
      0x01, 0x00, 0x00, (byte) 0xd4
  };

  @Test
  void buildsOneStaticReadOnlyCapsuleImage() {
    Fixture fixture = fixture();
    byte[] first = MachOImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME, 0);
    byte[] second = MachOImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME.clone(), 0);
    MachOImage.VerifiedImage verified =
        MachOImage.verify(first, fixture.plan(), fixture.abi());
    ByteBuffer image = ByteBuffer.wrap(first).order(ByteOrder.LITTLE_ENDIAN);

    assertArrayEquals(first, second);
    assertEquals(0xfeed_facf, image.getInt(0));
    assertEquals(0x0100_000c, image.getInt(4));
    assertEquals(2, image.getInt(12));
    assertEquals(5, image.getInt(16));
    assertEquals(528, image.getInt(20));
    assertEquals(5, image.getInt(164));
    assertEquals(1, image.getInt(236));
    assertEquals(0x1_0000_0290L, image.getLong(520));
    assertEquals(4652, first.length);
    assertEquals(4096, verified.capsuleOffset());
    assertEquals(fixture.plan().identity(), verified.planIdentity());
    assertEquals(fixture.capsule().identity(), verified.capsule().identity());
    assertArrayEquals(RUNTIME, verified.runtimeText());
    assertEquals(0, verified.runtimeEntryOffset());
    assertEquals(
        "d337a798bb86fce36afc69828a95affc454a884db7f156cdd33050858b50400d",
        verified.prev());

    byte[] returnedRuntime = verified.runtimeText();
    returnedRuntime[0] ^= 1;
    assertArrayEquals(RUNTIME, verified.runtimeText());
  }

  @Test
  void rejectsHeaderCommandsLocatorRuntimePaddingAndCapsuleDamage() {
    Fixture fixture = fixture();
    byte[] canonical = MachOImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME, 0);
    byte[] header = damaged(canonical, 0);
    byte[] textPermission = damaged(canonical, 164);
    byte[] capsulePermission = damaged(canonical, 236);
    byte[] entry = damaged(canonical, 520);
    byte[] locator = damaged(canonical, 560);
    byte[] runtime = damaged(canonical, 656);
    byte[] padding = damaged(canonical, 1000);
    byte[] capsule = damaged(canonical, canonical.length - 1);

    assertRejected(header, fixture);
    assertRejected(textPermission, fixture);
    assertRejected(capsulePermission, fixture);
    assertRejected(entry, fixture);
    assertRejected(locator, fixture);
    assertRejected(runtime, fixture);
    assertRejected(padding, fixture);
    assertRejected(capsule, fixture);
  }

  @Test
  void rejectsPlanAbiArtifactAndEntryDisagreementBeforeOutput() {
    Fixture fixture = fixture();
    NativeImagePlan wrongRuntime = plan(
        fixture.abi(), fixture.capsule(), hash(99), fixture.rootWbcIdentity(), true);
    NativeImagePlan unstripped = plan(
        fixture.abi(), fixture.capsule(), identity(RUNTIME), fixture.rootWbcIdentity(), false);
    NativeImagePlan wrongArtifact = plan(
        fixture.abi(), fixture.capsule(), identity(RUNTIME), hash(98), true);
    PlatformAbi wrongFormat = abi(PlatformAbi.Format.ELF, "linux-gnu");

    assertThrows(PackageFormatException.class,
        () -> MachOImage.build(wrongRuntime, fixture.abi(), fixture.capsule(), RUNTIME, 0));
    assertThrows(PackageFormatException.class,
        () -> MachOImage.build(unstripped, fixture.abi(), fixture.capsule(), RUNTIME, 0));
    assertThrows(PackageFormatException.class,
        () -> MachOImage.build(wrongArtifact, fixture.abi(), fixture.capsule(), RUNTIME, 0));
    assertThrows(PackageFormatException.class,
        () -> MachOImage.build(fixture.plan(), wrongFormat, fixture.capsule(), RUNTIME, 0));
    assertThrows(PackageFormatException.class,
        () -> MachOImage.build(fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME, 8));
    assertThrows(PackageFormatException.class,
        () -> MachOImage.build(fixture.plan(), fixture.abi(), fixture.capsule(), new byte[0], 0));
  }

  private static void assertRejected(byte[] image, Fixture fixture) {
    assertThrows(PackageFormatException.class,
        () -> MachOImage.verify(image, fixture.plan(), fixture.abi()));
  }

  private static byte[] damaged(byte[] source, int offset) {
    byte[] result = source.clone();
    result[offset] ^= 1;
    return result;
  }

  private static Fixture fixture() {
    PlatformAbi abi = abi(PlatformAbi.Format.MACH_O, "darwin");
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
        abi, capsule, identity(RUNTIME), wbc.identity(), true);
    return new Fixture(abi, capsule, plan, wbc.identity());
  }

  private static NativeImagePlan plan(
      PlatformAbi abi,
      ApplicationCapsule capsule,
      String runtime,
      String artifact,
      boolean stripped) {
    return new NativeImagePlan(
        PlatformAbi.Format.MACH_O,
        "aarch64-apple-darwin",
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

  private static PlatformAbi abi(PlatformAbi.Format format, String osAbi) {
    return new PlatformAbi(
        format,
        "aarch64",
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
        List.of("libsystem"),
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
