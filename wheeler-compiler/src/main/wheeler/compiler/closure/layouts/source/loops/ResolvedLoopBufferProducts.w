//! Resolves direct loop-buffer writes and indexed copies.

module wheeler.compiler.closure.resolved_loop_buffer_products;

import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.loop_buffer_operands;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class ResolvedLoopBufferProducts {
  /// Reports one resolved direct buffer operation.
  public record ResolvedLoopBufferProduct(long opcode, long operand, boolean valid) {}

  /// Resolves one `set` statement from visible source-local value products.
  public ResolvedLoopBufferProduct resolveLoopBufferProduct(
    borrow utf8 source,
    long owner,
    long ordinal,
    long token,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    LoopBodyValue writeOwner = resolveLoopBodyValue(
      source,
      tokenStarts[token + 2],
      tokenLengths[token + 2],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    LoopBodyValue writeIndex = resolveLoopBodyValue(
      source,
      tokenStarts[token + 4],
      tokenLengths[token + 4],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    LoopBodyValue writeValue = resolveLoopBodyValue(
      source,
      tokenStarts[token + 6],
      tokenLengths[token + 6],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (writeOwner.valid == false) {
      return new ResolvedLoopBufferProduct(0, 0, false);
    }

    if (writeIndex.valid == false) {
      return new ResolvedLoopBufferProduct(0, 0, false);
    }

    if (writeValue.valid == false) {
      return new ResolvedLoopBufferProduct(0, 0, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 7, PUNCTUATION_OPEN_SQUARE)
    ) {
      LoopBodyValue readIndex = resolveLoopBodyValue(
        source,
        tokenStarts[token + 8],
        tokenLengths[token + 8],
        owner,
        ordinal,
        valueCount,
        valueRows
      );
      if (readIndex.valid == false) {
        return new ResolvedLoopBufferProduct(0, 0, false);
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, token + 9, PUNCTUATION_CLOSE_SQUARE) == false
      ) {
        return new ResolvedLoopBufferProduct(0, 0, false);
      }

      LoopBufferOperand copy = resolveLoopBufferCopyOperand(
        source,
        owner,
        writeOwner.local,
        writeIndex.local,
        writeValue.local,
        readIndex.local,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      );
      if (copy.valid == false) {
        return new ResolvedLoopBufferProduct(0, 0, false);
      }

      long copyOpcode = BODY_WORDS_COPY;
      if (
        loopBodyValueType(
          source,
          owner,
          writeOwner.local,
          valueCount,
          valueRows,
          tokenCount,
          tokenStarts,
          tokenLengths
        ) == TOKEN_BYTES
      ) {
        copyOpcode = BODY_BYTES_COPY;
      }

      return new ResolvedLoopBufferProduct(copyOpcode, copy.operand, true);
    }

    LoopBufferOperand write = resolveLoopBufferWriteOperand(
      source,
      owner,
      writeOwner.local,
      writeIndex.local,
      writeValue.local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (write.valid == false) {
      return new ResolvedLoopBufferProduct(0, 0, false);
    }

    long writeOpcode = BODY_WORDS_SET;
    if (
      loopBodyValueType(
        source,
        owner,
        writeOwner.local,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      ) == TOKEN_BYTES
    ) {
      writeOpcode = BODY_BYTES_SET;
    }

    return new ResolvedLoopBufferProduct(writeOpcode, write.operand, true);
  }
}
