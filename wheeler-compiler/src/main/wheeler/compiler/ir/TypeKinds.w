//! Decodes canonical aggregate type identities for Wheeler-written bytecode tools.

module wheeler.compiler.type_kinds;

import wheeler.compiler.type_codes;

classical class TypeKinds {
  /// Decodes the metadata index shared by aggregate value codes.
  public long typeDescriptor(long typeCode) {
    return typeCode & TYPE_DESCRIPTOR_MASK;
  }
}
