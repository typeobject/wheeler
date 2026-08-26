package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.HexFormat;
import org.junit.jupiter.api.Test;

/** Cryptographic repository authorization evidence for native ELF distribution. */
final class RepositoryNativeImageSignatureTest {
  private static final String REPOSITORY = "ab".repeat(32);
  private static final byte[] IMAGE = {1, 2, 3, 4};
  private static final String PRIVATE_KEY =
      "302e020100300506032b657004220420"
          + "9d61b19deffd5a60ba844af492ec2cc4"
          + "4449c5697b326919703bac031cae7f60";
  private static final String PUBLIC_KEY =
      "302a300506032b6570032100"
          + "d75a980182b10ab7d54bfed3c964073a"
          + "0ee172f3daa62325af021a68f707511a";

  @Test
  void signsParsesAndVerifiesOneExactElfDistribution() throws Exception {
    KeyPair key = key();
    UnsignedNativeImageRecord unsigned = unsigned(IMAGE);

    RepositoryNativeImageSignature authorization = RepositoryNativeImageSignature.sign(
        REPOSITORY, unsigned, IMAGE, key.getPrivate(), key.getPublic());
    RepositoryNativeImageSignature parsed = RepositoryNativeImageSignature.parse(
        authorization.canonicalBytes());

    assertEquals(authorization, parsed);
    assertArrayEquals(authorization.canonicalBytes(), parsed.canonicalBytes());
    assertEquals(unsigned.identity(), parsed.unsignedRecord());
    assertEquals(unsigned.prev(), parsed.unsignedPrev());
    assertEquals(unsigned.prev(), parsed.distributionArtifact());
    assertEquals(
        RepositorySnapshotSignature.keyIdentity(key.getPublic()), parsed.keyIdentity());
    assertEquals(
        "74b2c461fae281237c764e4e0258606da7579eb9f84091c7a56f5797859a3d45",
        parsed.identity());
    parsed.verify(REPOSITORY, unsigned, IMAGE, key.getPublic());
  }

  @Test
  void rejectsRepositoryImageKeySignatureAndTransportSubstitution() throws Exception {
    KeyPair key = key();
    KeyPair other = KeyPairGenerator.getInstance("Ed25519").generateKeyPair();
    UnsignedNativeImageRecord unsigned = unsigned(IMAGE);
    RepositoryNativeImageSignature authorization = RepositoryNativeImageSignature.sign(
        REPOSITORY, unsigned, IMAGE, key.getPrivate(), key.getPublic());

    assertThrows(
        PackageFormatException.class,
        () -> authorization.verify("cd".repeat(32), unsigned, IMAGE, key.getPublic()));
    assertThrows(
        PackageFormatException.class,
        () -> authorization.verify(REPOSITORY, unsigned, new byte[] {1, 2, 3}, key.getPublic()));
    UnsignedNativeImageRecord changedRecord = new UnsignedNativeImageRecord(
        unsigned.format(),
        unsigned.target(),
        "04".repeat(32),
        unsigned.platformAbi(),
        unsigned.capsule(),
        unsigned.prev(),
        unsigned.bytes());
    assertThrows(
        PackageFormatException.class,
        () -> authorization.verify(REPOSITORY, changedRecord, IMAGE, key.getPublic()));
    assertThrows(
        PackageFormatException.class,
        () -> authorization.verify(REPOSITORY, unsigned, IMAGE, other.getPublic()));
    assertThrows(
        PackageFormatException.class,
        () -> RepositoryNativeImageSignature.sign(
            REPOSITORY, unsigned, IMAGE, key.getPrivate(), other.getPublic()));

    byte[] forged = Base64.getDecoder().decode(authorization.signature());
    forged[0] ^= 1;
    RepositoryNativeImageSignature changed = new RepositoryNativeImageSignature(
        authorization.schemaVersion(),
        authorization.repositoryIdentity(),
        authorization.unsignedRecord(),
        authorization.unsignedPrev(),
        authorization.distributionArtifact(),
        authorization.keyIdentity(),
        authorization.algorithm(),
        Base64.getEncoder().encodeToString(forged));
    assertThrows(
        PackageFormatException.class,
        () -> changed.verify(REPOSITORY, unsigned, IMAGE, key.getPublic()));
    assertThrows(
        PackageFormatException.class,
        () -> RepositoryNativeImageSignature.parse(
            authorization.canonicalText()
                .replace("schema: 1", "schema: 01")
                .getBytes(StandardCharsets.UTF_8)));
    assertThrows(
        PackageFormatException.class,
        () -> RepositoryNativeImageSignature.parse(
            new byte[RepositoryNativeImageSignature.MAX_BYTES + 1]));
  }

  private static UnsignedNativeImageRecord unsigned(byte[] image) {
    return new UnsignedNativeImageRecord(
        PlatformAbi.Format.ELF,
        "x86_64-unknown-linux-gnu",
        "01".repeat(32),
        "02".repeat(32),
        "03".repeat(32),
        identity(image),
        image.length);
  }

  private static String identity(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (Exception exception) {
      throw new IllegalStateException(exception);
    }
  }

  private static KeyPair key() {
    return new KeyPair(
        RepositorySnapshotSignature.decodePublicKey(HexFormat.of().parseHex(PUBLIC_KEY)),
        RepositorySnapshotSignature.decodePrivateKey(HexFormat.of().parseHex(PRIVATE_KEY)));
  }
}
