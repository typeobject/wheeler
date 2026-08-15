//! Checks the bounded classical proof records accepted by native bootstrap tools.
module wheeler.compiler.proof_verifier;

import wheeler.compiler.closure.generated_inverse_products;
import wheeler.compiler.opcodes;
import wheeler.compiler.proof_rules;
import wheeler.core.encoding.binary;

classical class ProofVerifier {
  private boolean differs(long left, long right) {
    if (left < right) {
      return true;
    }

    return right < left;
  }

  private boolean forbiddenStaticStepOpcode(long opcode) {
    if (opcode == OPCODE_CALL) {
      return true;
    }

    if (opcode == OPCODE_CALL_VALUE) {
      return true;
    }

    if (opcode == OPCODE_CALL_VOID) {
      return true;
    }

    if (opcode == OPCODE_CALL_RESULT_SLOT) {
      return true;
    }

    if (opcode == OPCODE_UNCALL_RESULT_SLOT) {
      return true;
    }

    if (opcode == OPCODE_JUMP) {
      return true;
    }

    return opcode == OPCODE_JUMP_IF_ZERO;
  }

  private long instructionCount(borrow byteview artifact, long start, long length) {
    long cursor = start;
    long end = start + length;
    long count = 0;
    while (cursor < end) limit MAX_CODE_INSTRUCTIONS {
      if (end - cursor < 8) {
        return -1;
      }

      long instructionLength = readUnsigned(artifact, cursor + 4, 4);
      if (instructionLength < 8) {
        return -1;
      }

      if (end < cursor + instructionLength) {
        return -1;
      }

      cursor += instructionLength;
      count += 1;
    }

    if (differs(cursor, end)) {
      return -1;
    }

    return count;
  }

  private long instructionCursor(borrow byteview artifact, long start, long target) {
    long cursor = start;
    long index = 0;
    while (index < target) limit MAX_CODE_INSTRUCTIONS {
      cursor += readUnsigned(artifact, cursor + 4, 4);
      index += 1;
    }

    return cursor;
  }

  private boolean instructionPayloadsEqual(borrow byteview artifact, long forward, long inverse) {
    long forwardLength = readUnsigned(artifact, forward + 4, 4);
    if (differs(forwardLength, readUnsigned(artifact, inverse + 4, 4))) {
      return false;
    }

    long offset = 2;
    while (offset < forwardLength) limit 40 {
      if (differs(artifact[forward + offset], artifact[inverse + offset])) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private long verifyGeneratedInverse(borrow byteview artifact, long descriptor, long codeOffset) {
    long flags = readUnsigned(artifact, descriptor + 8, 4);
    long returnOpcode = OPCODE_RETURN;
    if (flags == 13) {
      returnOpcode = OPCODE_RETURN_RESULT_SLOT;
    }

    long forwardOffset = readUnsigned(artifact, descriptor + 12, 4);
    long forwardLength = readUnsigned(artifact, descriptor + 16, 4);
    long inverseOffset = readUnsigned(artifact, descriptor + 20, 4);
    long inverseLength = readUnsigned(artifact, descriptor + 24, 4);
    long forwardStart = codeOffset + forwardOffset;
    long inverseStart = codeOffset + inverseOffset;
    long forwardCount = instructionCount(artifact, forwardStart, forwardLength);
    if (forwardCount < 1) {
      return 0;
    }

    long forwardReturn = instructionCursor(artifact, forwardStart, forwardCount - 1);
    if (differs(readUnsigned(artifact, forwardReturn, 2), returnOpcode)) {
      return 0;
    }

    long inverseCursor = inverseStart;
    long inverseIndex = 0;
    while (inverseIndex < forwardCount - 1) limit MAX_CODE_INSTRUCTIONS {
      long forwardIndex = forwardCount - 2 - inverseIndex;
      long forwardCursor = instructionCursor(artifact, forwardStart, forwardIndex);
      long expected = inverseGeneratedOpcode(readUnsigned(artifact, forwardCursor, 2));
      if (expected < 0) {
        return 0;
      }

      if (differs(readUnsigned(artifact, inverseCursor, 2), expected)) {
        return 0;
      }

      if (instructionPayloadsEqual(artifact, forwardCursor, inverseCursor)) {} else {
        return 0;
      }

      inverseCursor += readUnsigned(artifact, inverseCursor + 4, 4);
      inverseIndex += 1;
    }

    if (differs(readUnsigned(artifact, inverseCursor, 2), returnOpcode)) {
      return 0;
    }

    inverseCursor += readUnsigned(artifact, inverseCursor + 4, 4);
    if (differs(inverseCursor, inverseStart + inverseLength)) {
      return 0;
    }

    return 1;
  }

  private long straightLineInstructionCount(borrow byteview artifact, long start, long length) {
    long cursor = start;
    long end = start + length;
    long count = 0;
    while (cursor < end) limit MAX_CODE_INSTRUCTIONS {
      if (end - cursor < 8) {
        return -1;
      }

      long opcode = readUnsigned(artifact, cursor, 2);
      if (forbiddenStaticStepOpcode(opcode)) {
        return -1;
      }

      long instructionLength = readUnsigned(artifact, cursor + 4, 4);
      if (instructionLength < 8) {
        return -1;
      }

      if (end < cursor + instructionLength) {
        return -1;
      }

      cursor += instructionLength;
      count += 1;
    }

    if (differs(cursor, end)) {
      return -1;
    }

    return count;
  }

  /// Verifies `proofs` under the bounded bootstrap profile.
  public long verifyProofs(
    borrow byteview artifact,
    long sectionCount,
    long proofOffset,
    long proofLength,
    long functionsOffset,
    long codeOffset,
    long functionCount,
    long entryFunction,
    long stringCount,
    long maxSteps
  ) {
    if (sectionCount == 6) {
      return 1;
    }

    if (sectionCount == 7) {} else {
      return 0;
    }

    long proofCount = readUnsigned(artifact, proofOffset, 4);
    if (proofCount < 1) {
      return 0;
    }

    if (4096 < proofCount) {
      return 0;
    }

    if (differs(proofLength, 4 + proofCount * 24)) {
      return 0;
    }

    long proof = 0;
    while (proof < proofCount) limit 4096 {
      long proofRow = proofOffset + 4 + proof * 24;
      if (differs(readUnsigned(artifact, proofRow, 4), proof)) {
        return 0;
      }

      if (readUnsigned(artifact, proofRow + 4, 4) < stringCount) {} else {
        return 0;
      }

      long rule = readUnsigned(artifact, proofRow + 8, 4);
      long subject = readUnsigned(artifact, proofRow + 12, 4);
      if (subject < functionCount) {} else {
        return 0;
      }

      if (subject < entryFunction) {} else {
        return 0;
      }

      long descriptor = functionsOffset + 4 + subject * 40;
      boolean proofValid = false;
      if (rule == PROOF_GENERATED_INVERSE) {
        long functionFlags = readUnsigned(artifact, descriptor + 8, 4);
        boolean functionFlagsValid = functionFlags == 1;
        if (functionFlags == 13) {
          functionFlagsValid = true;
        }

        if (functionFlagsValid == false) {
          return 0;
        }

        long generatedArgumentByte = 0;
        while (generatedArgumentByte < 8) limit 8 {
          if (differs(artifact[proofRow + 16 + generatedArgumentByte], 255)) {
            return 0;
          }

          generatedArgumentByte += 1;
        }

        proofValid = verifyGeneratedInverse(artifact, descriptor, codeOffset) == 1;
      }

      if (rule == PROOF_STATIC_STEP_BOUND) {
        long staticBound = readUnsigned(artifact, proofRow + 16, 8);
        if (staticBound < 1) {
          return 0;
        }

        if (maxSteps < staticBound) {
          return 0;
        }

        long staticForwardOffset = readUnsigned(artifact, descriptor + 12, 4);
        long staticForwardLength = readUnsigned(artifact, descriptor + 16, 4);
        long staticSteps = straightLineInstructionCount(
          artifact,
          codeOffset + staticForwardOffset,
          staticForwardLength
        );
        if (staticSteps < 0) {
          return 0;
        }

        if (staticBound < staticSteps) {
          return 0;
        }

        proofValid = true;
      }

      if (proofValid == false) {
        return 0;
      }

      proof += 1;
    }

    return 1;
  }
}
