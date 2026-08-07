//! Owns register and instruction shapes for bounded borrowed intrinsics.

module wheeler.compiler.borrowed_intrinsic_shapes;

import wheeler.compiler.borrowed_intrinsic_kinds;

classical class BorrowedIntrinsicShapes {
  private boolean borrowedMutation(long opcode) {
    if (opcode == STATEMENT_SET_WORD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_SET_WORD) {
      return true;
    }

    if (opcode == STATEMENT_SET_BYTE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_SET_BYTE) {
      return true;
    }

    if (opcode == STATEMENT_SET_OWNED_BYTE) {
      return true;
    }

    if (opcode == STATEMENT_MAP_PUT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_MAP_PUT;
  }

  private boolean indexedRead(long opcode) {
    if (opcode == STATEMENT_LOCAL_MAP_GET_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_MAP_GET) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_MAP_HAS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_MAP_HAS) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_GET_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_GET) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_UTF8_SCALAR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_UTF8_SCALAR) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_UTF8_WIDTH_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_UTF8_WIDTH;
  }

  private boolean directIndexedIntrinsic(long opcode) {
    if (opcode == STATEMENT_RETURN_UTF8_SCALAR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_UTF8_SCALAR) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_UTF8_WIDTH_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_UTF8_WIDTH) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_MAP_GET_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_MAP_GET) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_MAP_HAS_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_MAP_HAS;
  }

  /// Returns the local width for one borrowed intrinsic, or minus one.
  public long borrowedIntrinsicLocalCount(long opcode) {
    if (borrowedMutation(opcode)) {
      return 3;
    }

    if (indexedRead(opcode)) {
      return 4;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_GET_NAMED) {
      return 3;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_GET) {
      return 3;
    }

    if (directIndexedIntrinsic(opcode)) {
      return 3;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_LENGTH) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH_NAMED) {
      return 3;
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH) {
      return 3;
    }

    return -1;
  }

  /// Returns the result-local offset for one intrinsic declaration, or minus one.
  public long borrowedIntrinsicResultOffset(long opcode) {
    if (indexedRead(opcode)) {
      return 3;
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH_NAMED) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH) {
      return 2;
    }

    return -1;
  }

  /// Returns the encoded width for one resolved borrowed intrinsic, or minus one.
  public long borrowedIntrinsicCodeLength(long opcode) {
    if (opcode == STATEMENT_SET_WORD_NAMED) {
      return -1;
    }

    if (opcode == STATEMENT_SET_BYTE_NAMED) {
      return -1;
    }

    if (opcode == STATEMENT_MAP_PUT_NAMED) {
      return -1;
    }

    if (opcode == STATEMENT_RETURN_UTF8_SCALAR_NAMED) {
      return -1;
    }

    if (opcode == STATEMENT_RETURN_UTF8_WIDTH_NAMED) {
      return -1;
    }

    if (opcode == STATEMENT_RETURN_MAP_GET_NAMED) {
      return -1;
    }

    if (opcode == STATEMENT_RETURN_MAP_HAS_NAMED) {
      return -1;
    }

    if (opcode == STATEMENT_LOCAL_MAP_GET_NAMED) {
      return -1;
    }

    if (opcode == STATEMENT_LOCAL_MAP_HAS_NAMED) {
      return -1;
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_GET_NAMED) {
      return -1;
    }

    if (opcode == STATEMENT_LOCAL_UTF8_SCALAR_NAMED) {
      return -1;
    }

    if (opcode == STATEMENT_LOCAL_UTF8_WIDTH_NAMED) {
      return -1;
    }

    if (borrowedMutation(opcode)) {
      return 104;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_LENGTH) {
      return 64;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_GET) {
      return 96;
    }

    if (directIndexedIntrinsic(opcode)) {
      return 96;
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH) {
      return 72;
    }

    if (indexedRead(opcode)) {
      return 104;
    }

    return -1;
  }

  /// Returns the instruction count for one resolved borrowed intrinsic, or minus one.
  public long borrowedIntrinsicInstructionCount(long opcode) {
    long length = borrowedIntrinsicCodeLength(opcode);
    if (length == 64) {
      return 3;
    }

    if (length == 72) {
      return 3;
    }

    if (length == 96) {
      return 4;
    }

    if (length == 104) {
      return 4;
    }

    return -1;
  }
}
