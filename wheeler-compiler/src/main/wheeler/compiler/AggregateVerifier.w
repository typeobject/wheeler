//! Verifies bounded record and finite-variant instruction operands.
module wheeler.compiler.aggregate_verifier;
import wheeler.compiler.opcodes;
import wheeler.compiler.type_codes;
import wheeler.core.encoding.binary;
classical class AggregateVerifier {
    private boolean differs(long left, long right) {
        if (left < right) {
            return true;
        }
        return right < left;
    }

    private long localType(byteview artifact, long activeTypes, long local) {
        return readUnsigned(artifact, activeTypes + local * 4, 4);
    }

    private long recordDescriptor(
        byteview artifact,
        long typesOffset,
        long globalCount,
        long recordCount,
        long recordId
    ) {
        long cursor = typesOffset + 8 + globalCount * 16;
        long record = 0;
        while (record < recordCount) limit INTERPRETER_AGGREGATE_COUNT {
            if (differs(readUnsigned(artifact, cursor, 4), record)) {
                return -1;
            }
            if (record == recordId) {
                return cursor;
            }
            long fieldCount = readUnsigned(artifact, cursor + 8, 4);
            cursor += 12 + fieldCount * 8;
            record += 1;
        }
        return -1;
    }

    private long recordFieldType(byteview artifact, long descriptor, long field) {
        return readUnsigned(artifact, descriptor + 16 + field * 8, 4);
    }

    private long variantDescriptor(
        byteview artifact,
        long variantsOffset,
        long variantCount,
        long variantId
    ) {
        long cursor = variantsOffset + 4;
        long variant = 0;
        while (variant < variantCount) limit INTERPRETER_AGGREGATE_COUNT {
            if (variant == variantId) {
                return cursor;
            }
            long caseCount = readUnsigned(artifact, cursor + 8, 4);
            cursor += 12;
            long variantCase = 0;
            while (variantCase < caseCount) limit INTERPRETER_AGGREGATE_COUNT {
                long fieldCount = readUnsigned(artifact, cursor + 4, 4);
                cursor += 8 + fieldCount * 8;
                variantCase += 1;
            }
            variant += 1;
        }
        return -1;
    }

    private long variantCaseDescriptor(byteview artifact, long descriptor, long tag) {
        long caseCount = readUnsigned(artifact, descriptor + 8, 4);
        if (tag < caseCount) {} else {
            return -1;
        }
        long cursor = descriptor + 12;
        long variantCase = 0;
        while (variantCase < tag) limit INTERPRETER_AGGREGATE_COUNT {
            long fieldCount = readUnsigned(artifact, cursor + 4, 4);
            cursor += 8 + fieldCount * 8;
            variantCase += 1;
        }
        return cursor;
    }

    private long variantFieldType(byteview artifact, long caseDescriptor, long field) {
        return readUnsigned(artifact, caseDescriptor + 12 + field * 8, 4);
    }

    private long recordOperandsValid(
        byteview artifact,
        long cursor,
        long opcode,
        long typesOffset,
        long globalCount,
        long recordCount,
        long localCount,
        long activeTypes
    ) {
        long destination = readUnsigned(artifact, cursor + 8, 8);
        if (opcode == OPCODE_RECORD_NEW) {
            long typeId = readUnsigned(artifact, cursor + 16, 8);
            long fieldBase = readUnsigned(artifact, cursor + 24, 8);
            long fieldCount = readUnsigned(artifact, cursor + 32, 8);
            long descriptor = recordDescriptor(
                artifact,
                typesOffset,
                globalCount,
                recordCount,
                typeId
            );
            if (descriptor < 0) {
                return 0;
            }
            if (differs(readUnsigned(artifact, descriptor + 8, 4), fieldCount)) {
                return 0;
            }
            if (localCount < fieldBase + fieldCount) {
                return 0;
            }
            if (destination < localCount) {
                if (
                    differs(localType(artifact, activeTypes, destination), TYPE_RECORD + typeId)
                ) {
                    return 0;
                }
            } else {
                return 0;
            }
            long field = 0;
            while (field < fieldCount) limit INTERPRETER_LOCAL_WIDTH {
                if (
                    differs(
                        localType(artifact, activeTypes, fieldBase + field),
                        recordFieldType(artifact, descriptor, field)
                    )
                ) {
                    return 0;
                }
                field += 1;
            }
            return 1;
        }
        long getSource = readUnsigned(artifact, cursor + 16, 8);
        long getField = readUnsigned(artifact, cursor + 24, 8);
        if (destination < localCount) {
            if (getSource < localCount) {
                long getSourceType = localType(artifact, activeTypes, getSource);
                if (isRecordType(getSourceType)) {
                    long getDescriptor = recordDescriptor(
                        artifact,
                        typesOffset,
                        globalCount,
                        recordCount,
                        recordTypeId(getSourceType)
                    );
                    if (0 < getDescriptor) {
                        if (getField < readUnsigned(artifact, getDescriptor + 8, 4)) {
                            if (
                                differs(
                                    localType(artifact, activeTypes, destination),
                                    recordFieldType(artifact, getDescriptor, getField)
                                )
                            ) {} else {
                                return 1;
                            }
                        }
                    }
                }
            }
        }
        return 0;
    }

    private long variantOperandsValid(
        byteview artifact,
        long cursor,
        long opcode,
        long variantsOffset,
        long variantCount,
        long localCount,
        long activeTypes
    ) {
        long destination = readUnsigned(artifact, cursor + 8, 8);
        if (opcode == OPCODE_VARIANT_NEW) {
            long typeId = readUnsigned(artifact, cursor + 16, 8);
            long tag = readUnsigned(artifact, cursor + 24, 8);
            long fieldBase = readUnsigned(artifact, cursor + 32, 8);
            long fieldCount = readUnsigned(artifact, cursor + 40, 8);
            long descriptor = variantDescriptor(artifact, variantsOffset, variantCount, typeId);
            if (descriptor < 0) {
                return 0;
            }
            long variantCase = variantCaseDescriptor(artifact, descriptor, tag);
            if (variantCase < 0) {
                return 0;
            }
            if (differs(readUnsigned(artifact, variantCase + 4, 4), fieldCount)) {
                return 0;
            }
            if (localCount < fieldBase + fieldCount) {
                return 0;
            }
            if (destination < localCount) {
                if (
                    differs(
                        localType(artifact, activeTypes, destination),
                        TYPE_VARIANT + typeId
                    )
                ) {
                    return 0;
                }
            } else {
                return 0;
            }
            long field = 0;
            while (field < fieldCount) limit INTERPRETER_LOCAL_WIDTH {
                if (
                    differs(
                        localType(artifact, activeTypes, fieldBase + field),
                        variantFieldType(artifact, variantCase, field)
                    )
                ) {
                    return 0;
                }
                field += 1;
            }
            return 1;
        }
        long getSource = readUnsigned(artifact, cursor + 16, 8);
        if (destination < localCount) {
            if (getSource < localCount) {
                long getSourceType = localType(artifact, activeTypes, getSource);
                if (isVariantType(getSourceType)) {
                    long getDescriptor = variantDescriptor(
                        artifact,
                        variantsOffset,
                        variantCount,
                        variantTypeId(getSourceType)
                    );
                    long getTag = readUnsigned(artifact, cursor + 24, 8);
                    long getCase = variantCaseDescriptor(artifact, getDescriptor, getTag);
                    if (opcode == OPCODE_VARIANT_TAG_EQ) {
                        if (localType(artifact, activeTypes, destination) == TYPE_BOOLEAN) {
                            if (0 < getCase) {
                                return 1;
                            }
                        }
                        return 0;
                    }
                    long getField = readUnsigned(artifact, cursor + 32, 8);
                    if (0 < getCase) {
                        if (getField < readUnsigned(artifact, getCase + 4, 4)) {
                            if (
                                differs(
                                    localType(artifact, activeTypes, destination),
                                    variantFieldType(artifact, getCase, getField)
                                )
                            ) {} else {
                                return 1;
                            }
                        }
                    }
                }
            }
        }
        return 0;
    }

    private long arrayDescriptor(
        byteview artifact,
        long typesOffset,
        long globalCount,
        long recordCount,
        long arrayCount,
        long arrayId
    ) {
        long cursor = typesOffset + 8 + globalCount * 16;
        long record = 0;
        while (record < recordCount) limit INTERPRETER_AGGREGATE_COUNT {
            long fieldCount = readUnsigned(artifact, cursor + 8, 4);
            cursor += 12 + fieldCount * 8;
            record += 1;
        }
        cursor += 4;
        if (arrayId < arrayCount) {
            long descriptor = cursor + arrayId * 12;
            if (readUnsigned(artifact, descriptor, 4) == arrayId) {
                return descriptor;
            }
        }
        return -1;
    }

    private long arrayOperandsValid(
        byteview artifact,
        long cursor,
        long opcode,
        long typesOffset,
        long globalCount,
        long recordCount,
        long arrayCount,
        long localCount,
        long activeTypes
    ) {
        long destination = readUnsigned(artifact, cursor + 8, 8);
        if (opcode == OPCODE_ARRAY_NEW) {
            long typeId = readUnsigned(artifact, cursor + 16, 8);
            long elementBase = readUnsigned(artifact, cursor + 24, 8);
            long elementCount = readUnsigned(artifact, cursor + 32, 8);
            long descriptor = arrayDescriptor(
                artifact,
                typesOffset,
                globalCount,
                recordCount,
                arrayCount,
                typeId
            );
            if (descriptor < 0) {
                return 0;
            }
            if (differs(readUnsigned(artifact, descriptor + 8, 4), elementCount)) {
                return 0;
            }
            if (localCount < elementBase + elementCount) {
                return 0;
            }
            if (destination < localCount) {
                if (localType(artifact, activeTypes, destination) == TYPE_ARRAY + typeId) {} else {
                    return 0;
                }
            } else {
                return 0;
            }
            long element = 0;
            while (element < elementCount) limit INTERPRETER_AGGREGATE_FIELDS {
                if (
                    localType(artifact, activeTypes, elementBase + element) == readUnsigned(
                        artifact,
                        descriptor + 4,
                        4
                    )
                ) {} else {
                    return 0;
                }
                element += 1;
            }
            return 1;
        }
        long source = readUnsigned(artifact, cursor + 16, 8);
        long indexLocal = readUnsigned(artifact, cursor + 24, 8);
        if (destination < localCount) {
            if (source < localCount) {
                if (indexLocal < localCount) {
                    long sourceType = localType(artifact, activeTypes, source);
                    if (isArrayType(sourceType)) {
                        long getDescriptor = arrayDescriptor(
                            artifact,
                            typesOffset,
                            globalCount,
                            recordCount,
                            arrayCount,
                            arrayTypeId(sourceType)
                        );
                        if (0 < getDescriptor) {
                            if (localType(artifact, activeTypes, indexLocal) == TYPE_SIGNED) {
                                if (
                                    localType(artifact, activeTypes, destination) == readUnsigned(
                                        artifact,
                                        getDescriptor + 4,
                                        4
                                    )
                                ) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
        }
        return 0;
    }

    private long sliceDescriptor(
        byteview artifact,
        long typesOffset,
        long globalCount,
        long recordCount,
        long arrayCount,
        long sliceCount,
        long sliceId
    ) {
        long cursor = typesOffset + 8 + globalCount * 16;
        long record = 0;
        while (record < recordCount) limit INTERPRETER_AGGREGATE_COUNT {
            long fieldCount = readUnsigned(artifact, cursor + 8, 4);
            cursor += 12 + fieldCount * 8;
            record += 1;
        }
        cursor += 4 + arrayCount * 12 + 4;
        if (sliceId < sliceCount) {
            long descriptor = cursor + sliceId * 8;
            if (readUnsigned(artifact, descriptor, 4) == sliceId) {
                return descriptor;
            }
        }
        return -1;
    }

    private long sliceOperandsValid(
        byteview artifact,
        long cursor,
        long opcode,
        long typesOffset,
        long globalCount,
        long recordCount,
        long arrayCount,
        long sliceCount,
        long localCount,
        long activeTypes
    ) {
        long destination = readUnsigned(artifact, cursor + 8, 8);
        if (opcode == OPCODE_SLICE_NEW) {
            long typeId = readUnsigned(artifact, cursor + 16, 8);
            long sourceArray = readUnsigned(artifact, cursor + 24, 8);
            long startLocal = readUnsigned(artifact, cursor + 32, 8);
            long lengthLocal = readUnsigned(artifact, cursor + 40, 8);
            if (destination < localCount) {
                if (sourceArray < localCount) {
                    if (startLocal < localCount) {
                        if (lengthLocal < localCount) {
                            long sourceType = localType(artifact, activeTypes, sourceArray);
                            if (isArrayType(sourceType)) {
                                long arrayInfo = arrayDescriptor(
                                    artifact,
                                    typesOffset,
                                    globalCount,
                                    recordCount,
                                    arrayCount,
                                    arrayTypeId(sourceType)
                                );
                                long sliceInfo = sliceDescriptor(
                                    artifact,
                                    typesOffset,
                                    globalCount,
                                    recordCount,
                                    arrayCount,
                                    sliceCount,
                                    typeId
                                );
                                if (0 < arrayInfo) {
                                    if (0 < sliceInfo) {
                                        if (
                                            localType(artifact, activeTypes, destination)
                                                == TYPE_SLICE + typeId
                                        ) {
                                            if (
                                                localType(artifact, activeTypes, startLocal)
                                                    == TYPE_SIGNED
                                            ) {
                                                if (
                                                    localType(artifact, activeTypes, lengthLocal)
                                                        == TYPE_SIGNED
                                                ) {
                                                    if (
                                                        readUnsigned(artifact, arrayInfo + 4, 4)
                                                            == readUnsigned(
                                                            artifact,
                                                            sliceInfo + 4,
                                                            4
                                                        )
                                                    ) {
                                                        return 1;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return 0;
        }
        long sourceSlice = readUnsigned(artifact, cursor + 16, 8);
        long indexLocal = readUnsigned(artifact, cursor + 24, 8);
        if (destination < localCount) {
            if (sourceSlice < localCount) {
                if (indexLocal < localCount) {
                    long getSourceType = localType(artifact, activeTypes, sourceSlice);
                    if (isSliceType(getSourceType)) {
                        long getInfo = sliceDescriptor(
                            artifact,
                            typesOffset,
                            globalCount,
                            recordCount,
                            arrayCount,
                            sliceCount,
                            sliceTypeId(getSourceType)
                        );
                        if (0 < getInfo) {
                            if (localType(artifact, activeTypes, indexLocal) == TYPE_SIGNED) {
                                if (
                                    localType(artifact, activeTypes, destination) == readUnsigned(
                                        artifact,
                                        getInfo + 4,
                                        4
                                    )
                                ) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
        }
        return 0;
    }

    /// Checks aggregate instruction operands against verified type metadata.
    public long aggregateOperandsValid(
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
        long localCount,
        long activeTypes
    ) {
        if (opcode == OPCODE_RECORD_NEW) {
            return recordOperandsValid(
                artifact,
                cursor,
                opcode,
                typesOffset,
                globalCount,
                recordCount,
                localCount,
                activeTypes
            );
        }
        if (opcode == OPCODE_RECORD_GET) {
            return recordOperandsValid(
                artifact,
                cursor,
                opcode,
                typesOffset,
                globalCount,
                recordCount,
                localCount,
                activeTypes
            );
        }
        if (opcode == OPCODE_VARIANT_NEW) {
            return variantOperandsValid(
                artifact,
                cursor,
                opcode,
                variantsOffset,
                variantCount,
                localCount,
                activeTypes
            );
        }
        if (opcode == OPCODE_VARIANT_TAG_EQ) {
            return variantOperandsValid(
                artifact,
                cursor,
                opcode,
                variantsOffset,
                variantCount,
                localCount,
                activeTypes
            );
        }
        if (opcode == OPCODE_VARIANT_GET) {
            return variantOperandsValid(
                artifact,
                cursor,
                opcode,
                variantsOffset,
                variantCount,
                localCount,
                activeTypes
            );
        }
        if (opcode == OPCODE_ARRAY_NEW) {
            return arrayOperandsValid(
                artifact,
                cursor,
                opcode,
                typesOffset,
                globalCount,
                recordCount,
                arrayCount,
                localCount,
                activeTypes
            );
        }
        if (opcode == OPCODE_ARRAY_GET) {
            return arrayOperandsValid(
                artifact,
                cursor,
                opcode,
                typesOffset,
                globalCount,
                recordCount,
                arrayCount,
                localCount,
                activeTypes
            );
        }
        if (opcode == OPCODE_SLICE_NEW) {
            return sliceOperandsValid(
                artifact,
                cursor,
                opcode,
                typesOffset,
                globalCount,
                recordCount,
                arrayCount,
                sliceCount,
                localCount,
                activeTypes
            );
        }
        if (opcode == OPCODE_SLICE_GET) {
            return sliceOperandsValid(
                artifact,
                cursor,
                opcode,
                typesOffset,
                globalCount,
                recordCount,
                arrayCount,
                sliceCount,
                localCount,
                activeTypes
            );
        }
        return -1;
    }
}
