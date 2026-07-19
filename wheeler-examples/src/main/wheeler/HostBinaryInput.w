//! Explicit immutable binary input; malformed UTF-8 is ordinary data here.
classical class HostBinaryInput {
    state long byteLength = 0;
    state long firstByte = 0;
    state long middleByte = 0;
    state long lastByte = 0;
    state long checksum = 0;
    state long outputLength = 0;

    /// Runs the bounded `HostBinaryInput` fixture.
    ///
    /// - Effects: Mutates declared state and caller-owned byte output.
    entry void main(byteview source, bytes output) {
        byteLength = bufferLength(source);
        firstByte = source[0];
        middleByte = source[1];
        lastByte = source[3];
        checksum = firstByte + middleByte + source[2] + lastByte;
        setByte(output, 0, firstByte);
        setByte(output, 1, lastByte);
        outputLength = 2;
        setOutputLength(output, outputLength);
        assert(byteLength == 4);
        assert(firstByte == 0);
        assert(middleByte == 255);
        assert(lastByte == 128);
        assert(checksum == 510);
    }
}
