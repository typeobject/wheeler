//! Compiles validated source-local callable products into canonical bytecode.

module wheeler.compiler.closure.compiled_callable_bodies;

import wheeler.compiler.compiler_core;
import wheeler.crypto.sha256;

classical class CompiledCallableBodies {
  private const long CALLABLE_CLASS_PREFIX_BYTES = 67;
  private const long CALLABLE_CLASS_SUFFIX_BYTES = 2;
  private const long IDENTITY_BYTES = 32;
  private const long MAX_CALLABLE_ARTIFACT_BYTES = 32768;
  private const long MAX_CALLABLES_PER_MODULE = 64;
  private const long MAX_CALLABLE_SOURCE_BYTES = 32768;

  /// Reports the exact compiled callable artifact extent.
  public record CompiledCallableBody(long length, long codeStart) {}

  private long copyArchiveRange(
    borrow byteview archive,
    long start,
    long length,
    borrow mut bytes output,
    long written
  ) {
    assert(-1 < start);
    assert(0 < length);
    assert(start < bufferLength(archive));
    assert(length < bufferLength(archive) - start + 1);
    long copied = 0;
    while (copied < length) limit MAX_CALLABLE_SOURCE_BYTES {
      setByte(output, written, archive[start + copied]);
      copied += 1;
      written += 1;
    }

    return written;
  }

  private CompiledCallableBody compileProductSource(
    bytes sourceBytes,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    long cleared = 0;
    while (cleared < bufferLength(artifact)) limit MAX_CALLABLE_ARTIFACT_BYTES {
      setByte(artifact, cleared, 0);
      cleared += 1;
    }

    utf8 source = freezeUtf8(sourceBytes);
    CoreCompilation compiled = compileMinimalCore(source, artifact);
    assert(0 < compiled.length);
    assert(compiled.length < MAX_CALLABLE_ARTIFACT_BYTES + 1);
    region hashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    hashSha256Range(artifact, 0, compiled.length, identity, hashArena);
    CompiledCallableBody result = new CompiledCallableBody(compiled.length, compiled.codeStart);
    drop(hashArena);
    drop(source);
    return result;
  }

  private void writeClassPrefix(borrow mut bytes output) {
    writeAscii(output, 0, "module wheeler.callable.product; classical class CallableProduct { ");
  }

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
    long sourceLength = CALLABLE_CLASS_PREFIX_BYTES + signatureLength + bodyLength
      + CALLABLE_CLASS_SUFFIX_BYTES;
    assert(sourceLength < MAX_CALLABLE_SOURCE_BYTES + 1);
    region sourceArena = new region(/* bytes= */ MAX_CALLABLE_SOURCE_BYTES, /* allocations= */ 1);
    bytes sourceBytes = allocateBytes(sourceArena, sourceLength);
    writeClassPrefix(sourceBytes);
    long written = CALLABLE_CLASS_PREFIX_BYTES;
    written = copyArchiveRange(archive, signatureStart, signatureLength, sourceBytes, written);
    written = copyArchiveRange(archive, bodyStart, bodyLength, sourceBytes, written);
    writeAscii(sourceBytes, written, " }");
    CompiledCallableBody result = compileProductSource(sourceBytes, artifact, identity);
    drop(sourceArena);
    return result;
  }

  /// Compiles all callable products owned by one source-local module.
  public CompiledCallableBody compileCallableModuleProduct(
    borrow byteview archive,
    long owner,
    long firstCallable,
    long callableCount,
    borrow mut words callableOwners,
    borrow mut words signatureStarts,
    borrow mut words signatureLengths,
    borrow mut words bodyStarts,
    borrow mut words bodyLengths,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    assert(bufferLength(artifact) == MAX_CALLABLE_ARTIFACT_BYTES);
    assert(bufferLength(identity) == IDENTITY_BYTES);
    assert(-1 < owner);
    assert(-1 < firstCallable);
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES_PER_MODULE + 1);
    long sourceLength = CALLABLE_CLASS_PREFIX_BYTES + CALLABLE_CLASS_SUFFIX_BYTES;
    long offset = 0;
    while (offset < callableCount) limit MAX_CALLABLES_PER_MODULE {
      long selectedCallable = firstCallable + offset;
      assert(callableOwners[selectedCallable] == owner);
      sourceLength += signatureLengths[selectedCallable] + bodyLengths[selectedCallable];
      if (0 < offset) {
        sourceLength += 1;
      }

      offset += 1;
    }

    assert(sourceLength < MAX_CALLABLE_SOURCE_BYTES + 1);
    region sourceArena = new region(/* bytes= */ MAX_CALLABLE_SOURCE_BYTES, /* allocations= */ 1);
    bytes sourceBytes = allocateBytes(sourceArena, sourceLength);
    writeClassPrefix(sourceBytes);
    long written = CALLABLE_CLASS_PREFIX_BYTES;
    offset = 0;
    while (offset < callableCount) limit MAX_CALLABLES_PER_MODULE {
      long writtenCallable = firstCallable + offset;
      if (0 < offset) {
        setByte(sourceBytes, written, 32);
        written += 1;
      }

      written = copyArchiveRange(
        archive,
        signatureStarts[writtenCallable],
        signatureLengths[writtenCallable],
        sourceBytes,
        written
      );
      written = copyArchiveRange(
        archive,
        bodyStarts[writtenCallable],
        bodyLengths[writtenCallable],
        sourceBytes,
        written
      );
      offset += 1;
    }

    writeAscii(sourceBytes, written, " }");
    CompiledCallableBody result = compileProductSource(sourceBytes, artifact, identity);
    drop(sourceArena);
    return result;
  }
}
