module examples.compiler.native_verifier;
import examples.compiler.verifier;
classical class NativeVerifier {
    state long artifactLength = 0;
    state long verification = 0;

    entry void main(byteview artifact) {
        artifactLength = bufferLength(artifact);
        verification = verifyArtifact(artifact, artifactLength);
        assert verification == 1;
    }
}
