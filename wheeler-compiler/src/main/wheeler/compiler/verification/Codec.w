//! Re-encodes verified canonical bytecode without host codec assistance.

module wheeler.compiler.codec;

import wheeler.compiler.verifier;

classical class BytecodeCodec {
  /// Verifies and copies one canonical artifact into caller-owned output.
  ///
  /// Canonical `.wbc` has one byte representation, so verified identity encoding is the
  /// canonical encoder. Publication remains the caller's responsibility.
  ///
  /// - Effects: Mutates only `output`; malformed input traps before the first output write.
  public long reencodeArtifact(borrow byteview artifact, borrow mut bytes output) {
    long length = bufferLength(artifact);
    long verification = verifyArtifact(artifact, length);
    assert(verification == 1);
    assert(length < bufferLength(output) + 1);
    long cursor = 0;
    while (cursor < length) limit 16777216 {
      setByte(output, cursor, artifact[cursor]);
      cursor += 1;
    }

    return length;
  }
}
