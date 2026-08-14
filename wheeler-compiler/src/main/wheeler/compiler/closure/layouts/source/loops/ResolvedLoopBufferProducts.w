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
      long readIndexToken = token + 8;
      boolean sumIndex = punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        token + 9,
        PUNCTUATION_PLUS
      );
      long readBaseLocal = -1;
      if (sumIndex) {
        LoopBodyValue readBase = resolveLoopBodyValue(
          source,
          tokenStarts[readIndexToken],
          tokenLengths[readIndexToken],
          owner,
          ordinal,
          valueCount,
          valueRows
        );
        if (readBase.valid == false) {
          return new ResolvedLoopBufferProduct(0, 0, false);
        }

        readBaseLocal = readBase.local;
        readIndexToken += 2;
      }

      LoopBodyValue readIndex = resolveLoopBodyValue(
        source,
        tokenStarts[readIndexToken],
        tokenLengths[readIndexToken],
        owner,
        ordinal,
        valueCount,
        valueRows
      );
      if (readIndex.valid == false) {
        return new ResolvedLoopBufferProduct(0, 0, false);
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          readIndexToken + 1,
          PUNCTUATION_CLOSE_SQUARE
        ) == false
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
      if (sumIndex) {
        copy = resolveLoopBufferOffsetCopyOperand(
          source,
          owner,
          writeOwner.local,
          writeIndex.local,
          writeValue.local,
          readBaseLocal,
          readIndex.local,
          valueCount,
          valueRows,
          tokenCount,
          tokenStarts,
          tokenLengths
        );
      }

      if (copy.valid == false) {
        return new ResolvedLoopBufferProduct(0, 0, false);
      }

      long writeType = loopBodyValueType(
        source,
        owner,
        writeOwner.local,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      );
      long readType = loopBodyValueType(
        source,
        owner,
        writeValue.local,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      );
      long copyOpcode = BODY_WORDS_COPY;
      if (writeType == TOKEN_BYTES) {
        copyOpcode = BODY_BYTES_COPY;
        if (readType == TOKEN_BYTEVIEW) {
          copyOpcode = BODY_BYTEVIEW_TO_BYTES_COPY;
          if (sumIndex) {
            copyOpcode = BODY_BYTEVIEW_TO_BYTES_COPY_SUM;
          }
        }
      }

      if (sumIndex) {
        if (copyOpcode != BODY_BYTEVIEW_TO_BYTES_COPY_SUM) {
          return new ResolvedLoopBufferProduct(0, 0, false);
        }
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
