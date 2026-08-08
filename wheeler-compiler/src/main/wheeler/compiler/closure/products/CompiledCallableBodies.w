//! Compiles one validated source-local callable product into canonical bytecode.

module wheeler.compiler.closure.compiled_callable_bodies;

import wheeler.compiler.compiler_core;
import wheeler.crypto.sha256;

classical class CompiledCallableBodies {
  private const long CALLABLE_CLASS_PREFIX_BYTES = 67;
  private const long CALLABLE_CLASS_SUFFIX_BYTES = 2;
  private const long IDENTITY_BYTES = 32;
  private const long MAX_CALLABLE_ARTIFACT_BYTES = 32768;
  private const long MAX_CALLABLE_SOURCE_BYTES = 32768;

  /// Reports the exact compiled callable artifact extent.
  public record CompiledCallableBody(long length, long codeStart) {}

  /// Compiles one callable without reading another module's source.
  public CompiledCallableBody compileCallableBodyProduct(
    borrow byteview archive,
    long signatureStart,
    long signatureLength,
    long bodyStart,
    long bodyLength,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    assert(bufferLength(artifact) == MAX_CALLABLE_ARTIFACT_BYTES);
    assert(bufferLength(identity) == IDENTITY_BYTES);
    assert(-1 < signatureStart);
    assert(0 < signatureLength);
    assert(-1 < bodyStart);
    assert(0 < bodyLength);
    assert(signatureStart < bufferLength(archive));
    assert(signatureLength < bufferLength(archive) - signatureStart + 1);
    assert(bodyStart < bufferLength(archive));
    assert(bodyLength < bufferLength(archive) - bodyStart + 1);
    long sourceLength = CALLABLE_CLASS_PREFIX_BYTES + signatureLength + bodyLength
      + CALLABLE_CLASS_SUFFIX_BYTES;
    assert(sourceLength < MAX_CALLABLE_SOURCE_BYTES + 1);
    region sourceArena = new region(/* bytes= */ MAX_CALLABLE_SOURCE_BYTES, /* allocations= */ 1);
    bytes sourceBytes = allocateBytes(sourceArena, sourceLength);
    writeAscii(
      sourceBytes,
      0,
      "module wheeler.callable.product; classical class CallableProduct { "
    );
    long written = CALLABLE_CLASS_PREFIX_BYTES;
    long copied = 0;
    while (copied < signatureLength) limit MAX_CALLABLE_SOURCE_BYTES {
      setByte(sourceBytes, written, archive[signatureStart + copied]);
      copied += 1;
      written += 1;
    }

    copied = 0;
    while (copied < bodyLength) limit MAX_CALLABLE_SOURCE_BYTES {
      setByte(sourceBytes, written, archive[bodyStart + copied]);
      copied += 1;
      written += 1;
    }

    writeAscii(sourceBytes, written, " }");
    utf8 source = freezeUtf8(sourceBytes);
    CoreCompilation compiled = compileMinimalCore(source, artifact);
    assert(0 < compiled.length);
    assert(compiled.length < MAX_CALLABLE_ARTIFACT_BYTES + 1);
    region hashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    hashSha256Range(artifact, 0, compiled.length, identity, hashArena);
    CompiledCallableBody result = new CompiledCallableBody(compiled.length, compiled.codeStart);
    drop(hashArena);
    drop(source);
    drop(sourceArena);
    return result;
  }
}
