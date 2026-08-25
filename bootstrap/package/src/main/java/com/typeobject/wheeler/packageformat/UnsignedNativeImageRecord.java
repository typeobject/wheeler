package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.regex.Pattern;

/** Canonical release record for one completely verified unsigned native image. */
public record UnsignedNativeImageRecord(
    PlatformAbi.Format format,
    String target,
    String plan,
    String platformAbi,
    String capsule,
    String prev,
    int bytes) {
  public static final int SCHEMA_VERSION = 1;
  public static final int MAX_RECORD_BYTES = 16 * 1024;
  private static final int MAX_IMAGE_BYTES = 64 * 1024 * 1024;
  private static final Pattern IDENTITY = Pattern.compile("[0-9a-f]{64}");
  private static final Pattern TARGET =
      Pattern.compile("[a-z0-9_]+-[a-z0-9_.-]+-[a-z0-9_.-]+");

  public UnsignedNativeImageRecord {
    if (format == null) {
      throw new PackageFormatException("Unsigned native image format is required");
    }
    if (target == null || !TARGET.matcher(target).matches() || 128 < target.length()) {
      throw new PackageFormatException("Invalid unsigned native image target");
    }
    plan = identity(plan, "native image plan");
    platformAbi = identity(platformAbi, "platform ABI");
    capsule = identity(capsule, "application capsule");
    prev = identity(prev, "unsigned PREV");
    if (bytes <= 0 || bytes > MAX_IMAGE_BYTES) {
      throw new PackageFormatException("Invalid unsigned native image byte count");
    }
  }

  /** Verifies complete bytes through the selected adapter and constructs their record. */
  public static UnsignedNativeImageRecord from(
      byte[] image,
      NativeImagePlan plan,
      PlatformAbi abi) {
    if (image == null || plan == null || abi == null) {
      throw new NullPointerException("Native image, plan, and ABI are required");
    }
    VerifiedOutput verified = switch (plan.format()) {
      case ELF -> {
        ElfImage.VerifiedImage result = ElfImage.verify(image, plan, abi);
        yield new VerifiedOutput(result.prev(), result.capsule().identity());
      }
      case MACH_O -> {
        MachOImage.VerifiedImage result = MachOImage.verify(image, plan, abi);
        yield new VerifiedOutput(result.prev(), result.capsule().identity());
      }
      case PE_COFF -> {
        PeImage.VerifiedImage result = PeImage.verify(image, plan, abi);
        yield new VerifiedOutput(result.prev(), result.capsule().identity());
      }
    };
    return new UnsignedNativeImageRecord(
        plan.format(),
        plan.target(),
        plan.identity(),
        abi.identity(),
        verified.capsule(),
        verified.prev(),
        image.length);
  }

  /** Requires bytes, plan, and ABI to reproduce this complete output record. */
  public void verify(byte[] image, NativeImagePlan expectedPlan, PlatformAbi abi) {
    if (!equals(from(image, expectedPlan, abi))) {
      throw new PackageFormatException("Unsigned native image record does not match output");
    }
  }

  /** Requires exact unsigned bytes without reopening or reparsing an image. */
  public void verifyContent(byte[] image) {
    if (image == null || image.length != bytes || !prev.equals(identity(image))) {
      throw new PackageFormatException("Unsigned native image content does not match its record");
    }
  }

  /** Returns strict canonical schema-1 transport bytes. */
  public byte[] canonicalBytes() {
    return canonicalText().getBytes(StandardCharsets.UTF_8);
  }

  /** Returns the identity consumed by later signing records. */
  public String identity() {
    return identity(canonicalBytes());
  }

  /** Parses one strict canonical output record. */
  public static UnsignedNativeImageRecord parse(byte[] input) {
    return new UnsignedNativeImageRecordParser().parse(input);
  }

  /** Returns strict canonical schema-1 YAML. */
  public String canonicalText() {
    return "schema: " + SCHEMA_VERSION + "\n"
        + "unsigned-native-image:\n"
        + field("format", format.wireName())
        + field("target", target)
        + field("plan", plan)
        + field("platform-abi", platformAbi)
        + field("capsule", capsule)
        + field("prev", prev)
        + "  bytes: " + bytes + "\n";
  }

  private static String identity(String value, String description) {
    if (value == null || !IDENTITY.matcher(value).matches()) {
      throw new PackageFormatException("Invalid SHA-256 identity for " + description);
    }
    return value;
  }

  private static String identity(byte[] value) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static String field(String name, String value) {
    return "  " + name + ": " + CanonicalYaml.quote(value) + "\n";
  }

  private record VerifiedOutput(String prev, String capsule) {}
}
