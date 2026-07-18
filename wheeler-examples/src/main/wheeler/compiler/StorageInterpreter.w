/// Executes bounded owned-region and word-buffer operations.
module examples.compiler.storage_interpreter;
import examples.compiler.opcodes;
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

    public StorageAllocation allocateWords(
        words kinds,
        words starts,
        words lengths,
        words owners,
        words live,
        words regionUsedBytes,
        words regionLiveObjects,
        long storageCount,
        long dataCursor,
        long regionHandle,
        long length
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
        long bytes = length * 8;
        if (bytes < lengths[region] - regionUsedBytes[region] + 1) {
        } else {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        if (regionLiveObjects[region] < owners[region]) {
        } else {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        if (dataCursor + length < INTERPRETER_STORAGE_WORDS + 1) {
        } else {
            return new StorageAllocation(0, storageCount, dataCursor);
        }
        set(kinds, storageCount, 2);
        set(starts, storageCount, dataCursor);
        set(lengths, storageCount, length);
        set(owners, storageCount, regionHandle);
        set(live, storageCount, 1);
        set(regionUsedBytes, region, regionUsedBytes[region] + bytes);
        set(regionLiveObjects, region, regionLiveObjects[region] + 1);
        return new StorageAllocation(
            storageCount + 1,
            storageCount + 1,
            dataCursor + length);
    }

    public boolean wordAccessValid(
        words kinds,
        words lengths,
        words live,
        long handle,
        long index
    ) {
        if (handle < 1) {
            return false;
        }
        long storage = handle - 1;
        if (kinds[storage] == 2) {
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

    public boolean dropWords(
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
            return false;
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

    public StorageStep executeStorageInstruction(
        byteview artifact,
        long cursor,
        long opcode,
        words locals,
        long depth,
        words kinds,
        words starts,
        words lengths,
        words owners,
        words live,
        words regionUsedBytes,
        words regionLiveObjects,
        words data,
        long storageCount,
        long dataCursor
    ) {
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
        if (opcode == OPCODE_WORDS_ALLOC) {
            long wordsDestination = readUnsigned(artifact, cursor + 8, 8);
            long wordsRegion = readUnsigned(artifact, cursor + 16, 8);
            long wordsLengthLocal = readUnsigned(artifact, cursor + 24, 8);
            StorageAllocation wordsAllocation = allocateWords(
                kinds,
                starts,
                lengths,
                owners,
                live,
                regionUsedBytes,
                regionLiveObjects,
                storageCount,
                dataCursor,
                locals[localIndex(depth, wordsRegion)],
                locals[localIndex(depth, wordsLengthLocal)]);
            if (wordsAllocation.handle < 1) {
                return new StorageStep.Error();
            }
            set(
                locals,
                localIndex(depth, wordsDestination),
                wordsAllocation.handle);
            return new StorageStep.Value(
                wordsAllocation.storageCount, wordsAllocation.dataCursor);
        }
        if (opcode == OPCODE_WORDS_GET) {
            long getDestination = readUnsigned(artifact, cursor + 8, 8);
            long getBuffer = readUnsigned(artifact, cursor + 16, 8);
            long getIndexLocal = readUnsigned(artifact, cursor + 24, 8);
            long getHandle = locals[localIndex(depth, getBuffer)];
            long getIndex = locals[localIndex(depth, getIndexLocal)];
            if (wordAccessValid(
                    kinds, lengths, live, getHandle, getIndex)) {
            } else {
                return new StorageStep.Error();
            }
            set(
                locals,
                localIndex(depth, getDestination),
                loadWord(starts, data, getHandle, getIndex));
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_WORDS_SET) {
            long setBuffer = readUnsigned(artifact, cursor + 8, 8);
            long setIndexLocal = readUnsigned(artifact, cursor + 16, 8);
            long setValueLocal = readUnsigned(artifact, cursor + 24, 8);
            long setHandle = locals[localIndex(depth, setBuffer)];
            long setIndex = locals[localIndex(depth, setIndexLocal)];
            if (wordAccessValid(
                    kinds, lengths, live, setHandle, setIndex)) {
            } else {
                return new StorageStep.Error();
            }
            storeWord(
                starts,
                data,
                setHandle,
                setIndex,
                locals[localIndex(depth, setValueLocal)]);
            return new StorageStep.Value(storageCount, dataCursor);
        }
        if (opcode == OPCODE_BUFFER_DROP) {
            long bufferDropLocal = readUnsigned(
                artifact, cursor + 8, 8);
            if (dropWords(
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
