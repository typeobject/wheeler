//! Generated instruction-registry view. Do not edit this module.

module wheeler.compiler.generated_instruction_registry;

classical class GeneratedInstructionRegistry {
  /// `INTRINSIC` reversibility.
  public const long REVERSIBILITY_INTRINSIC = 0;
  /// `CHECKED` reversibility.
  public const long REVERSIBILITY_CHECKED = 1;
  /// `LOGGED` reversibility.
  public const long REVERSIBILITY_LOGGED = 2;
  /// `BARRIER` reversibility.
  public const long REVERSIBILITY_BARRIER = 3;

  /// `ALLOCATION_LIMIT` operand role.
  public const long ROLE_ALLOCATION_LIMIT = 1;
  /// `ARGUMENT_BASE` operand role.
  public const long ROLE_ARGUMENT_BASE = 2;
  /// `ARGUMENT_COUNT` operand role.
  public const long ROLE_ARGUMENT_COUNT = 3;
  /// `CAPACITY` operand role.
  public const long ROLE_CAPACITY = 4;
  /// `CONDITION` operand role.
  public const long ROLE_CONDITION = 5;
  /// `DESCRIPTOR` operand role.
  public const long ROLE_DESCRIPTOR = 6;
  /// `DESTINATION` operand role.
  public const long ROLE_DESTINATION = 7;
  /// `ELEMENT_BASE` operand role.
  public const long ROLE_ELEMENT_BASE = 8;
  /// `ELEMENT_COUNT` operand role.
  public const long ROLE_ELEMENT_COUNT = 9;
  /// `FUNCTION` operand role.
  public const long ROLE_FUNCTION = 10;
  /// `GLOBAL` operand role.
  public const long ROLE_GLOBAL = 11;
  /// `IMMEDIATE` operand role.
  public const long ROLE_IMMEDIATE = 12;
  /// `INDEX` operand role.
  public const long ROLE_INDEX = 13;
  /// `ITERATION` operand role.
  public const long ROLE_ITERATION = 14;
  /// `KEY` operand role.
  public const long ROLE_KEY = 15;
  /// `LEFT_GLOBAL` operand role.
  public const long ROLE_LEFT_GLOBAL = 16;
  /// `LEFT_SOURCE` operand role.
  public const long ROLE_LEFT_SOURCE = 17;
  /// `LENGTH` operand role.
  public const long ROLE_LENGTH = 18;
  /// `LIMIT` operand role.
  public const long ROLE_LIMIT = 19;
  /// `LOCAL` operand role.
  public const long ROLE_LOCAL = 20;
  /// `OPERATION` operand role.
  public const long ROLE_OPERATION = 21;
  /// `OWNER` operand role.
  public const long ROLE_OWNER = 22;
  /// `RESULT` operand role.
  public const long ROLE_RESULT = 23;
  /// `RESULT_SLOT` operand role.
  public const long ROLE_RESULT_SLOT = 24;
  /// `RIGHT_GLOBAL` operand role.
  public const long ROLE_RIGHT_GLOBAL = 25;
  /// `RIGHT_SOURCE` operand role.
  public const long ROLE_RIGHT_SOURCE = 26;
  /// `SOURCE` operand role.
  public const long ROLE_SOURCE = 27;
  /// `START` operand role.
  public const long ROLE_START = 28;
  /// `TAG` operand role.
  public const long ROLE_TAG = 29;
  /// `TARGET` operand role.
  public const long ROLE_TARGET = 30;

  /// `NOP` opcode identity.
  public const long OPCODE_NOP = 0x0000;
  /// `NOP` operand count.
  public const long OPCODE_NOP_OPERAND_COUNT = 0;
  /// `NOP` packed operand roles.
  public const long OPCODE_NOP_ROLE_FORM = 0x0;
  /// `NOP` reversibility.
  public const long OPCODE_NOP_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// `HALT` opcode identity.
  public const long OPCODE_HALT = 0x0001;
  /// `HALT` operand count.
  public const long OPCODE_HALT_OPERAND_COUNT = 0;
  /// `HALT` packed operand roles.
  public const long OPCODE_HALT_ROLE_FORM = 0x0;
  /// `HALT` reversibility.
  public const long OPCODE_HALT_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `RETURN` opcode identity.
  public const long OPCODE_RETURN = 0x0002;
  /// `RETURN` operand count.
  public const long OPCODE_RETURN_OPERAND_COUNT = 0;
  /// `RETURN` packed operand roles.
  public const long OPCODE_RETURN_ROLE_FORM = 0x0;
  /// `RETURN` reversibility.
  public const long OPCODE_RETURN_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `ADD_CONST` opcode identity.
  public const long OPCODE_ADD_CONST = 0x0100;
  /// `ADD_CONST` operand count.
  public const long OPCODE_ADD_CONST_OPERAND_COUNT = 2;
  /// `ADD_CONST` packed operand roles.
  public const long OPCODE_ADD_CONST_ROLE_FORM = 0x18b;
  /// `ADD_CONST` reversibility.
  public const long OPCODE_ADD_CONST_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// `SUB_CONST` opcode identity.
  public const long OPCODE_SUB_CONST = 0x0101;
  /// `SUB_CONST` operand count.
  public const long OPCODE_SUB_CONST_OPERAND_COUNT = 2;
  /// `SUB_CONST` packed operand roles.
  public const long OPCODE_SUB_CONST_ROLE_FORM = 0x18b;
  /// `SUB_CONST` reversibility.
  public const long OPCODE_SUB_CONST_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// `XOR_CONST` opcode identity.
  public const long OPCODE_XOR_CONST = 0x0102;
  /// `XOR_CONST` operand count.
  public const long OPCODE_XOR_CONST_OPERAND_COUNT = 2;
  /// `XOR_CONST` packed operand roles.
  public const long OPCODE_XOR_CONST_ROLE_FORM = 0x18b;
  /// `XOR_CONST` reversibility.
  public const long OPCODE_XOR_CONST_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// `SWAP` opcode identity.
  public const long OPCODE_SWAP = 0x0103;
  /// `SWAP` operand count.
  public const long OPCODE_SWAP_OPERAND_COUNT = 2;
  /// `SWAP` packed operand roles.
  public const long OPCODE_SWAP_ROLE_FORM = 0x330;
  /// `SWAP` reversibility.
  public const long OPCODE_SWAP_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// `SET_LOGGED` opcode identity.
  public const long OPCODE_SET_LOGGED = 0x0104;
  /// `SET_LOGGED` operand count.
  public const long OPCODE_SET_LOGGED_OPERAND_COUNT = 2;
  /// `SET_LOGGED` packed operand roles.
  public const long OPCODE_SET_LOGGED_ROLE_FORM = 0x18b;
  /// `SET_LOGGED` reversibility.
  public const long OPCODE_SET_LOGGED_REVERSIBILITY = REVERSIBILITY_LOGGED;

  /// `CALL` opcode identity.
  public const long OPCODE_CALL = 0x0200;
  /// `CALL` operand count.
  public const long OPCODE_CALL_OPERAND_COUNT = 1;
  /// `CALL` packed operand roles.
  public const long OPCODE_CALL_ROLE_FORM = 0xa;
  /// `CALL` reversibility.
  public const long OPCODE_CALL_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `UNCALL` opcode identity.
  public const long OPCODE_UNCALL = 0x0201;
  /// `UNCALL` operand count.
  public const long OPCODE_UNCALL_OPERAND_COUNT = 1;
  /// `UNCALL` packed operand roles.
  public const long OPCODE_UNCALL_ROLE_FORM = 0xa;
  /// `UNCALL` reversibility.
  public const long OPCODE_UNCALL_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `CALL_VALUE` opcode identity.
  public const long OPCODE_CALL_VALUE = 0x0202;
  /// `CALL_VALUE` operand count.
  public const long OPCODE_CALL_VALUE_OPERAND_COUNT = 4;
  /// `CALL_VALUE` packed operand roles.
  public const long OPCODE_CALL_VALUE_ROLE_FORM = 0xb8c4a;
  /// `CALL_VALUE` reversibility.
  public const long OPCODE_CALL_VALUE_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `RETURN_VALUE` opcode identity.
  public const long OPCODE_RETURN_VALUE = 0x0203;
  /// `RETURN_VALUE` operand count.
  public const long OPCODE_RETURN_VALUE_OPERAND_COUNT = 1;
  /// `RETURN_VALUE` packed operand roles.
  public const long OPCODE_RETURN_VALUE_ROLE_FORM = 0x17;
  /// `RETURN_VALUE` reversibility.
  public const long OPCODE_RETURN_VALUE_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `CALL_VOID` opcode identity.
  public const long OPCODE_CALL_VOID = 0x0204;
  /// `CALL_VOID` operand count.
  public const long OPCODE_CALL_VOID_OPERAND_COUNT = 3;
  /// `CALL_VOID` packed operand roles.
  public const long OPCODE_CALL_VOID_ROLE_FORM = 0xc4a;
  /// `CALL_VOID` reversibility.
  public const long OPCODE_CALL_VOID_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `CALL_RESULT_SLOT` opcode identity.
  public const long OPCODE_CALL_RESULT_SLOT = 0x0205;
  /// `CALL_RESULT_SLOT` operand count.
  public const long OPCODE_CALL_RESULT_SLOT_OPERAND_COUNT = 4;
  /// `CALL_RESULT_SLOT` packed operand roles.
  public const long OPCODE_CALL_RESULT_SLOT_ROLE_FORM = 0xc0c4a;
  /// `CALL_RESULT_SLOT` reversibility.
  public const long OPCODE_CALL_RESULT_SLOT_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `UNCALL_RESULT_SLOT` opcode identity.
  public const long OPCODE_UNCALL_RESULT_SLOT = 0x0206;
  /// `UNCALL_RESULT_SLOT` operand count.
  public const long OPCODE_UNCALL_RESULT_SLOT_OPERAND_COUNT = 4;
  /// `UNCALL_RESULT_SLOT` packed operand roles.
  public const long OPCODE_UNCALL_RESULT_SLOT_ROLE_FORM = 0xc0c4a;
  /// `UNCALL_RESULT_SLOT` reversibility.
  public const long OPCODE_UNCALL_RESULT_SLOT_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `RESULT_FILL_CONSTANT` opcode identity.
  public const long OPCODE_RESULT_FILL_CONSTANT = 0x0207;
  /// `RESULT_FILL_CONSTANT` operand count.
  public const long OPCODE_RESULT_FILL_CONSTANT_OPERAND_COUNT = 2;
  /// `RESULT_FILL_CONSTANT` packed operand roles.
  public const long OPCODE_RESULT_FILL_CONSTANT_ROLE_FORM = 0x198;
  /// `RESULT_FILL_CONSTANT` reversibility.
  public const long OPCODE_RESULT_FILL_CONSTANT_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// `RETURN_RESULT_SLOT` opcode identity.
  public const long OPCODE_RETURN_RESULT_SLOT = 0x0208;
  /// `RETURN_RESULT_SLOT` operand count.
  public const long OPCODE_RETURN_RESULT_SLOT_OPERAND_COUNT = 1;
  /// `RETURN_RESULT_SLOT` packed operand roles.
  public const long OPCODE_RETURN_RESULT_SLOT_ROLE_FORM = 0x18;
  /// `RETURN_RESULT_SLOT` reversibility.
  public const long OPCODE_RETURN_RESULT_SLOT_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `RESULT_FILL_SOURCE` opcode identity.
  public const long OPCODE_RESULT_FILL_SOURCE = 0x0209;
  /// `RESULT_FILL_SOURCE` operand count.
  public const long OPCODE_RESULT_FILL_SOURCE_OPERAND_COUNT = 2;
  /// `RESULT_FILL_SOURCE` packed operand roles.
  public const long OPCODE_RESULT_FILL_SOURCE_ROLE_FORM = 0x378;
  /// `RESULT_FILL_SOURCE` reversibility.
  public const long OPCODE_RESULT_FILL_SOURCE_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// `RESULT_FILL_BINARY` opcode identity.
  public const long OPCODE_RESULT_FILL_BINARY = 0x020a;
  /// `RESULT_FILL_BINARY` operand count.
  public const long OPCODE_RESULT_FILL_BINARY_OPERAND_COUNT = 4;
  /// `RESULT_FILL_BINARY` packed operand roles.
  public const long OPCODE_RESULT_FILL_BINARY_ROLE_FORM = 0x65778;
  /// `RESULT_FILL_BINARY` reversibility.
  public const long OPCODE_RESULT_FILL_BINARY_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// `RESULT_FILL_BINARY_SOURCES` opcode identity.
  public const long OPCODE_RESULT_FILL_BINARY_SOURCES = 0x020b;
  /// `RESULT_FILL_BINARY_SOURCES` operand count.
  public const long OPCODE_RESULT_FILL_BINARY_SOURCES_OPERAND_COUNT = 4;
  /// `RESULT_FILL_BINARY_SOURCES` packed operand roles.
  public const long OPCODE_RESULT_FILL_BINARY_SOURCES_ROLE_FORM = 0xd5778;
  /// `RESULT_FILL_BINARY_SOURCES` reversibility.
  public const long OPCODE_RESULT_FILL_BINARY_SOURCES_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// `EXPECT_EQ` opcode identity.
  public const long OPCODE_EXPECT_EQ = 0x0300;
  /// `EXPECT_EQ` operand count.
  public const long OPCODE_EXPECT_EQ_OPERAND_COUNT = 2;
  /// `EXPECT_EQ` packed operand roles.
  public const long OPCODE_EXPECT_EQ_ROLE_FORM = 0x18b;
  /// `EXPECT_EQ` reversibility.
  public const long OPCODE_EXPECT_EQ_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `CHECKPOINT` opcode identity.
  public const long OPCODE_CHECKPOINT = 0x0301;
  /// `CHECKPOINT` operand count.
  public const long OPCODE_CHECKPOINT_OPERAND_COUNT = 0;
  /// `CHECKPOINT` packed operand roles.
  public const long OPCODE_CHECKPOINT_ROLE_FORM = 0x0;
  /// `CHECKPOINT` reversibility.
  public const long OPCODE_CHECKPOINT_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// `COMMIT` opcode identity.
  public const long OPCODE_COMMIT = 0x0302;
  /// `COMMIT` operand count.
  public const long OPCODE_COMMIT_OPERAND_COUNT = 0;
  /// `COMMIT` packed operand roles.
  public const long OPCODE_COMMIT_ROLE_FORM = 0x0;
  /// `COMMIT` reversibility.
  public const long OPCODE_COMMIT_REVERSIBILITY = REVERSIBILITY_BARRIER;

  /// `EXPECT_TRUE` opcode identity.
  public const long OPCODE_EXPECT_TRUE = 0x0303;
  /// `EXPECT_TRUE` operand count.
  public const long OPCODE_EXPECT_TRUE_OPERAND_COUNT = 1;
  /// `EXPECT_TRUE` packed operand roles.
  public const long OPCODE_EXPECT_TRUE_ROLE_FORM = 0x5;
  /// `EXPECT_TRUE` reversibility.
  public const long OPCODE_EXPECT_TRUE_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_CONST` opcode identity.
  public const long OPCODE_LOCAL_CONST = 0x0400;
  /// `LOCAL_CONST` operand count.
  public const long OPCODE_LOCAL_CONST_OPERAND_COUNT = 2;
  /// `LOCAL_CONST` packed operand roles.
  public const long OPCODE_LOCAL_CONST_ROLE_FORM = 0x187;
  /// `LOCAL_CONST` reversibility.
  public const long OPCODE_LOCAL_CONST_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_LOAD_GLOBAL` opcode identity.
  public const long OPCODE_LOCAL_LOAD_GLOBAL = 0x0401;
  /// `LOCAL_LOAD_GLOBAL` operand count.
  public const long OPCODE_LOCAL_LOAD_GLOBAL_OPERAND_COUNT = 2;
  /// `LOCAL_LOAD_GLOBAL` packed operand roles.
  public const long OPCODE_LOCAL_LOAD_GLOBAL_ROLE_FORM = 0x167;
  /// `LOCAL_LOAD_GLOBAL` reversibility.
  public const long OPCODE_LOCAL_LOAD_GLOBAL_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_STORE_GLOBAL` opcode identity.
  public const long OPCODE_LOCAL_STORE_GLOBAL = 0x0402;
  /// `LOCAL_STORE_GLOBAL` operand count.
  public const long OPCODE_LOCAL_STORE_GLOBAL_OPERAND_COUNT = 2;
  /// `LOCAL_STORE_GLOBAL` packed operand roles.
  public const long OPCODE_LOCAL_STORE_GLOBAL_ROLE_FORM = 0x36b;
  /// `LOCAL_STORE_GLOBAL` reversibility.
  public const long OPCODE_LOCAL_STORE_GLOBAL_REVERSIBILITY = REVERSIBILITY_LOGGED;

  /// `LOCAL_MOVE` opcode identity.
  public const long OPCODE_LOCAL_MOVE = 0x0403;
  /// `LOCAL_MOVE` operand count.
  public const long OPCODE_LOCAL_MOVE_OPERAND_COUNT = 2;
  /// `LOCAL_MOVE` packed operand roles.
  public const long OPCODE_LOCAL_MOVE_ROLE_FORM = 0x367;
  /// `LOCAL_MOVE` reversibility.
  public const long OPCODE_LOCAL_MOVE_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_ADD` opcode identity.
  public const long OPCODE_LOCAL_ADD = 0x0410;
  /// `LOCAL_ADD` operand count.
  public const long OPCODE_LOCAL_ADD_OPERAND_COUNT = 3;
  /// `LOCAL_ADD` packed operand roles.
  public const long OPCODE_LOCAL_ADD_ROLE_FORM = 0x6a27;
  /// `LOCAL_ADD` reversibility.
  public const long OPCODE_LOCAL_ADD_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_SUB` opcode identity.
  public const long OPCODE_LOCAL_SUB = 0x0411;
  /// `LOCAL_SUB` operand count.
  public const long OPCODE_LOCAL_SUB_OPERAND_COUNT = 3;
  /// `LOCAL_SUB` packed operand roles.
  public const long OPCODE_LOCAL_SUB_ROLE_FORM = 0x6a27;
  /// `LOCAL_SUB` reversibility.
  public const long OPCODE_LOCAL_SUB_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_XOR` opcode identity.
  public const long OPCODE_LOCAL_XOR = 0x0412;
  /// `LOCAL_XOR` operand count.
  public const long OPCODE_LOCAL_XOR_OPERAND_COUNT = 3;
  /// `LOCAL_XOR` packed operand roles.
  public const long OPCODE_LOCAL_XOR_ROLE_FORM = 0x6a27;
  /// `LOCAL_XOR` reversibility.
  public const long OPCODE_LOCAL_XOR_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_MUL` opcode identity.
  public const long OPCODE_LOCAL_MUL = 0x0413;
  /// `LOCAL_MUL` operand count.
  public const long OPCODE_LOCAL_MUL_OPERAND_COUNT = 3;
  /// `LOCAL_MUL` packed operand roles.
  public const long OPCODE_LOCAL_MUL_ROLE_FORM = 0x6a27;
  /// `LOCAL_MUL` reversibility.
  public const long OPCODE_LOCAL_MUL_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_DIV` opcode identity.
  public const long OPCODE_LOCAL_DIV = 0x0414;
  /// `LOCAL_DIV` operand count.
  public const long OPCODE_LOCAL_DIV_OPERAND_COUNT = 3;
  /// `LOCAL_DIV` packed operand roles.
  public const long OPCODE_LOCAL_DIV_ROLE_FORM = 0x6a27;
  /// `LOCAL_DIV` reversibility.
  public const long OPCODE_LOCAL_DIV_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_MOD` opcode identity.
  public const long OPCODE_LOCAL_MOD = 0x0415;
  /// `LOCAL_MOD` operand count.
  public const long OPCODE_LOCAL_MOD_OPERAND_COUNT = 3;
  /// `LOCAL_MOD` packed operand roles.
  public const long OPCODE_LOCAL_MOD_ROLE_FORM = 0x6a27;
  /// `LOCAL_MOD` reversibility.
  public const long OPCODE_LOCAL_MOD_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_AND` opcode identity.
  public const long OPCODE_LOCAL_AND = 0x0416;
  /// `LOCAL_AND` operand count.
  public const long OPCODE_LOCAL_AND_OPERAND_COUNT = 3;
  /// `LOCAL_AND` packed operand roles.
  public const long OPCODE_LOCAL_AND_ROLE_FORM = 0x6a27;
  /// `LOCAL_AND` reversibility.
  public const long OPCODE_LOCAL_AND_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_ROTR32` opcode identity.
  public const long OPCODE_LOCAL_ROTR32 = 0x0417;
  /// `LOCAL_ROTR32` operand count.
  public const long OPCODE_LOCAL_ROTR32_OPERAND_COUNT = 3;
  /// `LOCAL_ROTR32` packed operand roles.
  public const long OPCODE_LOCAL_ROTR32_ROLE_FORM = 0x6a27;
  /// `LOCAL_ROTR32` reversibility.
  public const long OPCODE_LOCAL_ROTR32_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_EQ` opcode identity.
  public const long OPCODE_LOCAL_EQ = 0x0420;
  /// `LOCAL_EQ` operand count.
  public const long OPCODE_LOCAL_EQ_OPERAND_COUNT = 3;
  /// `LOCAL_EQ` packed operand roles.
  public const long OPCODE_LOCAL_EQ_ROLE_FORM = 0x6a27;
  /// `LOCAL_EQ` reversibility.
  public const long OPCODE_LOCAL_EQ_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_LT` opcode identity.
  public const long OPCODE_LOCAL_LT = 0x0421;
  /// `LOCAL_LT` operand count.
  public const long OPCODE_LOCAL_LT_OPERAND_COUNT = 3;
  /// `LOCAL_LT` packed operand roles.
  public const long OPCODE_LOCAL_LT_ROLE_FORM = 0x6a27;
  /// `LOCAL_LT` reversibility.
  public const long OPCODE_LOCAL_LT_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `JUMP` opcode identity.
  public const long OPCODE_JUMP = 0x0430;
  /// `JUMP` operand count.
  public const long OPCODE_JUMP_OPERAND_COUNT = 1;
  /// `JUMP` packed operand roles.
  public const long OPCODE_JUMP_ROLE_FORM = 0x1e;
  /// `JUMP` reversibility.
  public const long OPCODE_JUMP_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `JUMP_IF_ZERO` opcode identity.
  public const long OPCODE_JUMP_IF_ZERO = 0x0431;
  /// `JUMP_IF_ZERO` operand count.
  public const long OPCODE_JUMP_IF_ZERO_OPERAND_COUNT = 2;
  /// `JUMP_IF_ZERO` packed operand roles.
  public const long OPCODE_JUMP_IF_ZERO_ROLE_FORM = 0x3c5;
  /// `JUMP_IF_ZERO` reversibility.
  public const long OPCODE_JUMP_IF_ZERO_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `LOCAL_LOOP_CHECK` opcode identity.
  public const long OPCODE_LOCAL_LOOP_CHECK = 0x0432;
  /// `LOCAL_LOOP_CHECK` operand count.
  public const long OPCODE_LOCAL_LOOP_CHECK_OPERAND_COUNT = 2;
  /// `LOCAL_LOOP_CHECK` packed operand roles.
  public const long OPCODE_LOCAL_LOOP_CHECK_ROLE_FORM = 0x26e;
  /// `LOCAL_LOOP_CHECK` reversibility.
  public const long OPCODE_LOCAL_LOOP_CHECK_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `RECORD_NEW` opcode identity.
  public const long OPCODE_RECORD_NEW = 0x0500;
  /// `RECORD_NEW` operand count.
  public const long OPCODE_RECORD_NEW_OPERAND_COUNT = 4;
  /// `RECORD_NEW` packed operand roles.
  public const long OPCODE_RECORD_NEW_ROLE_FORM = 0x4a0c7;
  /// `RECORD_NEW` reversibility.
  public const long OPCODE_RECORD_NEW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `RECORD_GET` opcode identity.
  public const long OPCODE_RECORD_GET = 0x0501;
  /// `RECORD_GET` operand count.
  public const long OPCODE_RECORD_GET_OPERAND_COUNT = 3;
  /// `RECORD_GET` packed operand roles.
  public const long OPCODE_RECORD_GET_ROLE_FORM = 0x36c7;
  /// `RECORD_GET` reversibility.
  public const long OPCODE_RECORD_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `VARIANT_NEW` opcode identity.
  public const long OPCODE_VARIANT_NEW = 0x0510;
  /// `VARIANT_NEW` operand count.
  public const long OPCODE_VARIANT_NEW_OPERAND_COUNT = 5;
  /// `VARIANT_NEW` packed operand roles.
  public const long OPCODE_VARIANT_NEW_ROLE_FORM = 0x9474c7;
  /// `VARIANT_NEW` reversibility.
  public const long OPCODE_VARIANT_NEW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `VARIANT_TAG_EQ` opcode identity.
  public const long OPCODE_VARIANT_TAG_EQ = 0x0511;
  /// `VARIANT_TAG_EQ` operand count.
  public const long OPCODE_VARIANT_TAG_EQ_OPERAND_COUNT = 3;
  /// `VARIANT_TAG_EQ` packed operand roles.
  public const long OPCODE_VARIANT_TAG_EQ_ROLE_FORM = 0x76c7;
  /// `VARIANT_TAG_EQ` reversibility.
  public const long OPCODE_VARIANT_TAG_EQ_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `VARIANT_GET` opcode identity.
  public const long OPCODE_VARIANT_GET = 0x0512;
  /// `VARIANT_GET` operand count.
  public const long OPCODE_VARIANT_GET_OPERAND_COUNT = 4;
  /// `VARIANT_GET` packed operand roles.
  public const long OPCODE_VARIANT_GET_ROLE_FORM = 0x6f6c7;
  /// `VARIANT_GET` reversibility.
  public const long OPCODE_VARIANT_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `ARRAY_NEW` opcode identity.
  public const long OPCODE_ARRAY_NEW = 0x0520;
  /// `ARRAY_NEW` operand count.
  public const long OPCODE_ARRAY_NEW_OPERAND_COUNT = 4;
  /// `ARRAY_NEW` packed operand roles.
  public const long OPCODE_ARRAY_NEW_ROLE_FORM = 0x4a0c7;
  /// `ARRAY_NEW` reversibility.
  public const long OPCODE_ARRAY_NEW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `ARRAY_GET` opcode identity.
  public const long OPCODE_ARRAY_GET = 0x0521;
  /// `ARRAY_GET` operand count.
  public const long OPCODE_ARRAY_GET_OPERAND_COUNT = 3;
  /// `ARRAY_GET` packed operand roles.
  public const long OPCODE_ARRAY_GET_ROLE_FORM = 0x36c7;
  /// `ARRAY_GET` reversibility.
  public const long OPCODE_ARRAY_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `SLICE_NEW` opcode identity.
  public const long OPCODE_SLICE_NEW = 0x0530;
  /// `SLICE_NEW` operand count.
  public const long OPCODE_SLICE_NEW_OPERAND_COUNT = 5;
  /// `SLICE_NEW` packed operand roles.
  public const long OPCODE_SLICE_NEW_ROLE_FORM = 0x12e58c7;
  /// `SLICE_NEW` reversibility.
  public const long OPCODE_SLICE_NEW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `SLICE_GET` opcode identity.
  public const long OPCODE_SLICE_GET = 0x0531;
  /// `SLICE_GET` operand count.
  public const long OPCODE_SLICE_GET_OPERAND_COUNT = 3;
  /// `SLICE_GET` packed operand roles.
  public const long OPCODE_SLICE_GET_ROLE_FORM = 0x36c7;
  /// `SLICE_GET` reversibility.
  public const long OPCODE_SLICE_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `OWNED_MOVE` opcode identity.
  public const long OPCODE_OWNED_MOVE = 0x0540;
  /// `OWNED_MOVE` operand count.
  public const long OPCODE_OWNED_MOVE_OPERAND_COUNT = 2;
  /// `OWNED_MOVE` packed operand roles.
  public const long OPCODE_OWNED_MOVE_ROLE_FORM = 0x367;
  /// `OWNED_MOVE` reversibility.
  public const long OPCODE_OWNED_MOVE_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `REGION_NEW` opcode identity.
  public const long OPCODE_REGION_NEW = 0x0541;
  /// `REGION_NEW` operand count.
  public const long OPCODE_REGION_NEW_OPERAND_COUNT = 3;
  /// `REGION_NEW` packed operand roles.
  public const long OPCODE_REGION_NEW_ROLE_FORM = 0x487;
  /// `REGION_NEW` reversibility.
  public const long OPCODE_REGION_NEW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `WORDS_ALLOC` opcode identity.
  public const long OPCODE_WORDS_ALLOC = 0x0542;
  /// `WORDS_ALLOC` operand count.
  public const long OPCODE_WORDS_ALLOC_OPERAND_COUNT = 3;
  /// `WORDS_ALLOC` packed operand roles.
  public const long OPCODE_WORDS_ALLOC_ROLE_FORM = 0x12c7;
  /// `WORDS_ALLOC` reversibility.
  public const long OPCODE_WORDS_ALLOC_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `WORDS_GET` opcode identity.
  public const long OPCODE_WORDS_GET = 0x0543;
  /// `WORDS_GET` operand count.
  public const long OPCODE_WORDS_GET_OPERAND_COUNT = 3;
  /// `WORDS_GET` packed operand roles.
  public const long OPCODE_WORDS_GET_ROLE_FORM = 0x36c7;
  /// `WORDS_GET` reversibility.
  public const long OPCODE_WORDS_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `WORDS_SET` opcode identity.
  public const long OPCODE_WORDS_SET = 0x0544;
  /// `WORDS_SET` operand count.
  public const long OPCODE_WORDS_SET_OPERAND_COUNT = 3;
  /// `WORDS_SET` packed operand roles.
  public const long OPCODE_WORDS_SET_ROLE_FORM = 0x6db6;
  /// `WORDS_SET` reversibility.
  public const long OPCODE_WORDS_SET_REVERSIBILITY = REVERSIBILITY_LOGGED;

  /// `BUFFER_DROP` opcode identity.
  public const long OPCODE_BUFFER_DROP = 0x0545;
  /// `BUFFER_DROP` operand count.
  public const long OPCODE_BUFFER_DROP_OPERAND_COUNT = 1;
  /// `BUFFER_DROP` packed operand roles.
  public const long OPCODE_BUFFER_DROP_ROLE_FORM = 0x14;
  /// `BUFFER_DROP` reversibility.
  public const long OPCODE_BUFFER_DROP_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `REGION_DROP` opcode identity.
  public const long OPCODE_REGION_DROP = 0x0546;
  /// `REGION_DROP` operand count.
  public const long OPCODE_REGION_DROP_OPERAND_COUNT = 1;
  /// `REGION_DROP` packed operand roles.
  public const long OPCODE_REGION_DROP_ROLE_FORM = 0x14;
  /// `REGION_DROP` reversibility.
  public const long OPCODE_REGION_DROP_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `BYTES_ALLOC` opcode identity.
  public const long OPCODE_BYTES_ALLOC = 0x0547;
  /// `BYTES_ALLOC` operand count.
  public const long OPCODE_BYTES_ALLOC_OPERAND_COUNT = 3;
  /// `BYTES_ALLOC` packed operand roles.
  public const long OPCODE_BYTES_ALLOC_ROLE_FORM = 0x12c7;
  /// `BYTES_ALLOC` reversibility.
  public const long OPCODE_BYTES_ALLOC_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `BYTES_GET` opcode identity.
  public const long OPCODE_BYTES_GET = 0x0548;
  /// `BYTES_GET` operand count.
  public const long OPCODE_BYTES_GET_OPERAND_COUNT = 3;
  /// `BYTES_GET` packed operand roles.
  public const long OPCODE_BYTES_GET_ROLE_FORM = 0x36c7;
  /// `BYTES_GET` reversibility.
  public const long OPCODE_BYTES_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `BYTES_SET` opcode identity.
  public const long OPCODE_BYTES_SET = 0x0549;
  /// `BYTES_SET` operand count.
  public const long OPCODE_BYTES_SET_OPERAND_COUNT = 3;
  /// `BYTES_SET` packed operand roles.
  public const long OPCODE_BYTES_SET_ROLE_FORM = 0x6db6;
  /// `BYTES_SET` reversibility.
  public const long OPCODE_BYTES_SET_REVERSIBILITY = REVERSIBILITY_LOGGED;

  /// `UTF8_VALID` opcode identity.
  public const long OPCODE_UTF8_VALID = 0x054a;
  /// `UTF8_VALID` operand count.
  public const long OPCODE_UTF8_VALID_OPERAND_COUNT = 2;
  /// `UTF8_VALID` packed operand roles.
  public const long OPCODE_UTF8_VALID_ROLE_FORM = 0x367;
  /// `UTF8_VALID` reversibility.
  public const long OPCODE_UTF8_VALID_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `UTF8_COUNT` opcode identity.
  public const long OPCODE_UTF8_COUNT = 0x054b;
  /// `UTF8_COUNT` operand count.
  public const long OPCODE_UTF8_COUNT_OPERAND_COUNT = 2;
  /// `UTF8_COUNT` packed operand roles.
  public const long OPCODE_UTF8_COUNT_ROLE_FORM = 0x367;
  /// `UTF8_COUNT` reversibility.
  public const long OPCODE_UTF8_COUNT_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `BUFFER_LENGTH` opcode identity.
  public const long OPCODE_BUFFER_LENGTH = 0x054c;
  /// `BUFFER_LENGTH` operand count.
  public const long OPCODE_BUFFER_LENGTH_OPERAND_COUNT = 2;
  /// `BUFFER_LENGTH` packed operand roles.
  public const long OPCODE_BUFFER_LENGTH_ROLE_FORM = 0x367;
  /// `BUFFER_LENGTH` reversibility.
  public const long OPCODE_BUFFER_LENGTH_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `UTF8_SCALAR` opcode identity.
  public const long OPCODE_UTF8_SCALAR = 0x054d;
  /// `UTF8_SCALAR` operand count.
  public const long OPCODE_UTF8_SCALAR_OPERAND_COUNT = 3;
  /// `UTF8_SCALAR` packed operand roles.
  public const long OPCODE_UTF8_SCALAR_ROLE_FORM = 0x36c7;
  /// `UTF8_SCALAR` reversibility.
  public const long OPCODE_UTF8_SCALAR_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `UTF8_WIDTH` opcode identity.
  public const long OPCODE_UTF8_WIDTH = 0x054e;
  /// `UTF8_WIDTH` operand count.
  public const long OPCODE_UTF8_WIDTH_OPERAND_COUNT = 3;
  /// `UTF8_WIDTH` packed operand roles.
  public const long OPCODE_UTF8_WIDTH_ROLE_FORM = 0x36c7;
  /// `UTF8_WIDTH` reversibility.
  public const long OPCODE_UTF8_WIDTH_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `MAP_ALLOC` opcode identity.
  public const long OPCODE_MAP_ALLOC = 0x054f;
  /// `MAP_ALLOC` operand count.
  public const long OPCODE_MAP_ALLOC_OPERAND_COUNT = 3;
  /// `MAP_ALLOC` packed operand roles.
  public const long OPCODE_MAP_ALLOC_ROLE_FORM = 0x12c7;
  /// `MAP_ALLOC` reversibility.
  public const long OPCODE_MAP_ALLOC_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `MAP_PUT` opcode identity.
  public const long OPCODE_MAP_PUT = 0x0550;
  /// `MAP_PUT` operand count.
  public const long OPCODE_MAP_PUT_OPERAND_COUNT = 3;
  /// `MAP_PUT` packed operand roles.
  public const long OPCODE_MAP_PUT_ROLE_FORM = 0x6df6;
  /// `MAP_PUT` reversibility.
  public const long OPCODE_MAP_PUT_REVERSIBILITY = REVERSIBILITY_LOGGED;

  /// `MAP_GET` opcode identity.
  public const long OPCODE_MAP_GET = 0x0551;
  /// `MAP_GET` operand count.
  public const long OPCODE_MAP_GET_OPERAND_COUNT = 3;
  /// `MAP_GET` packed operand roles.
  public const long OPCODE_MAP_GET_ROLE_FORM = 0x3ec7;
  /// `MAP_GET` reversibility.
  public const long OPCODE_MAP_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `MAP_HAS` opcode identity.
  public const long OPCODE_MAP_HAS = 0x0552;
  /// `MAP_HAS` operand count.
  public const long OPCODE_MAP_HAS_OPERAND_COUNT = 3;
  /// `MAP_HAS` packed operand roles.
  public const long OPCODE_MAP_HAS_ROLE_FORM = 0x3ec7;
  /// `MAP_HAS` reversibility.
  public const long OPCODE_MAP_HAS_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `UTF8_FREEZE` opcode identity.
  public const long OPCODE_UTF8_FREEZE = 0x0553;
  /// `UTF8_FREEZE` operand count.
  public const long OPCODE_UTF8_FREEZE_OPERAND_COUNT = 2;
  /// `UTF8_FREEZE` packed operand roles.
  public const long OPCODE_UTF8_FREEZE_ROLE_FORM = 0x367;
  /// `UTF8_FREEZE` reversibility.
  public const long OPCODE_UTF8_FREEZE_REVERSIBILITY = REVERSIBILITY_LOGGED;

  /// `UTF8_BORROW` opcode identity.
  public const long OPCODE_UTF8_BORROW = 0x0554;
  /// `UTF8_BORROW` operand count.
  public const long OPCODE_UTF8_BORROW_OPERAND_COUNT = 2;
  /// `UTF8_BORROW` packed operand roles.
  public const long OPCODE_UTF8_BORROW_ROLE_FORM = 0x367;
  /// `UTF8_BORROW` reversibility.
  public const long OPCODE_UTF8_BORROW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `MAP_BORROW` opcode identity.
  public const long OPCODE_MAP_BORROW = 0x0555;
  /// `MAP_BORROW` operand count.
  public const long OPCODE_MAP_BORROW_OPERAND_COUNT = 2;
  /// `MAP_BORROW` packed operand roles.
  public const long OPCODE_MAP_BORROW_ROLE_FORM = 0x367;
  /// `MAP_BORROW` reversibility.
  public const long OPCODE_MAP_BORROW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `BUFFER_BORROW` opcode identity.
  public const long OPCODE_BUFFER_BORROW = 0x0556;
  /// `BUFFER_BORROW` operand count.
  public const long OPCODE_BUFFER_BORROW_OPERAND_COUNT = 2;
  /// `BUFFER_BORROW` packed operand roles.
  public const long OPCODE_BUFFER_BORROW_ROLE_FORM = 0x367;
  /// `BUFFER_BORROW` reversibility.
  public const long OPCODE_BUFFER_BORROW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `REGION_BORROW` opcode identity.
  public const long OPCODE_REGION_BORROW = 0x0557;
  /// `REGION_BORROW` operand count.
  public const long OPCODE_REGION_BORROW_OPERAND_COUNT = 2;
  /// `REGION_BORROW` packed operand roles.
  public const long OPCODE_REGION_BORROW_ROLE_FORM = 0x367;
  /// `REGION_BORROW` reversibility.
  public const long OPCODE_REGION_BORROW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// `OUTPUT_LENGTH` opcode identity.
  public const long OPCODE_OUTPUT_LENGTH = 0x0558;
  /// `OUTPUT_LENGTH` operand count.
  public const long OPCODE_OUTPUT_LENGTH_OPERAND_COUNT = 2;
  /// `OUTPUT_LENGTH` packed operand roles.
  public const long OPCODE_OUTPUT_LENGTH_ROLE_FORM = 0x256;
  /// `OUTPUT_LENGTH` reversibility.
  public const long OPCODE_OUTPUT_LENGTH_REVERSIBILITY = REVERSIBILITY_LOGGED;
}
