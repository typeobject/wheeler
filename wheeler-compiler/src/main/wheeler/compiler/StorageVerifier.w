//! Verifies bounded owned-region and word-buffer instruction operands.
module wheeler.compiler.storage_verifier;
import wheeler.compiler.opcodes;
import wheeler.compiler.type_codes;
import wheeler.packages.binary;
classical class StorageVerifier {
    private long localType(byteview artifact, long activeTypes, long local) {
        return readUnsigned(artifact, activeTypes + local * 4, 4);
    }

    private boolean localHasType(byteview artifact, long activeTypes, long local, long expected) {
        return localType(artifact, activeTypes, local) == expected;
    }

    private boolean ownedType(long typeCode) {
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
        return typeCode == TYPE_UTF8;
    }

    private boolean ownerOrBorrow(long typeCode, long ownerType) {
        if (typeCode == ownerType) {
            return true;
        }
        if (ownerType == TYPE_REGION) {
            return typeCode == TYPE_REGION_BORROW;
        }
        if (ownerType == TYPE_WORDS) {
            return typeCode == TYPE_WORDS_BORROW;
        }
        if (ownerType == TYPE_BYTES) {
            return typeCode == TYPE_BYTES_BORROW;
        }
        if (ownerType == TYPE_LONG_MAP) {
            return typeCode == TYPE_LONG_MAP_BORROW;
        }
        return false;
    }

    private boolean utf8SequenceType(long typeCode) {
        if (typeCode == TYPE_BYTES) {
            return true;
        }
        if (typeCode == TYPE_BYTES_BORROW) {
            return true;
        }
        if (typeCode == TYPE_UTF8) {
            return true;
        }
        return typeCode == TYPE_UTF8_BORROW;
    }

    private boolean allocationOpcode(long opcode) {
        if (opcode == OPCODE_WORDS_ALLOC) {
            return true;
        }
        if (opcode == OPCODE_BYTES_ALLOC) {
            return true;
        }
        return opcode == OPCODE_MAP_ALLOC;
    }

    private boolean getOpcode(long opcode) {
        if (opcode == OPCODE_WORDS_GET) {
            return true;
        }
        return opcode == OPCODE_BYTES_GET;
    }

    private boolean setOpcode(long opcode) {
        if (opcode == OPCODE_WORDS_SET) {
            return true;
        }
        return opcode == OPCODE_BYTES_SET;
    }

    /// Checks owned-storage instruction operands against live typed locals.
    public long storageOperandsValid(
        byteview artifact,
        long cursor,
        long opcode,
        long localCount,
        long activeTypes
    ) {
        if (opcode < OPCODE_OWNED_MOVE) {
            return -1;
        }
        if (OPCODE_REGION_BORROW < opcode) {
            return -1;
        }
        long first = readUnsigned(artifact, cursor + 8, 8);
        if (opcode == OPCODE_OWNED_MOVE) {
            long source = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (source < localCount) {
                    long typeCode = localType(artifact, activeTypes, first);
                    if (ownedType(typeCode)) {
                        if (typeCode == localType(artifact, activeTypes, source)) {
                            return 1;
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_REGION_NEW) {
            long maxBytes = readUnsigned(artifact, cursor + 16, 8);
            long maxObjects = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (localHasType(artifact, activeTypes, first, TYPE_REGION)) {
                    if (maxBytes < INTERPRETER_STORAGE_WORDS * 8 + 1) {
                        if (maxObjects < INTERPRETER_STORAGE_COUNT + 1) {
                            if (0 < maxBytes) {
                                if (0 < maxObjects) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
            return 0;
        }
        if (allocationOpcode(opcode)) {
            long region = readUnsigned(artifact, cursor + 16, 8);
            long length = readUnsigned(artifact, cursor + 24, 8);
            long allocationType = TYPE_WORDS;
            if (opcode == OPCODE_BYTES_ALLOC) {
                allocationType = TYPE_BYTES;
            }
            if (opcode == OPCODE_MAP_ALLOC) {
                allocationType = TYPE_LONG_MAP;
            }
            if (first < localCount) {
                if (region < localCount) {
                    if (length < localCount) {
                        if (localHasType(artifact, activeTypes, first, allocationType)) {
                            if (
                                ownerOrBorrow(
                                    localType(artifact, activeTypes, region),
                                    TYPE_REGION
                                )
                            ) {
                                if (localHasType(artifact, activeTypes, length, TYPE_SIGNED)) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
            return 0;
        }
        if (getOpcode(opcode)) {
            long getBuffer = readUnsigned(artifact, cursor + 16, 8);
            long getIndex = readUnsigned(artifact, cursor + 24, 8);
            long getExpectedType = TYPE_WORDS;
            if (opcode == OPCODE_BYTES_GET) {
                getExpectedType = TYPE_BYTES;
            }
            if (first < localCount) {
                if (getBuffer < localCount) {
                    if (getIndex < localCount) {
                        if (localHasType(artifact, activeTypes, first, TYPE_SIGNED)) {
                            if (
                                ownerOrBorrow(
                                    localType(artifact, activeTypes, getBuffer),
                                    getExpectedType
                                )
                            ) {
                                if (localHasType(artifact, activeTypes, getIndex, TYPE_SIGNED)) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
            return 0;
        }
        if (setOpcode(opcode)) {
            long setIndex = readUnsigned(artifact, cursor + 16, 8);
            long setValue = readUnsigned(artifact, cursor + 24, 8);
            long setExpectedType = TYPE_WORDS;
            if (opcode == OPCODE_BYTES_SET) {
                setExpectedType = TYPE_BYTES;
            }
            if (first < localCount) {
                if (setIndex < localCount) {
                    if (setValue < localCount) {
                        if (
                            ownerOrBorrow(
                                localType(artifact, activeTypes, first),
                                setExpectedType
                            )
                        ) {
                            if (localHasType(artifact, activeTypes, setIndex, TYPE_SIGNED)) {
                                if (localHasType(artifact, activeTypes, setValue, TYPE_SIGNED)) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_BUFFER_DROP) {
            if (first < localCount) {
                long dropType = localType(artifact, activeTypes, first);
                if (dropType == TYPE_WORDS) {
                    return 1;
                }
                if (dropType == TYPE_BYTES) {
                    return 1;
                }
                if (dropType == TYPE_LONG_MAP) {
                    return 1;
                }
                if (dropType == TYPE_UTF8) {
                    return 1;
                }
            }
            return 0;
        }
        if (opcode == OPCODE_BUFFER_LENGTH) {
            long lengthBuffer = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (lengthBuffer < localCount) {
                    if (localHasType(artifact, activeTypes, first, TYPE_SIGNED)) {
                        long lengthType = localType(artifact, activeTypes, lengthBuffer);
                        if (lengthType == TYPE_WORDS) {
                            return 1;
                        }
                        if (lengthType == TYPE_BYTES) {
                            return 1;
                        }
                        if (lengthType == TYPE_WORDS_BORROW) {
                            return 1;
                        }
                        if (lengthType == TYPE_BYTES_BORROW) {
                            return 1;
                        }
                        if (lengthType == TYPE_UTF8) {
                            return 1;
                        }
                        if (lengthType == TYPE_UTF8_BORROW) {
                            return 1;
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_UTF8_VALID) {
            long utf8Buffer = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (utf8Buffer < localCount) {
                    if (localHasType(artifact, activeTypes, first, TYPE_BOOLEAN)) {
                        if (utf8SequenceType(localType(artifact, activeTypes, utf8Buffer))) {
                            return 1;
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_UTF8_COUNT) {
            long countBuffer = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (countBuffer < localCount) {
                    if (localHasType(artifact, activeTypes, first, TYPE_SIGNED)) {
                        if (utf8SequenceType(localType(artifact, activeTypes, countBuffer))) {
                            return 1;
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_UTF8_SCALAR) {
            long scalarBuffer = readUnsigned(artifact, cursor + 16, 8);
            long scalarIndex = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (scalarBuffer < localCount) {
                    if (scalarIndex < localCount) {
                        if (localHasType(artifact, activeTypes, first, TYPE_SIGNED)) {
                            if (
                                utf8SequenceType(localType(artifact, activeTypes, scalarBuffer))
                            ) {
                                if (
                                    localHasType(artifact, activeTypes, scalarIndex, TYPE_SIGNED)
                                ) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_UTF8_WIDTH) {
            long widthBuffer = readUnsigned(artifact, cursor + 16, 8);
            long widthIndex = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (widthBuffer < localCount) {
                    if (widthIndex < localCount) {
                        if (localHasType(artifact, activeTypes, first, TYPE_SIGNED)) {
                            if (utf8SequenceType(localType(artifact, activeTypes, widthBuffer))) {
                                if (
                                    localHasType(artifact, activeTypes, widthIndex, TYPE_SIGNED)
                                ) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_MAP_PUT) {
            long mapKey = readUnsigned(artifact, cursor + 16, 8);
            long mapValue = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (mapKey < localCount) {
                    if (mapValue < localCount) {
                        if (
                            ownerOrBorrow(
                                localType(artifact, activeTypes, first),
                                TYPE_LONG_MAP
                            )
                        ) {
                            if (localHasType(artifact, activeTypes, mapKey, TYPE_SIGNED)) {
                                if (localHasType(artifact, activeTypes, mapValue, TYPE_SIGNED)) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_MAP_GET) {
            long getMap = readUnsigned(artifact, cursor + 16, 8);
            long getMapKey = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (getMap < localCount) {
                    if (getMapKey < localCount) {
                        if (localHasType(artifact, activeTypes, first, TYPE_SIGNED)) {
                            if (
                                ownerOrBorrow(
                                    localType(artifact, activeTypes, getMap),
                                    TYPE_LONG_MAP
                                )
                            ) {
                                if (localHasType(artifact, activeTypes, getMapKey, TYPE_SIGNED)) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_MAP_HAS) {
            long hasMap = readUnsigned(artifact, cursor + 16, 8);
            long hasMapKey = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (hasMap < localCount) {
                    if (hasMapKey < localCount) {
                        if (localHasType(artifact, activeTypes, first, TYPE_BOOLEAN)) {
                            if (
                                ownerOrBorrow(
                                    localType(artifact, activeTypes, hasMap),
                                    TYPE_LONG_MAP
                                )
                            ) {
                                if (localHasType(artifact, activeTypes, hasMapKey, TYPE_SIGNED)) {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_UTF8_FREEZE) {
            long freezeSource = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (freezeSource < localCount) {
                    if (localHasType(artifact, activeTypes, first, TYPE_UTF8)) {
                        if (localHasType(artifact, activeTypes, freezeSource, TYPE_BYTES)) {
                            return 1;
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_UTF8_BORROW) {
            long borrowSource = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (borrowSource < localCount) {
                    if (localHasType(artifact, activeTypes, first, TYPE_UTF8_BORROW)) {
                        long borrowSourceType = localType(artifact, activeTypes, borrowSource);
                        if (borrowSourceType == TYPE_UTF8) {
                            return 1;
                        }
                        if (borrowSourceType == TYPE_UTF8_BORROW) {
                            return 1;
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_MAP_BORROW) {
            long mapBorrowSource = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (mapBorrowSource < localCount) {
                    if (localHasType(artifact, activeTypes, first, TYPE_LONG_MAP_BORROW)) {
                        if (
                            ownerOrBorrow(
                                localType(artifact, activeTypes, mapBorrowSource),
                                TYPE_LONG_MAP
                            )
                        ) {
                            return 1;
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_BUFFER_BORROW) {
            long bufferBorrowSource = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (bufferBorrowSource < localCount) {
                    long bufferBorrowDestinationType = localType(artifact, activeTypes, first);
                    long bufferBorrowSourceType = localType(
                        artifact,
                        activeTypes,
                        bufferBorrowSource
                    );
                    if (bufferBorrowDestinationType == TYPE_WORDS_BORROW) {
                        if (ownerOrBorrow(bufferBorrowSourceType, TYPE_WORDS)) {
                            return 1;
                        }
                    }
                    if (bufferBorrowDestinationType == TYPE_BYTES_BORROW) {
                        if (ownerOrBorrow(bufferBorrowSourceType, TYPE_BYTES)) {
                            return 1;
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_REGION_BORROW) {
            long regionBorrowSource = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (regionBorrowSource < localCount) {
                    if (localHasType(artifact, activeTypes, first, TYPE_REGION_BORROW)) {
                        if (
                            ownerOrBorrow(
                                localType(artifact, activeTypes, regionBorrowSource),
                                TYPE_REGION
                            )
                        ) {
                            return 1;
                        }
                    }
                }
            }
            return 0;
        }
        if (opcode == OPCODE_REGION_DROP) {
            if (first < localCount) {
                if (localHasType(artifact, activeTypes, first, TYPE_REGION)) {
                    return 1;
                }
            }
            return 0;
        }
        return -1;
    }
}
