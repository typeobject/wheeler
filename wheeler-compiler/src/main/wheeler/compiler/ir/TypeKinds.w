//! Decodes canonical aggregate type identities for Wheeler-written bytecode tools.

module wheeler.compiler.type_kinds;

import wheeler.compiler.type_codes;

classical class TypeKinds {
  /// Checks whether one canonical value code denotes a record type.
  public boolean isRecordType(long typeCode) {
    return(typeCode & TYPE_KIND_MASK) == TYPE_RECORD;
  }

  /// Decodes the record metadata index from a checked value code.
  public long recordTypeId(long typeCode) {
    return typeCode & TYPE_DESCRIPTOR_MASK;
  }

  /// Checks whether one canonical value code denotes a variant type.
  public boolean isVariantType(long typeCode) {
    return(typeCode & TYPE_KIND_MASK) == TYPE_VARIANT;
  }

  /// Decodes the variant metadata index from a checked value code.
  public long variantTypeId(long typeCode) {
    return typeCode & TYPE_DESCRIPTOR_MASK;
  }

  /// Checks whether one canonical value code denotes a fixed array type.
  public boolean isArrayType(long typeCode) {
    return(typeCode & TYPE_KIND_MASK) == TYPE_ARRAY;
  }

  /// Decodes the array metadata index from a checked value code.
  public long arrayTypeId(long typeCode) {
    return typeCode & TYPE_DESCRIPTOR_MASK;
  }

  /// Checks whether one canonical value code denotes a slice type.
  public boolean isSliceType(long typeCode) {
    return(typeCode & TYPE_KIND_MASK) == TYPE_SLICE;
  }

  /// Decodes the slice metadata index from a checked value code.
  public long sliceTypeId(long typeCode) {
    return typeCode & TYPE_DESCRIPTOR_MASK;
  }
}
