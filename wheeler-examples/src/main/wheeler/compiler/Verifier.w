module examples.compiler.verifier;
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
        bytes artifact,
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
        bytes artifact,
        long section,
        long field,
        long width
    ) {
        return readUnsigned(
            artifact, 40 + section * 32 + field, width);
    }

    private boolean magicValid(bytes artifact) {
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

    private long verifyDirectory(bytes artifact, long fileLength) {
        long section = 0;
        long expectedOffset = 232;
        while (section < 6) limit 6 {
            long sectionType = directoryField(artifact, section, 0, 4);
            if (differs(sectionType, section + 1)) {
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

    private long verifyPayloads(bytes artifact) {
        long manifestOffset = directoryField(artifact, 0, 8, 8);
        long stringsOffset = directoryField(artifact, 1, 8, 8);
        long typesOffset = directoryField(artifact, 2, 8, 8);
        long variantsOffset = directoryField(artifact, 3, 8, 8);
        long functionsOffset = directoryField(artifact, 4, 8, 8);
        long codeOffset = directoryField(artifact, 5, 8, 8);
        long codeLength = directoryField(artifact, 5, 16, 8);
        long globalCount = readUnsigned(artifact, typesOffset, 4);
        long stringCount = readUnsigned(artifact, stringsOffset, 4);
        long functionCount = readUnsigned(artifact, functionsOffset, 4);
        long localCount = readUnsigned(artifact, functionsOffset + 36, 4);
        long firstForwardLength = readUnsigned(
            artifact, functionsOffset + 20, 4);

        if (differs(directoryField(artifact, 0, 16, 8), 24)) {
            return 0;
        }
        if (differs(directoryField(artifact, 2, 16, 8),
                16 + globalCount * 16)) {
            return 0;
        }
        if (differs(directoryField(artifact, 3, 16, 8), 4)) {
            return 0;
        }
        long expectedFunctionsLength = 44 + localCount * 4;
        if (functionCount == 2) {
            expectedFunctionsLength = 84 + localCount * 4;
        }
        if (differs(
                directoryField(artifact, 4, 16, 8),
                expectedFunctionsLength)) {
            return 0;
        }
        if (globalCount < 2) {
        } else {
            return 0;
        }
        if (differs(stringCount, globalCount + 1 + functionCount)) {
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
        if (functionCount < 1) {
            return 0;
        }
        if (2 < functionCount) {
            return 0;
        }
        if (differs(readUnsigned(artifact, functionsOffset + 4, 4), 0)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, functionsOffset + 12, 4), 0)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, functionsOffset + 16, 4), 0)) {
            return 0;
        }
        if (functionCount == 1) {
            if (differs(firstForwardLength, codeLength)) {
                return 0;
            }
        }
        if (functionCount == 2) {
            if (differs(firstForwardLength + 24, codeLength)) {
                return 0;
            }
        }
        if (differs(readUnsigned(artifact, functionsOffset + 24, 4),
                4294967295)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, functionsOffset + 28, 4), 0)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, functionsOffset + 32, 4), 0)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, functionsOffset + 40, 4), 0)) {
            return 0;
        }
        long functionName = readUnsigned(
            artifact, functionsOffset + 8, 4);
        if (functionName < stringCount) {
        } else {
            return 0;
        }
        if (functionCount == 2) {
            if (differs(readUnsigned(artifact, functionsOffset + 44, 4), 1)) {
                return 0;
            }
            long entryName = readUnsigned(
                artifact, functionsOffset + 48, 4);
            if (entryName < stringCount) {
            } else {
                return 0;
            }
            if (differs(readUnsigned(artifact, functionsOffset + 52, 4), 0)) {
                return 0;
            }
            if (differs(
                    readUnsigned(artifact, functionsOffset + 56, 4),
                    firstForwardLength)) {
                return 0;
            }
            if (differs(readUnsigned(artifact, functionsOffset + 60, 4), 24)) {
                return 0;
            }
            if (differs(
                    readUnsigned(artifact, functionsOffset + 64, 4),
                    4294967295)) {
                return 0;
            }
            if (differs(readUnsigned(artifact, functionsOffset + 68, 4), 0)) {
                return 0;
            }
            if (differs(readUnsigned(artifact, functionsOffset + 72, 4), 0)) {
                return 0;
            }
            if (differs(readUnsigned(artifact, functionsOffset + 76, 4), 0)) {
                return 0;
            }
            if (differs(
                    readUnsigned(artifact, functionsOffset + 80, 4),
                    localCount)) {
                return 0;
            }
            if (differs(
                    readUnsigned(
                        artifact, codeOffset + firstForwardLength - 8, 2),
                    2)) {
                return 0;
            }
            if (differs(
                    readUnsigned(
                        artifact, codeOffset + firstForwardLength, 2),
                    512)) {
                return 0;
            }
        }
        if (differs(readUnsigned(artifact, codeOffset + codeLength - 8, 2), 1)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, codeOffset + codeLength - 6, 2), 0)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, codeOffset + codeLength - 4, 4), 8)) {
            return 0;
        }
        long programName = readUnsigned(artifact, manifestOffset, 4);
        if (programName < stringCount) {
        } else {
            return 0;
        }
        if (differs(
                readUnsigned(artifact, manifestOffset + 4, 4),
                functionCount - 1)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, manifestOffset + 8, 4), 100000)) {
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
        return 1;
    }

    public long verifyArtifact(bytes artifact, long fileLength) {
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
        if (differs(readUnsigned(artifact, 24, 4), 6)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, 28, 4), 32)) {
            return 0;
        }
        if (differs(readUnsigned(artifact, 32, 8), 40)) {
            return 0;
        }
        if (verifyDirectory(artifact, fileLength) == 1) {
            return verifyPayloads(artifact);
        }
        return 0;
    }
}
