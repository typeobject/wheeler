//! Emits canonical proof certificates from counted closure products.

module wheeler.compiler.closure.linked_proof_section;

import wheeler.compiler.closure.classical_proof_products;

classical class LinkedProofSection {
  private const long MAX_FUNCTIONS = 4096;
  private const long MAX_STRINGS = 16384;

  private void writeUnsigned(borrow mut bytes output, long cursor, long width, long value) {
    assert(-1 < value);
    long remaining = value;
    long outputByte = 0;
    while (outputByte < width) limit PROOF_WORD_BYTES {
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
    assert(proofCount < MAX_CLASSICAL_PROOFS + 1);
    assert(0 < functionCount);
    assert(functionCount < MAX_FUNCTIONS + 1);
    assert(0 < closureStringCount);
    assert(closureStringCount < MAX_STRINGS + 1);
    assert(bufferLength(proofRows) == CLASSICAL_PROOF_ROWS);
    assert(bufferLength(finalStringRows) == MAX_STRINGS);
    assert(-1 < outputStart);
    long sectionBytes = PROOF_WORD_BYTES + proofCount * CLASSICAL_PROOF_DESCRIPTOR_BYTES;
    assert(outputStart < bufferLength(output) + 1);
    assert(sectionBytes < bufferLength(output) - outputStart + 1);
    long proof = 0;
    while (proof < proofCount) limit MAX_CLASSICAL_PROOFS {
      long sourceName = proofRows[PROOF_NAME_ROW + proof];
      long rule = proofRows[PROOF_RULE_ROW + proof];
      long subject = proofRows[PROOF_SUBJECT_ROW + proof];
      assert(-1 < sourceName);
      assert(sourceName < closureStringCount);
      assert(-1 < finalStringRows[sourceName]);
      assert(finalStringRows[sourceName] < closureStringCount);
      assert(
        classicalProofArgumentValid(
          rule,
          proofRows[PROOF_ARGUMENT_LOW_ROW + proof],
          proofRows[PROOF_ARGUMENT_HIGH_ROW + proof]
        )
      );
      assert(-1 < subject);
      assert(subject < functionCount);
      proof += 1;
    }

    writeUnsigned(output, outputStart, PROOF_WORD_BYTES, proofCount);
    proof = 0;
    while (proof < proofCount) limit MAX_CLASSICAL_PROOFS {
      long descriptor = outputStart + PROOF_WORD_BYTES + proof * CLASSICAL_PROOF_DESCRIPTOR_BYTES;
      writeUnsigned(output, descriptor, PROOF_WORD_BYTES, proof);
      writeUnsigned(
        output,
        descriptor + PROOF_WORD_BYTES,
        PROOF_WORD_BYTES,
        finalStringRows[proofRows[PROOF_NAME_ROW + proof]]
      );
      writeUnsigned(
        output,
        descriptor + PROOF_WORD_BYTES * 2,
        PROOF_WORD_BYTES,
        proofRows[PROOF_RULE_ROW + proof]
      );
      writeUnsigned(
        output,
        descriptor + PROOF_WORD_BYTES * 3,
        PROOF_WORD_BYTES,
        proofRows[PROOF_SUBJECT_ROW + proof]
      );
      writeUnsigned(
        output,
        descriptor + PROOF_WORD_BYTES * 4,
        PROOF_WORD_BYTES,
        proofRows[PROOF_ARGUMENT_LOW_ROW + proof]
      );
      writeUnsigned(
        output,
        descriptor + PROOF_WORD_BYTES * 5,
        PROOF_WORD_BYTES,
        proofRows[PROOF_ARGUMENT_HIGH_ROW + proof]
      );
      proof += 1;
    }

    return sectionBytes;
  }
}
