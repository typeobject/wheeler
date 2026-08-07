//! Re-encodes an explicit canonical bytecode artifact in Wheeler.

module wheeler.conformance.compiler.native_bytecode_codec;

import wheeler.compiler.codec;

classical class NativeBytecodeCodec {
  state long artifactLength = 0;
  state long verification = 0;

  /// Runs the bounded native bytecode codec fixture.
  ///
  /// - Effects: Mutates declared state and caller-owned byte output.
  entry void main(borrow byteview artifact, borrow mut bytes output) {
    artifactLength = reencodeArtifact(artifact, output);
    verification = 1;
    setOutputLength(output, artifactLength);
    assert(0 < artifactLength);
  }
}
