// One bounded region owns one mutable word buffer and is dropped explicitly.
classical class RegionStorage {
    state long first = 0;

    entry void main() {
        region arena = new region(32, 2);
        long length = 4;
        words data = allocate(arena, length);
        set(data, 0, 7);
        set(data, 1, 11);
        first = data[0];
        assert first == 7;
        drop(data);
        drop(arena);
    }
}
