//! Merges source proof names with canonical artifact strings without duplicate IDs.

module wheeler.compiler.closure.source_proof_strings;

import wheeler.compiler.closure.source_classical_proofs;
import wheeler.compiler.encoding;
import wheeler.core.encoding.binary;

classical class SourceProofStrings {
  /// Bounds one source-local artifact string table.
  public const long MAX_SOURCE_PROOF_STRINGS = 256;
  /// Retains final IDs and original-table matches in separate columns.
  public const long SOURCE_PROOF_STRING_ROWS = MAX_SOURCE_PROOFS * 2;
  private const long EXISTING_STRING_ROW = MAX_SOURCE_PROOFS;
  private const long WORD_BYTES = 4;
  private const long MAX_NAME_BYTES = SOURCE_PROOF_NAMES / MAX_SOURCE_PROOFS;
  private const long ARTIFACT_BYTES = 32768;

  private long compareNames(
    borrow byteview left,
    long leftStart,
    long leftLength,
    borrow byteview right,
    long rightStart,
    long rightLength
  ) {
    long shared = leftLength;
    if (rightLength < shared) {
      shared = rightLength;
    }

    long offset = 0;
    while (offset < shared) limit ARTIFACT_BYTES {
      long leftByte = left[leftStart + offset];
      long rightByte = right[rightStart + offset];
      if (leftByte < rightByte) {
        return -1;
      }

      if (rightByte < leftByte) {
        return 1;
      }

      offset += 1;
    }

    if (leftLength < rightLength) {
      return -1;
    }

    if (rightLength < leftLength) {
      return 1;
    }

    return 0;
  }

  /// Indexes a complete canonical string section and unique source proof names.
  /// Effects: writes private mapping columns only. Callers must not publish them on rejection.
  public long indexSourceProofStrings(
    borrow byteview artifact,
    long sectionStart,
    long sectionLength,
    borrow byteview names,
    long proofCount,
    borrow mut words proofs,
    borrow mut words oldStarts,
    borrow mut words oldLengths,
    borrow mut words oldIds,
    borrow mut words proofIds
  ) {
    assert(bufferLength(proofs) == SOURCE_PROOF_ROWS);
    assert(bufferLength(oldStarts) == MAX_SOURCE_PROOF_STRINGS);
    assert(bufferLength(oldLengths) == MAX_SOURCE_PROOF_STRINGS);
    assert(bufferLength(oldIds) == MAX_SOURCE_PROOF_STRINGS);
    assert(bufferLength(proofIds) == SOURCE_PROOF_STRING_ROWS);
    assert(-1 < proofCount);
    assert(proofCount < MAX_SOURCE_PROOFS + 1);
    assert(-1 < sectionStart);
    assert(WORD_BYTES - 1 < sectionLength);
    assert(sectionLength < bufferLength(artifact) - sectionStart + 1);
    long oldCount = readUnsigned(artifact, sectionStart, WORD_BYTES);
    assert(0 < oldCount);
    assert(oldCount < MAX_SOURCE_PROOF_STRINGS + 1);
    long cursor = sectionStart + WORD_BYTES;
    long end = sectionStart + sectionLength;
    long old = 0;
    while (old < oldCount) limit MAX_SOURCE_PROOF_STRINGS {
      assert(WORD_BYTES - 1 < end - cursor);
      long oldLength = readUnsigned(artifact, cursor, WORD_BYTES);
      cursor += WORD_BYTES;
      assert(0 < oldLength);
      assert(oldLength < end - cursor + 1);
      set(oldStarts, old, cursor);
      set(oldLengths, old, oldLength);
      if (0 < old) {
        assert(
          compareNames(
            artifact,
            oldStarts[old - 1],
            oldLengths[old - 1],
            artifact,
            cursor,
            oldLength
          ) == -1
        );
      }

      cursor += oldLength;
      old += 1;
    }

    assert(cursor == end);
    long proof = 0;
    long added = 0;
    while (proof < proofCount) limit MAX_SOURCE_PROOFS {
      long start = proofs[proof];
      long length = proofs[SOURCE_PROOF_LENGTH_ROW + proof];
      assert(-1 < start);
      assert(0 < length);
      assert(length < MAX_NAME_BYTES + 1);
      assert(length < bufferLength(names) - start + 1);
      long earlier = 0;
      while (earlier < proof) limit MAX_SOURCE_PROOFS {
        assert(
          compareNames(
            names,
            proofs[earlier],
            proofs[SOURCE_PROOF_LENGTH_ROW + earlier],
            names,
            start,
            length
          ) != 0
        );
        earlier += 1;
      }

      long matched = -1;
      old = 0;
      while (old < oldCount) limit MAX_SOURCE_PROOF_STRINGS {
        if (
          compareNames(artifact, oldStarts[old], oldLengths[old], names, start, length) == 0
        ) {
          matched = old;
        }

        old += 1;
      }

      set(proofIds, EXISTING_STRING_ROW + proof, matched);
      if (matched < 0) {
        added += 1;
      }

      proof += 1;
    }

    assert(added < MAX_SOURCE_PROOF_STRINGS - oldCount + 1);
    old = 0;
    while (old < oldCount) limit MAX_SOURCE_PROOF_STRINGS {
      long preceding = 0;
      proof = 0;
      while (proof < proofCount) limit MAX_SOURCE_PROOFS {
        if (proofIds[EXISTING_STRING_ROW + proof] < 0) {
          if (
            compareNames(
              names,
              proofs[proof],
              proofs[SOURCE_PROOF_LENGTH_ROW + proof],
              artifact,
              oldStarts[old],
              oldLengths[old]
            ) < 0
          ) {
            preceding += 1;
          }
        }

        proof += 1;
      }

      set(oldIds, old, old + preceding);
      old += 1;
    }

    proof = 0;
    while (proof < proofCount) limit MAX_SOURCE_PROOFS {
      long existing = proofIds[EXISTING_STRING_ROW + proof];
      long id = 0;
      if (-1 < existing) {
        id = oldIds[existing];
      } else {
        old = 0;
        while (old < oldCount) limit MAX_SOURCE_PROOF_STRINGS {
          if (
            compareNames(
              artifact,
              oldStarts[old],
              oldLengths[old],
              names,
              proofs[proof],
              proofs[SOURCE_PROOF_LENGTH_ROW + proof]
            ) < 0
          ) {
            id += 1;
          }

          old += 1;
        }

        long other = 0;
        while (other < proofCount) limit MAX_SOURCE_PROOFS {
          if (proofIds[EXISTING_STRING_ROW + other] < 0) {
            if (
              compareNames(
                names,
                proofs[other],
                proofs[SOURCE_PROOF_LENGTH_ROW + other],
                names,
                proofs[proof],
                proofs[SOURCE_PROOF_LENGTH_ROW + proof]
              ) < 0
            ) {
              id += 1;
            }
          }

          other += 1;
        }
      }

      set(proofIds, proof, id);
      proof += 1;
    }

    return oldCount + added;
  }

  /// Writes the indexed union into private section storage, retaining shared string IDs once.
  public long writeSourceProofStrings(
    borrow byteview artifact,
    long oldCount,
    borrow mut words oldStarts,
    borrow mut words oldLengths,
    borrow mut words oldIds,
    borrow byteview names,
    long proofCount,
    borrow mut words proofs,
    borrow mut words proofIds,
    long mergedCount,
    borrow mut bytes output,
    long start
  ) {
    long cursor = writeUnsignedLittleEndian(output, start, mergedCount, WORD_BYTES);
    long id = 0;
    while (id < mergedCount) limit MAX_SOURCE_PROOF_STRINGS {
      long matches = 0;
      long old = 0;
      while (old < oldCount) limit MAX_SOURCE_PROOF_STRINGS {
        if (oldIds[old] == id) {
          long oldLength = oldLengths[old];
          cursor = writeUnsignedLittleEndian(output, cursor, oldLength, WORD_BYTES);
          long oldByte = 0;
          while (oldByte < oldLength) limit ARTIFACT_BYTES {
            setByte(output, cursor, artifact[oldStarts[old] + oldByte]);
            cursor += 1;
            oldByte += 1;
          }

          matches += 1;
        }

        old += 1;
      }

      long proof = 0;
      while (proof < proofCount) limit MAX_SOURCE_PROOFS {
        if (proofIds[EXISTING_STRING_ROW + proof] < 0) {
          if (proofIds[proof] == id) {
            long length = proofs[SOURCE_PROOF_LENGTH_ROW + proof];
            cursor = writeUnsignedLittleEndian(output, cursor, length, WORD_BYTES);
            long copied = 0;
            while (copied < length) limit MAX_NAME_BYTES {
              setByte(output, cursor, names[proofs[proof] + copied]);
              cursor += 1;
              copied += 1;
            }

            matches += 1;
          }
        }

        proof += 1;
      }

      assert(matches == 1);
      id += 1;
    }

    return cursor - start;
  }
}
