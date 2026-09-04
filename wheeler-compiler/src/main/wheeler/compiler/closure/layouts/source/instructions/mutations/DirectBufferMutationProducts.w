//! Emits exact root buffer-mutation products.

module wheeler.compiler.closure.direct_buffer_mutation_products;

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

classical class DirectBufferMutationProducts {
  private const long MAX_CODE_BYTES = 262144;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports one exact buffer mutation instruction and type extent.
  public record DirectBufferMutationProduct(long next, long typeCount, boolean valid) {}

  private boolean commaAt(
    borrow utf8 source,
    long token,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts
  ) {
    return punctuationAt(source, tokenKinds, tokenStarts, token, PUNCTUATION_COMMA);
  }

  /// Writes one complete `set` or `setByte` buffer mutation source product.
  public DirectBufferMutationProduct writeDirectBufferMutation(
    borrow utf8 source,
    long token,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    boolean wordMutation,
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
    assert(typeCount < 4094);
    assert(bufferLength(output) == MAX_CODE_BYTES);
    if (token < 0) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (tokenCount < token + 9) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (253 < localBase) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_OPEN_PAREN) == false
    ) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (tokenKinds[token + 2] != 1) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (commaAt(source, token + 3, tokenKinds, tokenStarts) == false) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (tokenKinds[token + 4] != 1) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (commaAt(source, token + 5, tokenKinds, tokenStarts) == false) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (tokenKinds[token + 6] != 1) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 7, PUNCTUATION_CLOSE_PAREN) == false
    ) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 8, PUNCTUATION_SEMICOLON) == false
    ) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    LoopBodyValue buffer = resolveLoopBodyValue(
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
    LoopBodyValue value = resolveLoopBodyValue(
      source,
      tokenStarts[token + 6],
      tokenLengths[token + 6],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (buffer.valid == false) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (index.valid == false) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (value.valid == false) {
      return new DirectBufferMutationProduct(0, 0, false);
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
    long mutationOpcode = OPCODE_BYTES_SET;
    if (wordMutation) {
      mutationOpcode = OPCODE_WORDS_SET;
      if (bufferType != TYPE_WORDS) {
        if (bufferType != TYPE_WORDS_BORROW) {
          return new DirectBufferMutationProduct(0, 0, false);
        }
      }
    } else {
      if (bufferType != TYPE_BYTES) {
        if (bufferType != TYPE_BYTES_BORROW) {
          return new DirectBufferMutationProduct(0, 0, false);
        }
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
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (
      signedLoopBodyLocal(
        source,
        owner,
        value.local,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      ) == false
    ) {
      return new DirectBufferMutationProduct(0, 0, false);
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
    long valueLocal = physicalValueLocal(
      owner,
      value.local,
      statementCount,
      statementRows,
      statementLocalRows,
      valueCount,
      valueRows,
      statementPhysicalStarts
    );
    if (bufferLocal < 0) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (indexLocal < 0) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (valueLocal < 0) {
      return new DirectBufferMutationProduct(0, 0, false);
    }

    if (MAX_CODE_BYTES - 104 < cursor) {
      return new DirectBufferMutationProduct(0, 0, false);
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
    next = writeInstructionHeader(output, next, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    next = writeUnsignedLittleEndian(output, next, localBase + 2, U64);
    next = writeUnsignedLittleEndian(output, next, valueLocal, U64);
    next = writeInstructionHeader(output, next, mutationOpcode, INSTRUCTION_FORM_TERNARY);
    next = writeUnsignedLittleEndian(output, next, localBase, U64);
    next = writeUnsignedLittleEndian(output, next, localBase + 1, U64);
    next = writeUnsignedLittleEndian(output, next, localBase + 2, U64);
    set(typeRows, typeCount, owner);
    set(typeRows, 4096 + typeCount, localBase);
    set(typeRows, 8192 + typeCount, bufferType);
    typeCount += 1;
    long offset = 1;
    while (offset < 3) limit 2 {
      set(typeRows, typeCount, owner);
      set(typeRows, 4096 + typeCount, localBase + offset);
      set(typeRows, 8192 + typeCount, TYPE_SIGNED);
      typeCount += 1;
      offset += 1;
    }

    return new DirectBufferMutationProduct(next, typeCount, true);
  }
}
