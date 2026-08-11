//! Encodes one canonical local type table entry.

module wheeler.compiler.local_type_encoding;

import wheeler.compiler.type_codes;

classical class LocalTypeEncoding {
  /// Writes one validated canonical local type code.
  /// Zero fails the nonzero proof, and a negative first octet fails before mutation.
  public long writeLocalType(borrow mut bytes output, long cursor, long type) {
    long nonzeroType = type / type;
    assert(nonzeroType == 1);
    long canonicalType = type % TYPE_SOURCE_METADATA_SCALE;
    long octet0 = canonicalType % 256;
    long remaining1 = canonicalType / 256;
    long octet1 = remaining1 % 256;
    long remaining2 = remaining1 / 256;
    long octet2 = remaining2 % 256;
    long remaining3 = remaining2 / 256;
    long octet3 = remaining3 % 256;
    long cursor1 = cursor + 1;
    long cursor2 = cursor + 2;
    long cursor3 = cursor + 3;
    long cursor4 = cursor + 4;
    setByte(output, cursor, octet0);
    setByte(output, cursor1, octet1);
    setByte(output, cursor2, octet2);
    setByte(output, cursor3, octet3);
    return cursor4;
  }

  /// Writes one canonical signed local type code.
  public long writeSignedLocalType(borrow mut bytes output, long cursor) {
    long typeCode = TYPE_SIGNED;
    long zero = 0;
    long cursor1 = cursor + 1;
    long cursor2 = cursor + 2;
    long cursor3 = cursor + 3;
    long cursor4 = cursor + 4;
    setByte(output, cursor, typeCode);
    setByte(output, cursor1, zero);
    setByte(output, cursor2, zero);
    setByte(output, cursor3, zero);
    return cursor4;
  }

  /// Writes one canonical Boolean local type code.
  public long writeBooleanLocalType(borrow mut bytes output, long cursor) {
    long typeCode = TYPE_BOOLEAN;
    long zero = 0;
    long cursor1 = cursor + 1;
    long cursor2 = cursor + 2;
    long cursor3 = cursor + 3;
    long cursor4 = cursor + 4;
    setByte(output, cursor, typeCode);
    setByte(output, cursor1, zero);
    setByte(output, cursor2, zero);
    setByte(output, cursor3, zero);
    return cursor4;
  }

}
