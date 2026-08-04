//! Defines canonical opcode identities for Wheeler-written bytecode tools.
module wheeler.compiler.opcodes;

classical class Opcodes {
  /// Names an instruction form with no operand fields.
  public const long INSTRUCTION_FORM_NULLARY = 0;
  /// Names an instruction form with one operand field.
  public const long INSTRUCTION_FORM_UNARY = 1;
  /// Names an instruction form with two operand fields.
  public const long INSTRUCTION_FORM_BINARY = 2;
  /// Names an instruction form with three operand fields.
  public const long INSTRUCTION_FORM_TERNARY = 3;
  /// Names an instruction form with four operand fields.
  public const long INSTRUCTION_FORM_QUATERNARY = 4;
  /// Names an instruction form with five operand fields.
  public const long INSTRUCTION_FORM_QUINARY = 5;
  /// Names the byte width of every canonical instruction operand.
  public const long INSTRUCTION_OPERAND_WIDTH = 8;

  /// Names the compile-time `OPCODE_HALT` value owned by this module.
  public const long OPCODE_HALT = 0x0001;
  /// Names the compile-time `OPCODE_RETURN` value owned by this module.
  public const long OPCODE_RETURN = 0x0002;

  /// Names the compile-time `OPCODE_ADD_CONST` value owned by this module.
  public const long OPCODE_ADD_CONST = 0x0100;
  /// Names the compile-time `OPCODE_SUB_CONST` value owned by this module.
  public const long OPCODE_SUB_CONST = 0x0101;
  /// Names the compile-time `OPCODE_XOR_CONST` value owned by this module.
  public const long OPCODE_XOR_CONST = 0x0102;

  /// Names the compile-time `OPCODE_CALL` value owned by this module.
  public const long OPCODE_CALL = 0x0200;
  /// Names the compile-time `OPCODE_UNCALL` value owned by this module.
  public const long OPCODE_UNCALL = 0x0201;
  /// Names the compile-time `OPCODE_CALL_VALUE` value owned by this module.
  public const long OPCODE_CALL_VALUE = 0x0202;
  /// Names the compile-time `OPCODE_RETURN_VALUE` value owned by this module.
  public const long OPCODE_RETURN_VALUE = 0x0203;
  /// Names the compile-time `OPCODE_CALL_VOID` value owned by this module.
  public const long OPCODE_CALL_VOID = 0x0204;
  /// Calls one reversible value function with a vacant caller result slot.
  public const long OPCODE_CALL_RESULT_SLOT = 0x0205;
  /// Calls one reversible value function inverse with its occupied result slot.
  public const long OPCODE_UNCALL_RESULT_SLOT = 0x0206;
  /// Exchanges an implicit result slot with one exact signed constant.
  public const long OPCODE_RESULT_FILL_CONSTANT = 0x0207;
  /// Returns one implicit result slot to its caller.
  public const long OPCODE_RETURN_RESULT_SLOT = 0x0208;
  /// Exchanges an implicit result slot with one preserved signed source local.
  public const long OPCODE_RESULT_FILL_SOURCE = 0x0209;
  /// Exchanges a result slot with one signed source and constant operation.
  public const long OPCODE_RESULT_FILL_BINARY = 0x020a;
  /// Exchanges a result slot with one operation over two signed sources.
  public const long OPCODE_RESULT_FILL_BINARY_SOURCES = 0x020b;
  /// Names the compile-time `OPCODE_EXPECT_EQ` value owned by this module.
  public const long OPCODE_EXPECT_EQ = 0x0300;

  /// Names the compile-time `OPCODE_EXPECT_TRUE` value owned by this module.
  public const long OPCODE_EXPECT_TRUE = 0x0303;

  /// Names the compile-time `OPCODE_LOCAL_CONST` value owned by this module.
  public const long OPCODE_LOCAL_CONST = 0x0400;
  /// Names the compile-time `OPCODE_LOCAL_LOAD_GLOBAL` value owned by this module.
  public const long OPCODE_LOCAL_LOAD_GLOBAL = 0x0401;
  /// Names the compile-time `OPCODE_LOCAL_STORE_GLOBAL` value owned by this module.
  public const long OPCODE_LOCAL_STORE_GLOBAL = 0x0402;
  /// Names the compile-time `OPCODE_LOCAL_MOVE` value owned by this module.
  public const long OPCODE_LOCAL_MOVE = 0x0403;
  /// Names the compile-time `OPCODE_LOCAL_ADD` value owned by this module.
  public const long OPCODE_LOCAL_ADD = 0x0410;
  /// Names the compile-time `OPCODE_LOCAL_SUB` value owned by this module.
  public const long OPCODE_LOCAL_SUB = 0x0411;
  /// Names the compile-time `OPCODE_LOCAL_XOR` value owned by this module.
  public const long OPCODE_LOCAL_XOR = 0x0412;
  /// Names the compile-time `OPCODE_LOCAL_MUL` value owned by this module.
  public const long OPCODE_LOCAL_MUL = 0x0413;
  /// Names the compile-time `OPCODE_LOCAL_DIV` value owned by this module.
  public const long OPCODE_LOCAL_DIV = 0x0414;
  /// Names the compile-time `OPCODE_LOCAL_MOD` value owned by this module.
  public const long OPCODE_LOCAL_MOD = 0x0415;
  /// Names the compile-time `OPCODE_LOCAL_AND` value owned by this module.
  public const long OPCODE_LOCAL_AND = 0x0416;
  /// Names the compile-time `OPCODE_LOCAL_ROTR32` value owned by this module.
  public const long OPCODE_LOCAL_ROTR32 = 0x0417;
  /// Names the compile-time `OPCODE_LOCAL_EQ` value owned by this module.
  public const long OPCODE_LOCAL_EQ = 0x0420;
  /// Names the compile-time `OPCODE_LOCAL_LT` value owned by this module.
  public const long OPCODE_LOCAL_LT = 0x0421;
  /// Names the compile-time `OPCODE_JUMP` value owned by this module.
  public const long OPCODE_JUMP = 0x0430;
  /// Names the compile-time `OPCODE_JUMP_IF_ZERO` value owned by this module.
  public const long OPCODE_JUMP_IF_ZERO = 0x0431;
  /// Names the compile-time `OPCODE_LOCAL_LOOP_CHECK` value owned by this module.
  public const long OPCODE_LOCAL_LOOP_CHECK = 0x0432;

  /// Names the compile-time `INTERPRETER_STORAGE_COUNT` value owned by this module.
  public const long INTERPRETER_STORAGE_COUNT = 16;
  /// Names the compile-time `INTERPRETER_STORAGE_WORDS` value owned by this module.
  public const long INTERPRETER_STORAGE_WORDS = 128;
  /// Names the compile-time `INTERPRETER_AGGREGATE_COUNT` value owned by this module.
  public const long INTERPRETER_AGGREGATE_COUNT = 32;
  /// Names the compile-time `INTERPRETER_AGGREGATE_FIELDS` value owned by this module.
  public const long INTERPRETER_AGGREGATE_FIELDS = 128;
  /// Names the compile-time `INTERPRETER_LOCAL_WIDTH` value owned by this module.
  public const long INTERPRETER_LOCAL_WIDTH = 256;
  /// Names the compile-time `INTERPRETER_FRAME_COUNT` value owned by this module.
  public const long INTERPRETER_FRAME_COUNT = 8;
  /// Names the compile-time `INTERPRETER_FUNCTION_COUNT` value owned by this module.
  public const long INTERPRETER_FUNCTION_COUNT = 8;
  /// Names the compile-time `INTERPRETER_GLOBAL_COUNT` value owned by this module.
  public const long INTERPRETER_GLOBAL_COUNT = 8;
  /// Names the compile-time `INTERPRETER_LOCAL_CAPACITY` value owned by this module.
  public const long INTERPRETER_LOCAL_CAPACITY = INTERPRETER_LOCAL_WIDTH * INTERPRETER_FRAME_COUNT;
  /// Names the compile-time `INTERPRETER_MAX_CALL_DEPTH` value owned by this module.
  public const long INTERPRETER_MAX_CALL_DEPTH = INTERPRETER_FRAME_COUNT - 1;
  /// Names the compile-time `MAX_CODE_INSTRUCTIONS` value owned by this module.
  public const long MAX_CODE_INSTRUCTIONS = 512;
  /// Names the compile-time `MAX_INTERPRETED_STEPS` value owned by this module.
  public const long MAX_INTERPRETED_STEPS = 512;

}
