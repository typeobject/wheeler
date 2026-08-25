package com.typeobject.wheeler.packageformat;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.Objects;

/** One immutable, uncompressed application capsule entry. */
public final class CapsuleEntry {
  public static final int REQUIRED = 1;
  public static final int STARTUP = 2;
  static final int FLAG_MASK = REQUIRED | STARTUP;
  static final int MAX_ENTRY_BYTES = 16 * 1024 * 1024;
  static final int MAX_ALIGNMENT = 65_536;

  private final Kind kind;
  private final String name;
  private final String identity;
  private final int alignment;
  private final int flags;
  private final byte[] bytes;

  public CapsuleEntry(Kind kind, String name, int alignment, int flags, byte[] bytes) {
    this(kind, name, boundedIdentity(bytes), alignment, flags, bytes);
  }

  CapsuleEntry(
      Kind kind,
      String name,
      String identity,
      int alignment,
      int flags,
      byte[] bytes) {
    this.kind = Objects.requireNonNull(kind, "kind");
    this.name = CapsuleRoot.requirePath(name, "entry name");
    CapsuleRoot.requireHash(identity, "entry");
    if (bytes == null) {
      throw new PackageFormatException("Capsule entry bytes are required");
    }
    validateDescriptor(kind, alignment, flags, bytes.length);
    String actualIdentity = identity(bytes);
    if (!actualIdentity.equals(identity)) {
      throw new PackageFormatException("Capsule entry identity mismatch");
    }
    this.identity = identity;
    this.alignment = alignment;
    this.flags = flags;
    this.bytes = bytes.clone();
  }

  public Kind kind() {
    return kind;
  }

  public String name() {
    return name;
  }

  public String identity() {
    return identity;
  }

  public int alignment() {
    return alignment;
  }

  public int flags() {
    return flags;
  }

  public byte[] bytes() {
    return bytes.clone();
  }

  int length() {
    return bytes.length;
  }

  @Override
  public boolean equals(Object other) {
    return other instanceof CapsuleEntry entry
        && kind == entry.kind
        && name.equals(entry.name)
        && identity.equals(entry.identity)
        && alignment == entry.alignment
        && flags == entry.flags
        && Arrays.equals(bytes, entry.bytes);
  }

  @Override
  public int hashCode() {
    int result = Objects.hash(kind, name, identity, alignment, flags);
    return 31 * result + Arrays.hashCode(bytes);
  }

  static void validateDescriptor(Kind kind, int alignment, int flags, int length) {
    if (alignment <= 0
        || alignment > MAX_ALIGNMENT
        || (alignment & (alignment - 1)) != 0) {
      throw new PackageFormatException("Invalid capsule entry alignment");
    }
    if (flags < 0 || (flags & ~FLAG_MASK) != 0) {
      throw new PackageFormatException("Invalid capsule entry flags");
    }
    if ((flags & STARTUP) != 0 && kind != Kind.WBC) {
      throw new PackageFormatException("Only WBC entries may be startup entries");
    }
    if (length < 0 || length > MAX_ENTRY_BYTES || kind == Kind.WBC && length == 0) {
      throw new PackageFormatException("Invalid capsule entry bytes");
    }
  }

  static String identity(byte[] bytes) {
    if (bytes == null) {
      throw new PackageFormatException("Capsule entry bytes are required");
    }
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static String boundedIdentity(byte[] bytes) {
    if (bytes == null || bytes.length > MAX_ENTRY_BYTES) {
      throw new PackageFormatException("Invalid capsule entry bytes");
    }
    return identity(bytes);
  }

  public enum Kind {
    WBC(0),
    RESOURCE(1),
    PROOF(2),
    NATIVE_PROVIDER(3),
    PROVENANCE(4);

    private final int code;

    Kind(int code) {
      this.code = code;
    }

    int code() {
      return code;
    }

    static Kind fromCode(int code) {
      for (Kind kind : values()) {
        if (kind.code == code) {
          return kind;
        }
      }
      throw new PackageFormatException("Unknown capsule entry kind " + code);
    }
  }
}
