//! Verifies an explicit canonical bytecode artifact in Wheeler.

module examples.compiler.native_verifier;
import wheeler.compiler.verifier;
classical class NativeVerifier {
    state long artifactLength = 0;
    state long verification = 0;

    /// Runs the bounded `NativeVerifier` fixture.
    ///
    /// - Effects: Mutates only the fixture's declared state.
    entry void main(byteview artifact) {
        artifactLength = bufferLength(artifact);
        verification = verifyArtifact(artifact, artifactLength);
        assert verification == 1;
    }
}
