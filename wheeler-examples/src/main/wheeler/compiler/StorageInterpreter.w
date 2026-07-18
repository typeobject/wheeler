/// Executes bounded owned-region and word-buffer operations.
module examples.compiler.storage_interpreter;
import examples.compiler.map_interpreter;
import examples.compiler.opcodes;
import examples.compiler.utf8_interpreter;
import examples.packages.binary;
classical class StorageInterpreter {
    public record StorageAllocation(
        long handle,
        long storageCount,
        long dataCursor
    ) {}

    public variant StorageStep {
        case Skipped();
        case Value(long storageCount, long dataCursor);
        case Error();
    }

    private long localIndex(long depth, long local) {
        return depth * INTERPRETER_LOCAL_WIDTH + local;
    }

    public StorageAllocation newRegion(
        words kinds,
        words lengths,
        words owners,
        words live,
        long storageCount,
        long maxBytes,
        long maxObjects,
        long dataCursor
    ) {
        if (storageCount < INTERPRETER_STORAGE_COUNT) {
        } else {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        set(kinds, storageCount, 1);
        set(lengths, storageCount, maxBytes);
        set(owners, storageCount, maxObjects);
        set(live, storageCount, 1);
        return new StorageAllocation(
            storageCount + 1, storageCount + 1, dataCursor);
    }

    public StorageAllocation allocateBuffer(
        words kinds,
        words starts,
        words lengths,
        words sizes,
        words owners,
        words live,
        words regionUsedBytes,
        words regionLiveObjects,
        long storageCount,
        long dataCursor,
        long regionHandle,
        long length,
        long kind,
        long bytesPerElement,
        long cellsPerElement
    ) {
        if (storageCount < INTERPRETER_STORAGE_COUNT) {
        } else {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        if (regionHandle < 1) {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        long region = regionHandle - 1;
        if (kinds[region] == 1) {
        } else {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        if (live[region] == 1) {
        } else {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        if (0 < length) {
        } else {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        if (length < INTERPRETER_STORAGE_WORDS + 1) {
        } else {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        long bytes = length * bytesPerElement;
        if (bytes < lengths[region] - regionUsedBytes[region] + 1) {
        } else {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        if (regionLiveObjects[region] < owners[region]) {
        } else {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        long dataCells = length * cellsPerElement;
        if (dataCursor + dataCells < INTERPRETER_STORAGE_WORDS + 1) {
        } else {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        set(kinds, storageCount, kind);
        set(starts, storageCount, dataCursor);
        set(lengths, storageCount, length);
        set(sizes, storageCount, 0);
        set(owners, storageCount, regionHandle);
        set(live, storageCount, 1);
        set(regionUsedBytes, region, regionUsedBytes[region] + bytes);
        set(regionLiveObjects, region, regionLiveObjects[region] + 1);
        return new StorageAllocation(
            storageCount + 1,
            storageCount + 1,
            dataCursor + dataCells);
    }

    public boolean bufferAccessValid(
        words kinds,
        words lengths,
        words live,
        long handle,
        long index,
        long expectedKind
    ) {
        if (handle < 1) {
            return false;
        }
        long storage = handle - 1;
        if (kinds[storage] == expectedKind) {
        } else {
            return false;
        }
        if (live[storage] == 1) {
        } else {
            return false;
        }
        if (index < 0) {
            return false;
        }
        return index < lengths[storage];
    }

    public long loadWord(
        words starts,
        words data,
        long handle,
        long index
    ) {
        return data[starts[handle - 1] + index];
    }

    public void storeWord(
        words starts,
        words data,
        long handle,
        long index,
        long value
    ) {
        set(data, starts[handle - 1] + index, value);
    }

    public boolean dropBuffer(
        words kinds,
        words owners,
        words live,
        words regionLiveObjects,
        long handle
    ) {
        if (handle < 1) {
            return false;
        }
        long storage = handle - 1;
        if (kinds[storage] == 2) {
        } else {
            if (kinds[storage] == 3) {
            } else {
                if (kinds[storage] == 4) {
                } else {
                    return false;
                }
            }
        }
        if (live[storage] == 1) {
        } else {
            return false;
        }
        long region = owners[storage] - 1;
        set(live, storage, 0);
        set(
            regionLiveObjects,
            region,
            regionLiveObjects[region] - 1);
        return true;
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

    public StorageStep executeStorageInstruction(
        byteview artifact,
        long cursor,
        long opcode,
        words locals,
        long depth,
        words kinds,
        words starts,
        words lengths,
        words sizes,
        words owners,
        words live,
        words regionUsedBytes,
        words regionLiveObjects,
        words data,
        long storageCount,
        long dataCursor
    ) {
        if (opcode < OPCODE_OWNED_MOVE) {
            return new StorageStep.Skipped();
        }
        if (OPCODE_MAP_HAS < opcode) {
            return new StorageStep.Skipped();
        }
        if (opcode == OPCODE_OWNED_MOVE) {
            long moveDestination = readUnsigned(artifact, cursor + 8, 8);
            long moveSource = readUnsigned(artifact, cursor + 16, 8);
            set(
                locals,
                localIndex(depth, moveDestination),
                locals[localIndex(depth, moveSource)]);
            set(locals, localIndex(depth, moveSource), 0);
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_REGION_NEW) {
            long regionDestination = readUnsigned(artifact, cursor + 8, 8);
            long maxBytes = readUnsigned(artifact, cursor + 16, 8);
            long maxObjects = readUnsigned(artifact, cursor + 24, 8);
            StorageAllocation regionAllocation = newRegion(
                kinds,
                lengths,
                owners,
                live,
                storageCount,
                maxBytes,
                maxObjects,
                dataCursor);
            if (regionAllocation.handle < 1) {
                return new StorageStep.Error();
            }
            set(
                locals,
                localIndex(depth, regionDestination),
                regionAllocation.handle);
            return new StorageStep.Value(
                regionAllocation.storageCount, dataCursor);
        }
        if (allocationOpcode(opcode)) {
            long allocationDestination = readUnsigned(
                artifact, cursor + 8, 8);
            long allocationRegion = readUnsigned(
                artifact, cursor + 16, 8);
            long allocationLengthLocal = readUnsigned(
                artifact, cursor + 24, 8);
            long allocationKind = 2;
            long allocationWidth = 8;
            long allocationCells = 1;
            if (opcode == OPCODE_BYTES_ALLOC) {
                allocationKind = 3;
                allocationWidth = 1;
            }
            if (opcode == OPCODE_MAP_ALLOC) {
                allocationKind = 4;
                allocationWidth = 24;
                allocationCells = 2;
            }
            StorageAllocation bufferAllocation = allocateBuffer(
                kinds,
                starts,
                lengths,
                sizes,
                owners,
                live,
                regionUsedBytes,
                regionLiveObjects,
                storageCount,
                dataCursor,
                locals[localIndex(depth, allocationRegion)],
                locals[localIndex(depth, allocationLengthLocal)],
                allocationKind,
                allocationWidth,
                allocationCells);
            if (bufferAllocation.handle < 1) {
                return new StorageStep.Error();
            }
            set(
                locals,
                localIndex(depth, allocationDestination),
                bufferAllocation.handle);
            return new StorageStep.Value(
                bufferAllocation.storageCount,
                bufferAllocation.dataCursor);
        }
        if (getOpcode(opcode)) {
            long getDestination = readUnsigned(artifact, cursor + 8, 8);
            long getBuffer = readUnsigned(artifact, cursor + 16, 8);
            long getIndexLocal = readUnsigned(artifact, cursor + 24, 8);
            long getHandle = locals[localIndex(depth, getBuffer)];
            long getIndex = locals[localIndex(depth, getIndexLocal)];
            long getKind = 2;
            if (opcode == OPCODE_BYTES_GET) {
                getKind = 3;
            }
            if (bufferAccessValid(
                    kinds,
                    lengths,
                    live,
                    getHandle,
                    getIndex,
                    getKind)) {
            } else {
                return new StorageStep.Error();
            }
            set(
                locals,
                localIndex(depth, getDestination),
                loadWord(starts, data, getHandle, getIndex));
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (setOpcode(opcode)) {
            long setBuffer = readUnsigned(artifact, cursor + 8, 8);
            long setIndexLocal = readUnsigned(artifact, cursor + 16, 8);
            long setValueLocal = readUnsigned(artifact, cursor + 24, 8);
            long setHandle = locals[localIndex(depth, setBuffer)];
            long setIndex = locals[localIndex(depth, setIndexLocal)];
            long setValue = locals[localIndex(depth, setValueLocal)];
            long setKind = 2;
            if (opcode == OPCODE_BYTES_SET) {
                setKind = 3;
                if (setValue < 0) {
                    return new StorageStep.Error();
                }
                if (255 < setValue) {
                    return new StorageStep.Error();
                }
            }
            if (bufferAccessValid(
                    kinds,
                    lengths,
                    live,
                    setHandle,
                    setIndex,
                    setKind)) {
            } else {
                return new StorageStep.Error();
            }
            storeWord(
                starts,
                data,
                setHandle,
                setIndex,
                setValue);
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_BUFFER_DROP) {
            long bufferDropLocal = readUnsigned(
                artifact, cursor + 8, 8);
            if (dropBuffer(
                    kinds,
                    owners,
                    live,
                    regionLiveObjects,
                    locals[localIndex(depth, bufferDropLocal)])) {
            } else {
                return new StorageStep.Error();
            }
            set(locals, localIndex(depth, bufferDropLocal), 0);
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_UTF8_VALID) {
            long validDestination = readUnsigned(
                artifact, cursor + 8, 8);
            long validBuffer = readUnsigned(artifact, cursor + 16, 8);
            long validHandle = locals[localIndex(depth, validBuffer)];
            if (bufferAccessValid(
                    kinds, lengths, live, validHandle, 0, 3)) {
            } else {
                return new StorageStep.Error();
            }
            long validResult = 0;
            if (0 < utf8ScalarCount(
                    starts, lengths, data, validHandle)) {
                validResult = 1;
            }
            set(
                locals,
                localIndex(depth, validDestination),
                validResult);
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_UTF8_COUNT) {
            long countDestination = readUnsigned(
                artifact, cursor + 8, 8);
            long countBuffer = readUnsigned(artifact, cursor + 16, 8);
            long countHandle = locals[localIndex(depth, countBuffer)];
            if (bufferAccessValid(
                    kinds, lengths, live, countHandle, 0, 3)) {
            } else {
                return new StorageStep.Error();
            }
            long scalarCount = utf8ScalarCount(
                starts, lengths, data, countHandle);
            if (scalarCount < 0) {
                return new StorageStep.Error();
            }
            set(
                locals,
                localIndex(depth, countDestination),
                scalarCount);
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_UTF8_SCALAR) {
            long scalarDestination = readUnsigned(
                artifact, cursor + 8, 8);
            long scalarBuffer = readUnsigned(
                artifact, cursor + 16, 8);
            long scalarIndexLocal = readUnsigned(
                artifact, cursor + 24, 8);
            long scalarHandle = locals[localIndex(depth, scalarBuffer)];
            long scalarIndex = locals[localIndex(
                depth, scalarIndexLocal)];
            if (bufferAccessValid(
                    kinds,
                    lengths,
                    live,
                    scalarHandle,
                    scalarIndex,
                    3)) {
            } else {
                return new StorageStep.Error();
            }
            long scalarValue = utf8ScalarAt(
                starts, lengths, data, scalarHandle, scalarIndex);
            if (scalarValue < 0) {
                return new StorageStep.Error();
            }
            set(
                locals,
                localIndex(depth, scalarDestination),
                scalarValue);
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_UTF8_WIDTH) {
            long widthDestination = readUnsigned(
                artifact, cursor + 8, 8);
            long widthBuffer = readUnsigned(
                artifact, cursor + 16, 8);
            long widthIndexLocal = readUnsigned(
                artifact, cursor + 24, 8);
            long widthHandle = locals[localIndex(depth, widthBuffer)];
            long widthIndex = locals[localIndex(depth, widthIndexLocal)];
            if (bufferAccessValid(
                    kinds,
                    lengths,
                    live,
                    widthHandle,
                    widthIndex,
                    3)) {
            } else {
                return new StorageStep.Error();
            }
            long widthValue = utf8WidthAt(
                starts, lengths, data, widthHandle, widthIndex);
            if (widthValue < 1) {
                return new StorageStep.Error();
            }
            set(
                locals,
                localIndex(depth, widthDestination),
                widthValue);
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_BUFFER_LENGTH) {
            long lengthDestination = readUnsigned(
                artifact, cursor + 8, 8);
            long lengthBuffer = readUnsigned(
                artifact, cursor + 16, 8);
            long lengthHandle = locals[localIndex(depth, lengthBuffer)];
            if (lengthHandle < 1) {
                return new StorageStep.Error();
            }
            if (live[lengthHandle - 1] == 1) {
            } else {
                return new StorageStep.Error();
            }
            set(
                locals,
                localIndex(depth, lengthDestination),
                lengths[lengthHandle - 1]);
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_MAP_PUT) {
            long putMapLocal = readUnsigned(artifact, cursor + 8, 8);
            long putKeyLocal = readUnsigned(artifact, cursor + 16, 8);
            long putValueLocal = readUnsigned(artifact, cursor + 24, 8);
            long putHandle = locals[localIndex(depth, putMapLocal)];
            if (mapValid(kinds, live, putHandle)) {
            } else {
                return new StorageStep.Error();
            }
            if (putMap(
                    starts,
                    lengths,
                    sizes,
                    data,
                    putHandle,
                    locals[localIndex(depth, putKeyLocal)],
                    locals[localIndex(depth, putValueLocal)])) {
            } else {
                return new StorageStep.Error();
            }
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_MAP_GET) {
            long mapGetDestination = readUnsigned(
                artifact, cursor + 8, 8);
            long mapGetLocal = readUnsigned(artifact, cursor + 16, 8);
            long mapGetKeyLocal = readUnsigned(
                artifact, cursor + 24, 8);
            long mapGetHandle = locals[localIndex(depth, mapGetLocal)];
            if (mapValid(kinds, live, mapGetHandle)) {
            } else {
                return new StorageStep.Error();
            }
            long getEntry = mapEntry(
                starts,
                sizes,
                data,
                mapGetHandle,
                locals[localIndex(depth, mapGetKeyLocal)]);
            if (getEntry < 0) {
                return new StorageStep.Error();
            }
            set(
                locals,
                localIndex(depth, mapGetDestination),
                data[starts[mapGetHandle - 1] + getEntry * 2 + 1]);
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_MAP_HAS) {
            long mapHasDestination = readUnsigned(
                artifact, cursor + 8, 8);
            long mapHasLocal = readUnsigned(artifact, cursor + 16, 8);
            long mapHasKeyLocal = readUnsigned(
                artifact, cursor + 24, 8);
            long mapHasHandle = locals[localIndex(depth, mapHasLocal)];
            if (mapValid(kinds, live, mapHasHandle)) {
            } else {
                return new StorageStep.Error();
            }
            long hasValue = 0;
            if (0 < mapEntry(
                    starts,
                    sizes,
                    data,
                    mapHasHandle,
                    locals[localIndex(depth, mapHasKeyLocal)]) + 1) {
                hasValue = 1;
            }
            set(
                locals,
                localIndex(depth, mapHasDestination),
                hasValue);
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_REGION_DROP) {
            long regionDropLocal = readUnsigned(
                artifact, cursor + 8, 8);
            if (dropRegion(
                    kinds,
                    live,
                    regionLiveObjects,
                    locals[localIndex(depth, regionDropLocal)])) {
            } else {
                return new StorageStep.Error();
            }
            set(locals, localIndex(depth, regionDropLocal), 0);
            return new StorageStep.Value(storageCount, dataCursor);
        }
        return new StorageStep.Skipped();
    }

    public boolean dropRegion(
        words kinds,
        words live,
        words regionLiveObjects,
        long handle
    ) {
        if (handle < 1) {
            return false;
        }
        long region = handle - 1;
        if (kinds[region] == 1) {
        } else {
            return false;
        }
        if (live[region] == 1) {
        } else {
            return false;
        }
        if (regionLiveObjects[region] == 0) {
        } else {
            return false;
        }
        set(live, region, 0);
        return true;
    }
}
