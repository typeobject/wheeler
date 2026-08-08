//! Publishes stable identities for validated counted callable signatures.

module wheeler.compiler.closure.callable_identities;

import wheeler.compiler.closure.callable_signature_products;
import wheeler.crypto.sha256;

classical class CallableProductIdentities {
  private const long CALLABLE_IDENTITY_STORAGE_BYTES = 131072;
  private const long IDENTITY_BYTES = 32;
  private const long MAX_CALLABLES = 4096;
  private const long MAX_IDENTITY_INPUT_BYTES = 33500;

  private long hexNibble(long scalar) {
    if (47 < scalar) {
      if (scalar < 58) {
        return scalar - 48;
      }
    }

    if (96 < scalar) {
      if (scalar < 103) {
        return scalar - 87;
      }
    }

    return -1;
  }

  private long writeCount(long value, borrow mut bytes input, long cursor) {
    if (-1 < value) {} else {
      return -1;
    }

    if (value < 65536) {} else {
      return -1;
    }

    setByte(input, cursor, value % 256);
    setByte(input, cursor + 1, value / 256);
    return cursor + 2;
  }

  private long writeSourceIdentity(
    borrow byteview manifest,
    long start,
    borrow mut bytes input,
    long cursor
  ) {
    long index = 0;
    while (index < IDENTITY_BYTES) limit IDENTITY_BYTES {
      long high = hexNibble(manifest[start + index * 2]);
      long low = hexNibble(manifest[start + index * 2 + 1]);
      if (-1 < high) {} else {
        return -1;
      }

      if (-1 < low) {} else {
        return -1;
      }

      setByte(input, cursor + index, high * 16 + low);
      index += 1;
    }

    return cursor + IDENTITY_BYTES;
  }

  private long writeArchiveRange(
    borrow byteview archive,
    long start,
    long length,
    borrow mut bytes input,
    long cursor
  ) {
    if (-1 < start) {} else {
      return -1;
    }

    if (0 < length) {} else {
      return -1;
    }

    if (start < bufferLength(archive)) {} else {
      return -1;
    }

    if (length < bufferLength(archive) - start + 1) {} else {
      return -1;
    }

    cursor = writeCount(length, input, cursor);
    if (-1 < cursor) {} else {
      return -1;
    }

    long copied = 0;
    while (copied < length) limit 32768 {
      setByte(input, cursor + copied, archive[start + copied]);
      copied += 1;
    }

    return cursor + length;
  }

  /// Publishes package- and source-bound callable signature identities atomically.
  public boolean publishCallableIdentities(
    borrow byteview archive,
    borrow byteview manifest,
    long moduleCount,
    long callableCount,
    borrow mut words moduleIdentityStarts,
    borrow mut words callableOwners,
    borrow mut words callableVisibilities,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableResultTypeStarts,
    borrow mut words callableResultTypeLengths,
    borrow mut words callableEffects,
    borrow mut words callableFirstParameters,
    borrow mut words callableParameterCounts,
    borrow mut words parameterTypeStarts,
    borrow mut words parameterTypeLengths,
    borrow mut words parameterModes,
    borrow mut bytes packageIdentity,
    borrow mut bytes callableIdentities
  ) {
    if (0 < moduleCount) {} else {
      return false;
    }

    if (-1 < callableCount) {} else {
      return false;
    }

    if (callableCount < MAX_CALLABLES + 1) {} else {
      return false;
    }

    if (bufferLength(packageIdentity) == IDENTITY_BYTES) {} else {
      return false;
    }

    if (bufferLength(callableIdentities) == CALLABLE_IDENTITY_STORAGE_BYTES) {} else {
      return false;
    }

    region identityArena = new region(/* bytes= */ 165000, /* allocations= */ 3);
    bytes scratchIdentities = allocateBytes(identityArena, CALLABLE_IDENTITY_STORAGE_BYTES);
    bytes input = allocateBytes(identityArena, MAX_IDENTITY_INPUT_BYTES);
    bytes digest = allocateBytes(identityArena, IDENTITY_BYTES);
    region hashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    long callable = 0;
    boolean valid = true;
    while (callable < callableCount) limit MAX_CALLABLES {
      writeAscii(input, 0, "wheeler-callable-signature-1");
      long cursor = 28;
      long copied = 0;
      while (copied < IDENTITY_BYTES) limit IDENTITY_BYTES {
        setByte(input, cursor + copied, packageIdentity[copied]);
        copied += 1;
      }

      cursor += IDENTITY_BYTES;
      long owner = callableOwners[callable];
      if (-1 < owner) {} else {
        valid = false;
        break;
      }

      if (owner < moduleCount) {} else {
        valid = false;
        break;
      }

      cursor = writeSourceIdentity(manifest, moduleIdentityStarts[owner], input, cursor);
      if (-1 < cursor) {} else {
        valid = false;
        break;
      }

      long visibility = callableVisibilities[callable];
      if (-1 < visibility) {} else {
        valid = false;
        break;
      }

      if (visibility < 2) {} else {
        valid = false;
        break;
      }

      long effects = callableEffects[callable];
      if (-1 < effects) {} else {
        valid = false;
        break;
      }

      if (effects < 16) {} else {
        valid = false;
        break;
      }

      setByte(input, cursor, visibility);
      setByte(input, cursor + 1, effects);
      cursor += 2;
      cursor = writeArchiveRange(
        archive,
        callableNameStarts[callable],
        callableNameLengths[callable],
        input,
        cursor
      );
      if (-1 < cursor) {} else {
        valid = false;
        break;
      }

      cursor = writeArchiveRange(
        archive,
        callableResultTypeStarts[callable],
        callableResultTypeLengths[callable],
        input,
        cursor
      );
      if (-1 < cursor) {} else {
        valid = false;
        break;
      }

      long parameterCount = callableParameterCounts[callable];
      if (-1 < parameterCount) {} else {
        valid = false;
        break;
      }

      if (parameterCount < MAX_CALLABLE_PARAMETERS + 1) {} else {
        valid = false;
        break;
      }

      cursor = writeCount(parameterCount, input, cursor);
      long firstParameter = callableFirstParameters[callable];
      long offset = 0;
      while (offset < parameterCount) limit MAX_CALLABLE_PARAMETERS {
        long parameter = firstParameter + offset;
        long mode = parameterModes[parameter];
        if (-1 < mode) {} else {
          valid = false;
          break;
        }

        if (mode < 3) {} else {
          valid = false;
          break;
        }

        setByte(input, cursor, mode);
        cursor += 1;
        cursor = writeArchiveRange(
          archive,
          parameterTypeStarts[parameter],
          parameterTypeLengths[parameter],
          input,
          cursor
        );
        if (-1 < cursor) {} else {
          valid = false;
          break;
        }

        offset += 1;
      }

      if (valid) {} else {
        break;
      }

      if (cursor < MAX_IDENTITY_INPUT_BYTES + 1) {} else {
        valid = false;
        break;
      }

      hashSha256Range(input, 0, cursor, digest, hashArena);
      long digestByte = 0;
      while (digestByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
        setByte(scratchIdentities, callable * IDENTITY_BYTES + digestByte, digest[digestByte]);
        digestByte += 1;
      }

      callable += 1;
    }

    if (valid) {
      long published = 0;
      while (published < callableCount * IDENTITY_BYTES) limit CALLABLE_IDENTITY_STORAGE_BYTES {
        setByte(callableIdentities, published, scratchIdentities[published]);
        published += 1;
      }
    }

    drop(hashArena);
    drop(digest);
    drop(input);
    drop(scratchIdentities);
    drop(identityArena);
    return valid;
  }
}
