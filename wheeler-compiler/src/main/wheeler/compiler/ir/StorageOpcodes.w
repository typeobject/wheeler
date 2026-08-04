//! Defines aggregate, affine storage, text, and map opcode identities.

module wheeler.compiler.storage_opcodes;

classical class StorageOpcodes {
  /// Names the compile-time `OPCODE_RECORD_NEW` value owned by this module.
  public const long OPCODE_RECORD_NEW = 0x0500;
  /// Names the compile-time `OPCODE_RECORD_GET` value owned by this module.
  public const long OPCODE_RECORD_GET = 0x0501;
  /// Names the compile-time `OPCODE_VARIANT_NEW` value owned by this module.
  public const long OPCODE_VARIANT_NEW = 0x0510;
  /// Names the compile-time `OPCODE_VARIANT_TAG_EQ` value owned by this module.
  public const long OPCODE_VARIANT_TAG_EQ = 0x0511;
  /// Names the compile-time `OPCODE_VARIANT_GET` value owned by this module.
  public const long OPCODE_VARIANT_GET = 0x0512;
  /// Names the compile-time `OPCODE_ARRAY_NEW` value owned by this module.
  public const long OPCODE_ARRAY_NEW = 0x0520;
  /// Names the compile-time `OPCODE_ARRAY_GET` value owned by this module.
  public const long OPCODE_ARRAY_GET = 0x0521;
  /// Names the compile-time `OPCODE_SLICE_NEW` value owned by this module.
  public const long OPCODE_SLICE_NEW = 0x0530;
  /// Names the compile-time `OPCODE_SLICE_GET` value owned by this module.
  public const long OPCODE_SLICE_GET = 0x0531;
  /// Names the compile-time `OPCODE_OWNED_MOVE` value owned by this module.
  public const long OPCODE_OWNED_MOVE = 0x0540;
  /// Names the compile-time `OPCODE_REGION_NEW` value owned by this module.
  public const long OPCODE_REGION_NEW = 0x0541;
  /// Names the compile-time `OPCODE_WORDS_ALLOC` value owned by this module.
  public const long OPCODE_WORDS_ALLOC = 0x0542;
  /// Names the compile-time `OPCODE_WORDS_GET` value owned by this module.
  public const long OPCODE_WORDS_GET = 0x0543;
  /// Names the compile-time `OPCODE_WORDS_SET` value owned by this module.
  public const long OPCODE_WORDS_SET = 0x0544;
  /// Names the compile-time `OPCODE_BUFFER_DROP` value owned by this module.
  public const long OPCODE_BUFFER_DROP = 0x0545;
  /// Names the compile-time `OPCODE_REGION_DROP` value owned by this module.
  public const long OPCODE_REGION_DROP = 0x0546;
  /// Names the compile-time `OPCODE_BYTES_ALLOC` value owned by this module.
  public const long OPCODE_BYTES_ALLOC = 0x0547;
  /// Names the compile-time `OPCODE_BYTES_GET` value owned by this module.
  public const long OPCODE_BYTES_GET = 0x0548;
  /// Names the compile-time `OPCODE_BYTES_SET` value owned by this module.
  public const long OPCODE_BYTES_SET = 0x0549;
  /// Names the compile-time `OPCODE_UTF8_VALID` value owned by this module.
  public const long OPCODE_UTF8_VALID = 0x054a;
  /// Names the compile-time `OPCODE_UTF8_COUNT` value owned by this module.
  public const long OPCODE_UTF8_COUNT = 0x054b;
  /// Names the compile-time `OPCODE_BUFFER_LENGTH` value owned by this module.
  public const long OPCODE_BUFFER_LENGTH = 0x054c;
  /// Names the compile-time `OPCODE_UTF8_SCALAR` value owned by this module.
  public const long OPCODE_UTF8_SCALAR = 0x054d;
  /// Names the compile-time `OPCODE_UTF8_WIDTH` value owned by this module.
  public const long OPCODE_UTF8_WIDTH = 0x054e;
  /// Names the compile-time `OPCODE_MAP_ALLOC` value owned by this module.
  public const long OPCODE_MAP_ALLOC = 0x054f;
  /// Names the compile-time `OPCODE_MAP_PUT` value owned by this module.
  public const long OPCODE_MAP_PUT = 0x0550;
  /// Names the compile-time `OPCODE_MAP_GET` value owned by this module.
  public const long OPCODE_MAP_GET = 0x0551;
  /// Names the compile-time `OPCODE_MAP_HAS` value owned by this module.
  public const long OPCODE_MAP_HAS = 0x0552;
  /// Names the compile-time `OPCODE_UTF8_FREEZE` value owned by this module.
  public const long OPCODE_UTF8_FREEZE = 0x0553;
  /// Names the compile-time `OPCODE_UTF8_BORROW` value owned by this module.
  public const long OPCODE_UTF8_BORROW = 0x0554;
  /// Names the compile-time `OPCODE_MAP_BORROW` value owned by this module.
  public const long OPCODE_MAP_BORROW = 0x0555;
  /// Names the compile-time `OPCODE_BUFFER_BORROW` value owned by this module.
  public const long OPCODE_BUFFER_BORROW = 0x0556;
  /// Names the compile-time `OPCODE_REGION_BORROW` value owned by this module.
  public const long OPCODE_REGION_BORROW = 0x0557;
}
