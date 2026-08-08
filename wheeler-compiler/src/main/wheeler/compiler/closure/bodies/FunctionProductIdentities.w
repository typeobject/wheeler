//! Binds validated callable bytecode products to semantic dependency identities.

module wheeler.compiler.closure.function_product_identities;

import wheeler.crypto.sha256;

classical class FunctionProductIdentities {
  private const long DEPENDENCY_IDENTITY_BYTES = 2048;
  private const long FUNCTION_ROWS = 640;
  private const long IDENTITY_BYTES = 32;
  private const long IDENTITY_ARENA_BYTES = 2496;
  private const long IDENTITY_INPUT_BYTES = 2400;
  private const long MAX_DIRECT_DEPENDENCIES = 64;
  private const long MAX_FUNCTIONS_PER_MODULE = 64;

  private long copyIdentity(borrow byteview source, borrow mut bytes input, long cursor) {
    assert(bufferLength(source) == IDENTITY_BYTES);
    long index = 0;
    while (index < IDENTITY_BYTES) limit IDENTITY_BYTES {
      setByte(input, cursor + index, source[index]);
      index += 1;
    }

    return cursor + IDENTITY_BYTES;
  }

  private long writeSigned(long value, borrow mut bytes input, long cursor) {
    long remaining = value;
    long index = 0;
    while (index < 8) limit 8 {
      long octet = remaining % 256;
      if (octet < 0) {
        octet += 256;
      }

      setByte(input, cursor + index, octet);
      remaining = (remaining - octet) / 256;
      index += 1;
    }

    return cursor + 8;
  }

  /// Publishes one stable function body identity after all ranges validate.
  public void publishFunctionProductIdentity(
    borrow byteview artifact,
    long artifactLength,
    borrow mut words functionRows,
    long function,
    borrow byteview signatureIdentity,
    long dependencyCount,
    borrow byteview dependencyIdentities,
    borrow byteview aggregateIdentity,
    borrow byteview ownershipIdentity,
    borrow byteview relocationIdentity,
    borrow mut bytes identity
  ) {
    assert(0 < artifactLength);
    assert(artifactLength < bufferLength(artifact) + 1);
    assert(bufferLength(functionRows) == FUNCTION_ROWS);
    assert(-1 < function);
    assert(function < MAX_FUNCTIONS_PER_MODULE);
    assert(bufferLength(signatureIdentity) == IDENTITY_BYTES);
    assert(-1 < dependencyCount);
    assert(dependencyCount < MAX_DIRECT_DEPENDENCIES + 1);
    assert(bufferLength(dependencyIdentities) == DEPENDENCY_IDENTITY_BYTES);
    assert(bufferLength(aggregateIdentity) == IDENTITY_BYTES);
    assert(bufferLength(ownershipIdentity) == IDENTITY_BYTES);
    assert(bufferLength(relocationIdentity) == IDENTITY_BYTES);
    assert(bufferLength(identity) == IDENTITY_BYTES);

    long forwardStart = functionRows[128 + function];
    long forwardLength = functionRows[192 + function];
    long inverseStart = functionRows[256 + function];
    long inverseLength = functionRows[320 + function];
    long typeStart = functionRows[512 + function];
    long typeCount = functionRows[576 + function];
    assert(-1 < forwardStart);
    assert(-1 < forwardLength);
    assert(forwardStart < artifactLength + 1);
    assert(forwardLength < artifactLength - forwardStart + 1);
    assert(-1 < inverseLength);
    if (0 < inverseLength) {
      assert(-1 < inverseStart);
      assert(inverseStart < artifactLength + 1);
      assert(inverseLength < artifactLength - inverseStart + 1);
    }

    assert(-1 < typeStart);
    assert(-1 < typeCount);
    assert(typeStart < artifactLength + 1);
    assert(typeCount * 4 < artifactLength - typeStart + 1);

    region identityArena = new region(/* bytes= */ IDENTITY_ARENA_BYTES, /* allocations= */ 4);
    bytes input = allocateBytes(identityArena, IDENTITY_INPUT_BYTES);
    bytes forwardIdentity = allocateBytes(identityArena, IDENTITY_BYTES);
    bytes inverseIdentity = allocateBytes(identityArena, IDENTITY_BYTES);
    bytes typeIdentity = allocateBytes(identityArena, IDENTITY_BYTES);
    region forwardHashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    hashSha256Range(artifact, forwardStart, forwardLength, forwardIdentity, forwardHashArena);
    region inverseHashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    if (0 < inverseLength) {
      hashSha256Range(artifact, inverseStart, inverseLength, inverseIdentity, inverseHashArena);
    } else {
      hashSha256Range(artifact, 0, 0, inverseIdentity, inverseHashArena);
    }

    region typeHashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    hashSha256Range(artifact, typeStart, typeCount * 4, typeIdentity, typeHashArena);

    writeAscii(input, 0, "wheeler-callable-body-product-1");
    long cursor = 31;
    cursor = copyIdentity(signatureIdentity, input, cursor);
    cursor = copyIdentity(aggregateIdentity, input, cursor);
    cursor = copyIdentity(ownershipIdentity, input, cursor);
    cursor = copyIdentity(relocationIdentity, input, cursor);
    cursor = writeSigned(dependencyCount, input, cursor);
    long dependencyByte = 0;
    while (dependencyByte < dependencyCount * IDENTITY_BYTES) limit DEPENDENCY_IDENTITY_BYTES {
      setByte(input, cursor + dependencyByte, dependencyIdentities[dependencyByte]);
      dependencyByte += 1;
    }

    cursor += dependencyCount * IDENTITY_BYTES;
    cursor = copyIdentity(forwardIdentity, input, cursor);
    cursor = copyIdentity(inverseIdentity, input, cursor);
    cursor = copyIdentity(typeIdentity, input, cursor);
    cursor = writeSigned(functionRows[64 + function], input, cursor);
    cursor = writeSigned(forwardLength, input, cursor);
    cursor = writeSigned(inverseLength, input, cursor);
    cursor = writeSigned(functionRows[384 + function], input, cursor);
    cursor = writeSigned(functionRows[448 + function], input, cursor);
    cursor = writeSigned(typeCount, input, cursor);
    assert(cursor < IDENTITY_INPUT_BYTES + 1);
    region productHashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    hashSha256Range(input, 0, cursor, identity, productHashArena);

    drop(productHashArena);
    drop(typeHashArena);
    drop(inverseHashArena);
    drop(forwardHashArena);
    drop(typeIdentity);
    drop(inverseIdentity);
    drop(forwardIdentity);
    drop(input);
    drop(identityArena);
  }
}
