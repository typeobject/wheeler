package com.typeobject.wheeler.core.bytecode;

/** Stable numeric identities for canonical classical opcodes. */
final class OpcodeIds {
  static final int NOP = 0x0000;
  static final int HALT = 0x0001;
  static final int RETURN = 0x0002;

  static final int ADD_CONST = 0x0100;
  static final int SUB_CONST = 0x0101;
  static final int XOR_CONST = 0x0102;
  static final int SWAP = 0x0103;
  static final int SET_LOGGED = 0x0104;

  static final int CALL = 0x0200;
  static final int UNCALL = 0x0201;
  static final int CALL_VALUE = 0x0202;
  static final int RETURN_VALUE = 0x0203;
  static final int CALL_VOID = 0x0204;

  static final int EXPECT_EQ = 0x0300;
  static final int CHECKPOINT = 0x0301;
  static final int COMMIT = 0x0302;
  static final int EXPECT_TRUE = 0x0303;

  static final int LOCAL_CONST = 0x0400;
  static final int LOCAL_LOAD_GLOBAL = 0x0401;
  static final int LOCAL_STORE_GLOBAL = 0x0402;
  static final int LOCAL_MOVE = 0x0403;
  static final int LOCAL_ADD = 0x0410;
  static final int LOCAL_SUB = 0x0411;
  static final int LOCAL_XOR = 0x0412;
  static final int LOCAL_MUL = 0x0413;
  static final int LOCAL_DIV = 0x0414;
  static final int LOCAL_MOD = 0x0415;
  static final int LOCAL_AND = 0x0416;
  static final int LOCAL_ROTR32 = 0x0417;
  static final int LOCAL_EQ = 0x0420;
  static final int LOCAL_LT = 0x0421;
  static final int JUMP = 0x0430;
  static final int JUMP_IF_ZERO = 0x0431;
  static final int LOCAL_LOOP_CHECK = 0x0432;

  static final int RECORD_NEW = 0x0500;
  static final int RECORD_GET = 0x0501;
  static final int VARIANT_NEW = 0x0510;
  static final int VARIANT_TAG_EQ = 0x0511;
  static final int VARIANT_GET = 0x0512;
  static final int ARRAY_NEW = 0x0520;
  static final int ARRAY_GET = 0x0521;
  static final int SLICE_NEW = 0x0530;
  static final int SLICE_GET = 0x0531;

  static final int OWNED_MOVE = 0x0540;
  static final int REGION_NEW = 0x0541;
  static final int WORDS_ALLOC = 0x0542;
  static final int WORDS_GET = 0x0543;
  static final int WORDS_SET = 0x0544;
  static final int BUFFER_DROP = 0x0545;
  static final int REGION_DROP = 0x0546;
  static final int BYTES_ALLOC = 0x0547;
  static final int BYTES_GET = 0x0548;
  static final int BYTES_SET = 0x0549;
  static final int UTF8_VALID = 0x054a;
  static final int UTF8_COUNT = 0x054b;
  static final int BUFFER_LENGTH = 0x054c;
  static final int UTF8_SCALAR = 0x054d;
  static final int UTF8_WIDTH = 0x054e;
  static final int MAP_ALLOC = 0x054f;
  static final int MAP_PUT = 0x0550;
  static final int MAP_GET = 0x0551;
  static final int MAP_HAS = 0x0552;
  static final int UTF8_FREEZE = 0x0553;
  static final int UTF8_BORROW = 0x0554;
  static final int MAP_BORROW = 0x0555;
  static final int BUFFER_BORROW = 0x0556;
  static final int REGION_BORROW = 0x0557;
  static final int OUTPUT_LENGTH = 0x0558;

  private OpcodeIds() {}
}
