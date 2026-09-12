//! Owns the canonical host-loan parameter shapes for classical entries.

module wheeler.compiler.entry_signatures;

import wheeler.compiler.type_codes;

classical class EntrySignatures {
  /// Caps an entry at one input loan followed by one output loan.
  public const long MAX_ENTRY_PARAMETERS = 2;

  private boolean entryInputType(long type) {
    if (type == TYPE_UTF8_BORROW) {
      return true;
    }

    return type == TYPE_BYTE_VIEW;
  }

  /// Checks exact active parameter types and zero-valued inactive positions.
  public boolean entryParameterTypesValid(long count, long firstType, long secondType) {
    if (count == 0) {
      if (firstType != 0) {
        return false;
      }

      return secondType == 0;
    }

    if (count == 1) {
      if (secondType != 0) {
        return false;
      }

      if (entryInputType(firstType)) {
        return true;
      }

      return firstType == TYPE_BYTES_BORROW;
    }

    if (count == MAX_ENTRY_PARAMETERS) {
      if (entryInputType(firstType) == false) {
        return false;
      }

      return secondType == TYPE_BYTES_BORROW;
    }

    return false;
  }
}
