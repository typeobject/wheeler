package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.util.Base64;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Tests detached canonical authorization for immutable repository snapshots. */
final class RepositorySnapshotSignatureTest {
  private static final String REPOSITORY = "ab".repeat(32);

  @Test
  void signsParsesAndVerifiesCanonicalSnapshotBytes() throws Exception {
    KeyPair key = key();
    RepositorySnapshot snapshot = snapshot("1.0.0", '1');

    RepositorySnapshotSignature signed = RepositorySnapshotSignature.sign(
        REPOSITORY, snapshot, key.getPrivate(), key.getPublic());
    RepositorySnapshotSignature decoded = RepositorySnapshotSignature.parse(
        signed.canonicalBytes());

    assertEquals(signed, decoded);
    assertArrayEquals(signed.canonicalBytes(), decoded.canonicalBytes());
    assertEquals(
        RepositorySnapshotSignature.keyIdentity(key.getPublic()),
        signed.keyIdentity());
    decoded.verify(REPOSITORY, snapshot, key.getPublic());
    assertEquals(
        key.getPublic(),
        RepositorySnapshotSignature.decodePublicKey(key.getPublic().getEncoded()));
    assertEquals(
        key.getPrivate(),
        RepositorySnapshotSignature.decodePrivateKey(key.getPrivate().getEncoded()));
  }

  @Test
  void rejectsSubstitutionAndNoncanonicalEnvelopes() throws Exception {
    KeyPair key = key();
    KeyPair other = key();
    RepositorySnapshot snapshot = snapshot("1.0.0", '1');
    RepositorySnapshotSignature signed = RepositorySnapshotSignature.sign(
        REPOSITORY, snapshot, key.getPrivate(), key.getPublic());

    assertThrows(
        PackageFormatException.class,
        () -> signed.verify("cd".repeat(32), snapshot, key.getPublic()));
    assertThrows(
        PackageFormatException.class,
        () -> signed.verify(REPOSITORY, snapshot("1.0.1", '2'), key.getPublic()));
    assertThrows(
        PackageFormatException.class,
        () -> signed.verify(REPOSITORY, snapshot, other.getPublic()));

    byte[] forged = Base64.getDecoder().decode(signed.signature());
    forged[0] ^= 1;
    RepositorySnapshotSignature changed = new RepositorySnapshotSignature(
        signed.schemaVersion(),
        signed.repositoryIdentity(),
        signed.snapshotIdentity(),
        signed.keyIdentity(),
        signed.algorithm(),
        Base64.getEncoder().encodeToString(forged));
    assertThrows(
        PackageFormatException.class,
        () -> changed.verify(REPOSITORY, snapshot, key.getPublic()));
    assertThrows(
        PackageFormatException.class,
        () -> RepositorySnapshotSignature.parse(
            signed.canonicalText()
                .replace("schema: 1", "schema: 01")
                .getBytes(StandardCharsets.UTF_8)));
  }

  private static RepositorySnapshot snapshot(String version, char identity) {
    return new RepositorySnapshot(List.of(new RepositorySnapshot.Entry(
        "demo.lib",
        version,
        Character.toString(identity).repeat(64),
        Character.toString((char) (identity + 1)).repeat(64))));
  }

  private static KeyPair key() throws Exception {
    return KeyPairGenerator.getInstance("Ed25519").generateKeyPair();
  }
}
