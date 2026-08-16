//! Resolves buffer types and assertion opcodes onto exact physical locals.

module wheeler.compiler.closure.direct_statement_coordinates;

import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.structured_source_coordinates;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.type_codes;

classical class DirectStatementCoordinates {
  /// Returns the exact retained type of one buffer value.
  public long directBufferLocalType(
    borrow utf8 source,
    long owner,
    long local,
    long valueCount,
    borrow mut words valueRows,
    long semanticCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long sourceType = loopBodyValueType(
      source,
      owner,
      local,
      valueCount,
      valueRows,
      semanticCount,
      tokenStarts,
      tokenLengths
    );
    boolean borrowed = borrowedLoopBodyLocal(
      source,
      owner,
      local,
      valueCount,
      valueRows,
      semanticCount,
      tokenStarts,
      tokenLengths
    );
    if (sourceType == TOKEN_BYTEVIEW) {
      return TYPE_BYTE_VIEW;
    }

    if (sourceType == TOKEN_WORDS) {
      if (borrowed) {
        return TYPE_WORDS_BORROW;
      }

      return TYPE_WORDS;
    }

    if (sourceType == TOKEN_BYTES) {
      if (borrowed) {
        return TYPE_BYTES_BORROW;
      }

      return TYPE_BYTES;
    }

    if (sourceType == TOKEN_UTF8) {
      if (borrowed) {
        return TYPE_UTF8_BORROW;
      }

      return TYPE_UTF8;
    }

    return -1;
  }

  /// Maps one assertion's packed local component onto its physical local.
  public long physicalDirectAssertionOpcode(
    long opcode,
    long owner,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementLocalRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words statementPhysicalStarts
  ) {
    long base = -1;
    if (BODY_ASSERT_EQ_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_BOOLEAN_LITERAL) {
        base = opcode / 256 * 256;
      }
    }

    if (BODY_ASSERT_LITERAL_LT_BASE - 1 < opcode) {
      if (opcode < BODY_ASSERT_LOCAL_LT_BASE + 256) {
        base = opcode / 256 * 256;
      }
    }

    if (base < 0) {
      return opcode;
    }

    long physical = physicalValueLocal(
      owner,
      opcode - base,
      statementCount,
      statementRows,
      statementLocalRows,
      valueCount,
      valueRows,
      statementPhysicalStarts
    );
    if (physical < 0) {
      return -1;
    }

    return base + physical;
  }
}
