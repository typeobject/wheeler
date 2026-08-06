//! Defines canonical scalar type codes for Wheeler-written bytecode tools.
module wheeler.compiler.type_codes;

classical class TypeCodes {
  /// Names the compile-time `TYPE_SIGNED` value owned by this module.
  public const long TYPE_SIGNED = 1;
  /// Names the compile-time `TYPE_BOOLEAN` value owned by this module.
  public const long TYPE_BOOLEAN = 2;
  /// Names the compile-time `TYPE_REGION` value owned by this module.
  public const long TYPE_REGION = 3;
  /// Names the compile-time `TYPE_WORDS` value owned by this module.
  public const long TYPE_WORDS = 4;
  /// Names the compile-time `TYPE_BYTES` value owned by this module.
  public const long TYPE_BYTES = 5;
  /// Names the compile-time `TYPE_LONG_MAP` value owned by this module.
  public const long TYPE_LONG_MAP = 6;
  /// Names the compile-time `TYPE_UTF8` value owned by this module.
  public const long TYPE_UTF8 = 7;
  /// Names the compile-time `TYPE_UTF8_BORROW` value owned by this module.
  public const long TYPE_UTF8_BORROW = 8;
  /// Names the compile-time `TYPE_LONG_MAP_BORROW` value owned by this module.
  public const long TYPE_LONG_MAP_BORROW = 9;
  /// Names the compile-time `TYPE_WORDS_BORROW` value owned by this module.
  public const long TYPE_WORDS_BORROW = 10;
  /// Names the compile-time `TYPE_BYTES_BORROW` value owned by this module.
  public const long TYPE_BYTES_BORROW = 11;
  /// Names the compile-time `TYPE_REGION_BORROW` value owned by this module.
  public const long TYPE_REGION_BORROW = 12;
  /// Names the compile-time `TYPE_BYTE_VIEW` value owned by this module.
  public const long TYPE_BYTE_VIEW = 13;
  /// Names the one-value `Done` completion type.
  public const long TYPE_DONE = 14;
  /// Names the compile-time `TYPE_DESCRIPTOR_MASK` value owned by this module.
  public const long TYPE_DESCRIPTOR_MASK = 0x0fffffff;
  /// Names the compile-time `TYPE_KIND_MASK` value owned by this module.
  public const long TYPE_KIND_MASK = 0xf0000000;
  /// Names the compile-time `TYPE_RECORD` value owned by this module.
  public const long TYPE_RECORD = 0x10000000;
  /// Names the compile-time `TYPE_VARIANT` value owned by this module.
  public const long TYPE_VARIANT = 0x20000000;
  /// Names the compile-time `TYPE_ARRAY` value owned by this module.
  public const long TYPE_ARRAY = 0x30000000;
  /// Names the compile-time `TYPE_SLICE` value owned by this module.
  public const long TYPE_SLICE = 0x40000000;
  /// Keeps bounded source-only array lengths above the canonical 32-bit code.
  public const long TYPE_SOURCE_METADATA_SCALE = 4294967296;
  /// Caps each native fixed array at the machine's local bound.
  public const long MAX_NATIVE_FIXED_ARRAY_LENGTH = 64;
  /// Caps unique encounter-ordered fixed-array descriptors in one module graph.
  public const long MAX_NATIVE_FIXED_ARRAY_TYPES = 16;
}
