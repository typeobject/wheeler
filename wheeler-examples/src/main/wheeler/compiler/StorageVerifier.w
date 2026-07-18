/// Verifies bounded owned-region and word-buffer instruction operands.
module examples.compiler.storage_verifier;
import examples.compiler.opcodes;
import examples.compiler.type_codes;
import examples.packages.binary;
classical class StorageVerifier {
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

    private boolean ownedType(long typeCode) {
        if (typeCode == TYPE_REGION) {
            return true;
        }
        if (typeCode == TYPE_WORDS) {
            return true;
        }
        return typeCode == TYPE_BYTES;
    }

    private boolean allocationOpcode(long opcode) {
        if (opcode == OPCODE_WORDS_ALLOC) {
            return true;
        }
        return opcode == OPCODE_BYTES_ALLOC;
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
        if (OPCODE_UTF8_WIDTH < opcode) {
            return -1;
        }
        long first = readUnsigned(artifact, cursor + 8, 8);
        if (opcode == OPCODE_OWNED_MOVE) {
            long source = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (source < localCount) {
                    long typeCode = localType(
                        artifact, activeTypes, first);
                    if (ownedType(typeCode)) {
                        if (typeCode == localType(
                                artifact, activeTypes, source)) {
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
                if (localHasType(
                        artifact, activeTypes, first, TYPE_REGION)) {
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
            if (first < localCount) {
                if (region < localCount) {
                    if (length < localCount) {
                        if (localHasType(
                                artifact,
                                activeTypes,
                                first,
                                allocationType)) {
                            if (localHasType(
                                    artifact,
                                    activeTypes,
                                    region,
                                    TYPE_REGION)) {
                                if (localHasType(
                                        artifact,
                                        activeTypes,
                                        length,
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
                        if (localHasType(
                                artifact, activeTypes, first, TYPE_SIGNED)) {
                            if (localHasType(
                                    artifact,
                                    activeTypes,
                                    getBuffer,
                                    getExpectedType)) {
                                if (localHasType(
                                        artifact,
                                        activeTypes,
                                        getIndex,
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
                        if (localHasType(
                                artifact,
                                activeTypes,
                                first,
                                setExpectedType)) {
                            if (localHasType(
                                    artifact,
                                    activeTypes,
                                    setIndex,
                                    TYPE_SIGNED)) {
                                if (localHasType(
                                        artifact,
                                        activeTypes,
                                        setValue,
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
        if (opcode == OPCODE_BUFFER_DROP) {
            if (first < localCount) {
                long dropType = localType(artifact, activeTypes, first);
                if (dropType == TYPE_WORDS) {
                    return 1;
                }
                if (dropType == TYPE_BYTES) {
                    return 1;
                }
            }
            return 0;
        }
        if (opcode == OPCODE_BUFFER_LENGTH) {
            long lengthBuffer = readUnsigned(artifact, cursor + 16, 8);
            if (first < localCount) {
                if (lengthBuffer < localCount) {
                    if (localHasType(
                            artifact, activeTypes, first, TYPE_SIGNED)) {
                        long lengthType = localType(
                            artifact, activeTypes, lengthBuffer);
                        if (lengthType == TYPE_WORDS) {
                            return 1;
                        }
                        if (lengthType == TYPE_BYTES) {
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
                    if (localHasType(
                            artifact, activeTypes, first, TYPE_BOOLEAN)) {
                        if (localHasType(
                                artifact,
                                activeTypes,
                                utf8Buffer,
                                TYPE_BYTES)) {
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
                    if (localHasType(
                            artifact, activeTypes, first, TYPE_SIGNED)) {
                        if (localHasType(
                                artifact,
                                activeTypes,
                                countBuffer,
                                TYPE_BYTES)) {
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
                        if (localHasType(
                                artifact, activeTypes, first, TYPE_SIGNED)) {
                            if (localHasType(
                                    artifact,
                                    activeTypes,
                                    scalarBuffer,
                                    TYPE_BYTES)) {
                                if (localHasType(
                                        artifact,
                                        activeTypes,
                                        scalarIndex,
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
        if (opcode == OPCODE_UTF8_WIDTH) {
            long widthBuffer = readUnsigned(artifact, cursor + 16, 8);
            long widthIndex = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (widthBuffer < localCount) {
                    if (widthIndex < localCount) {
                        if (localHasType(
                                artifact, activeTypes, first, TYPE_SIGNED)) {
                            if (localHasType(
                                    artifact,
                                    activeTypes,
                                    widthBuffer,
                                    TYPE_BYTES)) {
                                if (localHasType(
                                        artifact,
                                        activeTypes,
                                        widthIndex,
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
        if (opcode == OPCODE_REGION_DROP) {
            if (first < localCount) {
                if (localHasType(
                        artifact, activeTypes, first, TYPE_REGION)) {
                    return 1;
                }
            }
            return 0;
        }
        return -1;
    }
}
