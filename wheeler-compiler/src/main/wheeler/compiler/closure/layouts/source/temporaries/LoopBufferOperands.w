//! Resolves borrowed and owned loop-buffer operand tuples.

module wheeler.compiler.closure.loop_buffer_operands;

import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.loop_body_opcodes;

classical class LoopBufferOperands {
  /// Reports one packed buffer operand tuple.
  public record LoopBufferOperand(long operand, boolean valid) {}

  /// Rebases every local coordinate while preserving buffer reborrow bits.
  public long rebaseLoopBufferOperand(long opcode, long operand, long boundary, long bias) {
    if (opcode == BODY_WORDS_GET) {
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

    if (opcode == BODY_WORDS_SET) {
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

    if (opcode == BODY_WORDS_COPY) {
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
    if (
      wordsLoopBodyLocal(
        source,
        owner,
        sourceLocal,
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
      borrowedWordsLoopBodyLocal(
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
    if (
      wordsLoopBodyLocal(
        source,
        owner,
        writeOwner,
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
      borrowedWordsLoopBodyLocal(
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
