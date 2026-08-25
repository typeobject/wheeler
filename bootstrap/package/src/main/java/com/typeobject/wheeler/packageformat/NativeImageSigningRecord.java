package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.regex.Pattern;

/** Canonical signing record that keeps signed output outside unsigned build identity. */
public record NativeImageSigningRecord(
    SigningMethod method,
    String unsignedRecord,
    String unsignedPrev,
    String distributionArtifact,
    int distributionBytes,
    String signatureEvidence,
    int signatureBytes,
    String signer,
    String signingTool) {
  public static final int SCHEMA_VERSION = 1;
  public static final int MAX_RECORD_BYTES = 16 * 1024;
  public static final int MAX_DISTRIBUTION_BYTES = 72 * 1024 * 1024;
  public static final int MAX_SIGNATURE_BYTES = 1024 * 1024;
  private static final Pattern IDENTITY = Pattern.compile("[0-9a-f]{64}");

  /** Platform signing mechanism applied after unsigned PREV publication. */
  public enum SigningMethod {
    REPOSITORY_DETACHED("repository-detached", PlatformAbi.Format.ELF),
    APPLE_CODE_SIGNATURE("apple-code-signature", PlatformAbi.Format.MACH_O),
    AUTHENTICODE("authenticode", PlatformAbi.Format.PE_COFF);

    private final String wireName;
    private final PlatformAbi.Format format;

    SigningMethod(String wireName, PlatformAbi.Format format) {
      this.wireName = wireName;
      this.format = format;
    }

    public String wireName() {
      return wireName;
    }

    public PlatformAbi.Format format() {
      return format;
    }
  }

  public NativeImageSigningRecord {
    if (method == null) {
      throw new PackageFormatException("Native image signing method is required");
    }
    unsignedRecord = identity(unsignedRecord, "unsigned native image record");
    unsignedPrev = identity(unsignedPrev, "unsigned PREV");
    distributionArtifact = identity(distributionArtifact, "distribution artifact");
    signatureEvidence = identity(signatureEvidence, "signature evidence");
    signer = identity(signer, "native image signer");
    signingTool = identity(signingTool, "native image signing tool");
    if (distributionBytes <= 0 || distributionBytes > MAX_DISTRIBUTION_BYTES) {
      throw new PackageFormatException("Invalid signed distribution byte count");
    }
    if (signatureBytes <= 0 || signatureBytes > MAX_SIGNATURE_BYTES) {
      throw new PackageFormatException("Invalid signature evidence byte count");
    }
  }

  /** Constructs a record only after exact unsigned, distribution, and evidence bytes exist. */
  public static NativeImageSigningRecord create(
      UnsignedNativeImageRecord unsigned,
      byte[] unsignedImage,
      SigningMethod method,
      byte[] distribution,
      byte[] signatureEvidence,
      String signer,
      String signingTool) {
    if (unsigned == null || method == null) {
      throw new NullPointerException("Unsigned image record and signing method are required");
    }
    validateInputs(unsigned, unsignedImage, method, distribution, signatureEvidence);
    return new NativeImageSigningRecord(
        method,
        unsigned.identity(),
        unsigned.prev(),
        identity(distribution),
        distribution.length,
        identity(signatureEvidence),
        signatureEvidence.length,
        signer,
        signingTool);
  }

  /** Requires all retained signing inputs to reproduce this record. */
  public void verify(
      UnsignedNativeImageRecord unsigned,
      byte[] unsignedImage,
      byte[] distribution,
      byte[] evidence) {
    if (unsigned == null) {
      throw new NullPointerException("Unsigned native image record is required");
    }
    validateInputs(unsigned, unsignedImage, method, distribution, evidence);
    if (!unsignedRecord.equals(unsigned.identity())
        || !unsignedPrev.equals(unsigned.prev())
        || distributionBytes != distribution.length
        || !distributionArtifact.equals(identity(distribution))
        || signatureBytes != evidence.length
        || !signatureEvidence.equals(identity(evidence))) {
      throw new PackageFormatException("Native image signing record does not match its inputs");
    }
  }

  /** Returns strict canonical schema-1 transport bytes. */
  public byte[] canonicalBytes() {
    return canonicalText().getBytes(StandardCharsets.UTF_8);
  }

  /** Returns the signed-release record identity, not unsigned PREV. */
  public String identity() {
    return identity(canonicalBytes());
  }

  /** Parses one strict canonical signing record. */
  public static NativeImageSigningRecord parse(byte[] input) {
    return new NativeImageSigningRecordParser().parse(input);
  }

  /** Returns strict canonical schema-1 YAML. */
  public String canonicalText() {
    return "schema: " + SCHEMA_VERSION + "\n"
        + "native-image-signing:\n"
        + field("method", method.wireName())
        + field("unsigned-record", unsignedRecord)
        + field("unsigned-prev", unsignedPrev)
        + field("distribution-artifact", distributionArtifact)
        + "  distribution-bytes: " + distributionBytes + "\n"
        + field("signature-evidence", signatureEvidence)
        + "  signature-bytes: " + signatureBytes + "\n"
        + field("signer", signer)
        + field("signing-tool", signingTool);
  }

  private static void validateInputs(
      UnsignedNativeImageRecord unsigned,
      byte[] unsignedImage,
      SigningMethod method,
      byte[] distribution,
      byte[] evidence) {
    if (method.format() != unsigned.format()) {
      throw new PackageFormatException("Signing method does not match native image format");
    }
    unsigned.verifyContent(unsignedImage);
    if (distribution == null
        || distribution.length == 0
        || distribution.length > MAX_DISTRIBUTION_BYTES
        || evidence == null
        || evidence.length == 0
        || evidence.length > MAX_SIGNATURE_BYTES) {
      throw new PackageFormatException("Invalid native image signing input length");
    }
    boolean sameDistribution = Arrays.equals(unsignedImage, distribution);
    if (method == SigningMethod.REPOSITORY_DETACHED && !sameDistribution) {
      throw new PackageFormatException("Detached signing must retain exact unsigned image bytes");
    }
    if (method != SigningMethod.REPOSITORY_DETACHED && sameDistribution) {
      throw new PackageFormatException("Attached signing must change distribution bytes");
    }
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
}
