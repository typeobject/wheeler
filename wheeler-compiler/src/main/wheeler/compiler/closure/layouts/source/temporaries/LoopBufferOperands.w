//! Resolves borrowed and owned loop-buffer operand tuples.

module wheeler.compiler.closure.loop_buffer_operands;

import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.loop_body_opcodes;

classical class LoopBufferOperands {
  private const long LITERAL_INDEX_OFFSET_SCALE = 131072;
  private const long OFFSET_COPY_READ_BORROW_SCALE = 2199023255552;
  private const long OFFSET_COPY_WRITE_BORROW_SCALE = 1099511627776;
  private const long OFFSET_COPY_WRITE_OWNER_SCALE = 4294967296;
  private const long OFFSET_COPY_WRITE_INDEX_SCALE = 16777216;
  private const long OFFSET_COPY_READ_OWNER_SCALE = 65536;
  private const long OFFSET_COPY_READ_BASE_SCALE = 256;

  /// Reports one packed buffer operand tuple.
  public record LoopBufferOperand(long operand, boolean valid) {}

  /// Rebases every local coordinate while preserving buffer reborrow bits.
  public long rebaseLoopBufferOperand(long opcode, long operand, long boundary, long bias) {
    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY_SUM) {
      long sumReadBorrowed = operand / OFFSET_COPY_READ_BORROW_SCALE;
      long sumWriteBorrowed = operand / OFFSET_COPY_WRITE_BORROW_SCALE % 2;
      long sumTuple = operand % OFFSET_COPY_WRITE_BORROW_SCALE;
      long sumWriteOwner = sumTuple / OFFSET_COPY_WRITE_OWNER_SCALE;
      long sumWriteIndex = sumTuple / OFFSET_COPY_WRITE_INDEX_SCALE % 256;
      long sumReadOwner = sumTuple / OFFSET_COPY_READ_OWNER_SCALE % 256;
      long sumReadBase = sumTuple / OFFSET_COPY_READ_BASE_SCALE % 256;
      long sumReadIndex = sumTuple % 256;
      if (boundary < sumWriteOwner + 1) {
        sumWriteOwner += bias;
      }

      if (boundary < sumWriteIndex + 1) {
        sumWriteIndex += bias;
      }

      if (boundary < sumReadOwner + 1) {
        sumReadOwner += bias;
      }

      if (boundary < sumReadBase + 1) {
        sumReadBase += bias;
      }

      if (boundary < sumReadIndex + 1) {
        sumReadIndex += bias;
      }

      return sumReadBorrowed * OFFSET_COPY_READ_BORROW_SCALE + sumWriteBorrowed
        * OFFSET_COPY_WRITE_BORROW_SCALE + sumWriteOwner * OFFSET_COPY_WRITE_OWNER_SCALE
        + sumWriteIndex * OFFSET_COPY_WRITE_INDEX_SCALE + sumReadOwner
        * OFFSET_COPY_READ_OWNER_SCALE + sumReadBase * OFFSET_COPY_READ_BASE_SCALE + sumReadIndex;
    }

    if (opcode == BODY_WORDS_GET_OFFSET) {
      long offset = operand / LITERAL_INDEX_OFFSET_SCALE;
      long offsetOperand = operand % LITERAL_INDEX_OFFSET_SCALE;
      long offsetBorrowed = offsetOperand / 65536;
      long offsetPair = offsetOperand % 65536;
      long offsetOwner = offsetPair / 256;
      long offsetIndex = offsetPair % 256;
      if (boundary < offsetOwner + 1) {
        offsetOwner += bias;
      }

      if (boundary < offsetIndex + 1) {
        offsetIndex += bias;
      }

      return offset * LITERAL_INDEX_OFFSET_SCALE + offsetBorrowed * 65536 + offsetOwner * 256
        + offsetIndex;
    }

    boolean bufferGet = opcode == BODY_WORDS_GET;
    if (opcode == BODY_BYTES_GET) {
      bufferGet = true;
    }

    if (opcode == BODY_BYTEVIEW_GET) {
      bufferGet = true;
    }

    if (bufferGet) {
      long readBorrowed = operand / 65536;
      long readPair = operand % 65536;
      long readOwner = readPair / 256;
      long readIndex = readPair % 256;
      if (boundary < readOwner + 1) {
        readOwner += bias;
      }

      if (boundary < readIndex + 1) {
        readIndex += bias;
      }

      return readBorrowed * 65536 + readOwner * 256 + readIndex;
    }

    boolean bufferSet = opcode == BODY_WORDS_SET;
    if (opcode == BODY_BYTES_SET) {
      bufferSet = true;
    }

    if (bufferSet) {
      long writeBorrowed = operand / 16777216;
      long writeTuple = operand % 16777216;
      long writeOwner = writeTuple / 65536;
      long writeIndex = writeTuple / 256 % 256;
      long writeValue = writeTuple % 256;
      if (boundary < writeOwner + 1) {
        writeOwner += bias;
      }

      if (boundary < writeIndex + 1) {
        writeIndex += bias;
      }

      if (boundary < writeValue + 1) {
        writeValue += bias;
      }

      return writeBorrowed * 16777216 + writeOwner * 65536 + writeIndex * 256 + writeValue;
    }

    boolean bufferCopy = opcode == BODY_WORDS_COPY;
    if (opcode == BODY_BYTES_COPY) {
      bufferCopy = true;
    }

    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY) {
      bufferCopy = true;
    }

    if (bufferCopy) {
      long copyReadBorrowed = operand / 8589934592;
      long copyWriteBorrowed = operand / 4294967296 % 2;
      long copyTuple = operand % 4294967296;
      long copyWriteOwner = copyTuple / 16777216;
      long copyWriteIndex = copyTuple / 65536 % 256;
      long copyReadOwner = copyTuple / 256 % 256;
      long copyReadIndex = copyTuple % 256;
      if (boundary < copyWriteOwner + 1) {
        copyWriteOwner += bias;
      }

      if (boundary < copyWriteIndex + 1) {
        copyWriteIndex += bias;
      }

      if (boundary < copyReadOwner + 1) {
        copyReadOwner += bias;
      }

      if (boundary < copyReadIndex + 1) {
        copyReadIndex += bias;
      }

      return copyReadBorrowed * 8589934592 + copyWriteBorrowed * 4294967296 + copyWriteOwner
        * 16777216 + copyWriteIndex * 65536 + copyReadOwner * 256 + copyReadIndex;
    }

    return operand;
  }

  /// Packs one type-checked owner and index pair, including its reborrow bit.
  public LoopBufferOperand resolveLoopBufferReadOperand(
    borrow utf8 source,
    long owner,
    long sourceLocal,
    long indexLocal,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long sourceType = loopBodyValueType(
      source,
      owner,
      sourceLocal,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    boolean readable = sourceType == TOKEN_WORDS;
    if (sourceType == TOKEN_BYTES) {
      readable = true;
    }

    if (sourceType == TOKEN_BYTEVIEW) {
      readable = true;
    }

    if (readable == false) {
      return new LoopBufferOperand(0, false);
    }

    if (
      signedLoopBodyLocal(
        source,
        owner,
        indexLocal,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      ) == false
    ) {
      return new LoopBufferOperand(0, false);
    }

    long operand = sourceLocal * 256 + indexLocal;
    if (
      borrowedLoopBodyLocal(
        source,
        owner,
        sourceLocal,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      )
    ) {
      operand += 65536;
    }

    return new LoopBufferOperand(operand, true);
  }

  /// Packs one byte-view copy whose read index is the sum of two signed locals.
  public LoopBufferOperand resolveLoopBufferOffsetCopyOperand(
    borrow utf8 source,
    long owner,
    long writeOwner,
    long writeIndex,
    long readOwner,
    long readBase,
    long readIndex,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    LoopBufferOperand direct = resolveLoopBufferCopyOperand(
      source,
      owner,
      writeOwner,
      writeIndex,
      readOwner,
      readIndex,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (direct.valid == false) {
      return new LoopBufferOperand(0, false);
    }

    if (
      signedLoopBodyLocal(
        source,
        owner,
        readBase,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      ) == false
    ) {
      return new LoopBufferOperand(0, false);
    }

    long readBorrowed = direct.operand / 8589934592;
    long writeBorrowed = direct.operand / 4294967296 % 2;
    long directTuple = direct.operand % 4294967296;
    long packedWriteOwner = directTuple / 16777216;
    long packedWriteIndex = directTuple / 65536 % 256;
    long packedReadOwner = directTuple / 256 % 256;
    long packedReadIndex = directTuple % 256;
    long packed = readBorrowed * OFFSET_COPY_READ_BORROW_SCALE + writeBorrowed
      * OFFSET_COPY_WRITE_BORROW_SCALE + packedWriteOwner * OFFSET_COPY_WRITE_OWNER_SCALE
      + packedWriteIndex * OFFSET_COPY_WRITE_INDEX_SCALE + packedReadOwner
      * OFFSET_COPY_READ_OWNER_SCALE + readBase * OFFSET_COPY_READ_BASE_SCALE + packedReadIndex;
    return new LoopBufferOperand(packed, true);
  }

  /// Packs one type-checked indexed buffer copy and both reborrow bits.
  public LoopBufferOperand resolveLoopBufferCopyOperand(
    borrow utf8 source,
    long owner,
    long writeOwner,
    long writeIndex,
    long readOwner,
    long readIndex,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    LoopBufferOperand write = resolveLoopBufferReadOperand(
      source,
      owner,
      writeOwner,
      writeIndex,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    LoopBufferOperand read = resolveLoopBufferReadOperand(
      source,
      owner,
      readOwner,
      readIndex,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (write.valid == false) {
      return new LoopBufferOperand(0, false);
    }

    if (read.valid == false) {
      return new LoopBufferOperand(0, false);
    }

    long writeType = loopBodyValueType(
      source,
      owner,
      writeOwner,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    long readType = loopBodyValueType(
      source,
      owner,
      readOwner,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    boolean compatible = writeType == readType;
    if (writeType == TOKEN_BYTES) {
      if (readType == TOKEN_BYTEVIEW) {
        compatible = true;
      }
    }

    if (compatible == false) {
      return new LoopBufferOperand(0, false);
    }

    if (writeType == TOKEN_BYTEVIEW) {
      return new LoopBufferOperand(0, false);
    }

    long writeBorrowed = write.operand / 65536;
    long writePair = write.operand % 65536;
    long readBorrowed = read.operand / 65536;
    long readPair = read.operand % 65536;
    long operand = writePair / 256 * 16777216 + writePair % 256 * 65536 + readPair / 256 * 256
      + readPair % 256;
    if (0 < writeBorrowed) {
      operand += 4294967296;
    }

    if (0 < readBorrowed) {
      operand += 8589934592;
    }

    return new LoopBufferOperand(operand, true);
  }

  /// Packs one type-checked owner, index, and value tuple, including its reborrow bit.
  public LoopBufferOperand resolveLoopBufferWriteOperand(
    borrow utf8 source,
    long owner,
    long writeOwner,
    long writeIndex,
    long writeValue,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long writeType = loopBodyValueType(
      source,
      owner,
      writeOwner,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    boolean writable = writeType == TOKEN_WORDS;
    if (writeType == TOKEN_BYTES) {
      writable = true;
    }

    if (writable == false) {
      return new LoopBufferOperand(0, false);
    }

    if (
      signedLoopBodyLocal(
        source,
        owner,
        writeIndex,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      ) == false
    ) {
      return new LoopBufferOperand(0, false);
    }

    if (
      signedLoopBodyLocal(
        source,
        owner,
        writeValue,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      ) == false
    ) {
      return new LoopBufferOperand(0, false);
    }

    long operand = writeOwner * 65536 + writeIndex * 256 + writeValue;
    if (
      borrowedLoopBodyLocal(
        source,
        owner,
        writeOwner,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      )
    ) {
      operand += 16777216;
    }

    return new LoopBufferOperand(operand, true);
  }
}
