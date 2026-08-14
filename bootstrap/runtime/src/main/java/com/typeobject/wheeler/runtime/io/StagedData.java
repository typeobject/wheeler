package com.typeobject.wheeler.runtime.io;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** Typed placement evidence for one named tier and failure domain, never durability. */
public record StagedData(
    String tier,
    String failureDomain,
    String contentIdentity,
    long bytes,
    String parentIdentity,
    String identity) {
  public StagedData {
    tier = name(tier, "tier");
    failureDomain = name(failureDomain, "failure domain");
    contentIdentity = hash(contentIdentity, "content identity");
    if (bytes < 0) {
      throw new IllegalArgumentException("staged byte count cannot be negative");
    }
    if (!parentIdentity.equals("-")) {
      parentIdentity = hash(parentIdentity, "parent identity");
    }
    String expected = identity(tier, failureDomain, contentIdentity, bytes, parentIdentity);
    if (!expected.equals(identity)) {
      throw new IllegalArgumentException("staged-data identity mismatch");
    }
  }

  /** Creates initial placement evidence without making a stability claim. */
  public static StagedData initial(
      String tier, String failureDomain, String contentIdentity, long bytes) {
    return create(tier, failureDomain, contentIdentity, bytes, "-");
  }

  /** Records complete placement in another named tier while retaining exact ancestry. */
  public StagedData restage(String nextTier, String nextFailureDomain) {
    return create(nextTier, nextFailureDomain, contentIdentity, bytes, identity);
  }

  /** Records a known placed prefix after a bounded partial transfer. */
  public static StagedData partialOf(
      StagedData source,
      String nextTier,
      String nextFailureDomain,
      String prefixContentIdentity,
      long prefixBytes) {
    Objects.requireNonNull(source, "source");
    if (prefixBytes < 0 || prefixBytes >= source.bytes) {
      throw new IllegalArgumentException("partial placement must be shorter than its source");
    }
    return create(
        nextTier,
        nextFailureDomain,
        prefixContentIdentity,
        prefixBytes,
        source.identity);
  }

  private static StagedData create(
      String tier,
      String failureDomain,
      String contentIdentity,
      long bytes,
      String parentIdentity) {
    String canonicalTier = name(tier, "tier");
    String canonicalDomain = name(failureDomain, "failure domain");
    String canonicalContent = hash(contentIdentity, "content identity");
    return new StagedData(
        canonicalTier,
        canonicalDomain,
        canonicalContent,
        bytes,
        parentIdentity,
        identity(canonicalTier, canonicalDomain, canonicalContent, bytes, parentIdentity));
  }

  private static String identity(
      String tier,
      String failureDomain,
      String contentIdentity,
      long bytes,
      String parentIdentity) {
    String canonical = "wheeler-staged-data-1\0"
        + tier + '\0'
        + failureDomain + '\0'
        + contentIdentity + '\0'
        + bytes + '\0'
        + parentIdentity;
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(
          canonical.getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static String name(String value, String field) {
    Objects.requireNonNull(value, field);
    if (value.isBlank() || value.length() > 128 || !value.equals(value.trim())) {
      throw new IllegalArgumentException(field + " must be 1..128 visible ASCII bytes");
    }
    for (int index = 0; index < value.length(); index++) {
      char scalar = value.charAt(index);
      if (scalar < 0x21 || scalar > 0x7e) {
        throw new IllegalArgumentException(field + " must use visible ASCII");
      }
    }
    return value;
  }

  private static String hash(String value, String field) {
    Objects.requireNonNull(value, field);
    if (value.length() != 64) {
      throw new IllegalArgumentException(field + " must be lowercase SHA-256");
    }
    for (int index = 0; index < value.length(); index++) {
      char scalar = value.charAt(index);
      if (!((scalar >= '0' && scalar <= '9') || (scalar >= 'a' && scalar <= 'f'))) {
        throw new IllegalArgumentException(field + " must be lowercase SHA-256");
      }
    }
    return value;
  }
}
