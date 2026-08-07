//! Compiles bounded Wheeler source and publishes only its verified artifact identity.

module wheeler.conformance.compiler.native_compiler_identity;

import wheeler.compiler.driver;
import wheeler.crypto.content_identity;

classical class NativeCompilerIdentity {
  state long sourceLength = 0;
  state long artifactLength = 0;
  state long published = 0;

  /// Compiles and identifies one source without publishing private artifact bytes.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow utf8 source, borrow mut bytes identity) {
    if (4096 < bufferLength(source)) {
      long oversized = utf8Scalar(source, -1);
    }

    region arena = new region(7000, 6);
    bytes artifact = allocateBytes(arena, 4096);
    Compilation compiled = compileMinimal(source, artifact);
    sourceLength = bufferLength(source);
    artifactLength = compiled.length;
    publishSha256Range(artifact, 0, compiled.length, identity, arena);
    published = 1;
    setOutputLength(identity, 32);
    drop(artifact);
    drop(arena);
  }
}
