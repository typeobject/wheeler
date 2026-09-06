package com.typeobject.wheeler.core.proof;

import com.typeobject.wheeler.core.bytecode.Opcode;

/** Explicit instruction policy for one forward-body VM-transition bound. */
final class StaticStepRule {
  private StaticStepRule() {}

  // No default: adding an opcode requires an explicit kernel decision at compile time.
  static boolean admits(Opcode opcode) {
    return switch (opcode) {
      case NOP, HALT, RETURN, ADD_CONST, SUB_CONST, XOR_CONST, SWAP, SET_LOGGED,
          RETURN_VALUE, RESULT_FILL_CONSTANT, RESULT_FILL_SOURCE, RESULT_FILL_BINARY,
          RESULT_FILL_BINARY_SOURCES, RETURN_RESULT_SLOT, EXPECT_EQ, CHECKPOINT, COMMIT,
          EXPECT_TRUE, LOCAL_CONST, LOCAL_LOAD_GLOBAL, LOCAL_STORE_GLOBAL, LOCAL_MOVE,
          LOCAL_ADD, LOCAL_SUB, LOCAL_XOR, LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND,
          LOCAL_ROTR32, LOCAL_EQ, LOCAL_LT, LOCAL_LOOP_CHECK, RECORD_NEW, RECORD_GET,
          VARIANT_NEW, VARIANT_TAG_EQ, VARIANT_GET, ARRAY_NEW, ARRAY_GET, SLICE_NEW, SLICE_GET,
          OWNED_MOVE, REGION_NEW, WORDS_ALLOC, WORDS_GET, WORDS_SET, BUFFER_DROP, REGION_DROP,
          BYTES_ALLOC, BYTES_GET, BYTES_SET, UTF8_VALID, UTF8_COUNT, BUFFER_LENGTH, UTF8_SCALAR,
          UTF8_WIDTH, MAP_ALLOC, MAP_PUT, MAP_GET, MAP_HAS, UTF8_FREEZE, UTF8_BORROW,
          MAP_BORROW, BUFFER_BORROW, REGION_BORROW, OUTPUT_LENGTH -> true;
      case CALL, UNCALL, CALL_VALUE, CALL_VOID, CALL_RESULT_SLOT, UNCALL_RESULT_SLOT,
          JUMP, JUMP_IF_ZERO -> false;
    };
  }
}
