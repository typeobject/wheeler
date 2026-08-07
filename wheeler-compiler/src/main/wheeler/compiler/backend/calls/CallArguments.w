//! Selects canonical opcodes for typed helper-call arguments.

module wheeler.compiler.call_arguments;

import wheeler.compiler.opcodes;
import wheeler.compiler.storage_opcodes;
import wheeler.compiler.type_codes;

classical class CallArguments {
  /// Selects one type from the bounded scalar-call source column.
  public long callSourceType(
    long index,
    long firstSourceType,
    long secondSourceType,
    long thirdSourceType,
    long fourthSourceType,
    long fifthSourceType,
    long sixthSourceType,
    long seventhSourceType
  ) {
    if (index == 0) {
      return firstSourceType;
    }

    if (index == 1) {
      return secondSourceType;
    }

    if (index == 2) {
      return thirdSourceType;
    }

    if (index == 3) {
      return fourthSourceType;
    }

    if (index == 4) {
      return fifthSourceType;
    }

    if (index == 5) {
      return sixthSourceType;
    }

    return seventhSourceType;
  }

  /// Returns the reborrow or scalar move opcode for one argument type.
  public long callArgumentOpcode(long type) {
    if (type == TYPE_UTF8_BORROW) {
      return OPCODE_UTF8_BORROW;
    }

    if (type == TYPE_LONG_MAP_BORROW) {
      return OPCODE_MAP_BORROW;
    }

    if (type == TYPE_REGION_BORROW) {
      return OPCODE_REGION_BORROW;
    }

    if (type == TYPE_WORDS_BORROW) {
      return OPCODE_BUFFER_BORROW;
    }

    if (type == TYPE_BYTES_BORROW) {
      return OPCODE_BUFFER_BORROW;
    }

    if (type == TYPE_BYTE_VIEW) {
      return OPCODE_BUFFER_BORROW;
    }

    return OPCODE_LOCAL_MOVE;
  }
}
