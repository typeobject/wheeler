//! Binds canonical instruction-derived ownership events to callable bodies.

module wheeler.compiler.closure.ownership_product_identities;

import wheeler.crypto.sha256;

classical class OwnershipProductIdentities {
  private const long EVENT_ROWS = 40960;
  private const long IDENTITY_BYTES = 32;
  private const long INPUT_BYTES = 262400;
  private const long MAX_EVENTS_PER_MODULE = 8192;

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

  /// Publishes one ownership identity after the complete ordered event table validates.
  public void publishOwnershipProductIdentity(
    long function,
    long eventCount,
    borrow mut words eventRows,
    borrow mut bytes identity
  ) {
    assert(-1 < function);
    assert(function < 64);
    assert(-1 < eventCount);
    assert(eventCount < MAX_EVENTS_PER_MODULE + 1);
    assert(bufferLength(eventRows) == EVENT_ROWS);
    assert(bufferLength(identity) == IDENTITY_BYTES);

    long selectedCount = 0;
    long previousInstruction = -1;
    long event = 0;
    while (event < eventCount) limit MAX_EVENTS_PER_MODULE {
      long kind = eventRows[event];
      long instruction = eventRows[8192 + event];
      long ownerFunction = eventRows[16384 + event];
      assert(0 < kind);
      assert(kind < 6);
      assert(-1 < instruction);
      assert(previousInstruction < instruction + 1);
      assert(-1 < ownerFunction);
      assert(ownerFunction < 64);
      if (ownerFunction == function) {
        selectedCount += 1;
      }

      previousInstruction = instruction;
      event += 1;
    }

    region product = new region(/* bytes= */ INPUT_BYTES, /* allocations= */ 1);
    bytes input = allocateBytes(product, INPUT_BYTES);
    writeAscii(input, 0, "wheeler-callable-ownership-product-1");
    long cursor = writeSigned(selectedCount, input, 36);
    event = 0;
    while (event < eventCount) limit MAX_EVENTS_PER_MODULE {
      if (eventRows[16384 + event] == function) {
        cursor = writeSigned(eventRows[event], input, cursor);
        cursor = writeSigned(eventRows[8192 + event], input, cursor);
        cursor = writeSigned(eventRows[24576 + event], input, cursor);
        cursor = writeSigned(eventRows[32768 + event], input, cursor);
      }

      event += 1;
    }

    assert(cursor < INPUT_BYTES + 1);
    region hashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    hashSha256Range(input, 0, cursor, identity, hashArena);
    drop(hashArena);
    drop(input);
    drop(product);
  }
}
