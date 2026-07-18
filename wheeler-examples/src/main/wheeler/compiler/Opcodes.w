/// Defines canonical opcode identities for Wheeler-written bytecode tools.
module examples.compiler.opcodes;
classical class Opcodes {
    public const long OPCODE_HALT = 0x0001;
    public const long OPCODE_RETURN = 0x0002;

    public const long OPCODE_ADD_CONST = 0x0100;
    public const long OPCODE_SUB_CONST = 0x0101;
    public const long OPCODE_XOR_CONST = 0x0102;

    public const long OPCODE_CALL = 0x0200;
    public const long OPCODE_UNCALL = 0x0201;
    public const long OPCODE_CALL_VALUE = 0x0202;
    public const long OPCODE_RETURN_VALUE = 0x0203;
    public const long OPCODE_CALL_VOID = 0x0204;
    public const long OPCODE_EXPECT_EQ = 0x0300;

    public const long OPCODE_LOCAL_CONST = 0x0400;
    public const long OPCODE_LOCAL_LOAD_GLOBAL = 0x0401;
    public const long OPCODE_LOCAL_STORE_GLOBAL = 0x0402;
    public const long OPCODE_LOCAL_MOVE = 0x0403;
    public const long OPCODE_LOCAL_ADD = 0x0410;
    public const long OPCODE_LOCAL_SUB = 0x0411;
    public const long OPCODE_LOCAL_XOR = 0x0412;
    public const long OPCODE_LOCAL_MUL = 0x0413;
    public const long OPCODE_LOCAL_DIV = 0x0414;
    public const long OPCODE_LOCAL_MOD = 0x0415;
    public const long OPCODE_LOCAL_AND = 0x0416;
    public const long OPCODE_LOCAL_ROTR32 = 0x0417;
    public const long OPCODE_LOCAL_EQ = 0x0420;
    public const long OPCODE_LOCAL_LT = 0x0421;
    public const long OPCODE_JUMP = 0x0430;
    public const long OPCODE_JUMP_IF_ZERO = 0x0431;
    public const long OPCODE_LOCAL_LOOP_CHECK = 0x0432;
    public const long OPCODE_RECORD_NEW = 0x0500;
    public const long OPCODE_RECORD_GET = 0x0501;
    public const long OPCODE_VARIANT_NEW = 0x0510;
    public const long OPCODE_VARIANT_TAG_EQ = 0x0511;
    public const long OPCODE_VARIANT_GET = 0x0512;
    public const long OPCODE_ARRAY_NEW = 0x0520;
    public const long OPCODE_ARRAY_GET = 0x0521;
    public const long OPCODE_SLICE_NEW = 0x0530;
    public const long OPCODE_SLICE_GET = 0x0531;
    public const long OPCODE_OWNED_MOVE = 0x0540;
    public const long OPCODE_REGION_NEW = 0x0541;
    public const long OPCODE_WORDS_ALLOC = 0x0542;
    public const long OPCODE_WORDS_GET = 0x0543;
    public const long OPCODE_WORDS_SET = 0x0544;
    public const long OPCODE_BUFFER_DROP = 0x0545;
    public const long OPCODE_REGION_DROP = 0x0546;
    public const long OPCODE_BYTES_ALLOC = 0x0547;
    public const long OPCODE_BYTES_GET = 0x0548;
    public const long OPCODE_BYTES_SET = 0x0549;
    public const long OPCODE_UTF8_VALID = 0x054a;
    public const long OPCODE_UTF8_COUNT = 0x054b;
    public const long OPCODE_BUFFER_LENGTH = 0x054c;
    public const long OPCODE_UTF8_SCALAR = 0x054d;
    public const long OPCODE_UTF8_WIDTH = 0x054e;
    public const long OPCODE_MAP_ALLOC = 0x054f;
    public const long OPCODE_MAP_PUT = 0x0550;
    public const long OPCODE_MAP_GET = 0x0551;
    public const long OPCODE_MAP_HAS = 0x0552;
    public const long OPCODE_UTF8_FREEZE = 0x0553;
    public const long OPCODE_UTF8_BORROW = 0x0554;

    public const long INTERPRETER_STORAGE_COUNT = 16;
    public const long INTERPRETER_STORAGE_WORDS = 128;
    public const long INTERPRETER_AGGREGATE_COUNT = 32;
    public const long INTERPRETER_AGGREGATE_FIELDS = 128;
    public const long INTERPRETER_LOCAL_WIDTH = 32;
    public const long INTERPRETER_FRAME_COUNT = 8;
    public const long INTERPRETER_FUNCTION_COUNT = 8;
    public const long INTERPRETER_GLOBAL_COUNT = 8;
    public const long INTERPRETER_LOCAL_CAPACITY =
        INTERPRETER_LOCAL_WIDTH * INTERPRETER_FRAME_COUNT;
    public const long INTERPRETER_MAX_CALL_DEPTH =
        INTERPRETER_FRAME_COUNT - 1;
    public const long MAX_CODE_INSTRUCTIONS = 64;
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
