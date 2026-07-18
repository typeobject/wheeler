module examples.compiler.verifier;
import examples.compiler.function_verifier;
import examples.compiler.proof_verifier;
import examples.compiler.type_codes;
classical class Verifier {
    private boolean differs(long left, long right) {
        if (left < right) {
            return true;
        }
        return right < left;
    }

    private long align8(long value) {
        long remainder = value % 8;
        if (remainder == 0) {
            return value;
        }
        return value + 8 - remainder;
    }

    private long readUnsigned(
        byteview artifact,
        long offset,
        long width
    ) {
        long value = 0;
        long multiplier = 1;
        long cursor = 0;
        while (cursor < width) limit 8 {
            value += artifact[offset + cursor] * multiplier;
            cursor += 1;
            if (cursor < width) {
                multiplier = multiplier * 256;
            }
        }
        return value;
    }

    private long directoryField(
        byteview artifact,
        long section,
        long field,
        long width
    ) {
        return readUnsigned(
            artifact, 40 + section * 32 + field, width);
    }

    private boolean magicValid(byteview artifact) {
        if (artifact[0] == 87) {
            if (artifact[1] == 72) {
                if (artifact[2] == 69) {
                    if (artifact[3] == 69) {
                        if (artifact[4] == 76) {
                            if (artifact[5] == 66) {
                                if (artifact[6] == 67) {
                                    return artifact[7] == 0;
                                }
                            }
                        }
                    }
                }
            }
        }
        return false;
    }

    private long verifyDirectory(
        byteview artifact,
        long fileLength,
        long sectionCount
    ) {
        long section = 0;
        long expectedOffset = align8(40 + sectionCount * 32);
        while (section < sectionCount) limit 7 {
            long sectionType = directoryField(artifact, section, 0, 4);
            long expectedType = section + 1;
            if (section == 6) {
                expectedType = 10;
            }
            if (differs(sectionType, expectedType)) {
                return 0;
            }
            if (differs(directoryField(artifact, section, 4, 4), 1)) {
                return 0;
            }
            long sectionOffset = directoryField(
                artifact, section, 8, 8);
            long sectionLength = directoryField(
                artifact, section, 16, 8);
            if (differs(sectionOffset, align8(expectedOffset))) {
                return 0;
            }
            if (sectionLength < 1) {
                return 0;
            }
            if (differs(directoryField(artifact, section, 24, 4), 8)) {
                return 0;
            }
            if (differs(directoryField(artifact, section, 28, 4), 0)) {
                return 0;
            }
            expectedOffset = sectionOffset + sectionLength;
            section += 1;
        }
        if (differs(align8(expectedOffset), fileLength)) {
            return 0;
        }
        return 1;
    }

    private long verifyPayloads(byteview artifact, long sectionCount) {
        long manifestOffset = directoryField(artifact, 0, 8, 8);
        long stringsOffset = directoryField(artifact, 1, 8, 8);
        long typesOffset = directoryField(artifact, 2, 8, 8);
        long variantsOffset = directoryField(artifact, 3, 8, 8);
        long functionsOffset = directoryField(artifact, 4, 8, 8);
        long functionsLength = directoryField(artifact, 4, 16, 8);
        long codeOffset = directoryField(artifact, 5, 8, 8);
        long codeLength = directoryField(artifact, 5, 16, 8);
        long globalCount = readUnsigned(artifact, typesOffset, 4);
        long stringCount = readUnsigned(artifact, stringsOffset, 4);
        long functionCount = readUnsigned(artifact, functionsOffset, 4);
        long entryFunction = readUnsigned(artifact, manifestOffset + 4, 4);
        if (globalCount < 2) {
        } else {
            return 0;
        }
        if (differs(directoryField(artifact, 0, 16, 8), 24)) {
            return 0;
        }
        if (differs(
                directoryField(artifact, 2, 16, 8),
                16 + globalCount * 16)) {
            return 0;
        }
        if (differs(directoryField(artifact, 3, 16, 8), 4)) {
            return 0;
        }
        if (globalCount == 1) {
            long globalName = readUnsigned(artifact, typesOffset + 4, 4);
            if (globalName < stringCount) {
            } else {
                return 0;
            }
            if (differs(
                    readUnsigned(artifact, typesOffset + 8, 4),
                    TYPE_SIGNED)) {
                return 0;
            }
        }
        if (differs(
                stringCount,
                globalCount + 1 + functionCount + sectionCount - 6)) {
            return 0;
        }
        long typeCounts = typesOffset + 4 + globalCount * 16;
        if (differs(readUnsigned(artifact, typeCounts, 4), 0)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, typeCounts + 4, 4), 0)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, typeCounts + 8, 4), 0)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, variantsOffset, 4), 0)) {
            return 0;
        }
        if (verifyFunctions(
                artifact,
                functionsOffset,
                functionsLength,
                codeOffset,
                codeLength,
                globalCount,
                functionCount,
                entryFunction,
                stringCount) == 0) {
            return 0;
        }
        long programName = readUnsigned(artifact, manifestOffset, 4);
        if (programName < stringCount) {
        } else {
            return 0;
        }
        if (differs(entryFunction, functionCount - 1)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, manifestOffset + 8, 4), 250000)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, manifestOffset + 12, 4), 0)) {
            return 0;
        }
        if (differs(
                readUnsigned(artifact, manifestOffset + 16, 8),
                1000000)) {
            return 0;
        }
        long proofOffset = 0;
        long proofLength = 0;
        if (sectionCount == 7) {
            proofOffset = directoryField(artifact, 6, 8, 8);
            proofLength = directoryField(artifact, 6, 16, 8);
        }
        if (verifyProofs(
                artifact,
                sectionCount,
                proofOffset,
                proofLength,
                functionsOffset,
                codeOffset,
                functionCount,
                entryFunction,
                stringCount,
                readUnsigned(artifact, manifestOffset + 16, 8)) == 0) {
            return 0;
        }
        return 1;
    }

    public long verifyArtifact(byteview artifact, long fileLength) {
        if (fileLength < 320) {
            return 0;
        }
        if (bufferLength(artifact) < fileLength) {
            return 0;
        }
        if (magicValid(artifact)) {
        } else {
            return 0;
        }
        if (differs(readUnsigned(artifact, 8, 2), 1)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, 10, 2), 0)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, 12, 4), 0)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, 16, 8), fileLength)) {
            return 0;
        }
        long sectionCount = readUnsigned(artifact, 24, 4);
        if (sectionCount < 6) {
            return 0;
        }
        if (7 < sectionCount) {
            return 0;
        }
        if (differs(readUnsigned(artifact, 28, 4), 32)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, 32, 8), 40)) {
            return 0;
        }
        if (verifyDirectory(
                artifact, fileLength, sectionCount) == 1) {
            return verifyPayloads(artifact, sectionCount);
        }
        return 0;
    }
}
