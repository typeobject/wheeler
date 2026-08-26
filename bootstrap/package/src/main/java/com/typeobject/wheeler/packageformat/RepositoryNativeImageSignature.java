package com.typeobject.wheeler.packageformat;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Signature;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Set;

/** Detached Ed25519 repository authorization for one verified ELF image. */
public record RepositoryNativeImageSignature(
    int schemaVersion,
    String repositoryIdentity,
    String unsignedRecord,
    String unsignedPrev,
    String distributionArtifact,
    String keyIdentity,
    String algorithm,
    String signature) {
  public static final int SCHEMA_VERSION = 1;
  public static final int MAX_BYTES = 16 * 1024;
  public static final String ALGORITHM = "ed25519";
  private static final byte[] DOMAIN = "wheeler-native-image-repository-signature-1\0"
      .getBytes(StandardCharsets.UTF_8);
  private static final Set<String> FIELDS = Set.of(
      "schema",
      "repository",
      "unsigned-record",
      "unsigned-prev",
      "distribution-artifact",
      "key",
      "algorithm",
      "signature");

  public RepositoryNativeImageSignature {
    if (schemaVersion != SCHEMA_VERSION) {
      throw new PackageFormatException(
          "Unsupported native repository signature schema " + schemaVersion);
    }
    requireIdentity(repositoryIdentity, "repository");
    requireIdentity(unsignedRecord, "unsigned record");
    requireIdentity(unsignedPrev, "unsigned PREV");
    requireIdentity(distributionArtifact, "distribution artifact");
    requireIdentity(keyIdentity, "key");
    if (!ALGORITHM.equals(algorithm)) {
      throw new PackageFormatException(
          "Unsupported native repository signature algorithm " + algorithm);
    }
    if (decodeSignature(signature).length != 64) {
      throw new PackageFormatException("Native Ed25519 signature must contain 64 bytes");
    }
  }

  /** Signs one exact verified ELF image in a named repository trust domain. */
  public static RepositoryNativeImageSignature sign(
      String repositoryIdentity,
      UnsignedNativeImageRecord unsigned,
      byte[] image,
      PrivateKey privateKey,
      PublicKey publicKey) {
    requireElf(unsigned, image);
    requireEd25519(privateKey.getAlgorithm(), "private");
    requireEd25519(publicKey.getAlgorithm(), "public");
    String keyIdentity = RepositorySnapshotSignature.keyIdentity(publicKey);
    try {
      Signature signer = Signature.getInstance("Ed25519");
      signer.initSign(privateKey);
      update(signer, repositoryIdentity, unsigned, image);
      RepositoryNativeImageSignature result = new RepositoryNativeImageSignature(
          SCHEMA_VERSION,
          repositoryIdentity,
          unsigned.identity(),
          unsigned.prev(),
          unsigned.prev(),
          keyIdentity,
          ALGORITHM,
          Base64.getEncoder().encodeToString(signer.sign()));
      result.verify(repositoryIdentity, unsigned, image, publicKey);
      return result;
    } catch (GeneralSecurityException exception) {
      throw new PackageFormatException("Cannot sign native repository image", exception);
    }
  }

  /** Verifies repository, image, release, key, and signature identities together. */
  public void verify(
      String expectedRepositoryIdentity,
      UnsignedNativeImageRecord unsigned,
      byte[] image,
      PublicKey publicKey) {
    requireElf(unsigned, image);
    if (!repositoryIdentity.equals(expectedRepositoryIdentity)) {
      throw new PackageFormatException("Native signature repository identity mismatch");
    }
    if (!unsignedRecord.equals(unsigned.identity())
        || !unsignedPrev.equals(unsigned.prev())
        || !distributionArtifact.equals(unsigned.prev())) {
      throw new PackageFormatException("Native signature unsigned image identity mismatch");
    }
    if (!keyIdentity.equals(RepositorySnapshotSignature.keyIdentity(publicKey))) {
      throw new PackageFormatException("Native signature key identity mismatch");
    }
    requireEd25519(publicKey.getAlgorithm(), "public");
    try {
      Signature verifier = Signature.getInstance("Ed25519");
      verifier.initVerify(publicKey);
      update(verifier, repositoryIdentity, unsigned, image);
      if (!verifier.verify(decodeSignature(signature))) {
        throw new PackageFormatException("Native repository signature verification failed");
      }
    } catch (GeneralSecurityException exception) {
      throw new PackageFormatException("Cannot verify native repository signature", exception);
    }
  }

  public String canonicalText() {
    return "schema: 1\n"
        + field("repository", repositoryIdentity)
        + field("unsigned-record", unsignedRecord)
        + field("unsigned-prev", unsignedPrev)
        + field("distribution-artifact", distributionArtifact)
        + field("key", keyIdentity)
        + field("algorithm", algorithm)
        + field("signature", signature);
  }

  public byte[] canonicalBytes() {
    return canonicalText().getBytes(StandardCharsets.UTF_8);
  }

  public String identity() {
    try {
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(canonicalBytes()));
    } catch (GeneralSecurityException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  public static RepositoryNativeImageSignature parse(byte[] utf8) {
    if (utf8 == null || utf8.length > MAX_BYTES) {
      throw new PackageFormatException("Native repository signature exceeds byte limit");
    }
    try {
      String source = StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(utf8))
          .toString();
      CanonicalYaml.Mapping root = CanonicalYaml.mapping(
          CanonicalYaml.parse(source, "native repository signature"),
          "native repository signature");
      CanonicalYaml.fields(root, FIELDS, "native repository signature");
      RepositoryNativeImageSignature result = new RepositoryNativeImageSignature(
          CanonicalYaml.integer(
              CanonicalYaml.required(root, "schema", "native repository signature"),
              "native repository signature.schema"),
          string(root, "repository"),
          string(root, "unsigned-record"),
          string(root, "unsigned-prev"),
          string(root, "distribution-artifact"),
          string(root, "key"),
          string(root, "algorithm"),
          string(root, "signature"));
      if (!result.canonicalText().equals(source)) {
        throw new PackageFormatException("Native repository signature is not canonical");
      }
      return result;
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException(
          "Native repository signature is not strict UTF-8", exception);
    }
  }

  private static void update(
      Signature signature,
      String repositoryIdentity,
      UnsignedNativeImageRecord unsigned,
      byte[] image) throws GeneralSecurityException {
    requireIdentity(repositoryIdentity, "repository");
    signature.update(DOMAIN);
    signature.update(HexFormat.of().parseHex(repositoryIdentity));
    signature.update(unsigned.canonicalBytes());
    signature.update(image);
  }

  private static void requireElf(UnsignedNativeImageRecord unsigned, byte[] image) {
    if (unsigned == null) {
      throw new NullPointerException("Unsigned native image record is required");
    }
    if (unsigned.format() != PlatformAbi.Format.ELF) {
      throw new PackageFormatException("Repository detached signing requires ELF");
    }
    unsigned.verifyContent(image);
  }

  private static String string(CanonicalYaml.Mapping root, String name) {
    return CanonicalYaml.string(
        CanonicalYaml.required(root, name, "native repository signature"),
        "native repository signature." + name);
  }

  private static String field(String name, String value) {
    return name + ": " + CanonicalYaml.quote(value) + "\n";
  }

  private static byte[] decodeSignature(String encoded) {
    try {
      byte[] decoded = Base64.getDecoder().decode(encoded);
      if (!Base64.getEncoder().encodeToString(decoded).equals(encoded)) {
        throw new PackageFormatException("Native signature is not canonical base64");
      }
      return decoded;
    } catch (IllegalArgumentException exception) {
      throw new PackageFormatException("Invalid native repository signature", exception);
    }
  }

  private static void requireIdentity(String identity, String description) {
    if (identity == null || !identity.matches("[0-9a-f]{64}")) {
      throw new PackageFormatException(
          "Invalid native signature " + description + " identity");
    }
  }

  private static void requireEd25519(String algorithm, String description) {
    if (!"EdDSA".equals(algorithm) && !"Ed25519".equals(algorithm)) {
      throw new PackageFormatException(
          "Native signature " + description + " key is not Ed25519");
    }
  }
}
