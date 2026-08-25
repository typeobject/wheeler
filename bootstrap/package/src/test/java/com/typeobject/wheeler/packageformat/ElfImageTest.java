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

/** Canonical ELF64 capsule segment, locator, permission, and PREV evidence. */
final class ElfImageTest {
  private static final byte[] RUNTIME = {
      (byte) 0xb8, 0x3c, 0, 0, 0,
      0x31, (byte) 0xff,
      0x0f, 0x05
  };

  @Test
  void buildsOnePositionIndependentReadOnlyCapsuleImage() {
    Fixture fixture = fixture();
    byte[] first = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME, 0);
    byte[] second = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME.clone(), 0);
    ElfImage.VerifiedImage verified = ElfImage.verify(first, fixture.plan(), fixture.abi());
    ByteBuffer elf = ByteBuffer.wrap(first).order(ByteOrder.LITTLE_ENDIAN);

    assertArrayEquals(first, second);
    assertArrayEquals(new byte[] {0x7f, 'E', 'L', 'F'},
        java.util.Arrays.copyOf(first, 4));
    assertEquals(3, Short.toUnsignedInt(elf.getShort(16)));
    assertEquals(62, Short.toUnsignedInt(elf.getShort(18)));
    assertEquals(336, elf.getLong(24));
    assertEquals(3, Short.toUnsignedInt(elf.getShort(56)));
    assertEquals(5, elf.getInt(68));
    assertEquals(4, elf.getInt(124));
    assertEquals(6, elf.getInt(180));
    assertEquals(4652, first.length);
    assertEquals(4096, verified.capsuleOffset());
    assertEquals(fixture.plan().identity(), verified.planIdentity());
    assertEquals(fixture.capsule().identity(), verified.capsule().identity());
    assertArrayEquals(RUNTIME, verified.runtimeText());
    assertEquals(0, verified.runtimeEntryOffset());
    assertEquals(
        "9a8db1ccd58cc43beb78394bcfa4f4c710ff7639acc1a8d57dc9764071ce6a58",
        verified.prev());

    byte[] returnedRuntime = verified.runtimeText();
    returnedRuntime[0] ^= 1;
    assertArrayEquals(RUNTIME, verified.runtimeText());
  }

  @Test
  void emitsTheExplicitAarch64MachineProfile() {
    byte[] runtime = {0x00, 0x00, (byte) 0x80, (byte) 0xd2};
    Fixture fixture = fixture("aarch64", runtime);
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), runtime, 0);

    assertEquals(183, Short.toUnsignedInt(
        ByteBuffer.wrap(image).order(ByteOrder.LITTLE_ENDIAN).getShort(18)));
    assertArrayEquals(runtime,
        ElfImage.verify(image, fixture.plan(), fixture.abi()).runtimeText());
  }

  @Test
  void rejectsHeaderLocatorPermissionRuntimePaddingAndCapsuleDamage() {
    Fixture fixture = fixture();
    byte[] canonical = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME, 0);
    byte[] header = canonical.clone();
    header[4] = 1;
    byte[] locator = canonical.clone();
    locator[232] ^= 1;
    byte[] permissions = canonical.clone();
    permissions[68] = 7;
    byte[] runtime = canonical.clone();
    runtime[336] ^= 1;
    byte[] padding = canonical.clone();
    padding[1000] = 1;
    byte[] capsule = canonical.clone();
    capsule[capsule.length - 1] ^= 1;

    assertThrows(PackageFormatException.class,
        () -> ElfImage.verify(header, fixture.plan(), fixture.abi()));
    assertThrows(PackageFormatException.class,
        () -> ElfImage.verify(locator, fixture.plan(), fixture.abi()));
    assertThrows(PackageFormatException.class,
        () -> ElfImage.verify(permissions, fixture.plan(), fixture.abi()));
    assertThrows(PackageFormatException.class,
        () -> ElfImage.verify(runtime, fixture.plan(), fixture.abi()));
    assertThrows(PackageFormatException.class,
        () -> ElfImage.verify(padding, fixture.plan(), fixture.abi()));
    assertThrows(PackageFormatException.class,
        () -> ElfImage.verify(capsule, fixture.plan(), fixture.abi()));
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
    PlatformAbi aarch64 = abi("aarch64");

    assertThrows(PackageFormatException.class,
        () -> ElfImage.build(wrongRuntime, fixture.abi(), fixture.capsule(), RUNTIME, 0));
    assertThrows(PackageFormatException.class,
        () -> ElfImage.build(unstripped, fixture.abi(), fixture.capsule(), RUNTIME, 0));
    assertThrows(PackageFormatException.class,
        () -> ElfImage.build(wrongArtifact, fixture.abi(), fixture.capsule(), RUNTIME, 0));
    assertThrows(PackageFormatException.class,
        () -> ElfImage.build(fixture.plan(), aarch64, fixture.capsule(), RUNTIME, 0));
    assertThrows(PackageFormatException.class,
        () -> ElfImage.build(fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME, 9));
    assertThrows(PackageFormatException.class,
        () -> ElfImage.build(fixture.plan(), fixture.abi(), fixture.capsule(), new byte[0], 0));
  }

  private static Fixture fixture() {
    return fixture("x86_64", RUNTIME);
  }

  private static Fixture fixture(String architecture, byte[] runtime) {
    PlatformAbi abi = abi(architecture);
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
    NativeImagePlan plan = plan(abi, capsule, identity(runtime), wbc.identity(), true);
    return new Fixture(abi, capsule, plan, wbc.identity());
  }

  private static NativeImagePlan plan(
      PlatformAbi abi,
      ApplicationCapsule capsule,
      String runtime,
      String artifact,
      boolean stripped) {
    return new NativeImagePlan(
        PlatformAbi.Format.ELF,
        abi.architecture() + "-unknown-" + abi.osAbi(),
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

  private static PlatformAbi abi(String architecture) {
    return new PlatformAbi(
        PlatformAbi.Format.ELF,
        architecture,
        "linux-gnu",
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
        List.of("libc.so.6"),
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
