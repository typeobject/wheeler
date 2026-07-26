package com.typeobject.wheeler.tools;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.attribute.BasicFileAttributes;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** Stable bounded read of one physical evidence file and its content identity. */
record PhysicalEvidenceFile(Path path, byte[] bytes, String identity) {
  PhysicalEvidenceFile {
    Objects.requireNonNull(path, "path");
    bytes = bytes.clone();
    Objects.requireNonNull(identity, "identity");
  }

  @Override
  public byte[] bytes() {
    return bytes.clone();
  }

  static PhysicalEvidenceFile read(
      Path requested, boolean allowEmpty, long maximumBytes, String description)
      throws IOException {
    if (!Files.isRegularFile(requested, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(requested)) {
      throw new IOException(description + " is not a physical file: " + requested);
    }
    BasicFileAttributes before = Files.readAttributes(
        requested, BasicFileAttributes.class, LinkOption.NOFOLLOW_LINKS);
    if (before.size() > maximumBytes || (!allowEmpty && before.size() == 0)) {
      throw new IOException(description + " is empty or exceeds " + maximumBytes
          + " bytes: " + requested);
    }
    byte[] bytes = Files.readAllBytes(requested);
    BasicFileAttributes after = Files.readAttributes(
        requested, BasicFileAttributes.class, LinkOption.NOFOLLOW_LINKS);
    if (!after.isRegularFile()
        || before.size() != bytes.length
        || after.size() != bytes.length
        || !sameFile(before, after)) {
      throw new IOException(description + " changed while being read: " + requested);
    }
    return new PhysicalEvidenceFile(requested, bytes, sha256(bytes));
  }

  private static boolean sameFile(BasicFileAttributes before, BasicFileAttributes after) {
    if (before.fileKey() != null && after.fileKey() != null
        && !Objects.equals(before.fileKey(), after.fileKey())) {
      return false;
    }
    return before.lastModifiedTime().equals(after.lastModifiedTime());
  }

  private static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }
}
