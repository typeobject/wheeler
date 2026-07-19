package com.typeobject.wheeler.core.bytecode;

import java.util.Locale;

/** Canonical register type reference; aggregate references carry a type-table ID. */
public record ValueType(Kind kind, int descriptorId) {
  public static final ValueType SIGNED = new ValueType(Kind.SIGNED, -1);
  public static final ValueType BOOLEAN = new ValueType(Kind.BOOLEAN, -1);
  public static final ValueType REGION = new ValueType(Kind.REGION, -1);
  public static final ValueType WORDS = new ValueType(Kind.WORDS, -1);
  public static final ValueType BYTES = new ValueType(Kind.BYTES, -1);
  public static final ValueType LONG_MAP = new ValueType(Kind.LONG_MAP, -1);
  public static final ValueType UTF8 = new ValueType(Kind.UTF8, -1);
  public static final ValueType UTF8_BORROW = new ValueType(Kind.UTF8_BORROW, -1);
  public static final ValueType LONG_MAP_BORROW =
      new ValueType(Kind.LONG_MAP_BORROW, -1);
  public static final ValueType WORDS_BORROW = new ValueType(Kind.WORDS_BORROW, -1);
  public static final ValueType BYTES_BORROW = new ValueType(Kind.BYTES_BORROW, -1);
  public static final ValueType REGION_BORROW = new ValueType(Kind.REGION_BORROW, -1);
  public static final ValueType BYTE_VIEW = new ValueType(Kind.BYTE_VIEW, -1);
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
            || kind == Kind.REGION || kind == Kind.WORDS || kind == Kind.BYTES
            || kind == Kind.LONG_MAP || kind == Kind.UTF8 || kind == Kind.UTF8_BORROW || kind == Kind.LONG_MAP_BORROW || kind == Kind.WORDS_BORROW
            || kind == Kind.BYTES_BORROW || kind == Kind.REGION_BORROW
            || kind == Kind.BYTE_VIEW)
            && descriptorId != -1)) {
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
      case WORDS -> 4;
      case BYTES -> 5;
      case LONG_MAP -> 6;
      case UTF8 -> 7;
      case UTF8_BORROW -> 8;
      case LONG_MAP_BORROW -> 9;
      case WORDS_BORROW -> 10;
      case BYTES_BORROW -> 11;
      case REGION_BORROW -> 12;
      case BYTE_VIEW -> 13;
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
      case SIGNED, BOOLEAN, REGION, WORDS, BYTES, LONG_MAP, UTF8, UTF8_BORROW,
          LONG_MAP_BORROW, WORDS_BORROW, BYTES_BORROW, REGION_BORROW, BYTE_VIEW ->
          kind.name().toLowerCase(Locale.ROOT);
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
      return WORDS;
    }
    if (code == 5) {
      return BYTES;
    }
    if (code == 6) {
      return LONG_MAP;
    }
    if (code == 7) {
      return UTF8;
    }
    if (code == 8) {
      return UTF8_BORROW;
    }
    if (code == 9) {
      return LONG_MAP_BORROW;
    }
    if (code == 10) {
      return WORDS_BORROW;
    }
    if (code == 11) {
      return BYTES_BORROW;
    }
    if (code == 12) {
      return REGION_BORROW;
    }
    if (code == 13) {
      return BYTE_VIEW;
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
    WORDS,
    BYTES,
    LONG_MAP,
    UTF8,
    UTF8_BORROW,
    LONG_MAP_BORROW,
    WORDS_BORROW,
    BYTES_BORROW,
    REGION_BORROW,
    BYTE_VIEW,
    RECORD,
    VARIANT,
    ARRAY,
    SLICE
  }
}
