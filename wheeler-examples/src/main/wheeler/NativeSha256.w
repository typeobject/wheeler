//! Hashes explicit host input with the Wheeler SHA-256 implementation.

module examples.crypto.sha256_main;
import examples.crypto.sha256;
classical class NativeSha256 {
    state long inputLength = 0;
    state long digestLength = 0;

    /// Runs the bounded `NativeSha256` fixture.
    ///
    /// - Effects: Mutates declared state and caller-owned byte output.
    entry void main(byteview input, bytes digest) {
        region arena = new region(1088, 3);
        inputLength = bufferLength(input);
        hashSha256(input, digest, arena);
        digestLength = 32;
        setOutputLength(digest, digestLength);
        drop(arena);
        assert digestLength == 32;
    }
}
