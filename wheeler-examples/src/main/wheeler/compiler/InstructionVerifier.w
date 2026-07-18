/// Verifies bounded instruction streams, operands, local types, and branch targets.
module examples.compiler.instruction_verifier;
import examples.compiler.opcodes;
import examples.compiler.type_codes;
import examples.packages.binary;
classical class InstructionVerifier {
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

    public long verifyCodeStream(
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

}
