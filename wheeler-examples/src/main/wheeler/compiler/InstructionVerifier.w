/// Verifies bounded instruction streams, operands, local types, and branch targets.
module examples.compiler.instruction_verifier;
import examples.compiler.aggregate_verifier;
import examples.compiler.opcodes;
import examples.compiler.storage_verifier;
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

    private long descriptorBase(long functionsOffset, long function) {
        return functionsOffset + 4 + function * 40;
    }

    private boolean functionHasFlag(
        byteview artifact,
        long functionsOffset,
        long function,
        long flag
    ) {
        long flags = readUnsigned(
            artifact, descriptorBase(functionsOffset, function) + 8, 4);
        return (flags & flag) == flag;
    }

    private long functionParameterCount(
        byteview artifact,
        long functionsOffset,
        long function
    ) {
        return readUnsigned(
            artifact, descriptorBase(functionsOffset, function) + 28, 4);
    }

    private long functionTypeStart(
        byteview artifact,
        long functionsOffset,
        long functionCount,
        long function
    ) {
        long descriptor = descriptorBase(functionsOffset, function);
        long typeOffset = readUnsigned(artifact, descriptor + 36, 4);
        long start = functionsOffset + 4 + functionCount * 40
            + typeOffset * 4;
        if (functionHasFlag(artifact, functionsOffset, function, 4)) {
            start += 4;
        }
        return start;
    }

    private long functionResultType(
        byteview artifact,
        long functionsOffset,
        long functionCount,
        long function
    ) {
        long descriptor = descriptorBase(functionsOffset, function);
        long typeOffset = readUnsigned(artifact, descriptor + 36, 4);
        return readUnsigned(
            artifact,
            functionsOffset + 4 + functionCount * 40 + typeOffset * 4,
            4);
    }

    private long callArgumentsValid(
        byteview artifact,
        long functionsOffset,
        long functionCount,
        long activeTypes,
        long localCount,
        long target,
        long argumentBase,
        long argumentCount
    ) {
        if (target < functionCount) {
        } else {
            return 0;
        }
        if (differs(
                argumentCount,
                functionParameterCount(artifact, functionsOffset, target))) {
            return 0;
        }
        if (localCount < argumentBase + argumentCount) {
            return 0;
        }
        long targetTypes = functionTypeStart(
            artifact, functionsOffset, functionCount, target);
        long argument = 0;
        while (argument < argumentCount) limit INTERPRETER_LOCAL_WIDTH {
            if (differs(
                    localType(
                        artifact, activeTypes, argumentBase + argument),
                    localType(artifact, targetTypes, argument))) {
                return 0;
            }
            argument += 1;
        }
        return 1;
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
        if (opcode == OPCODE_CALL_VALUE) {
            return 4;
        }
        if (opcode == OPCODE_RETURN_VALUE) {
            return 1;
        }
        if (opcode == OPCODE_CALL_VOID) {
            return 3;
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
        if (opcode == OPCODE_RECORD_NEW) {
            return 4;
        }
        if (opcode == OPCODE_RECORD_GET) {
            return 3;
        }
        if (opcode == OPCODE_VARIANT_NEW) {
            return 5;
        }
        if (opcode == OPCODE_VARIANT_TAG_EQ) {
            return 3;
        }
        if (opcode == OPCODE_VARIANT_GET) {
            return 4;
        }
        if (opcode == OPCODE_ARRAY_NEW) {
            return 4;
        }
        if (opcode == OPCODE_ARRAY_GET) {
            return 3;
        }
        if (opcode == OPCODE_SLICE_NEW) {
            return 5;
        }
        if (opcode == OPCODE_SLICE_GET) {
            return 3;
        }
        if (opcode == OPCODE_OWNED_MOVE) {
            return 2;
        }
        if (opcode == OPCODE_REGION_NEW) {
            return 3;
        }
        if (opcode == OPCODE_WORDS_ALLOC) {
            return 3;
        }
        if (opcode == OPCODE_WORDS_GET) {
            return 3;
        }
        if (opcode == OPCODE_WORDS_SET) {
            return 3;
        }
        if (opcode == OPCODE_BUFFER_DROP) {
            return 1;
        }
        if (opcode == OPCODE_REGION_DROP) {
            return 1;
        }
        if (opcode == OPCODE_BYTES_ALLOC) {
            return 3;
        }
        if (opcode == OPCODE_BYTES_GET) {
            return 3;
        }
        if (opcode == OPCODE_BYTES_SET) {
            return 3;
        }
        if (opcode == OPCODE_BUFFER_LENGTH) {
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
        long typesOffset,
        long variantsOffset,
        long globalCount,
        long recordCount,
        long variantCount,
        long arrayCount,
        long sliceCount,
        long functionCount,
        long localCount,
        long activeStart,
        long activeEnd,
        long activeTypes,
        long activeResultType,
        long functionsOffset
    ) {
        if (opcode == OPCODE_HALT) {
            return 1;
        }
        if (opcode == OPCODE_RETURN) {
            return 1;
        }
        long first = readUnsigned(artifact, cursor + 8, 8);
        long aggregateValid = aggregateOperandsValid(
            artifact,
            cursor,
            opcode,
            typesOffset,
            variantsOffset,
            globalCount,
            recordCount,
            variantCount,
            arrayCount,
            sliceCount,
            localCount,
            activeTypes);
        if (aggregateValid < 0) {
        } else {
            return aggregateValid;
        }
        long storageValid = storageOperandsValid(
            artifact,
            cursor,
            opcode,
            localCount,
            activeTypes);
        if (storageValid < 0) {
        } else {
            return storageValid;
        }
        if (isGlobalConstantOpcode(opcode)) {
            if (first < globalCount) {
                return 1;
            }
            return 0;
        }
        if (opcode == OPCODE_RETURN_VALUE) {
            if (first < localCount) {
                if (localType(artifact, activeTypes, first)
                        == activeResultType) {
                    return 1;
                }
            }
            return 0;
        }
        if (opcode == OPCODE_CALL) {
            if (first < functionCount - 1) {
                if (functionParameterCount(
                        artifact, functionsOffset, first) == 0) {
                    if (functionHasFlag(
                            artifact, functionsOffset, first, 4)) {
                    } else {
                        return 1;
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_UNCALL) {
            if (first < functionCount - 1) {
                if (functionParameterCount(
                        artifact, functionsOffset, first) == 0) {
                    if (functionHasFlag(
                            artifact, functionsOffset, first, 1)) {
                        if (functionHasFlag(
                                artifact, functionsOffset, first, 4)) {
                        } else {
                            return 1;
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_CALL_VALUE) {
            long valueArgumentBase = readUnsigned(
                artifact, cursor + 16, 8);
            long valueArgumentCount = readUnsigned(
                artifact, cursor + 24, 8);
            long valueDestination = readUnsigned(
                artifact, cursor + 32, 8);
            if (first < functionCount - 1) {
                if (valueDestination < localCount) {
                    if (functionHasFlag(
                            artifact, functionsOffset, first, 4)) {
                        if (localType(
                                artifact,
                                activeTypes,
                                valueDestination)
                                == functionResultType(
                                    artifact,
                                    functionsOffset,
                                    functionCount,
                                    first)) {
                            return callArgumentsValid(
                                artifact,
                                functionsOffset,
                                functionCount,
                                activeTypes,
                                localCount,
                                first,
                                valueArgumentBase,
                                valueArgumentCount);
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_CALL_VOID) {
            long voidArgumentBase = readUnsigned(
                artifact, cursor + 16, 8);
            long voidArgumentCount = readUnsigned(
                artifact, cursor + 24, 8);
            if (first < functionCount - 1) {
                if (functionHasFlag(
                        artifact, functionsOffset, first, 4)) {
                } else {
                    return callArgumentsValid(
                        artifact,
                        functionsOffset,
                        functionCount,
                        activeTypes,
                        localCount,
                        first,
                        voidArgumentBase,
                        voidArgumentCount);
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

    public long verifyFunctionCode(
        byteview artifact,
        long codeStart,
        long codeLength,
        long functionsOffset,
        long typesOffset,
        long variantsOffset,
        long globalCount,
        long recordCount,
        long variantCount,
        long arrayCount,
        long sliceCount,
        long functionCount,
        long localCount,
        long activeTypes,
        long resultType,
        long entryBody
    ) {
        long cursor = codeStart;
        long end = codeStart + codeLength;
        long lastOpcode = -1;
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
            if (instructionOperandsValid(
                    artifact,
                    cursor,
                    opcode,
                    typesOffset,
                    variantsOffset,
                    globalCount,
                    recordCount,
                    variantCount,
                    arrayCount,
                    sliceCount,
                    functionCount,
                    localCount,
                    codeStart,
                    end,
                    activeTypes,
                    resultType,
                    functionsOffset) == 0) {
                return 0;
            }
            if (opcode == OPCODE_HALT) {
                if (entryBody == 1) {
                    if (differs(cursor + instructionLength, end)) {
                        return 0;
                    }
                } else {
                    return 0;
                }
            }
            if (opcode == OPCODE_RETURN) {
                if (entryBody == 0) {
                    if (resultType == 0) {
                    } else {
                        return 0;
                    }
                } else {
                    return 0;
                }
            }
            if (opcode == OPCODE_RETURN_VALUE) {
                if (entryBody == 0) {
                    if (0 < resultType) {
                    } else {
                        return 0;
                    }
                } else {
                    return 0;
                }
            }
            lastOpcode = opcode;
            cursor += instructionLength;
        }
        if (differs(cursor, end)) {
            return 0;
        }
        if (entryBody == 1) {
            if (lastOpcode == OPCODE_HALT) {
                return 1;
            }
            return 0;
        }
        if (0 < resultType) {
            if (lastOpcode == OPCODE_RETURN_VALUE) {
                return 1;
            }
            return 0;
        }
        if (lastOpcode == OPCODE_RETURN) {
            return 1;
        }
        return 0;
    }

}
