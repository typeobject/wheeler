package com.typeobject.wheeler.core.bytecode;

import java.util.Locale;

/** Canonical register type reference; aggregate references carry a type-table ID. */
public record ValueType(Kind kind, int descriptorId) {
  public static final ValueType SIGNED = new ValueType(Kind.SIGNED, -1);
  public static final ValueType BOOLEAN = new ValueType(Kind.BOOLEAN, -1);
  public static final ValueType REGION = new ValueType(Kind.REGION, -1);
  public static final ValueType BUFFER = new ValueType(Kind.BUFFER, -1);
  private static final int RECORD_TAG = 0x1000_0000;
  private static final int VARIANT_TAG = 0x2000_0000;
  private static final int ARRAY_TAG = 0x3000_0000;
  private static final int SLICE_TAG = 0x4000_0000;

  public ValueType {
    if (kind == null
        || ((kind == Kind.RECORD || kind == Kind.VARIANT
            || kind == Kind.ARRAY || kind == Kind.SLICE)
            && (descriptorId < 0 || descriptorId > 0x0fff_ffff))
        || ((kind == Kind.SIGNED || kind == Kind.BOOLEAN
            || kind == Kind.REGION || kind == Kind.BUFFER) && descriptorId != -1)) {
      throw new IllegalArgumentException("Invalid register type reference");
    }
  }

  public static ValueType record(int descriptorId) {
    return new ValueType(Kind.RECORD, descriptorId);
  }

  public static ValueType variant(int descriptorId) {
    return new ValueType(Kind.VARIANT, descriptorId);
  }

  public static ValueType array(int descriptorId) {
    return new ValueType(Kind.ARRAY, descriptorId);
  }

  public static ValueType slice(int descriptorId) {
    return new ValueType(Kind.SLICE, descriptorId);
  }

  public int code() {
    return switch (kind) {
      case SIGNED -> 1;
      case BOOLEAN -> 2;
      case REGION -> 3;
      case BUFFER -> 4;
      case RECORD -> RECORD_TAG | descriptorId;
      case VARIANT -> VARIANT_TAG | descriptorId;
      case ARRAY -> ARRAY_TAG | descriptorId;
      case SLICE -> SLICE_TAG | descriptorId;
    };
  }

  public String displayName() {
    return switch (kind) {
      case RECORD -> "record#" + descriptorId;
      case VARIANT -> "variant#" + descriptorId;
      case ARRAY -> "array#" + descriptorId;
      case SLICE -> "slice#" + descriptorId;
      case SIGNED, BOOLEAN, REGION, BUFFER -> kind.name().toLowerCase(Locale.ROOT);
    };
  }

  public static ValueType fromCode(int code) {
    if (code == 1) {
      return SIGNED;
    }
    if (code == 2) {
      return BOOLEAN;
    }
    if (code == 3) {
      return REGION;
    }
    if (code == 4) {
      return BUFFER;
    }
    if ((code & 0xf000_0000) == RECORD_TAG) {
      return record(code & 0x0fff_ffff);
    }
    if ((code & 0xf000_0000) == VARIANT_TAG) {
      return variant(code & 0x0fff_ffff);
    }
    if ((code & 0xf000_0000) == ARRAY_TAG) {
      return array(code & 0x0fff_ffff);
    }
    if ((code & 0xf000_0000) == SLICE_TAG) {
      return slice(code & 0x0fff_ffff);
    }
    throw new BytecodeException("Unsupported local register type " + code);
  }

  public enum Kind {
    SIGNED,
    BOOLEAN,
    REGION,
    BUFFER,
    RECORD,
    VARIANT,
    ARRAY,
    SLICE
  }
}
