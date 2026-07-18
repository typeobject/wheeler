//! Defines canonical opcode identities for Wheeler-written bytecode tools.
module examples.compiler.opcodes;
classical class Opcodes {
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
    /// Names the compile-time `OPCODE_EXPECT_EQ` value owned by this module.
    public const long OPCODE_EXPECT_EQ = 0x0300;

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

    /// Names the compile-time `INTERPRETER_STORAGE_COUNT` value owned by this module.
    public const long INTERPRETER_STORAGE_COUNT = 16;
    /// Names the compile-time `INTERPRETER_STORAGE_WORDS` value owned by this module.
    public const long INTERPRETER_STORAGE_WORDS = 128;
    /// Names the compile-time `INTERPRETER_AGGREGATE_COUNT` value owned by this module.
    public const long INTERPRETER_AGGREGATE_COUNT = 32;
    /// Names the compile-time `INTERPRETER_AGGREGATE_FIELDS` value owned by this module.
    public const long INTERPRETER_AGGREGATE_FIELDS = 128;
    /// Names the compile-time `INTERPRETER_LOCAL_WIDTH` value owned by this module.
    public const long INTERPRETER_LOCAL_WIDTH = 64;
    /// Names the compile-time `INTERPRETER_FRAME_COUNT` value owned by this module.
    public const long INTERPRETER_FRAME_COUNT = 8;
    /// Names the compile-time `INTERPRETER_FUNCTION_COUNT` value owned by this module.
    public const long INTERPRETER_FUNCTION_COUNT = 8;
    /// Names the compile-time `INTERPRETER_GLOBAL_COUNT` value owned by this module.
    public const long INTERPRETER_GLOBAL_COUNT = 8;
    /// Names the compile-time `INTERPRETER_LOCAL_CAPACITY` value owned by this module.
    public const long INTERPRETER_LOCAL_CAPACITY = INTERPRETER_LOCAL_WIDTH
        * INTERPRETER_FRAME_COUNT;
    /// Names the compile-time `INTERPRETER_MAX_CALL_DEPTH` value owned by this module.
    public const long INTERPRETER_MAX_CALL_DEPTH = INTERPRETER_FRAME_COUNT - 1;
    /// Names the compile-time `MAX_CODE_INSTRUCTIONS` value owned by this module.
    public const long MAX_CODE_INSTRUCTIONS = 128;
    /// Names the compile-time `MAX_INTERPRETED_STEPS` value owned by this module.
    public const long MAX_INTERPRETED_STEPS = 512;

    /// Reports whether an opcode mutates one global with a constant operand.
    public boolean isGlobalConstantOpcode(long opcode) {
        if (opcode == OPCODE_ADD_CONST) {
            return true;
        }
        if (opcode == OPCODE_SUB_CONST) {
            return true;
        }
        return opcode == OPCODE_XOR_CONST;
    }

    /// Reports whether an opcode applies the bounded three-local math shape.
    public boolean isLocalMathOpcode(long opcode) {
        if (opcode == OPCODE_LOCAL_ADD) {
            return true;
        }
        if (opcode == OPCODE_LOCAL_SUB) {
            return true;
        }
        if (opcode == OPCODE_LOCAL_XOR) {
            return true;
        }
        if (opcode == OPCODE_LOCAL_MUL) {
            return true;
        }
        if (opcode == OPCODE_LOCAL_DIV) {
            return true;
        }
        if (opcode == OPCODE_LOCAL_MOD) {
            return true;
        }
        if (opcode == OPCODE_LOCAL_AND) {
            return true;
        }
        return opcode == OPCODE_LOCAL_ROTR32;
    }
}
