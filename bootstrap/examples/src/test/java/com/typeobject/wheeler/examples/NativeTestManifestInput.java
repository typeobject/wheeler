package com.typeobject.wheeler.examples;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;

/** Mutates canonical runner manifests while repairing their lock roots. */
final class NativeTestManifestInput {
  private NativeTestManifestInput() {}

  static byte[] emptyLock(String manifestText) {
    try {
      String root = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(
          manifestText.getBytes(StandardCharsets.UTF_8)));
      return ("schema: 3\nroot: \"" + root + "\"\npackages: []\n")
          .getBytes(StandardCharsets.UTF_8);
    } catch (Exception exception) {
      throw new AssertionError(exception);
    }
  }

  static byte[] replace(
      byte[] input, String manifestText, String original, String replacement) throws Exception {
    if (original.length() != replacement.length()) {
      throw new IllegalArgumentException("replacement changes manifest length");
    }
    int valueOffset = manifestText.indexOf(original);
    byte[] manifest = manifestText.getBytes(StandardCharsets.UTF_8);
    byte[] replacementBytes = replacement.getBytes(StandardCharsets.UTF_8);
    System.arraycopy(replacementBytes, 0, manifest, valueOffset, replacementBytes.length);

    byte[] replaced = input.clone();
    System.arraycopy(replacementBytes, 0, replaced, 23 + valueOffset, replacementBytes.length);
    byte[] manifestIdentity = HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(manifest))
        .getBytes(StandardCharsets.UTF_8);
    int lockStart = 27 + manifest.length;
    System.arraycopy(manifestIdentity, 0, replaced, lockStart + 17, manifestIdentity.length);
    return replaced;
  }
}
