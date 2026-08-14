//! Resolves borrowed and owned loop-buffer operand tuples.

module wheeler.compiler.closure.loop_buffer_operands;

import wheeler.compiler.closure.loop_body_values;

classical class LoopBufferOperands {
  /// Reports one packed buffer operand tuple.
  public record LoopBufferOperand(long operand, boolean valid) {}

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
