package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Unsigned PREV and post-build signing identity separation evidence. */
final class NativeImageReleaseRecordTest {
  private static final byte[] RUNTIME = {
      (byte) 0xb8, 0x3c, 0, 0, 0,
      0x31, (byte) 0xff,
      0x0f, 0x05
  };

  @Test
  void derivesAndReverifiesOneCompleteUnsignedElfRecord() {
    Fixture fixture = fixture();
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME, 0);
    UnsignedNativeImageRecord record =
        UnsignedNativeImageRecord.from(image, fixture.plan(), fixture.abi());
    UnsignedNativeImageRecord parsed =
        UnsignedNativeImageRecord.parse(record.canonicalBytes());

    assertEquals(PlatformAbi.Format.ELF, record.format());
    assertEquals(fixture.plan().target(), record.target());
    assertEquals(fixture.plan().identity(), record.plan());
    assertEquals(fixture.abi().identity(), record.platformAbi());
    assertEquals(fixture.capsule().identity(), record.capsule());
    assertEquals(ElfImage.verify(image, fixture.plan(), fixture.abi()).prev(), record.prev());
    assertEquals(image.length, record.bytes());
    assertEquals(record, parsed);
    assertArrayEquals(record.canonicalBytes(), parsed.canonicalBytes());
    assertEquals(
        "84a4fb6195bbf6cb7248b2779855c97d4ef57b5d248857357041d45db3106ee4",
        record.identity());
    record.verify(image, fixture.plan(), fixture.abi());

