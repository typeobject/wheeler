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

    public const long INTERPRETER_LOCAL_WIDTH = 16;
    public const long INTERPRETER_FRAME_COUNT = 8;
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
