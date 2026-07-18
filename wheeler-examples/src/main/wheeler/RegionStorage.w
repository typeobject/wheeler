// One bounded region owns one mutable word buffer and is dropped explicitly.
classical class RegionStorage {
    state long first = 0;
    state long byteValue = 0;
    state long utf8Scalars = 0;
    state long validUtf8 = 0;
    state long byteLength = 0;
    state long decodedScalars = 0;
    state long scalarSum = 0;

    entry void main() {
        region arena = new region(40, 2);
        long length = 4;
        words data = allocate(arena, length);
        set(data, 0, 7);
        set(data, 1, 11);
        first = data[0];
        assert first == 7;

        bytes packet = allocateBytes(arena, 6);
        setByte(packet, 0, 65);
        setByte(packet, 1, 194);
        setByte(packet, 2, 162);
        setByte(packet, 3, 226);
        setByte(packet, 4, 130);
        setByte(packet, 5, 172);
        byteValue = packet[0];
        assert byteValue == 65;

        byteLength = bufferLength(packet);
        assert byteLength == 6;

        boolean valid = utf8Valid(packet);
        if (valid) {
            validUtf8 = 1;
        } else {
            validUtf8 = 0;
        }
        utf8Scalars = utf8Count(packet);
        assert validUtf8 == 1;
        assert utf8Scalars == 3;

        long cursor = 0;
        while (cursor < byteLength) limit 6 {
            scalarSum += utf8Scalar(packet, cursor);
            cursor += utf8Width(packet, cursor);
            decodedScalars += 1;
        }
        assert decodedScalars == 3;
        assert scalarSum == 8591;

        drop(packet);
        drop(data);
        drop(arena);
    }
}
