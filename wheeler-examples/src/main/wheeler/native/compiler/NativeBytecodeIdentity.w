//! Computes the content identity of one bounded canonical bytecode artifact.

module examples.compiler.native_bytecode_identity;

import wheeler.compiler.codec;
import wheeler.crypto.content_identity;

classical class NativeBytecodeIdentity {
  state long artifactLength = 0;
  state long verifiedLength = 0;
  state long published = 0;

  /// Verifies and identifies one artifact without publishing partial output.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview artifact, borrow mut bytes identity) {
    if (4096 < bufferLength(artifact)) {
      long oversized = artifact[-1];
    }

    region arena = new region(8192, 6);
    bytes verified = allocateBytes(arena, bufferLength(artifact));
    long length = reencodeArtifact(artifact, verified);
    if (length == bufferLength(artifact)) {} else {
      assert(published == 1);
    }

    artifactLength = bufferLength(artifact);
    verifiedLength = length;
    publishSha256(artifact, identity, arena);
    published = 1;
    setOutputLength(identity, 32);
    drop(verified);
    drop(arena);
  }
}
