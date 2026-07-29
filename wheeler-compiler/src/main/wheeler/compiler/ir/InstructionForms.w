//! Defines canonical operand counts for Wheeler-native instruction verification.

module wheeler.compiler.instruction_forms;

import wheeler.compiler.opcodes;

classical class InstructionForms {
  /// Returns the canonical operand count or minus one for an unknown opcode.
  public long expectedOperandCount(long opcode) {
    if (opcode == OPCODE_HALT) {
      return 0;
    }

    if (opcode == OPCODE_RETURN) {
      return 0;
    }

    if (opcode == OPCODE_ADD_CONST) {
      return 2;
    }

    if (opcode == OPCODE_SUB_CONST) {
      return 2;
    }

    if (opcode == OPCODE_XOR_CONST) {
      return 2;
    }

    if (opcode == OPCODE_CALL) {
      return 1;
    }

    if (opcode == OPCODE_UNCALL) {
      return 1;
    }

    if (opcode == OPCODE_CALL_VALUE) {
      return 4;
    }

    if (opcode == OPCODE_RETURN_VALUE) {
      return 1;
    }

    if (opcode == OPCODE_CALL_VOID) {
      return 3;
    }

    if (opcode == OPCODE_CALL_RESULT_SLOT) {
      return 4;
    }

    if (opcode == OPCODE_UNCALL_RESULT_SLOT) {
      return 4;
    }

    if (opcode == OPCODE_RESULT_FILL_CONSTANT) {
      return 2;
    }

    if (opcode == OPCODE_RETURN_RESULT_SLOT) {
      return 1;
    }

    if (opcode == OPCODE_EXPECT_EQ) {
      return 2;
    }

    if (opcode == OPCODE_EXPECT_TRUE) {
      return 1;
    }

    if (opcode == OPCODE_LOCAL_CONST) {
      return 2;
    }

    if (opcode == OPCODE_LOCAL_LOAD_GLOBAL) {
      return 2;
    }

    if (opcode == OPCODE_LOCAL_STORE_GLOBAL) {
      return 2;
    }

    if (opcode == OPCODE_LOCAL_MOVE) {
      return 2;
    }

    if (opcode == OPCODE_LOCAL_ADD) {
      return 3;
    }

    if (opcode == OPCODE_LOCAL_SUB) {
      return 3;
    }

    if (opcode == OPCODE_LOCAL_XOR) {
      return 3;
    }

    if (opcode == OPCODE_LOCAL_MUL) {
      return 3;
    }

    if (opcode == OPCODE_LOCAL_DIV) {
      return 3;
    }

    if (opcode == OPCODE_LOCAL_MOD) {
      return 3;
    }

    if (opcode == OPCODE_LOCAL_AND) {
      return 3;
    }

    if (opcode == OPCODE_LOCAL_ROTR32) {
      return 3;
    }

    if (opcode == OPCODE_LOCAL_EQ) {
      return 3;
    }

    if (opcode == OPCODE_LOCAL_LT) {
      return 3;
    }

    if (opcode == OPCODE_JUMP) {
      return 1;
    }

    if (opcode == OPCODE_JUMP_IF_ZERO) {
      return 2;
    }

    if (opcode == OPCODE_LOCAL_LOOP_CHECK) {
      return 2;
    }

    if (opcode == OPCODE_RECORD_NEW) {
      return 4;
    }

    if (opcode == OPCODE_RECORD_GET) {
      return 3;
    }

    if (opcode == OPCODE_VARIANT_NEW) {
      return 5;
    }

    if (opcode == OPCODE_VARIANT_TAG_EQ) {
      return 3;
    }

    if (opcode == OPCODE_VARIANT_GET) {
      return 4;
    }

    if (opcode == OPCODE_ARRAY_NEW) {
      return 4;
    }

    if (opcode == OPCODE_ARRAY_GET) {
      return 3;
    }

    if (opcode == OPCODE_SLICE_NEW) {
      return 5;
    }

    if (opcode == OPCODE_SLICE_GET) {
      return 3;
    }

    if (opcode == OPCODE_OWNED_MOVE) {
      return 2;
    }

    if (opcode == OPCODE_REGION_NEW) {
      return 3;
    }

    if (opcode == OPCODE_WORDS_ALLOC) {
      return 3;
    }

    if (opcode == OPCODE_WORDS_GET) {
      return 3;
    }

    if (opcode == OPCODE_WORDS_SET) {
      return 3;
    }

    if (opcode == OPCODE_BUFFER_DROP) {
      return 1;
    }

    if (opcode == OPCODE_REGION_DROP) {
      return 1;
    }

    if (opcode == OPCODE_BYTES_ALLOC) {
      return 3;
    }

    if (opcode == OPCODE_BYTES_GET) {
      return 3;
    }

    if (opcode == OPCODE_BYTES_SET) {
      return 3;
    }

    if (opcode == OPCODE_UTF8_VALID) {
      return 2;
    }

    if (opcode == OPCODE_UTF8_COUNT) {
      return 2;
    }

    if (opcode == OPCODE_BUFFER_LENGTH) {
      return 2;
    }

    if (opcode == OPCODE_UTF8_SCALAR) {
      return 3;
    }

    if (opcode == OPCODE_UTF8_WIDTH) {
      return 3;
    }

    if (opcode == OPCODE_MAP_ALLOC) {
      return 3;
    }

    if (opcode == OPCODE_MAP_PUT) {
      return 3;
    }

    if (opcode == OPCODE_MAP_GET) {
      return 3;
    }

    if (opcode == OPCODE_MAP_HAS) {
      return 3;
    }

    if (opcode == OPCODE_UTF8_FREEZE) {
      return 2;
    }

    if (opcode == OPCODE_UTF8_BORROW) {
      return 2;
    }

    if (opcode == OPCODE_MAP_BORROW) {
      return 2;
    }

    if (opcode == OPCODE_BUFFER_BORROW) {
      return 2;
    }

    if (opcode == OPCODE_REGION_BORROW) {
      return 2;
    }

    return -1;
  }

}
