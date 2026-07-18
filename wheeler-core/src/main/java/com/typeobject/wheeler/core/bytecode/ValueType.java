package com.typeobject.wheeler.core.bytecode;

import java.util.Locale;

/** Canonical register type reference; aggregate references carry a type-table ID. */
public record ValueType(Kind kind, int descriptorId) {
  public static final ValueType SIGNED = new ValueType(Kind.SIGNED, -1);
  public static final ValueType BOOLEAN = new ValueType(Kind.BOOLEAN, -1);
  private static final int RECORD_TAG = 0x1000_0000;
  private static final int VARIANT_TAG = 0x2000_0000;

  public ValueType {
    if (kind == null
        || ((kind == Kind.RECORD || kind == Kind.VARIANT)
            && (descriptorId < 0 || descriptorId > 0x0fff_ffff))
        || ((kind == Kind.SIGNED || kind == Kind.BOOLEAN) && descriptorId != -1)) {
      throw new IllegalArgumentException("Invalid register type reference");
    }
  }

  public static ValueType record(int descriptorId) {
    return new ValueType(Kind.RECORD, descriptorId);
  }

  public static ValueType variant(int descriptorId) {
    return new ValueType(Kind.VARIANT, descriptorId);
  }

  public int code() {
    return switch (kind) {
      case SIGNED -> 1;
      case BOOLEAN -> 2;
      case RECORD -> RECORD_TAG | descriptorId;
      case VARIANT -> VARIANT_TAG | descriptorId;
    };
  }

  public String displayName() {
    return switch (kind) {
      case RECORD -> "record#" + descriptorId;
      case VARIANT -> "variant#" + descriptorId;
      case SIGNED, BOOLEAN -> kind.name().toLowerCase(Locale.ROOT);
    };
  }

  public static ValueType fromCode(int code) {
    if (code == 1) {
      return SIGNED;
    }
    if (code == 2) {
      return BOOLEAN;
    }
    if ((code & 0xf000_0000) == RECORD_TAG) {
      return record(code & 0x0fff_ffff);
    }
    if ((code & 0xf000_0000) == VARIANT_TAG) {
      return variant(code & 0x0fff_ffff);
    }
    throw new BytecodeException("Unsupported local register type " + code);
  }

  public enum Kind {
    SIGNED,
    BOOLEAN,
    RECORD,
    VARIANT
  }
}
