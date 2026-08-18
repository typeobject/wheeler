//! Emits exact root buffer projection products.

module wheeler.compiler.closure.direct_buffer_projection_products;

import wheeler.compiler.closure.direct_statement_coordinates;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.structured_source_coordinates;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.storage_opcodes;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class DirectBufferProjectionProducts {
  private const long MAX_CODE_BYTES = 262144;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports one exact buffer projection instruction and type extent.
  public record DirectBufferProjectionProduct(long next, long typeCount, boolean valid) {}

  /// Writes one complete `long value = owner[index];` initializer product.
  public DirectBufferProjectionProduct writeDirectBufferProjection(
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
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    if (tokenCount < token + 5) {
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    if (252 < localBase) {
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    if (tokenKinds[token] != 1) {
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_OPEN_SQUARE) == false
    ) {
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    if (tokenKinds[token + 2] != 1) {
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 3, PUNCTUATION_CLOSE_SQUARE) == false
    ) {
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 4, PUNCTUATION_SEMICOLON) == false
    ) {
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    LoopBodyValue buffer = resolveLoopBodyValue(
      source,
      tokenStarts[token],
      tokenLengths[token],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    LoopBodyValue index = resolveLoopBodyValue(
      source,
      tokenStarts[token + 2],
      tokenLengths[token + 2],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (buffer.valid == false) {
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    if (index.valid == false) {
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    long bufferType = directBufferLocalType(
      source,
      owner,
      buffer.local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    boolean byteBuffer = bufferType == TYPE_BYTE_VIEW;
    if (bufferType == TYPE_BYTES) {
      byteBuffer = true;
    }

    if (bufferType == TYPE_BYTES_BORROW) {
      byteBuffer = true;
    }

    boolean wordBuffer = bufferType == TYPE_WORDS;
    if (bufferType == TYPE_WORDS_BORROW) {
      wordBuffer = true;
    }

    if (byteBuffer == false) {
      if (wordBuffer == false) {
        return new DirectBufferProjectionProduct(0, 0, false);
      }
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
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    long bufferLocal = physicalValueLocal(
      owner,
      buffer.local,
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
    if (bufferLocal < 0) {
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    if (indexLocal < 0) {
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    if (MAX_CODE_BYTES - 104 < cursor) {
      return new DirectBufferProjectionProduct(0, 0, false);
    }

    long next = writeInstructionHeader(
      output,
      cursor,
      OPCODE_LOCAL_MOVE,
      INSTRUCTION_FORM_BINARY
    );
    next = writeUnsignedLittleEndian(output, next, localBase, U64);
    next = writeUnsignedLittleEndian(output, next, bufferLocal, U64);
    next = writeInstructionHeader(output, next, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    next = writeUnsignedLittleEndian(output, next, localBase + 1, U64);
    next = writeUnsignedLittleEndian(output, next, indexLocal, U64);
    long projectionOpcode = OPCODE_BYTES_GET;
    if (wordBuffer) {
      projectionOpcode = OPCODE_WORDS_GET;
    }

    next = writeInstructionHeader(output, next, projectionOpcode, INSTRUCTION_FORM_TERNARY);
    next = writeUnsignedLittleEndian(output, next, localBase + 2, U64);
    next = writeUnsignedLittleEndian(output, next, localBase, U64);
    next = writeUnsignedLittleEndian(output, next, localBase + 1, U64);
    next = writeInstructionHeader(output, next, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    next = writeUnsignedLittleEndian(output, next, localBase + 3, U64);
    next = writeUnsignedLittleEndian(output, next, localBase + 2, U64);
    set(typeRows, typeCount, owner);
    set(typeRows, 4096 + typeCount, localBase);
    set(typeRows, 8192 + typeCount, bufferType);
    typeCount += 1;
    long offset = 1;
    while (offset < 4) limit 3 {
      set(typeRows, typeCount, owner);
      set(typeRows, 4096 + typeCount, localBase + offset);
      set(typeRows, 8192 + typeCount, TYPE_SIGNED);
      typeCount += 1;
      offset += 1;
    }

    return new DirectBufferProjectionProduct(next, typeCount, true);
  }
}
