//! Checks the bounded classical proof records accepted by native bootstrap tools.
module examples.compiler.proof_verifier;
import examples.compiler.opcodes;
import examples.compiler.proof_rules;
import examples.packages.binary;
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
        if (opcode == OPCODE_JUMP) {
            return true;
        }
        return opcode == OPCODE_JUMP_IF_ZERO;
    }

    private long inverseOpcode(long opcode) {
        if (opcode == OPCODE_ADD_CONST) {
            return OPCODE_SUB_CONST;
        }
        if (opcode == OPCODE_SUB_CONST) {
            return OPCODE_ADD_CONST;
        }
        if (opcode == OPCODE_XOR_CONST) {
            return OPCODE_XOR_CONST;
        }
        if (opcode == OPCODE_CALL) {
            return OPCODE_UNCALL;
        }
        if (opcode == OPCODE_UNCALL) {
            return OPCODE_CALL;
        }
        if (opcode == OPCODE_EXPECT_EQ) {
            return OPCODE_EXPECT_EQ;
        }
        return -1;
    }

    private long instructionCount(byteview artifact, long start, long length) {
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

    private long instructionCursor(byteview artifact, long start, long target) {
        long cursor = start;
        long index = 0;
        while (index < target) limit MAX_CODE_INSTRUCTIONS {
            cursor += readUnsigned(artifact, cursor + 4, 4);
            index += 1;
        }
        return cursor;
    }

    private boolean instructionPayloadsEqual(byteview artifact, long forward, long inverse) {
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

    private long verifyGeneratedInverse(byteview artifact, long descriptor, long codeOffset) {
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
        if (differs(readUnsigned(artifact, forwardReturn, 2), OPCODE_RETURN)) {
            return 0;
        }
        long inverseCursor = inverseStart;
        long inverseIndex = 0;
        while (inverseIndex < forwardCount - 1) limit MAX_CODE_INSTRUCTIONS {
            long forwardIndex = forwardCount - 2 - inverseIndex;
            long forwardCursor = instructionCursor(artifact, forwardStart, forwardIndex);
            long expected = inverseOpcode(readUnsigned(artifact, forwardCursor, 2));
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
        if (differs(readUnsigned(artifact, inverseCursor, 2), OPCODE_RETURN)) {
            return 0;
        }
        inverseCursor += readUnsigned(artifact, inverseCursor + 4, 4);
        if (differs(inverseCursor, inverseStart + inverseLength)) {
            return 0;
        }
        return 1;
    }

    private long straightLineInstructionCount(byteview artifact, long start, long length) {
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
        byteview artifact,
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
        if (differs(proofLength, 28)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, proofOffset, 4), 1)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, proofOffset + 4, 4), 0)) {
            return 0;
        }
        if (readUnsigned(artifact, proofOffset + 8, 4) < stringCount) {} else {
            return 0;
        }
        long rule = readUnsigned(artifact, proofOffset + 12, 4);
        long subject = readUnsigned(artifact, proofOffset + 16, 4);
        if (subject < entryFunction) {} else {
            return 0;
        }
        long descriptor = functionsOffset + 4 + subject * 40;
        if (rule == PROOF_GENERATED_INVERSE) {
            if (differs(readUnsigned(artifact, descriptor + 8, 4), 1)) {
                return 0;
            }
            long argumentByte = 0;
            while (argumentByte < 8) limit 8 {
                if (differs(artifact[proofOffset + 20 + argumentByte], 255)) {
                    return 0;
                }
                argumentByte += 1;
            }
            return verifyGeneratedInverse(artifact, descriptor, codeOffset);
        }
        if (rule == PROOF_STATIC_STEP_BOUND) {
            long bound = readUnsigned(artifact, proofOffset + 20, 8);
            if (bound < 1) {
                return 0;
            }
            if (maxSteps < bound) {
                return 0;
            }
            long forwardOffset = readUnsigned(artifact, descriptor + 12, 4);
            long forwardLength = readUnsigned(artifact, descriptor + 16, 4);
            long steps = straightLineInstructionCount(
                artifact,
                codeOffset + forwardOffset,
                forwardLength
            );
            if (steps < 0) {
                return 0;
            }
            if (bound < steps) {
                return 0;
            }
            return 1;
        }
        return 0;
    }
}
