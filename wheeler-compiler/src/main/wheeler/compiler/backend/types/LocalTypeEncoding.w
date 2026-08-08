//! Encodes one canonical local type table entry.

module wheeler.compiler.local_type_encoding;

import wheeler.compiler.encoding;
import wheeler.compiler.type_codes;

classical class LocalTypeEncoding {
  /// Writes one validated canonical local type code.
  public long writeLocalType(borrow mut bytes output, long cursor, long type) {
    assert(0 < type);
    long canonicalType = type % TYPE_SOURCE_METADATA_SCALE;
    return writeUnsignedLittleEndian(output, cursor, canonicalType, 4);
  }

  /// Writes one canonical signed local type code.
  public long writeSignedLocalType(borrow mut bytes output, long cursor) {
    return writeLocalType(output, cursor, TYPE_SIGNED);
  }

  /// Writes one canonical Boolean local type code.
  public long writeBooleanLocalType(borrow mut bytes output, long cursor) {
    return writeLocalType(output, cursor, TYPE_BOOLEAN);
  }

}
