module examples.compiler.verifier;
import examples.compiler.opcodes;
import examples.compiler.type_codes;
classical class Verifier {
    private boolean differs(long left, long right) {
        if (left < right) {
            return true;
        }
        return right < left;
    }

    private long localType(
        byteview artifact,
        long activeTypes,
        long local
    ) {
        return readUnsigned(artifact, activeTypes + local * 4, 4);
    }

    private boolean localHasType(
        byteview artifact,
        long activeTypes,
        long local,
        long expected
    ) {
        return localType(artifact, activeTypes, local) == expected;
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

    private long expectedOperandCount(long opcode) {
        if (opcode == OPCODE_HALT) {
            return 0;
        }
        if (opcode == OPCODE_RETURN) {
            return 0;
        }
        if (isGlobalConstantOpcode(opcode)) {
            return 2;
        }
        if (opcode == OPCODE_CALL) {
            return 1;
        }
        if (opcode == OPCODE_UNCALL) {
            return 1;
        }
        if (opcode == OPCODE_EXPECT_EQ) {
            return 2;
        }
        if (opcode == OPCODE_LOCAL_CONST) {
            return 2;
        }
        if (opcode == OPCODE_LOCAL_LOAD_GLOBAL) {
            return 2;
        }
        if (opcode == OPCODE_LOCAL_STORE_GLOBAL) {
            return 2;
        }
        if (opcode == OPCODE_LOCAL_MOVE) {
            return 2;
        }
        if (isLocalMathOpcode(opcode)) {
            return 3;
        }
        if (opcode == OPCODE_LOCAL_EQ) {
            return 3;
        }
        if (opcode == OPCODE_LOCAL_LT) {
            return 3;
        }
        if (opcode == OPCODE_JUMP) {
            return 1;
        }
        if (opcode == OPCODE_JUMP_IF_ZERO) {
            return 2;
        }
        if (opcode == OPCODE_LOCAL_LOOP_CHECK) {
            return 2;
        }
        return -1;
    }

    private long instructionCount(
        byteview artifact,
        long start,
        long end
    ) {
        long cursor = start;
        long count = 0;
        while (cursor < end) limit MAX_CODE_INSTRUCTIONS {
            if (end - cursor < 8) {
                return -1;
            }
            long length = readUnsigned(artifact, cursor + 4, 4);
            if (length < 8) {
                return -1;
            }
            if (end < cursor + length) {
                return -1;
            }
            cursor += length;
            count += 1;
        }
        if (differs(cursor, end)) {
            return -1;
        }
        return count;
    }

    private long instructionOperandsValid(
        byteview artifact,
        long cursor,
        long opcode,
        long globalCount,
        long functionCount,
        long localCount,
        long reversibleHelper,
        long activeStart,
        long activeEnd,
        long activeTypes
    ) {
        if (opcode == OPCODE_HALT) {
            return 1;
        }
        if (opcode == OPCODE_RETURN) {
            return 1;
        }
        long first = readUnsigned(artifact, cursor + 8, 8);
        if (isGlobalConstantOpcode(opcode)) {
            if (first < globalCount) {
                return 1;
            }
            return 0;
        }
        if (opcode == OPCODE_CALL) {
            if (first == 0) {
                if (1 < functionCount) {
                    return 1;
                }
            }
            return 0;
        }
        if (opcode == OPCODE_UNCALL) {
            if (reversibleHelper == 1) {
                if (first == 0) {
                    if (1 < functionCount) {
                        return 1;
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_EXPECT_EQ) {
            if (first < globalCount) {
                return 1;
            }
            return 0;
        }
        if (opcode == OPCODE_LOCAL_CONST) {
            if (first < localCount) {
                long destinationType = localType(
                    artifact, activeTypes, first);
                if (destinationType == TYPE_SIGNED) {
                    return 1;
                }
                if (destinationType == TYPE_BOOLEAN) {
                    if (readUnsigned(artifact, cursor + 16, 8) < 2) {
                        return 1;
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_LOCAL_LOAD_GLOBAL) {
            long global = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (global < globalCount) {
                    if (localHasType(
                            artifact, activeTypes, first, TYPE_SIGNED)) {
                        return 1;
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_LOCAL_STORE_GLOBAL) {
            long local = readUnsigned(artifact, cursor + 16, 8);
            if (first < globalCount) {
                if (local < localCount) {
                    if (localHasType(
                            artifact, activeTypes, local, TYPE_SIGNED)) {
                        return 1;
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_LOCAL_MOVE) {
            long source = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (source < localCount) {
                    if (localType(artifact, activeTypes, first)
                            == localType(artifact, activeTypes, source)) {
                        return 1;
                    }
                }
            }
            return 0;
        }
        if (isLocalMathOpcode(opcode)) {
            long left = readUnsigned(artifact, cursor + 16, 8);
            long right = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (left < localCount) {
                    if (right < localCount) {
                        if (localHasType(
                                artifact, activeTypes, first, TYPE_SIGNED)) {
                            if (localHasType(
                                    artifact, activeTypes, left, TYPE_SIGNED)) {
                                if (localHasType(
                                        artifact, activeTypes, right, TYPE_SIGNED)) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_LOCAL_EQ) {
            long equalityLeft = readUnsigned(artifact, cursor + 16, 8);
            long equalityRight = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (equalityLeft < localCount) {
                    if (equalityRight < localCount) {
                        if (localHasType(
                                artifact, activeTypes, first, TYPE_BOOLEAN)) {
                            if (localType(artifact, activeTypes, equalityLeft)
                                    == localType(
                                        artifact,
                                        activeTypes,
                                        equalityRight)) {
                                return 1;
                            }
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_LOCAL_LT) {
            long lessLeft = readUnsigned(artifact, cursor + 16, 8);
            long lessRight = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (lessLeft < localCount) {
                    if (lessRight < localCount) {
                        if (localHasType(
                                artifact, activeTypes, first, TYPE_BOOLEAN)) {
                            if (localHasType(
                                    artifact, activeTypes, lessLeft, TYPE_SIGNED)) {
                                if (localHasType(
                                        artifact,
                                        activeTypes,
                                        lessRight,
                                        TYPE_SIGNED)) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
            return 0;
        }
        long activeInstructions = instructionCount(
            artifact, activeStart, activeEnd);
        if (activeInstructions < 0) {
            return 0;
        }
        if (opcode == OPCODE_JUMP) {
            if (first < activeInstructions) {
                return 1;
            }
            return 0;
        }
        if (opcode == OPCODE_JUMP_IF_ZERO) {
            long target = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (target < activeInstructions) {
                    if (localHasType(
                            artifact, activeTypes, first, TYPE_BOOLEAN)) {
                        return 1;
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_LOCAL_LOOP_CHECK) {
            long limit = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (limit < localCount) {
                    if (localHasType(
                            artifact, activeTypes, first, TYPE_SIGNED)) {
                        if (localHasType(
                                artifact, activeTypes, limit, TYPE_SIGNED)) {
                            return 1;
                        }
                    }
                }
            }
            return 0;
        }
        return 1;
    }

    private long verifyCodeStream(
        byteview artifact,
        long codeOffset,
        long codeLength,
        long functionsOffset,
        long globalCount,
        long functionCount,
        long helperForwardLength,
        long helperInverseLength,
        long helperLocalCount,
        long entryLocalCount,
        long reversibleHelper
    ) {
        long cursor = codeOffset;
        long end = codeOffset + codeLength;
        while (cursor < end) limit MAX_CODE_INSTRUCTIONS {
            if (end - cursor < 8) {
                return 0;
            }
            long opcode = readUnsigned(artifact, cursor, 2);
            long operandCount = readUnsigned(artifact, cursor + 2, 2);
            long expectedOperands = expectedOperandCount(opcode);
            if (expectedOperands < 0) {
                return 0;
            }
            if (differs(operandCount, expectedOperands)) {
                return 0;
            }
            long instructionLength = readUnsigned(
                artifact, cursor + 4, 4);
            long expectedLength = 8 + operandCount * 8;
            if (differs(instructionLength, expectedLength)) {
                return 0;
            }
            if (end < cursor + instructionLength) {
                return 0;
            }
            long activeLocalCount = helperLocalCount;
            long activeStart = codeOffset;
            long activeEnd = codeOffset + codeLength;
            long activeTypes = functionsOffset + 84;
            if (functionCount == 1) {
                activeLocalCount = entryLocalCount;
                activeTypes = functionsOffset + 44;
            }
            if (1 < functionCount) {
                long forwardEnd = codeOffset + helperForwardLength;
                long inverseEnd = forwardEnd + helperInverseLength;
                if (cursor < forwardEnd) {
                    activeEnd = forwardEnd;
                } else {
                    if (cursor < inverseEnd) {
                        activeStart = forwardEnd;
                        activeEnd = inverseEnd;
                    } else {
                        activeLocalCount = entryLocalCount;
                        activeStart = inverseEnd;
                        activeTypes += helperLocalCount * 4;
                    }
                }
            }
            if (instructionOperandsValid(
                    artifact,
                    cursor,
                    opcode,
                    globalCount,
                    functionCount,
                    activeLocalCount,
                    reversibleHelper,
                    activeStart,
                    activeEnd,
                    activeTypes) == 0) {
                return 0;
            }
            if (opcode == OPCODE_HALT) {
                if (differs(cursor + instructionLength, end)) {
                    return 0;
                }
            }
            cursor += instructionLength;
        }
        if (differs(cursor, end)) {
            return 0;
        }
        return 1;
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

    private long verifyLocalTypes(
        byteview artifact,
        long functionsOffset,
        long functionCount,
        long helperLocalCount,
        long entryLocalCount
    ) {
        long typeCursor = functionsOffset + 44;
        long typeCount = entryLocalCount;
        if (functionCount == 2) {
            typeCursor = functionsOffset + 84;
            typeCount = helperLocalCount + entryLocalCount;
        }
        long index = 0;
        while (index < typeCount)
            limit INTERPRETER_LOCAL_WIDTH * 2 {
            long typeCode = readUnsigned(artifact, typeCursor, 4);
            if (typeCode == TYPE_SIGNED) {
            } else {
                if (typeCode == TYPE_BOOLEAN) {
                } else {
                    return 0;
                }
            }
            typeCursor += 4;
            index += 1;
        }
        return 1;
    }

    private long verifyPayloads(byteview artifact, long sectionCount) {
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
        long entryLocalCount = localCount;
        if (functionCount == 2) {
            entryLocalCount = readUnsigned(
                artifact, functionsOffset + 76, 4);
        }
        long firstFlags = readUnsigned(
            artifact, functionsOffset + 12, 4);
        long firstForwardLength = readUnsigned(
            artifact, functionsOffset + 20, 4);
        long firstInverseOffset = readUnsigned(
            artifact, functionsOffset + 24, 4);
        long firstInverseLength = readUnsigned(
            artifact, functionsOffset + 28, 4);
        if (globalCount < 2) {
        } else {
            return 0;
        }
        if (functionCount < 1) {
            return 0;
        }
        if (2 < functionCount) {
            return 0;
        }
        if (INTERPRETER_LOCAL_WIDTH < localCount) {
            return 0;
        }
        if (INTERPRETER_LOCAL_WIDTH < entryLocalCount) {
            return 0;
        }

        if (verifyCodeStream(
                artifact,
                codeOffset,
                codeLength,
                functionsOffset,
                globalCount,
                functionCount,
                firstForwardLength,
                firstInverseLength,
                localCount,
                entryLocalCount,
                firstFlags) == 0) {
            return 0;
        }
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
            expectedFunctionsLength = 84
                + localCount * 4
                + entryLocalCount * 4;
        }
        if (differs(
                directoryField(artifact, 4, 16, 8),
                expectedFunctionsLength)) {
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
        if (verifyLocalTypes(
                artifact,
                functionsOffset,
                functionCount,
                localCount,
                entryLocalCount) == 0) {
            return 0;
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
        if (differs(readUnsigned(artifact, functionsOffset + 4, 4), 0)) {
            return 0;
        }
        if (1 < firstFlags) {
            return 0;
        }
        if (functionCount == 1) {
            if (differs(firstFlags, 0)) {
                return 0;
            }
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
            long entryForwardLength = readUnsigned(
                artifact, functionsOffset + 60, 4);
            if (differs(
                    firstForwardLength
                        + firstInverseLength
                        + entryForwardLength,
                    codeLength)) {
                return 0;
            }
            if (firstFlags == 0) {
                if (entryForwardLength < 24) {
                    return 0;
                }
                if (differs(firstInverseOffset, 4294967295)) {
                    return 0;
                }
                if (differs(firstInverseLength, 0)) {
                    return 0;
                }
            }
            if (firstFlags == 1) {
                if (entryForwardLength < 40) {
                    return 0;
                }
                if (differs(firstInverseOffset, firstForwardLength)) {
                    return 0;
                }
                if (differs(firstInverseLength, firstForwardLength)) {
                    return 0;
                }
                if (firstInverseLength < 32) {
                    return 0;
                }
            }
        }
        if (functionCount == 1) {
            if (differs(firstInverseOffset, 4294967295)) {
                return 0;
            }
            if (differs(firstInverseLength, 0)) {
                return 0;
            }
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
            long entryOffset = firstForwardLength + firstInverseLength;
            if (differs(
                    readUnsigned(artifact, functionsOffset + 56, 4),
                    entryOffset)) {
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
            if (differs(
                    readUnsigned(artifact, functionsOffset + 80, 4),
                    localCount)) {
                return 0;
            }
            if (differs(
                    readUnsigned(
                        artifact, codeOffset + firstForwardLength - 8, 2),
                    OPCODE_RETURN)) {
                return 0;
            }
            if (firstFlags == 1) {
                if (differs(
                        readUnsigned(
                            artifact,
                            codeOffset + firstForwardLength
                                + firstInverseLength - 8,
                            2),
                        OPCODE_RETURN)) {
                    return 0;
                }
            }
            long entryCode = codeOffset
                + firstForwardLength
                + firstInverseLength;
            if (differs(
                    readUnsigned(artifact, entryCode, 2),
                    OPCODE_CALL)) {
                return 0;
            }
        }
        if (differs(
                readUnsigned(artifact, codeOffset + codeLength - 8, 2),
                OPCODE_HALT)) {
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
        if (sectionCount == 7) {
            long proofOffset = directoryField(artifact, 6, 8, 8);
            if (differs(directoryField(artifact, 6, 16, 8), 28)) {
                return 0;
            }
            if (differs(readUnsigned(artifact, proofOffset, 4), 1)) {
                return 0;
            }
            if (differs(readUnsigned(artifact, proofOffset + 4, 4), 0)) {
                return 0;
            }
            long proofName = readUnsigned(artifact, proofOffset + 8, 4);
            if (proofName < stringCount) {
            } else {
                return 0;
            }
            if (differs(readUnsigned(artifact, proofOffset + 12, 4), 1)) {
                return 0;
            }
            if (differs(readUnsigned(artifact, proofOffset + 16, 4), 0)) {
                return 0;
            }
            if (firstFlags == 1) {
            } else {
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
