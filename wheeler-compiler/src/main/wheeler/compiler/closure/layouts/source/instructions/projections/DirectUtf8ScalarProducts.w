//! Emits exact root UTF-8 scalar projection products.

module wheeler.compiler.closure.direct_utf8_scalar_products;

import wheeler.compiler.closure.direct_statement_coordinates;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.structured_source_coordinates;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.storage_opcodes;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class DirectUtf8ScalarProducts {
  private const long MAX_CODE_BYTES = 262144;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports one exact UTF-8 scalar projection instruction and type extent.
  public record DirectUtf8ScalarProduct(long next, long typeCount, boolean valid) {}

  private DirectUtf8ScalarProduct invalidProjection() {
    return new DirectUtf8ScalarProduct(0, 0, false);
  }

  /// Writes one complete `long value = utf8Scalar(source, index);` initializer product.
  public DirectUtf8ScalarProduct writeDirectUtf8Scalar(
    borrow utf8 source,
    long token,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long owner,
    long ordinal,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words typeRows,
    long typeCount,
    borrow mut bytes output,
    long cursor,
    long localBase
  ) {
    assert(bufferLength(typeRows) == 12288);
    assert(-1 < typeCount);
    assert(typeCount < 4093);
    assert(bufferLength(output) == MAX_CODE_BYTES);
    if (token < 0) {
      return invalidProjection();
    }

    if (tokenCount < token + 7) {
      return invalidProjection();
    }

    if (252 < localBase) {
      return invalidProjection();
    }

    if (tokenHash(source, tokenStarts, tokenLengths, token) != TOKEN_UTF8_SCALAR) {
      return invalidProjection();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_OPEN_PAREN) == false
    ) {
      return invalidProjection();
    }

    if (tokenKinds[token + 2] != 1) {
      return invalidProjection();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 3, PUNCTUATION_COMMA) == false
    ) {
      return invalidProjection();
    }

    if (tokenKinds[token + 4] != 1) {
      return invalidProjection();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 5, PUNCTUATION_CLOSE_PAREN) == false
    ) {
      return invalidProjection();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 6, PUNCTUATION_SEMICOLON) == false
    ) {
      return invalidProjection();
    }

    LoopBodyValue text = resolveLoopBodyValue(
      source,
      tokenStarts[token + 2],
      tokenLengths[token + 2],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    LoopBodyValue index = resolveLoopBodyValue(
      source,
      tokenStarts[token + 4],
      tokenLengths[token + 4],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (text.valid == false) {
      return invalidProjection();
    }

    if (index.valid == false) {
      return invalidProjection();
    }

    long textType = directBufferLocalType(
      source,
      owner,
      text.local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (textType != TYPE_UTF8_BORROW) {
      return invalidProjection();
    }

    if (
      signedLoopBodyLocal(
        source,
        owner,
        index.local,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      ) == false
    ) {
      return invalidProjection();
    }

    long textLocal = physicalValueLocal(
      owner,
      text.local,
      statementCount,
      statementRows,
      statementLocalRows,
      valueCount,
      valueRows,
      statementPhysicalStarts
    );
    long indexLocal = physicalValueLocal(
      owner,
      index.local,
      statementCount,
      statementRows,
      statementLocalRows,
      valueCount,
      valueRows,
      statementPhysicalStarts
    );
    if (textLocal < 0) {
      return invalidProjection();
    }

    if (indexLocal < 0) {
      return invalidProjection();
    }

    if (MAX_CODE_BYTES - 104 < cursor) {
      return invalidProjection();
    }

    long next = writeInstructionHeader(
      output,
      cursor,
      OPCODE_LOCAL_MOVE,
      INSTRUCTION_FORM_BINARY
    );
    next = writeUnsignedLittleEndian(output, next, localBase, U64);
    next = writeUnsignedLittleEndian(output, next, textLocal, U64);
    next = writeInstructionHeader(output, next, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    next = writeUnsignedLittleEndian(output, next, localBase + 1, U64);
    next = writeUnsignedLittleEndian(output, next, indexLocal, U64);
    next = writeInstructionHeader(output, next, OPCODE_UTF8_SCALAR, INSTRUCTION_FORM_TERNARY);
    next = writeUnsignedLittleEndian(output, next, localBase + 2, U64);
    next = writeUnsignedLittleEndian(output, next, localBase, U64);
    next = writeUnsignedLittleEndian(output, next, localBase + 1, U64);
    next = writeInstructionHeader(output, next, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    next = writeUnsignedLittleEndian(output, next, localBase + 3, U64);
    next = writeUnsignedLittleEndian(output, next, localBase + 2, U64);
    set(typeRows, typeCount, owner);
    set(typeRows, 4096 + typeCount, localBase);
    set(typeRows, 8192 + typeCount, textType);
    typeCount += 1;
    long offset = 1;
    while (offset < 4) limit 3 {
      set(typeRows, typeCount, owner);
      set(typeRows, 4096 + typeCount, localBase + offset);
      set(typeRows, 8192 + typeCount, TYPE_SIGNED);
      typeCount += 1;
      offset += 1;
    }

    return new DirectUtf8ScalarProduct(next, typeCount, true);
  }
}