    byte[] damaged = image.clone();
    damaged[damaged.length - 1] ^= 1;
    assertThrows(PackageFormatException.class, () -> record.verifyContent(damaged));
    assertThrows(
        PackageFormatException.class,
        () -> record.verify(damaged, fixture.plan(), fixture.abi()));
  }

  @Test
  void recordsDetachedSigningWithoutChangingUnsignedIdentity() {
    Fixture fixture = fixture();
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME, 0);
    UnsignedNativeImageRecord unsigned =
        UnsignedNativeImageRecord.from(image, fixture.plan(), fixture.abi());
    byte[] evidence = "repository-signature".getBytes(java.nio.charset.StandardCharsets.US_ASCII);
    NativeImageSigningRecord signing = NativeImageSigningRecord.create(
        unsigned,
        image,
        NativeImageSigningRecord.SigningMethod.REPOSITORY_DETACHED,
        image.clone(),
        evidence,
        hash(50),
        hash(51));
    NativeImageSigningRecord parsed =
        NativeImageSigningRecord.parse(signing.canonicalBytes());

    assertEquals(unsigned.identity(), signing.unsignedRecord());
    assertEquals(unsigned.prev(), signing.unsignedPrev());
    assertEquals(unsigned.prev(), signing.distributionArtifact());
    assertEquals(image.length, signing.distributionBytes());
    assertEquals(identity(evidence), signing.signatureEvidence());
    assertEquals(evidence.length, signing.signatureBytes());
    assertEquals(signing, parsed);
    assertNotEquals(unsigned.identity(), signing.identity());
    assertEquals(
        "e00e64063584d4d31bee456bd360cb1a0e779dba3fccf689367ae6074bf3fc94",
        signing.identity());
    signing.verify(unsigned, image, image, evidence);

    byte[] changedEvidence = evidence.clone();
    changedEvidence[0] ^= 1;
    assertThrows(
        PackageFormatException.class,
        () -> signing.verify(unsigned, image, image, changedEvidence));
    assertThrows(
        PackageFormatException.class,
        () -> NativeImageSigningRecord.create(
            unsigned,
            image,
            NativeImageSigningRecord.SigningMethod.REPOSITORY_DETACHED,
            append(image, (byte) 1),
            evidence,
            hash(50),
            hash(51)));
  }

  @Test
  void separatesAppleAndAuthenticodeDistributionArtifacts() {
    byte[] appleUnsignedBytes = {1, 2, 3};
    byte[] appleDistribution = {1, 2, 3, 4};
    byte[] appleEvidence = {9, 8};
    UnsignedNativeImageRecord appleUnsigned = unsigned(
        PlatformAbi.Format.MACH_O,
        "aarch64-apple-darwin",
        appleUnsignedBytes,
        60);
    NativeImageSigningRecord apple = NativeImageSigningRecord.create(
        appleUnsigned,
        appleUnsignedBytes,
        NativeImageSigningRecord.SigningMethod.APPLE_CODE_SIGNATURE,
        appleDistribution,
        appleEvidence,
        hash(61),
        hash(62));

    byte[] peUnsignedBytes = {5, 6, 7};
    byte[] peDistribution = {5, 6, 7, 8};
    byte[] peEvidence = {4, 3};
    UnsignedNativeImageRecord peUnsigned = unsigned(
        PlatformAbi.Format.PE_COFF,
        "x86_64-pc-windows-msvc",
        peUnsignedBytes,
        70);
    NativeImageSigningRecord authenticode = NativeImageSigningRecord.create(
        peUnsigned,
        peUnsignedBytes,
        NativeImageSigningRecord.SigningMethod.AUTHENTICODE,
        peDistribution,
        peEvidence,
        hash(71),
        hash(72));

    apple.verify(appleUnsigned, appleUnsignedBytes, appleDistribution, appleEvidence);
    authenticode.verify(peUnsigned, peUnsignedBytes, peDistribution, peEvidence);
    assertNotEquals(appleUnsigned.prev(), apple.distributionArtifact());
    assertNotEquals(peUnsigned.prev(), authenticode.distributionArtifact());
    assertNotEquals(apple.identity(), authenticode.identity());
    assertThrows(
        PackageFormatException.class,
        () -> NativeImageSigningRecord.create(
            appleUnsigned,
            appleUnsignedBytes,
            NativeImageSigningRecord.SigningMethod.AUTHENTICODE,
            appleDistribution,
            appleEvidence,
            hash(61),
            hash(62)));
    assertThrows(
        PackageFormatException.class,
        () -> NativeImageSigningRecord.create(
            appleUnsigned,
            appleUnsignedBytes,
            NativeImageSigningRecord.SigningMethod.APPLE_CODE_SIGNATURE,
            appleUnsignedBytes,
            appleEvidence,
            hash(61),
            hash(62)));
  }

  @Test
  void rejectsMalformedNoncanonicalAndOversizedRecords() {
    Fixture fixture = fixture();
    byte[] image = ElfImage.build(
        fixture.plan(), fixture.abi(), fixture.capsule(), RUNTIME, 0);
    UnsignedNativeImageRecord unsigned =
        UnsignedNativeImageRecord.from(image, fixture.plan(), fixture.abi());
    byte[] evidence = {1};
    NativeImageSigningRecord signing = NativeImageSigningRecord.create(
        unsigned,
        image,
        NativeImageSigningRecord.SigningMethod.REPOSITORY_DETACHED,
        image,
        evidence,
        hash(80),
        hash(81));

    assertThrows(
        PackageFormatException.class,
        () -> UnsignedNativeImageRecord.parse(replace(
            unsigned.canonicalBytes(), "schema: 1", "schema: 2")));
    assertThrows(
        PackageFormatException.class,
        () -> UnsignedNativeImageRecord.parse(replace(
            unsigned.canonicalBytes(), "  bytes: ", "  extra: 1\n  bytes: ")));
    assertThrows(
        PackageFormatException.class,
        () -> UnsignedNativeImageRecord.parse(new byte[] {(byte) 0xc3, 0x28}));
    assertThrows(
        PackageFormatException.class,
        () -> UnsignedNativeImageRecord.parse(
            new byte[UnsignedNativeImageRecord.MAX_RECORD_BYTES + 1]));
    assertThrows(
        PackageFormatException.class,
        () -> NativeImageSigningRecord.parse(replace(
            signing.canonicalBytes(), "repository-detached", "unknown")));
    assertThrows(
        PackageFormatException.class,
        () -> NativeImageSigningRecord.parse(replace(
            signing.canonicalBytes(), "schema: 1", "schema: 01")));
    assertThrows(
        PackageFormatException.class,
        () -> NativeImageSigningRecord.parse(
            new byte[NativeImageSigningRecord.MAX_RECORD_BYTES + 1]));
    assertThrows(
        PackageFormatException.class,
        () -> new UnsignedNativeImageRecord(
            PlatformAbi.Format.ELF,
            "x86_64-unknown-linux-gnu",
            hash(1),
            hash(2),
            hash(3),
            hash(4),
            0));
    assertThrows(
        PackageFormatException.class,
        () -> new NativeImageSigningRecord(
            NativeImageSigningRecord.SigningMethod.REPOSITORY_DETACHED,
            hash(1),
            hash(2),
            hash(3),
            1,
            hash(4),
            0,
            hash(5),
            hash(6)));
  }

  private static UnsignedNativeImageRecord unsigned(
      PlatformAbi.Format format,
      String target,
      byte[] bytes,
      int identityBase) {
    return new UnsignedNativeImageRecord(
        format,
        target,
        hash(identityBase),
        hash(identityBase + 1),
        hash(identityBase + 2),
        identity(bytes),
        bytes.length);
  }

  private static byte[] replace(byte[] source, String oldText, String newText) {
    return new String(source, java.nio.charset.StandardCharsets.UTF_8)
        .replace(oldText, newText)
        .getBytes(java.nio.charset.StandardCharsets.UTF_8);
  }

  private static byte[] append(byte[] source, byte value) {
    byte[] result = Arrays.copyOf(source, source.length + 1);
    result[result.length - 1] = value;
    return result;
  }

  private static Fixture fixture() {
    PlatformAbi abi = new PlatformAbi(
        PlatformAbi.Format.ELF,
        "x86_64",
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
        List.of("x86-64-v1"),
        List.of(),
        requiredServices());
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
    ApplicationCapsule capsule = new ApplicationCapsule(
        root,
        List.of(new CapsulePackageReceipt(
            hash(8),
            "wheeler.app@1.0.0",
            hash(9),
            "release",
            hash(10),
            hash(11),
            "app",
            hash(1))),
        List.of(wbc));
    NativeImagePlan plan = new NativeImagePlan(
        PlatformAbi.Format.ELF,
        "x86_64-unknown-linux-gnu",
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        true,
        true,
        wbc.identity(),
        abi.identity(),
        capsule.identity(),
        hash(12),
        identity(RUNTIME),
        hash(13),
        hash(14),
        hash(15),
        hash(16),
        hash(17));
    return new Fixture(abi, capsule, plan);
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

  private static String identity(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException(exception);
    }
  }

  private static String hash(int value) {
    return "%064x".formatted(value);
  }

  private record Fixture(
      PlatformAbi abi,
      ApplicationCapsule capsule,
      NativeImagePlan plan) {}
}
