package com.typeobject.wheeler.packageformat;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.KeyFactory;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Set;

/** Detached Ed25519 authorization for one immutable repository snapshot. */
public record RepositorySnapshotSignature(
    int schemaVersion,
    String repositoryIdentity,
    String snapshotIdentity,
    String keyIdentity,
    String algorithm,
    String signature) {
  public static final int SCHEMA_VERSION = 1;
  public static final String ALGORITHM = "ed25519";
  public static final String SUFFIX = ".snapshot-signature.yaml";
  private static final int MAX_BYTES = 16 * 1024;
  private static final byte[] DOMAIN = "wheeler-repository-snapshot-signature-1\0"
      .getBytes(StandardCharsets.UTF_8);
  private static final Set<String> FIELDS = Set.of(
      "schema", "repository", "snapshot", "key", "algorithm", "signature");

  public RepositorySnapshotSignature {
    if (schemaVersion != SCHEMA_VERSION) {
      throw new PackageFormatException(
          "Unsupported repository snapshot signature schema " + schemaVersion);
    }
    requireIdentity(repositoryIdentity, "repository");
    requireIdentity(snapshotIdentity, "snapshot");
    requireIdentity(keyIdentity, "key");
    if (!ALGORITHM.equals(algorithm)) {
      throw new PackageFormatException("Unsupported snapshot signature algorithm " + algorithm);
    }
    byte[] decoded = decodeBase64(signature, "snapshot signature");
    if (decoded.length != 64) {
      throw new PackageFormatException("Ed25519 snapshot signature must contain 64 bytes");
    }
  }

  /** Signs canonical snapshot bytes for one stable repository trust domain. */
  public static RepositorySnapshotSignature sign(
      String repositoryIdentity,
      RepositorySnapshot snapshot,
      PrivateKey privateKey,
      PublicKey publicKey) {
    requireEd25519(privateKey.getAlgorithm(), "private");
    requireEd25519(publicKey.getAlgorithm(), "public");
    try {
      Signature signer = Signature.getInstance("Ed25519");
      signer.initSign(privateKey);
      signer.update(message(repositoryIdentity, snapshot));
      return new RepositorySnapshotSignature(
          SCHEMA_VERSION,
          repositoryIdentity,
          snapshot.identity(),
          keyIdentity(publicKey),
          ALGORITHM,
          Base64.getEncoder().encodeToString(signer.sign()));
    } catch (GeneralSecurityException exception) {
      throw new PackageFormatException("Cannot sign repository snapshot", exception);
    }
  }

  /** Verifies the authorization and every identity it claims to bind. */
  public void verify(
      String expectedRepositoryIdentity,
      RepositorySnapshot snapshot,
      PublicKey publicKey) {
    if (!repositoryIdentity.equals(expectedRepositoryIdentity)) {
      throw new PackageFormatException("Snapshot signature repository identity mismatch");
    }
    if (!snapshotIdentity.equals(snapshot.identity())) {
      throw new PackageFormatException("Snapshot signature snapshot identity mismatch");
    }
    if (!keyIdentity.equals(keyIdentity(publicKey))) {
      throw new PackageFormatException("Snapshot signature key identity mismatch");
    }
    requireEd25519(publicKey.getAlgorithm(), "public");
    try {
      Signature verifier = Signature.getInstance("Ed25519");
      verifier.initVerify(publicKey);
      verifier.update(message(repositoryIdentity, snapshot));
      if (!verifier.verify(decodeBase64(signature, "snapshot signature"))) {
        throw new PackageFormatException("Repository snapshot signature verification failed");
      }
    } catch (GeneralSecurityException exception) {
      throw new PackageFormatException("Cannot verify repository snapshot signature", exception);
    }
  }

  public String canonicalText() {
    return "schema: 1\n"
        + "repository: " + CanonicalYaml.quote(repositoryIdentity) + "\n"
        + "snapshot: " + CanonicalYaml.quote(snapshotIdentity) + "\n"
        + "key: " + CanonicalYaml.quote(keyIdentity) + "\n"
        + "algorithm: \"ed25519\"\n"
        + "signature: " + CanonicalYaml.quote(signature) + "\n";
  }

  public byte[] canonicalBytes() {
    return canonicalText().getBytes(StandardCharsets.UTF_8);
  }

  public static RepositorySnapshotSignature parse(byte[] utf8) {
    if (utf8.length > MAX_BYTES) {
      throw new PackageFormatException("Repository snapshot signature exceeds byte limit");
    }
    try {
      String source = StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(utf8))
          .toString();
      CanonicalYaml.Mapping root = CanonicalYaml.mapping(
          CanonicalYaml.parse(source, "repository snapshot signature"),
          "repository snapshot signature");
      CanonicalYaml.fields(root, FIELDS, "repository snapshot signature");
      RepositorySnapshotSignature result = new RepositorySnapshotSignature(
          CanonicalYaml.integer(
              CanonicalYaml.required(root, "schema", "repository snapshot signature"),
              "snapshot signature.schema"),
          string(root, "repository"),
          string(root, "snapshot"),
          string(root, "key"),
          string(root, "algorithm"),
          string(root, "signature"));
      if (!result.canonicalText().equals(source)) {
        throw new PackageFormatException("Repository snapshot signature is not canonical");
      }
      return result;
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException(
          "Repository snapshot signature is not strict UTF-8", exception);
    }
  }

  public static PublicKey decodePublicKey(byte[] x509) {
    try {
      PublicKey key = KeyFactory.getInstance("Ed25519")
          .generatePublic(new X509EncodedKeySpec(x509));
      if (!MessageDigest.isEqual(x509, key.getEncoded())) {
        throw new PackageFormatException("Ed25519 public key is not canonical X.509 DER");
      }
      return key;
    } catch (GeneralSecurityException exception) {
      throw new PackageFormatException("Invalid Ed25519 public key", exception);
    }
  }

  public static PrivateKey decodePrivateKey(byte[] pkcs8) {
    try {
      PrivateKey key = KeyFactory.getInstance("Ed25519")
          .generatePrivate(new PKCS8EncodedKeySpec(pkcs8));
      if (!MessageDigest.isEqual(pkcs8, key.getEncoded())) {
        throw new PackageFormatException("Ed25519 private key is not canonical PKCS#8 DER");
      }
      return key;
    } catch (GeneralSecurityException exception) {
      throw new PackageFormatException("Invalid Ed25519 private key", exception);
    }
  }

  public static String keyIdentity(PublicKey key) {
    requireEd25519(key.getAlgorithm(), "public");
    try {
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(key.getEncoded()));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static byte[] message(String repositoryIdentity, RepositorySnapshot snapshot) {
    requireIdentity(repositoryIdentity, "repository");
    byte[] repository = HexFormat.of().parseHex(repositoryIdentity);
    byte[] snapshotBytes = snapshot.canonicalBytes();
    ByteBuffer result = ByteBuffer.allocate(DOMAIN.length + repository.length + snapshotBytes.length);
    return result.put(DOMAIN).put(repository).put(snapshotBytes).array();
  }

  private static String string(CanonicalYaml.Mapping mapping, String key) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, "repository snapshot signature"),
        "snapshot signature." + key);
  }

  private static byte[] decodeBase64(String encoded, String description) {
    try {
      byte[] decoded = Base64.getDecoder().decode(encoded);
      if (!Base64.getEncoder().encodeToString(decoded).equals(encoded)) {
        throw new PackageFormatException(description + " is not canonical base64");
      }
      return decoded;
    } catch (IllegalArgumentException exception) {
      throw new PackageFormatException("Invalid " + description, exception);
    }
  }

  private static void requireIdentity(String identity, String description) {
    if (identity == null || !identity.matches("[0-9a-f]{64}")) {
      throw new PackageFormatException("Invalid snapshot signature " + description + " identity");
    }
  }

  private static void requireEd25519(String algorithm, String description) {
    if (!"EdDSA".equals(algorithm) && !"Ed25519".equals(algorithm)) {
      throw new PackageFormatException("Snapshot signature " + description + " key is not Ed25519");
    }
  }
}
