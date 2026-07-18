// One bounded region owns one mutable word buffer and is dropped explicitly.
classical class RegionStorage {
    state long first = 0;
    state long byteValue = 0;

    entry void main() {
        region arena = new region(40, 2);
        long length = 4;
        words data = allocate(arena, length);
        set(data, 0, 7);
        set(data, 1, 11);
        first = data[0];
        assert first == 7;

        bytes packet = allocateBytes(arena, 4);
        setByte(packet, 0, 255);
        byteValue = packet[0];
        assert byteValue == 255;

        drop(packet);
        drop(data);
        drop(arena);
    }
}
