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
        return typeCode == TYPE_WORDS;
    }

    public long storageOperandsValid(
        byteview artifact,
        long cursor,
        long opcode,
        long localCount,
        long activeTypes
    ) {
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
        if (opcode == OPCODE_WORDS_ALLOC) {
            long region = readUnsigned(artifact, cursor + 16, 8);
            long length = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (region < localCount) {
                    if (length < localCount) {
                        if (localHasType(
                                artifact, activeTypes, first, TYPE_WORDS)) {
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
        if (opcode == OPCODE_WORDS_GET) {
            long getBuffer = readUnsigned(artifact, cursor + 16, 8);
            long getIndex = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (getBuffer < localCount) {
                    if (getIndex < localCount) {
                        if (localHasType(
                                artifact, activeTypes, first, TYPE_SIGNED)) {
                            if (localHasType(
                                    artifact,
                                    activeTypes,
                                    getBuffer,
                                    TYPE_WORDS)) {
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
        if (opcode == OPCODE_WORDS_SET) {
            long setIndex = readUnsigned(artifact, cursor + 16, 8);
            long setValue = readUnsigned(artifact, cursor + 24, 8);
            if (first < localCount) {
                if (setIndex < localCount) {
                    if (setValue < localCount) {
                        if (localHasType(
                                artifact, activeTypes, first, TYPE_WORDS)) {
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
                if (localHasType(
                        artifact, activeTypes, first, TYPE_WORDS)) {
                    return 1;
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
