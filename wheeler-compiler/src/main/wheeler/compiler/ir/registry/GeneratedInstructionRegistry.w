//! Generated instruction-registry view. Do not edit this module.

module wheeler.compiler.generated_instruction_registry;

classical class GeneratedInstructionRegistry {
  /// Names the generated `INTRINSIC` reversibility class.
  public const long REVERSIBILITY_INTRINSIC = 0;
  /// Names the generated `CHECKED` reversibility class.
  public const long REVERSIBILITY_CHECKED = 1;
  /// Names the generated `LOGGED` reversibility class.
  public const long REVERSIBILITY_LOGGED = 2;
  /// Names the generated `BARRIER` reversibility class.
  public const long REVERSIBILITY_BARRIER = 3;

  /// Names the generated `ALLOCATION_LIMIT` operand role.
  public const long ROLE_ALLOCATION_LIMIT = 1;
  /// Names the generated `ARGUMENT_BASE` operand role.
  public const long ROLE_ARGUMENT_BASE = 2;
  /// Names the generated `ARGUMENT_COUNT` operand role.
  public const long ROLE_ARGUMENT_COUNT = 3;
  /// Names the generated `CAPACITY` operand role.
  public const long ROLE_CAPACITY = 4;
  /// Names the generated `CONDITION` operand role.
  public const long ROLE_CONDITION = 5;
  /// Names the generated `DESCRIPTOR` operand role.
  public const long ROLE_DESCRIPTOR = 6;
  /// Names the generated `DESTINATION` operand role.
  public const long ROLE_DESTINATION = 7;
  /// Names the generated `ELEMENT_BASE` operand role.
  public const long ROLE_ELEMENT_BASE = 8;
  /// Names the generated `ELEMENT_COUNT` operand role.
  public const long ROLE_ELEMENT_COUNT = 9;
  /// Names the generated `FUNCTION` operand role.
  public const long ROLE_FUNCTION = 10;
  /// Names the generated `GLOBAL` operand role.
  public const long ROLE_GLOBAL = 11;
  /// Names the generated `IMMEDIATE` operand role.
  public const long ROLE_IMMEDIATE = 12;
  /// Names the generated `INDEX` operand role.
  public const long ROLE_INDEX = 13;
  /// Names the generated `ITERATION` operand role.
  public const long ROLE_ITERATION = 14;
  /// Names the generated `KEY` operand role.
  public const long ROLE_KEY = 15;
  /// Names the generated `LEFT_GLOBAL` operand role.
  public const long ROLE_LEFT_GLOBAL = 16;
  /// Names the generated `LEFT_SOURCE` operand role.
  public const long ROLE_LEFT_SOURCE = 17;
  /// Names the generated `LENGTH` operand role.
  public const long ROLE_LENGTH = 18;
  /// Names the generated `LIMIT` operand role.
  public const long ROLE_LIMIT = 19;
  /// Names the generated `LOCAL` operand role.
  public const long ROLE_LOCAL = 20;
  /// Names the generated `OPERATION` operand role.
  public const long ROLE_OPERATION = 21;
  /// Names the generated `OWNER` operand role.
  public const long ROLE_OWNER = 22;
  /// Names the generated `RESULT` operand role.
  public const long ROLE_RESULT = 23;
  /// Names the generated `RESULT_SLOT` operand role.
  public const long ROLE_RESULT_SLOT = 24;
  /// Names the generated `RIGHT_GLOBAL` operand role.
  public const long ROLE_RIGHT_GLOBAL = 25;
  /// Names the generated `RIGHT_SOURCE` operand role.
  public const long ROLE_RIGHT_SOURCE = 26;
  /// Names the generated `SOURCE` operand role.
  public const long ROLE_SOURCE = 27;
  /// Names the generated `START` operand role.
  public const long ROLE_START = 28;
  /// Names the generated `TAG` operand role.
  public const long ROLE_TAG = 29;
  /// Names the generated `TARGET` operand role.
  public const long ROLE_TARGET = 30;

  /// Names the generated `NOP` opcode identity.
  public const long OPCODE_NOP = 0x0000;
  /// Names the generated `NOP` operand count.
  public const long OPCODE_NOP_OPERAND_COUNT = 0;
  /// Packs the generated `NOP` roles in operand order.
  public const long OPCODE_NOP_ROLE_FORM = 0x0;
  /// Names the generated `NOP` reversibility class.
  public const long OPCODE_NOP_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// Names the generated `HALT` opcode identity.
  public const long OPCODE_HALT = 0x0001;
  /// Names the generated `HALT` operand count.
  public const long OPCODE_HALT_OPERAND_COUNT = 0;
  /// Packs the generated `HALT` roles in operand order.
  public const long OPCODE_HALT_ROLE_FORM = 0x0;
  /// Names the generated `HALT` reversibility class.
  public const long OPCODE_HALT_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `RETURN` opcode identity.
  public const long OPCODE_RETURN = 0x0002;
  /// Names the generated `RETURN` operand count.
  public const long OPCODE_RETURN_OPERAND_COUNT = 0;
  /// Packs the generated `RETURN` roles in operand order.
  public const long OPCODE_RETURN_ROLE_FORM = 0x0;
  /// Names the generated `RETURN` reversibility class.
  public const long OPCODE_RETURN_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `ADD_CONST` opcode identity.
  public const long OPCODE_ADD_CONST = 0x0100;
  /// Names the generated `ADD_CONST` operand count.
  public const long OPCODE_ADD_CONST_OPERAND_COUNT = 2;
  /// Packs the generated `ADD_CONST` roles in operand order.
  public const long OPCODE_ADD_CONST_ROLE_FORM = 0x18b;
  /// Names the generated `ADD_CONST` reversibility class.
  public const long OPCODE_ADD_CONST_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// Names the generated `SUB_CONST` opcode identity.
  public const long OPCODE_SUB_CONST = 0x0101;
  /// Names the generated `SUB_CONST` operand count.
  public const long OPCODE_SUB_CONST_OPERAND_COUNT = 2;
  /// Packs the generated `SUB_CONST` roles in operand order.
  public const long OPCODE_SUB_CONST_ROLE_FORM = 0x18b;
  /// Names the generated `SUB_CONST` reversibility class.
  public const long OPCODE_SUB_CONST_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// Names the generated `XOR_CONST` opcode identity.
  public const long OPCODE_XOR_CONST = 0x0102;
  /// Names the generated `XOR_CONST` operand count.
  public const long OPCODE_XOR_CONST_OPERAND_COUNT = 2;
  /// Packs the generated `XOR_CONST` roles in operand order.
  public const long OPCODE_XOR_CONST_ROLE_FORM = 0x18b;
  /// Names the generated `XOR_CONST` reversibility class.
  public const long OPCODE_XOR_CONST_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// Names the generated `SWAP` opcode identity.
  public const long OPCODE_SWAP = 0x0103;
  /// Names the generated `SWAP` operand count.
  public const long OPCODE_SWAP_OPERAND_COUNT = 2;
  /// Packs the generated `SWAP` roles in operand order.
  public const long OPCODE_SWAP_ROLE_FORM = 0x330;
  /// Names the generated `SWAP` reversibility class.
  public const long OPCODE_SWAP_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// Names the generated `SET_LOGGED` opcode identity.
  public const long OPCODE_SET_LOGGED = 0x0104;
  /// Names the generated `SET_LOGGED` operand count.
  public const long OPCODE_SET_LOGGED_OPERAND_COUNT = 2;
  /// Packs the generated `SET_LOGGED` roles in operand order.
  public const long OPCODE_SET_LOGGED_ROLE_FORM = 0x18b;
  /// Names the generated `SET_LOGGED` reversibility class.
  public const long OPCODE_SET_LOGGED_REVERSIBILITY = REVERSIBILITY_LOGGED;

  /// Names the generated `CALL` opcode identity.
  public const long OPCODE_CALL = 0x0200;
  /// Names the generated `CALL` operand count.
  public const long OPCODE_CALL_OPERAND_COUNT = 1;
  /// Packs the generated `CALL` roles in operand order.
  public const long OPCODE_CALL_ROLE_FORM = 0xa;
  /// Names the generated `CALL` reversibility class.
  public const long OPCODE_CALL_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `UNCALL` opcode identity.
  public const long OPCODE_UNCALL = 0x0201;
  /// Names the generated `UNCALL` operand count.
  public const long OPCODE_UNCALL_OPERAND_COUNT = 1;
  /// Packs the generated `UNCALL` roles in operand order.
  public const long OPCODE_UNCALL_ROLE_FORM = 0xa;
  /// Names the generated `UNCALL` reversibility class.
  public const long OPCODE_UNCALL_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `CALL_VALUE` opcode identity.
  public const long OPCODE_CALL_VALUE = 0x0202;
  /// Names the generated `CALL_VALUE` operand count.
  public const long OPCODE_CALL_VALUE_OPERAND_COUNT = 4;
  /// Packs the generated `CALL_VALUE` roles in operand order.
  public const long OPCODE_CALL_VALUE_ROLE_FORM = 0xb8c4a;
  /// Names the generated `CALL_VALUE` reversibility class.
  public const long OPCODE_CALL_VALUE_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `RETURN_VALUE` opcode identity.
  public const long OPCODE_RETURN_VALUE = 0x0203;
  /// Names the generated `RETURN_VALUE` operand count.
  public const long OPCODE_RETURN_VALUE_OPERAND_COUNT = 1;
  /// Packs the generated `RETURN_VALUE` roles in operand order.
  public const long OPCODE_RETURN_VALUE_ROLE_FORM = 0x17;
  /// Names the generated `RETURN_VALUE` reversibility class.
  public const long OPCODE_RETURN_VALUE_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `CALL_VOID` opcode identity.
  public const long OPCODE_CALL_VOID = 0x0204;
  /// Names the generated `CALL_VOID` operand count.
  public const long OPCODE_CALL_VOID_OPERAND_COUNT = 3;
  /// Packs the generated `CALL_VOID` roles in operand order.
  public const long OPCODE_CALL_VOID_ROLE_FORM = 0xc4a;
  /// Names the generated `CALL_VOID` reversibility class.
  public const long OPCODE_CALL_VOID_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `CALL_RESULT_SLOT` opcode identity.
  public const long OPCODE_CALL_RESULT_SLOT = 0x0205;
  /// Names the generated `CALL_RESULT_SLOT` operand count.
  public const long OPCODE_CALL_RESULT_SLOT_OPERAND_COUNT = 4;
  /// Packs the generated `CALL_RESULT_SLOT` roles in operand order.
  public const long OPCODE_CALL_RESULT_SLOT_ROLE_FORM = 0xc0c4a;
  /// Names the generated `CALL_RESULT_SLOT` reversibility class.
  public const long OPCODE_CALL_RESULT_SLOT_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `UNCALL_RESULT_SLOT` opcode identity.
  public const long OPCODE_UNCALL_RESULT_SLOT = 0x0206;
  /// Names the generated `UNCALL_RESULT_SLOT` operand count.
  public const long OPCODE_UNCALL_RESULT_SLOT_OPERAND_COUNT = 4;
  /// Packs the generated `UNCALL_RESULT_SLOT` roles in operand order.
  public const long OPCODE_UNCALL_RESULT_SLOT_ROLE_FORM = 0xc0c4a;
  /// Names the generated `UNCALL_RESULT_SLOT` reversibility class.
  public const long OPCODE_UNCALL_RESULT_SLOT_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `RESULT_FILL_CONSTANT` opcode identity.
  public const long OPCODE_RESULT_FILL_CONSTANT = 0x0207;
  /// Names the generated `RESULT_FILL_CONSTANT` operand count.
  public const long OPCODE_RESULT_FILL_CONSTANT_OPERAND_COUNT = 2;
  /// Packs the generated `RESULT_FILL_CONSTANT` roles in operand order.
  public const long OPCODE_RESULT_FILL_CONSTANT_ROLE_FORM = 0x198;
  /// Names the generated `RESULT_FILL_CONSTANT` reversibility class.
  public const long OPCODE_RESULT_FILL_CONSTANT_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// Names the generated `RETURN_RESULT_SLOT` opcode identity.
  public const long OPCODE_RETURN_RESULT_SLOT = 0x0208;
  /// Names the generated `RETURN_RESULT_SLOT` operand count.
  public const long OPCODE_RETURN_RESULT_SLOT_OPERAND_COUNT = 1;
  /// Packs the generated `RETURN_RESULT_SLOT` roles in operand order.
  public const long OPCODE_RETURN_RESULT_SLOT_ROLE_FORM = 0x18;
  /// Names the generated `RETURN_RESULT_SLOT` reversibility class.
  public const long OPCODE_RETURN_RESULT_SLOT_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `RESULT_FILL_SOURCE` opcode identity.
  public const long OPCODE_RESULT_FILL_SOURCE = 0x0209;
  /// Names the generated `RESULT_FILL_SOURCE` operand count.
  public const long OPCODE_RESULT_FILL_SOURCE_OPERAND_COUNT = 2;
  /// Packs the generated `RESULT_FILL_SOURCE` roles in operand order.
  public const long OPCODE_RESULT_FILL_SOURCE_ROLE_FORM = 0x378;
  /// Names the generated `RESULT_FILL_SOURCE` reversibility class.
  public const long OPCODE_RESULT_FILL_SOURCE_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// Names the generated `RESULT_FILL_BINARY` opcode identity.
  public const long OPCODE_RESULT_FILL_BINARY = 0x020a;
  /// Names the generated `RESULT_FILL_BINARY` operand count.
  public const long OPCODE_RESULT_FILL_BINARY_OPERAND_COUNT = 4;
  /// Packs the generated `RESULT_FILL_BINARY` roles in operand order.
  public const long OPCODE_RESULT_FILL_BINARY_ROLE_FORM = 0x65778;
  /// Names the generated `RESULT_FILL_BINARY` reversibility class.
  public const long OPCODE_RESULT_FILL_BINARY_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// Names the generated `RESULT_FILL_BINARY_SOURCES` opcode identity.
  public const long OPCODE_RESULT_FILL_BINARY_SOURCES = 0x020b;
  /// Names the generated `RESULT_FILL_BINARY_SOURCES` operand count.
  public const long OPCODE_RESULT_FILL_BINARY_SOURCES_OPERAND_COUNT = 4;
  /// Packs the generated `RESULT_FILL_BINARY_SOURCES` roles in operand order.
  public const long OPCODE_RESULT_FILL_BINARY_SOURCES_ROLE_FORM = 0xd5778;
  /// Names the generated `RESULT_FILL_BINARY_SOURCES` reversibility class.
  public const long OPCODE_RESULT_FILL_BINARY_SOURCES_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// Names the generated `EXPECT_EQ` opcode identity.
  public const long OPCODE_EXPECT_EQ = 0x0300;
  /// Names the generated `EXPECT_EQ` operand count.
  public const long OPCODE_EXPECT_EQ_OPERAND_COUNT = 2;
  /// Packs the generated `EXPECT_EQ` roles in operand order.
  public const long OPCODE_EXPECT_EQ_ROLE_FORM = 0x18b;
  /// Names the generated `EXPECT_EQ` reversibility class.
  public const long OPCODE_EXPECT_EQ_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `CHECKPOINT` opcode identity.
  public const long OPCODE_CHECKPOINT = 0x0301;
  /// Names the generated `CHECKPOINT` operand count.
  public const long OPCODE_CHECKPOINT_OPERAND_COUNT = 0;
  /// Packs the generated `CHECKPOINT` roles in operand order.
  public const long OPCODE_CHECKPOINT_ROLE_FORM = 0x0;
  /// Names the generated `CHECKPOINT` reversibility class.
  public const long OPCODE_CHECKPOINT_REVERSIBILITY = REVERSIBILITY_INTRINSIC;

  /// Names the generated `COMMIT` opcode identity.
  public const long OPCODE_COMMIT = 0x0302;
  /// Names the generated `COMMIT` operand count.
  public const long OPCODE_COMMIT_OPERAND_COUNT = 0;
  /// Packs the generated `COMMIT` roles in operand order.
  public const long OPCODE_COMMIT_ROLE_FORM = 0x0;
  /// Names the generated `COMMIT` reversibility class.
  public const long OPCODE_COMMIT_REVERSIBILITY = REVERSIBILITY_BARRIER;

  /// Names the generated `EXPECT_TRUE` opcode identity.
  public const long OPCODE_EXPECT_TRUE = 0x0303;
  /// Names the generated `EXPECT_TRUE` operand count.
  public const long OPCODE_EXPECT_TRUE_OPERAND_COUNT = 1;
  /// Packs the generated `EXPECT_TRUE` roles in operand order.
  public const long OPCODE_EXPECT_TRUE_ROLE_FORM = 0x5;
  /// Names the generated `EXPECT_TRUE` reversibility class.
  public const long OPCODE_EXPECT_TRUE_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_CONST` opcode identity.
  public const long OPCODE_LOCAL_CONST = 0x0400;
  /// Names the generated `LOCAL_CONST` operand count.
  public const long OPCODE_LOCAL_CONST_OPERAND_COUNT = 2;
  /// Packs the generated `LOCAL_CONST` roles in operand order.
  public const long OPCODE_LOCAL_CONST_ROLE_FORM = 0x187;
  /// Names the generated `LOCAL_CONST` reversibility class.
  public const long OPCODE_LOCAL_CONST_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_LOAD_GLOBAL` opcode identity.
  public const long OPCODE_LOCAL_LOAD_GLOBAL = 0x0401;
  /// Names the generated `LOCAL_LOAD_GLOBAL` operand count.
  public const long OPCODE_LOCAL_LOAD_GLOBAL_OPERAND_COUNT = 2;
  /// Packs the generated `LOCAL_LOAD_GLOBAL` roles in operand order.
  public const long OPCODE_LOCAL_LOAD_GLOBAL_ROLE_FORM = 0x167;
  /// Names the generated `LOCAL_LOAD_GLOBAL` reversibility class.
  public const long OPCODE_LOCAL_LOAD_GLOBAL_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_STORE_GLOBAL` opcode identity.
  public const long OPCODE_LOCAL_STORE_GLOBAL = 0x0402;
  /// Names the generated `LOCAL_STORE_GLOBAL` operand count.
  public const long OPCODE_LOCAL_STORE_GLOBAL_OPERAND_COUNT = 2;
  /// Packs the generated `LOCAL_STORE_GLOBAL` roles in operand order.
  public const long OPCODE_LOCAL_STORE_GLOBAL_ROLE_FORM = 0x36b;
  /// Names the generated `LOCAL_STORE_GLOBAL` reversibility class.
  public const long OPCODE_LOCAL_STORE_GLOBAL_REVERSIBILITY = REVERSIBILITY_LOGGED;

  /// Names the generated `LOCAL_MOVE` opcode identity.
  public const long OPCODE_LOCAL_MOVE = 0x0403;
  /// Names the generated `LOCAL_MOVE` operand count.
  public const long OPCODE_LOCAL_MOVE_OPERAND_COUNT = 2;
  /// Packs the generated `LOCAL_MOVE` roles in operand order.
  public const long OPCODE_LOCAL_MOVE_ROLE_FORM = 0x367;
  /// Names the generated `LOCAL_MOVE` reversibility class.
  public const long OPCODE_LOCAL_MOVE_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_ADD` opcode identity.
  public const long OPCODE_LOCAL_ADD = 0x0410;
  /// Names the generated `LOCAL_ADD` operand count.
  public const long OPCODE_LOCAL_ADD_OPERAND_COUNT = 3;
  /// Packs the generated `LOCAL_ADD` roles in operand order.
  public const long OPCODE_LOCAL_ADD_ROLE_FORM = 0x6a27;
  /// Names the generated `LOCAL_ADD` reversibility class.
  public const long OPCODE_LOCAL_ADD_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_SUB` opcode identity.
  public const long OPCODE_LOCAL_SUB = 0x0411;
  /// Names the generated `LOCAL_SUB` operand count.
  public const long OPCODE_LOCAL_SUB_OPERAND_COUNT = 3;
  /// Packs the generated `LOCAL_SUB` roles in operand order.
  public const long OPCODE_LOCAL_SUB_ROLE_FORM = 0x6a27;
  /// Names the generated `LOCAL_SUB` reversibility class.
  public const long OPCODE_LOCAL_SUB_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_XOR` opcode identity.
  public const long OPCODE_LOCAL_XOR = 0x0412;
  /// Names the generated `LOCAL_XOR` operand count.
  public const long OPCODE_LOCAL_XOR_OPERAND_COUNT = 3;
  /// Packs the generated `LOCAL_XOR` roles in operand order.
  public const long OPCODE_LOCAL_XOR_ROLE_FORM = 0x6a27;
  /// Names the generated `LOCAL_XOR` reversibility class.
  public const long OPCODE_LOCAL_XOR_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_MUL` opcode identity.
  public const long OPCODE_LOCAL_MUL = 0x0413;
  /// Names the generated `LOCAL_MUL` operand count.
  public const long OPCODE_LOCAL_MUL_OPERAND_COUNT = 3;
  /// Packs the generated `LOCAL_MUL` roles in operand order.
  public const long OPCODE_LOCAL_MUL_ROLE_FORM = 0x6a27;
  /// Names the generated `LOCAL_MUL` reversibility class.
  public const long OPCODE_LOCAL_MUL_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_DIV` opcode identity.
  public const long OPCODE_LOCAL_DIV = 0x0414;
  /// Names the generated `LOCAL_DIV` operand count.
  public const long OPCODE_LOCAL_DIV_OPERAND_COUNT = 3;
  /// Packs the generated `LOCAL_DIV` roles in operand order.
  public const long OPCODE_LOCAL_DIV_ROLE_FORM = 0x6a27;
  /// Names the generated `LOCAL_DIV` reversibility class.
  public const long OPCODE_LOCAL_DIV_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_MOD` opcode identity.
  public const long OPCODE_LOCAL_MOD = 0x0415;
  /// Names the generated `LOCAL_MOD` operand count.
  public const long OPCODE_LOCAL_MOD_OPERAND_COUNT = 3;
  /// Packs the generated `LOCAL_MOD` roles in operand order.
  public const long OPCODE_LOCAL_MOD_ROLE_FORM = 0x6a27;
  /// Names the generated `LOCAL_MOD` reversibility class.
  public const long OPCODE_LOCAL_MOD_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_AND` opcode identity.
  public const long OPCODE_LOCAL_AND = 0x0416;
  /// Names the generated `LOCAL_AND` operand count.
  public const long OPCODE_LOCAL_AND_OPERAND_COUNT = 3;
  /// Packs the generated `LOCAL_AND` roles in operand order.
  public const long OPCODE_LOCAL_AND_ROLE_FORM = 0x6a27;
  /// Names the generated `LOCAL_AND` reversibility class.
  public const long OPCODE_LOCAL_AND_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_ROTR32` opcode identity.
  public const long OPCODE_LOCAL_ROTR32 = 0x0417;
  /// Names the generated `LOCAL_ROTR32` operand count.
  public const long OPCODE_LOCAL_ROTR32_OPERAND_COUNT = 3;
  /// Packs the generated `LOCAL_ROTR32` roles in operand order.
  public const long OPCODE_LOCAL_ROTR32_ROLE_FORM = 0x6a27;
  /// Names the generated `LOCAL_ROTR32` reversibility class.
  public const long OPCODE_LOCAL_ROTR32_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_EQ` opcode identity.
  public const long OPCODE_LOCAL_EQ = 0x0420;
  /// Names the generated `LOCAL_EQ` operand count.
  public const long OPCODE_LOCAL_EQ_OPERAND_COUNT = 3;
  /// Packs the generated `LOCAL_EQ` roles in operand order.
  public const long OPCODE_LOCAL_EQ_ROLE_FORM = 0x6a27;
  /// Names the generated `LOCAL_EQ` reversibility class.
  public const long OPCODE_LOCAL_EQ_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_LT` opcode identity.
  public const long OPCODE_LOCAL_LT = 0x0421;
  /// Names the generated `LOCAL_LT` operand count.
  public const long OPCODE_LOCAL_LT_OPERAND_COUNT = 3;
  /// Packs the generated `LOCAL_LT` roles in operand order.
  public const long OPCODE_LOCAL_LT_ROLE_FORM = 0x6a27;
  /// Names the generated `LOCAL_LT` reversibility class.
  public const long OPCODE_LOCAL_LT_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `JUMP` opcode identity.
  public const long OPCODE_JUMP = 0x0430;
  /// Names the generated `JUMP` operand count.
  public const long OPCODE_JUMP_OPERAND_COUNT = 1;
  /// Packs the generated `JUMP` roles in operand order.
  public const long OPCODE_JUMP_ROLE_FORM = 0x1e;
  /// Names the generated `JUMP` reversibility class.
  public const long OPCODE_JUMP_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `JUMP_IF_ZERO` opcode identity.
  public const long OPCODE_JUMP_IF_ZERO = 0x0431;
  /// Names the generated `JUMP_IF_ZERO` operand count.
  public const long OPCODE_JUMP_IF_ZERO_OPERAND_COUNT = 2;
  /// Packs the generated `JUMP_IF_ZERO` roles in operand order.
  public const long OPCODE_JUMP_IF_ZERO_ROLE_FORM = 0x3c5;
  /// Names the generated `JUMP_IF_ZERO` reversibility class.
  public const long OPCODE_JUMP_IF_ZERO_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `LOCAL_LOOP_CHECK` opcode identity.
  public const long OPCODE_LOCAL_LOOP_CHECK = 0x0432;
  /// Names the generated `LOCAL_LOOP_CHECK` operand count.
  public const long OPCODE_LOCAL_LOOP_CHECK_OPERAND_COUNT = 2;
  /// Packs the generated `LOCAL_LOOP_CHECK` roles in operand order.
  public const long OPCODE_LOCAL_LOOP_CHECK_ROLE_FORM = 0x26e;
  /// Names the generated `LOCAL_LOOP_CHECK` reversibility class.
  public const long OPCODE_LOCAL_LOOP_CHECK_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `RECORD_NEW` opcode identity.
  public const long OPCODE_RECORD_NEW = 0x0500;
  /// Names the generated `RECORD_NEW` operand count.
  public const long OPCODE_RECORD_NEW_OPERAND_COUNT = 4;
  /// Packs the generated `RECORD_NEW` roles in operand order.
  public const long OPCODE_RECORD_NEW_ROLE_FORM = 0x4a0c7;
  /// Names the generated `RECORD_NEW` reversibility class.
  public const long OPCODE_RECORD_NEW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `RECORD_GET` opcode identity.
  public const long OPCODE_RECORD_GET = 0x0501;
  /// Names the generated `RECORD_GET` operand count.
  public const long OPCODE_RECORD_GET_OPERAND_COUNT = 3;
  /// Packs the generated `RECORD_GET` roles in operand order.
  public const long OPCODE_RECORD_GET_ROLE_FORM = 0x36c7;
  /// Names the generated `RECORD_GET` reversibility class.
  public const long OPCODE_RECORD_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `VARIANT_NEW` opcode identity.
  public const long OPCODE_VARIANT_NEW = 0x0510;
  /// Names the generated `VARIANT_NEW` operand count.
  public const long OPCODE_VARIANT_NEW_OPERAND_COUNT = 5;
  /// Packs the generated `VARIANT_NEW` roles in operand order.
  public const long OPCODE_VARIANT_NEW_ROLE_FORM = 0x9474c7;
  /// Names the generated `VARIANT_NEW` reversibility class.
  public const long OPCODE_VARIANT_NEW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `VARIANT_TAG_EQ` opcode identity.
  public const long OPCODE_VARIANT_TAG_EQ = 0x0511;
  /// Names the generated `VARIANT_TAG_EQ` operand count.
  public const long OPCODE_VARIANT_TAG_EQ_OPERAND_COUNT = 3;
  /// Packs the generated `VARIANT_TAG_EQ` roles in operand order.
  public const long OPCODE_VARIANT_TAG_EQ_ROLE_FORM = 0x76c7;
  /// Names the generated `VARIANT_TAG_EQ` reversibility class.
  public const long OPCODE_VARIANT_TAG_EQ_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `VARIANT_GET` opcode identity.
  public const long OPCODE_VARIANT_GET = 0x0512;
  /// Names the generated `VARIANT_GET` operand count.
  public const long OPCODE_VARIANT_GET_OPERAND_COUNT = 4;
  /// Packs the generated `VARIANT_GET` roles in operand order.
  public const long OPCODE_VARIANT_GET_ROLE_FORM = 0x6f6c7;
  /// Names the generated `VARIANT_GET` reversibility class.
  public const long OPCODE_VARIANT_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `ARRAY_NEW` opcode identity.
  public const long OPCODE_ARRAY_NEW = 0x0520;
  /// Names the generated `ARRAY_NEW` operand count.
  public const long OPCODE_ARRAY_NEW_OPERAND_COUNT = 4;
  /// Packs the generated `ARRAY_NEW` roles in operand order.
  public const long OPCODE_ARRAY_NEW_ROLE_FORM = 0x4a0c7;
  /// Names the generated `ARRAY_NEW` reversibility class.
  public const long OPCODE_ARRAY_NEW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `ARRAY_GET` opcode identity.
  public const long OPCODE_ARRAY_GET = 0x0521;
  /// Names the generated `ARRAY_GET` operand count.
  public const long OPCODE_ARRAY_GET_OPERAND_COUNT = 3;
  /// Packs the generated `ARRAY_GET` roles in operand order.
  public const long OPCODE_ARRAY_GET_ROLE_FORM = 0x36c7;
  /// Names the generated `ARRAY_GET` reversibility class.
  public const long OPCODE_ARRAY_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `SLICE_NEW` opcode identity.
  public const long OPCODE_SLICE_NEW = 0x0530;
  /// Names the generated `SLICE_NEW` operand count.
  public const long OPCODE_SLICE_NEW_OPERAND_COUNT = 5;
  /// Packs the generated `SLICE_NEW` roles in operand order.
  public const long OPCODE_SLICE_NEW_ROLE_FORM = 0x12e58c7;
  /// Names the generated `SLICE_NEW` reversibility class.
  public const long OPCODE_SLICE_NEW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `SLICE_GET` opcode identity.
  public const long OPCODE_SLICE_GET = 0x0531;
  /// Names the generated `SLICE_GET` operand count.
  public const long OPCODE_SLICE_GET_OPERAND_COUNT = 3;
  /// Packs the generated `SLICE_GET` roles in operand order.
  public const long OPCODE_SLICE_GET_ROLE_FORM = 0x36c7;
  /// Names the generated `SLICE_GET` reversibility class.
  public const long OPCODE_SLICE_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `OWNED_MOVE` opcode identity.
  public const long OPCODE_OWNED_MOVE = 0x0540;
  /// Names the generated `OWNED_MOVE` operand count.
  public const long OPCODE_OWNED_MOVE_OPERAND_COUNT = 2;
  /// Packs the generated `OWNED_MOVE` roles in operand order.
  public const long OPCODE_OWNED_MOVE_ROLE_FORM = 0x367;
  /// Names the generated `OWNED_MOVE` reversibility class.
  public const long OPCODE_OWNED_MOVE_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `REGION_NEW` opcode identity.
  public const long OPCODE_REGION_NEW = 0x0541;
  /// Names the generated `REGION_NEW` operand count.
  public const long OPCODE_REGION_NEW_OPERAND_COUNT = 3;
  /// Packs the generated `REGION_NEW` roles in operand order.
  public const long OPCODE_REGION_NEW_ROLE_FORM = 0x487;
  /// Names the generated `REGION_NEW` reversibility class.
  public const long OPCODE_REGION_NEW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `WORDS_ALLOC` opcode identity.
  public const long OPCODE_WORDS_ALLOC = 0x0542;
  /// Names the generated `WORDS_ALLOC` operand count.
  public const long OPCODE_WORDS_ALLOC_OPERAND_COUNT = 3;
  /// Packs the generated `WORDS_ALLOC` roles in operand order.
  public const long OPCODE_WORDS_ALLOC_ROLE_FORM = 0x12c7;
  /// Names the generated `WORDS_ALLOC` reversibility class.
  public const long OPCODE_WORDS_ALLOC_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `WORDS_GET` opcode identity.
  public const long OPCODE_WORDS_GET = 0x0543;
  /// Names the generated `WORDS_GET` operand count.
  public const long OPCODE_WORDS_GET_OPERAND_COUNT = 3;
  /// Packs the generated `WORDS_GET` roles in operand order.
  public const long OPCODE_WORDS_GET_ROLE_FORM = 0x36c7;
  /// Names the generated `WORDS_GET` reversibility class.
  public const long OPCODE_WORDS_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `WORDS_SET` opcode identity.
  public const long OPCODE_WORDS_SET = 0x0544;
  /// Names the generated `WORDS_SET` operand count.
  public const long OPCODE_WORDS_SET_OPERAND_COUNT = 3;
  /// Packs the generated `WORDS_SET` roles in operand order.
  public const long OPCODE_WORDS_SET_ROLE_FORM = 0x6db6;
  /// Names the generated `WORDS_SET` reversibility class.
  public const long OPCODE_WORDS_SET_REVERSIBILITY = REVERSIBILITY_LOGGED;

  /// Names the generated `BUFFER_DROP` opcode identity.
  public const long OPCODE_BUFFER_DROP = 0x0545;
  /// Names the generated `BUFFER_DROP` operand count.
  public const long OPCODE_BUFFER_DROP_OPERAND_COUNT = 1;
  /// Packs the generated `BUFFER_DROP` roles in operand order.
  public const long OPCODE_BUFFER_DROP_ROLE_FORM = 0x14;
  /// Names the generated `BUFFER_DROP` reversibility class.
  public const long OPCODE_BUFFER_DROP_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `REGION_DROP` opcode identity.
  public const long OPCODE_REGION_DROP = 0x0546;
  /// Names the generated `REGION_DROP` operand count.
  public const long OPCODE_REGION_DROP_OPERAND_COUNT = 1;
  /// Packs the generated `REGION_DROP` roles in operand order.
  public const long OPCODE_REGION_DROP_ROLE_FORM = 0x14;
  /// Names the generated `REGION_DROP` reversibility class.
  public const long OPCODE_REGION_DROP_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `BYTES_ALLOC` opcode identity.
  public const long OPCODE_BYTES_ALLOC = 0x0547;
  /// Names the generated `BYTES_ALLOC` operand count.
  public const long OPCODE_BYTES_ALLOC_OPERAND_COUNT = 3;
  /// Packs the generated `BYTES_ALLOC` roles in operand order.
  public const long OPCODE_BYTES_ALLOC_ROLE_FORM = 0x12c7;
  /// Names the generated `BYTES_ALLOC` reversibility class.
  public const long OPCODE_BYTES_ALLOC_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `BYTES_GET` opcode identity.
  public const long OPCODE_BYTES_GET = 0x0548;
  /// Names the generated `BYTES_GET` operand count.
  public const long OPCODE_BYTES_GET_OPERAND_COUNT = 3;
  /// Packs the generated `BYTES_GET` roles in operand order.
  public const long OPCODE_BYTES_GET_ROLE_FORM = 0x36c7;
  /// Names the generated `BYTES_GET` reversibility class.
  public const long OPCODE_BYTES_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `BYTES_SET` opcode identity.
  public const long OPCODE_BYTES_SET = 0x0549;
  /// Names the generated `BYTES_SET` operand count.
  public const long OPCODE_BYTES_SET_OPERAND_COUNT = 3;
  /// Packs the generated `BYTES_SET` roles in operand order.
  public const long OPCODE_BYTES_SET_ROLE_FORM = 0x6db6;
  /// Names the generated `BYTES_SET` reversibility class.
  public const long OPCODE_BYTES_SET_REVERSIBILITY = REVERSIBILITY_LOGGED;

  /// Names the generated `UTF8_VALID` opcode identity.
  public const long OPCODE_UTF8_VALID = 0x054a;
  /// Names the generated `UTF8_VALID` operand count.
  public const long OPCODE_UTF8_VALID_OPERAND_COUNT = 2;
  /// Packs the generated `UTF8_VALID` roles in operand order.
  public const long OPCODE_UTF8_VALID_ROLE_FORM = 0x367;
  /// Names the generated `UTF8_VALID` reversibility class.
  public const long OPCODE_UTF8_VALID_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `UTF8_COUNT` opcode identity.
  public const long OPCODE_UTF8_COUNT = 0x054b;
  /// Names the generated `UTF8_COUNT` operand count.
  public const long OPCODE_UTF8_COUNT_OPERAND_COUNT = 2;
  /// Packs the generated `UTF8_COUNT` roles in operand order.
  public const long OPCODE_UTF8_COUNT_ROLE_FORM = 0x367;
  /// Names the generated `UTF8_COUNT` reversibility class.
  public const long OPCODE_UTF8_COUNT_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `BUFFER_LENGTH` opcode identity.
  public const long OPCODE_BUFFER_LENGTH = 0x054c;
  /// Names the generated `BUFFER_LENGTH` operand count.
  public const long OPCODE_BUFFER_LENGTH_OPERAND_COUNT = 2;
  /// Packs the generated `BUFFER_LENGTH` roles in operand order.
  public const long OPCODE_BUFFER_LENGTH_ROLE_FORM = 0x367;
  /// Names the generated `BUFFER_LENGTH` reversibility class.
  public const long OPCODE_BUFFER_LENGTH_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `UTF8_SCALAR` opcode identity.
  public const long OPCODE_UTF8_SCALAR = 0x054d;
  /// Names the generated `UTF8_SCALAR` operand count.
  public const long OPCODE_UTF8_SCALAR_OPERAND_COUNT = 3;
  /// Packs the generated `UTF8_SCALAR` roles in operand order.
  public const long OPCODE_UTF8_SCALAR_ROLE_FORM = 0x36c7;
  /// Names the generated `UTF8_SCALAR` reversibility class.
  public const long OPCODE_UTF8_SCALAR_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `UTF8_WIDTH` opcode identity.
  public const long OPCODE_UTF8_WIDTH = 0x054e;
  /// Names the generated `UTF8_WIDTH` operand count.
  public const long OPCODE_UTF8_WIDTH_OPERAND_COUNT = 3;
  /// Packs the generated `UTF8_WIDTH` roles in operand order.
  public const long OPCODE_UTF8_WIDTH_ROLE_FORM = 0x36c7;
  /// Names the generated `UTF8_WIDTH` reversibility class.
  public const long OPCODE_UTF8_WIDTH_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `MAP_ALLOC` opcode identity.
  public const long OPCODE_MAP_ALLOC = 0x054f;
  /// Names the generated `MAP_ALLOC` operand count.
  public const long OPCODE_MAP_ALLOC_OPERAND_COUNT = 3;
  /// Packs the generated `MAP_ALLOC` roles in operand order.
  public const long OPCODE_MAP_ALLOC_ROLE_FORM = 0x12c7;
  /// Names the generated `MAP_ALLOC` reversibility class.
  public const long OPCODE_MAP_ALLOC_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `MAP_PUT` opcode identity.
  public const long OPCODE_MAP_PUT = 0x0550;
  /// Names the generated `MAP_PUT` operand count.
  public const long OPCODE_MAP_PUT_OPERAND_COUNT = 3;
  /// Packs the generated `MAP_PUT` roles in operand order.
  public const long OPCODE_MAP_PUT_ROLE_FORM = 0x6df6;
  /// Names the generated `MAP_PUT` reversibility class.
  public const long OPCODE_MAP_PUT_REVERSIBILITY = REVERSIBILITY_LOGGED;

  /// Names the generated `MAP_GET` opcode identity.
  public const long OPCODE_MAP_GET = 0x0551;
  /// Names the generated `MAP_GET` operand count.
  public const long OPCODE_MAP_GET_OPERAND_COUNT = 3;
  /// Packs the generated `MAP_GET` roles in operand order.
  public const long OPCODE_MAP_GET_ROLE_FORM = 0x3ec7;
  /// Names the generated `MAP_GET` reversibility class.
  public const long OPCODE_MAP_GET_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `MAP_HAS` opcode identity.
  public const long OPCODE_MAP_HAS = 0x0552;
  /// Names the generated `MAP_HAS` operand count.
  public const long OPCODE_MAP_HAS_OPERAND_COUNT = 3;
  /// Packs the generated `MAP_HAS` roles in operand order.
  public const long OPCODE_MAP_HAS_ROLE_FORM = 0x3ec7;
  /// Names the generated `MAP_HAS` reversibility class.
  public const long OPCODE_MAP_HAS_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `UTF8_FREEZE` opcode identity.
  public const long OPCODE_UTF8_FREEZE = 0x0553;
  /// Names the generated `UTF8_FREEZE` operand count.
  public const long OPCODE_UTF8_FREEZE_OPERAND_COUNT = 2;
  /// Packs the generated `UTF8_FREEZE` roles in operand order.
  public const long OPCODE_UTF8_FREEZE_ROLE_FORM = 0x367;
  /// Names the generated `UTF8_FREEZE` reversibility class.
  public const long OPCODE_UTF8_FREEZE_REVERSIBILITY = REVERSIBILITY_LOGGED;

  /// Names the generated `UTF8_BORROW` opcode identity.
  public const long OPCODE_UTF8_BORROW = 0x0554;
  /// Names the generated `UTF8_BORROW` operand count.
  public const long OPCODE_UTF8_BORROW_OPERAND_COUNT = 2;
  /// Packs the generated `UTF8_BORROW` roles in operand order.
  public const long OPCODE_UTF8_BORROW_ROLE_FORM = 0x367;
  /// Names the generated `UTF8_BORROW` reversibility class.
  public const long OPCODE_UTF8_BORROW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `MAP_BORROW` opcode identity.
  public const long OPCODE_MAP_BORROW = 0x0555;
  /// Names the generated `MAP_BORROW` operand count.
  public const long OPCODE_MAP_BORROW_OPERAND_COUNT = 2;
  /// Packs the generated `MAP_BORROW` roles in operand order.
  public const long OPCODE_MAP_BORROW_ROLE_FORM = 0x367;
  /// Names the generated `MAP_BORROW` reversibility class.
  public const long OPCODE_MAP_BORROW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `BUFFER_BORROW` opcode identity.
  public const long OPCODE_BUFFER_BORROW = 0x0556;
  /// Names the generated `BUFFER_BORROW` operand count.
  public const long OPCODE_BUFFER_BORROW_OPERAND_COUNT = 2;
  /// Packs the generated `BUFFER_BORROW` roles in operand order.
  public const long OPCODE_BUFFER_BORROW_ROLE_FORM = 0x367;
  /// Names the generated `BUFFER_BORROW` reversibility class.
  public const long OPCODE_BUFFER_BORROW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `REGION_BORROW` opcode identity.
  public const long OPCODE_REGION_BORROW = 0x0557;
  /// Names the generated `REGION_BORROW` operand count.
  public const long OPCODE_REGION_BORROW_OPERAND_COUNT = 2;
  /// Packs the generated `REGION_BORROW` roles in operand order.
  public const long OPCODE_REGION_BORROW_ROLE_FORM = 0x367;
  /// Names the generated `REGION_BORROW` reversibility class.
  public const long OPCODE_REGION_BORROW_REVERSIBILITY = REVERSIBILITY_CHECKED;

  /// Names the generated `OUTPUT_LENGTH` opcode identity.
  public const long OPCODE_OUTPUT_LENGTH = 0x0558;
  /// Names the generated `OUTPUT_LENGTH` operand count.
  public const long OPCODE_OUTPUT_LENGTH_OPERAND_COUNT = 2;
  /// Packs the generated `OUTPUT_LENGTH` roles in operand order.
  public const long OPCODE_OUTPUT_LENGTH_ROLE_FORM = 0x256;
  /// Names the generated `OUTPUT_LENGTH` reversibility class.
  public const long OPCODE_OUTPUT_LENGTH_REVERSIBILITY = REVERSIBILITY_LOGGED;
}
