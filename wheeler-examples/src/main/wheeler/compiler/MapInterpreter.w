/// Executes deterministic bounded signed-map operations.
module examples.compiler.map_interpreter;
import examples.compiler.opcodes;
classical class MapInterpreter {
    public boolean mapValid(
        words kinds,
        words live,
        long handle
    ) {
        if (handle < 1) {
            return false;
        }
        if (kinds[handle - 1] == 4) {
        } else {
            return false;
        }
        return live[handle - 1] == 1;
    }

    public long mapEntry(
        words starts,
        words sizes,
        words data,
        long handle,
        long key
    ) {
        long storage = handle - 1;
        long entry = 0;
        while (entry < sizes[storage])
            limit INTERPRETER_STORAGE_WORDS {
            if (data[starts[storage] + entry * 2] == key) {
                return entry;
            }
            entry += 1;
        }
        return -1;
    }

    public boolean putMap(
        words starts,
        words lengths,
        words sizes,
        words data,
        long handle,
        long key,
        long value
    ) {
        long storage = handle - 1;
        long entry = mapEntry(starts, sizes, data, handle, key);
        if (entry < 0) {
            if (sizes[storage] < lengths[storage]) {
                entry = sizes[storage];
                set(sizes, storage, sizes[storage] + 1);
                set(data, starts[storage] + entry * 2, key);
            } else {
                return false;
            }
        }
        set(data, starts[storage] + entry * 2 + 1, value);
        return true;
    }
}
