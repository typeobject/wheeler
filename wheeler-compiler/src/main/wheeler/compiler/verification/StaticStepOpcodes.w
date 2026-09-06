//! Admits only explicit one-transition instructions for a forward-body step certificate.

module wheeler.compiler.static_step_opcodes;

import wheeler.compiler.opcodes;
import wheeler.compiler.storage_opcodes;

classical class StaticStepOpcodes {
  private boolean scalarStepOpcode(long opcode) {
    if (opcode == OPCODE_HALT) {
      return true;
    }

    if (opcode == OPCODE_RETURN) {
      return true;
    }

    if (opcode == OPCODE_ADD_CONST) {
      return true;
    }

    if (opcode == OPCODE_SUB_CONST) {
      return true;
    }

    if (opcode == OPCODE_XOR_CONST) {
      return true;
    }

    if (opcode == OPCODE_RETURN_VALUE) {
      return true;
    }

    if (opcode == OPCODE_RESULT_FILL_CONSTANT) {
      return true;
    }

    if (opcode == OPCODE_RESULT_FILL_SOURCE) {
      return true;
    }

    if (opcode == OPCODE_RESULT_FILL_BINARY) {
      return true;
    }

    if (opcode == OPCODE_RESULT_FILL_BINARY_SOURCES) {
      return true;
    }

    if (opcode == OPCODE_RETURN_RESULT_SLOT) {
      return true;
    }

    if (opcode == OPCODE_EXPECT_EQ) {
      return true;
    }

    if (opcode == OPCODE_EXPECT_TRUE) {
      return true;
    }

    if (opcode == OPCODE_LOCAL_CONST) {
      return true;
    }

    if (opcode == OPCODE_LOCAL_LOAD_GLOBAL) {
      return true;
    }

    if (opcode == OPCODE_LOCAL_STORE_GLOBAL) {
      return true;
    }

    if (opcode == OPCODE_LOCAL_MOVE) {
      return true;
    }

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

    if (opcode == OPCODE_LOCAL_ROTR32) {
      return true;
    }

    if (opcode == OPCODE_LOCAL_EQ) {
      return true;
    }

    if (opcode == OPCODE_LOCAL_LT) {
      return true;
    }

    if (opcode == OPCODE_LOCAL_LOOP_CHECK) {
      return true;
    }

    return false;
  }

  private boolean storageStepOpcode(long opcode) {
    if (opcode == OPCODE_RECORD_NEW) {
      return true;
    }

    if (opcode == OPCODE_RECORD_GET) {
      return true;
    }

    if (opcode == OPCODE_VARIANT_NEW) {
      return true;
    }

    if (opcode == OPCODE_VARIANT_TAG_EQ) {
      return true;
    }

    if (opcode == OPCODE_VARIANT_GET) {
      return true;
    }

    if (opcode == OPCODE_ARRAY_NEW) {
      return true;
    }

    if (opcode == OPCODE_ARRAY_GET) {
      return true;
    }

    if (opcode == OPCODE_SLICE_NEW) {
      return true;
    }

    if (opcode == OPCODE_SLICE_GET) {
      return true;
    }

    if (opcode == OPCODE_OWNED_MOVE) {
      return true;
    }

    if (opcode == OPCODE_REGION_NEW) {
      return true;
    }

    if (opcode == OPCODE_WORDS_ALLOC) {
      return true;
    }

    if (opcode == OPCODE_WORDS_GET) {
      return true;
    }

    if (opcode == OPCODE_WORDS_SET) {
      return true;
    }

    if (opcode == OPCODE_BUFFER_DROP) {
      return true;
    }

    if (opcode == OPCODE_REGION_DROP) {
      return true;
    }

    if (opcode == OPCODE_BYTES_ALLOC) {
      return true;
    }

    if (opcode == OPCODE_BYTES_GET) {
      return true;
    }

    if (opcode == OPCODE_BYTES_SET) {
      return true;
    }

    if (opcode == OPCODE_UTF8_VALID) {
      return true;
    }

    if (opcode == OPCODE_UTF8_COUNT) {
      return true;
    }

    if (opcode == OPCODE_BUFFER_LENGTH) {
      return true;
    }

    if (opcode == OPCODE_UTF8_SCALAR) {
      return true;
    }

    if (opcode == OPCODE_UTF8_WIDTH) {
      return true;
    }

    if (opcode == OPCODE_MAP_ALLOC) {
      return true;
    }

    if (opcode == OPCODE_MAP_PUT) {
      return true;
    }

    if (opcode == OPCODE_MAP_GET) {
      return true;
    }

    if (opcode == OPCODE_MAP_HAS) {
      return true;
    }

    if (opcode == OPCODE_UTF8_FREEZE) {
      return true;
    }

    if (opcode == OPCODE_UTF8_BORROW) {
      return true;
    }

    if (opcode == OPCODE_MAP_BORROW) {
      return true;
    }

    if (opcode == OPCODE_BUFFER_BORROW) {
      return true;
    }

    if (opcode == OPCODE_REGION_BORROW) {
      return true;
    }

    return false;
  }

  /// Reports explicit native instruction membership, not artifact or operand validity.
  ///
  /// - Bounds: Unknown identities reject, including gaps between assigned opcodes.
  public boolean staticStepOpcodeAllowed(long opcode) {
    if (scalarStepOpcode(opcode)) {
      return true;
    }

    return storageStepOpcode(opcode);
  }
}
