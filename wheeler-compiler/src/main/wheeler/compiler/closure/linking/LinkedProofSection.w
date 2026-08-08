//! Emits canonical proof certificates from counted closure products.

module wheeler.compiler.closure.linked_proof_section;

classical class LinkedProofSection {
  private const long MAX_FUNCTIONS = 4096;
  private const long MAX_PROOFS = 4096;
  private const long MAX_STRINGS = 16384;
  private const long PROOF_ROWS = 24576;

  private void writeUnsigned(borrow mut bytes output, long cursor, long width, long value) {
    assert(-1 < value);
    long remaining = value;
    long outputByte = 0;
    while (outputByte < width) limit 4 {
      setByte(output, cursor + outputByte, remaining % 256);
      remaining = remaining / 256;
      outputByte += 1;
    }

    assert(remaining == 0);
  }

  /// Emits section type 10 after validating all final names and subjects.
  public long emitLinkedProofSection(
    long proofCount,
    long functionCount,
    long closureStringCount,
    borrow mut words proofRows,
    borrow mut words finalStringRows,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(0 < proofCount);
    assert(proofCount < MAX_PROOFS + 1);
    assert(0 < functionCount);
    assert(functionCount < MAX_FUNCTIONS + 1);
    assert(0 < closureStringCount);
    assert(closureStringCount < MAX_STRINGS + 1);
    assert(bufferLength(proofRows) == PROOF_ROWS);
    assert(bufferLength(finalStringRows) == MAX_STRINGS);
    assert(-1 < outputStart);
    long sectionBytes = 4 + proofCount * 24;
    assert(outputStart < bufferLength(output) + 1);
    assert(sectionBytes < bufferLength(output) - outputStart + 1);
    long proof = 0;
    while (proof < proofCount) limit MAX_PROOFS {
      long sourceName = proofRows[4096 + proof];
      long rule = proofRows[8192 + proof];
      long subject = proofRows[12288 + proof];
      assert(-1 < sourceName);
      assert(sourceName < closureStringCount);
      assert(-1 < finalStringRows[sourceName]);
      assert(finalStringRows[sourceName] < closureStringCount);
      assert(0 < rule);
      assert(rule < 3);
      assert(-1 < subject);
      assert(subject < functionCount);
      proof += 1;
    }

    writeUnsigned(output, outputStart, 4, proofCount);
    proof = 0;
    while (proof < proofCount) limit MAX_PROOFS {
      long descriptor = outputStart + 4 + proof * 24;
      writeUnsigned(output, descriptor, 4, proof);
      writeUnsigned(output, descriptor + 4, 4, finalStringRows[proofRows[4096 + proof]]);
      writeUnsigned(output, descriptor + 8, 4, proofRows[8192 + proof]);
      writeUnsigned(output, descriptor + 12, 4, proofRows[12288 + proof]);
      writeUnsigned(output, descriptor + 16, 4, proofRows[16384 + proof]);
      writeUnsigned(output, descriptor + 20, 4, proofRows[20480 + proof]);
      proof += 1;
    }

    return sectionBytes;
  }
}
