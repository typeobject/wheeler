/// Checks the bounded classical proof records accepted by native bootstrap tools.
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

    private long straightLineInstructionCount(
        byteview artifact,
        long start,
        long length
    ) {
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
            long instructionLength = readUnsigned(
                artifact, cursor + 4, 4);
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
        if (sectionCount == 7) {
        } else {
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
        if (readUnsigned(artifact, proofOffset + 8, 4) < stringCount) {
        } else {
            return 0;
        }
        long rule = readUnsigned(artifact, proofOffset + 12, 4);
        long subject = readUnsigned(artifact, proofOffset + 16, 4);
        if (subject < entryFunction) {
        } else {
            return 0;
        }
        long descriptor = functionsOffset + 4 + subject * 40;
        if (rule == PROOF_GENERATED_INVERSE) {
            if (differs(readUnsigned(artifact, descriptor + 8, 4), 1)) {
                return 0;
            }
            long argumentByte = 0;
            while (argumentByte < 8) limit 8 {
                if (differs(
                        artifact[proofOffset + 20 + argumentByte],
                        255)) {
                    return 0;
                }
                argumentByte += 1;
            }
            return 1;
        }
        if (rule == PROOF_STATIC_STEP_BOUND) {
            long bound = readUnsigned(artifact, proofOffset + 20, 8);
            if (bound < 1) {
                return 0;
            }
            if (maxSteps < bound) {
                return 0;
            }
            long forwardOffset = readUnsigned(
                artifact, descriptor + 12, 4);
            long forwardLength = readUnsigned(
                artifact, descriptor + 16, 4);
            long steps = straightLineInstructionCount(
                artifact,
                codeOffset + forwardOffset,
                forwardLength);
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
