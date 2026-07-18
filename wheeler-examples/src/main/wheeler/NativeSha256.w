module examples.crypto.sha256_main;
import examples.crypto.sha256;
classical class NativeSha256 {
    state long inputLength = 0;
    state long digestLength = 0;

    entry void main(byteview input, bytes digest) {
        region arena = new region(576, 2);
        inputLength = bufferLength(input);
        hashSha256(input, digest, arena);
        digestLength = 32;
        setOutputLength(digest, digestLength);
        drop(arena);
        assert digestLength == 32;
    }
}
