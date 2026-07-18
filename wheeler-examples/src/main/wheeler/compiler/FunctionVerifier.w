/// Verifies bounded function descriptors, scalar type windows, and code ranges.
module examples.compiler.function_verifier;
import examples.compiler.instruction_verifier;
import examples.compiler.opcodes;
import examples.compiler.type_codes;
import examples.packages.binary;
classical class FunctionVerifier {
    private boolean differs(long left, long right) {
        if (left < right) {
            return true;
        }
        return right < left;
    }

    private boolean validValueType(
        long typeCode,
        long recordCount,
        long variantCount,
        long arrayCount,
        long sliceCount
    ) {
        if (typeCode == TYPE_SIGNED) {
            return true;
        }
        if (typeCode == TYPE_BOOLEAN) {
            return true;
        }
        if (typeCode == TYPE_REGION) {
            return true;
        }
        if (typeCode == TYPE_WORDS) {
            return true;
        }
        if (typeCode == TYPE_BYTES) {
            return true;
        }
        if (typeCode == TYPE_LONG_MAP) {
            return true;
        }
        if (typeCode == TYPE_UTF8) {
            return true;
        }
        if (typeCode == TYPE_UTF8_BORROW) {
            return true;
        }
        if (isRecordType(typeCode)) {
            return recordTypeId(typeCode) < recordCount;
        }
        if (isVariantType(typeCode)) {
            return variantTypeId(typeCode) < variantCount;
        }
        if (isArrayType(typeCode)) {
            return arrayTypeId(typeCode) < arrayCount;
        }
        if (isSliceType(typeCode)) {
            return sliceTypeId(typeCode) < sliceCount;
        }
        return false;
    }

    private long verifyTypeWindow(
        byteview artifact,
        long start,
        long count,
        long recordCount,
        long variantCount,
        long arrayCount,
        long sliceCount
    ) {
        long index = 0;
        while (index < count) limit INTERPRETER_LOCAL_WIDTH + 1 {
            if (validValueType(
                    readUnsigned(artifact, start + index * 4, 4),
                    recordCount,
                    variantCount,
                    arrayCount,
                    sliceCount)) {
            } else {
                return 0;
            }
            index += 1;
        }
        return 1;
    }

    public long verifyFunctions(
        byteview artifact,
        long functionsOffset,
        long functionsLength,
        long codeOffset,
        long codeLength,
        long typesOffset,
        long variantsOffset,
        long globalCount,
        long recordCount,
        long variantCount,
        long arrayCount,
        long sliceCount,
        long functionCount,
        long entryFunction,
        long stringCount
    ) {
        if (functionCount < 1) {
            return 0;
        }
        if (INTERPRETER_FUNCTION_COUNT < functionCount) {
            return 0;
        }
        if (differs(entryFunction, functionCount - 1)) {
            return 0;
        }
        long typeTable = functionsOffset + 4 + functionCount * 40;
        long expectedCodeOffset = 0;
        long expectedTypeOffset = 0;
        long function = 0;
        while (function < functionCount) limit INTERPRETER_FUNCTION_COUNT {
            long descriptor = functionsOffset + 4 + function * 40;
            if (differs(readUnsigned(artifact, descriptor, 4), function)) {
                return 0;
            }
            if (readUnsigned(
                    artifact, descriptor + 4, 4) < stringCount) {
            } else {
                return 0;
            }
            long flags = readUnsigned(artifact, descriptor + 8, 4);
            long resultCount = 0;
            if (flags == 0) {
            } else {
                if (flags == 1) {
                } else {
                    if (flags == 4) {
                        resultCount = 1;
                    } else {
                        return 0;
                    }
                }
            }
            if (function == entryFunction) {
                if (differs(flags, 0)) {
                    return 0;
                }
            }
            long forwardOffset = readUnsigned(
                artifact, descriptor + 12, 4);
            long forwardLength = readUnsigned(
                artifact, descriptor + 16, 4);
            long inverseOffset = readUnsigned(
                artifact, descriptor + 20, 4);
            long inverseLength = readUnsigned(
                artifact, descriptor + 24, 4);
            long parameterCount = readUnsigned(
                artifact, descriptor + 28, 4);
            long localCount = readUnsigned(
                artifact, descriptor + 32, 4);
            long typeOffset = readUnsigned(
                artifact, descriptor + 36, 4);
            if (differs(forwardOffset, expectedCodeOffset)) {
                return 0;
            }
            if (forwardLength < 8) {
                return 0;
            }
            if (INTERPRETER_LOCAL_WIDTH < localCount) {
                return 0;
            }
            if (localCount < parameterCount) {
                return 0;
            }
            if (flags == 1) {
                if (differs(parameterCount, 0)) {
                    return 0;
                }
                if (differs(
                        inverseOffset,
                        forwardOffset + forwardLength)) {
                    return 0;
                }
                if (differs(inverseLength, forwardLength)) {
                    return 0;
                }
            } else {
                if (differs(inverseOffset, 4294967295)) {
                    return 0;
                }
                if (differs(inverseLength, 0)) {
                    return 0;
                }
            }
            if (differs(typeOffset, expectedTypeOffset)) {
                return 0;
            }
            long resultType = 0;
            if (resultCount == 1) {
                resultType = readUnsigned(
                    artifact, typeTable + typeOffset * 4, 4);
                if (validValueType(
                        resultType,
                        recordCount,
                        variantCount,
                        arrayCount,
                        sliceCount)) {
                } else {
                    return 0;
                }
            }
            long activeTypes = typeTable
                + (typeOffset + resultCount) * 4;
            if (verifyTypeWindow(
                    artifact,
                    activeTypes,
                    localCount,
                    recordCount,
                    variantCount,
                    arrayCount,
                    sliceCount) == 0) {
                return 0;
            }
            long entryBody = 0;
            if (function == entryFunction) {
                entryBody = 1;
            }
            if (verifyFunctionCode(
                    artifact,
                    codeOffset + forwardOffset,
                    forwardLength,
                    functionsOffset,
                    typesOffset,
                    variantsOffset,
                    globalCount,
                    recordCount,
                    variantCount,
                    arrayCount,
                    sliceCount,
                    functionCount,
                    localCount,
                    activeTypes,
                    resultType,
                    entryBody) == 0) {
                return 0;
            }
            if (flags == 1) {
                if (verifyFunctionCode(
                        artifact,
                        codeOffset + inverseOffset,
                        inverseLength,
                        functionsOffset,
                        typesOffset,
                        variantsOffset,
                        globalCount,
                        recordCount,
                        variantCount,
                        arrayCount,
                        sliceCount,
                        functionCount,
                        localCount,
                        activeTypes,
                        0,
                        0) == 0) {
                    return 0;
                }
            }
            expectedCodeOffset += forwardLength + inverseLength;
            expectedTypeOffset += resultCount + localCount;
            function += 1;
        }
        if (differs(expectedCodeOffset, codeLength)) {
            return 0;
        }
        if (differs(
                functionsLength,
                4 + functionCount * 40 + expectedTypeOffset * 4)) {
            return 0;
        }
        return 1;
    }
}
