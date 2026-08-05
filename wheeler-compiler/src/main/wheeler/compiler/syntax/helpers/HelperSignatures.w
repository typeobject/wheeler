//! Classifies bounded helper signatures and reversible result-slot conventions.

module wheeler.compiler.helper_signatures;

import wheeler.compiler.helper_abi;

classical class HelperSignatures {
  /// Returns the bounded scalar parameter count for one helper kind.
  public long parameterCountForHelper(long helperKind) {
    if (helperKind == HELPER_SIGNED_ONE) {
      return 1;
    }

    if (helperKind == HELPER_BOOLEAN_ONE) {
      return 1;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_ONE) {
      return 1;
    }

    if (helperKind == HELPER_REVERSIBLE_SIGNED_ONE) {
      return 1;
    }

    if (helperKind == HELPER_SIGNED_TWO) {
      return 2;
    }

    if (helperKind == HELPER_BOOLEAN_TWO) {
      return 2;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_TWO) {
      return 2;
    }

    if (helperKind == HELPER_REVERSIBLE_SIGNED_TWO) {
      return 2;
    }

    return 0;
  }

  /// Checks whether one helper uses generated inverse code.
  public boolean reversibleHelper(long helperKind) {
    if (helperKind == HELPER_REVERSIBLE) {
      return true;
    }

    if (helperKind == HELPER_REVERSIBLE_SIGNED) {
      return true;
    }

    if (helperKind == HELPER_REVERSIBLE_SIGNED_ONE) {
      return true;
    }

    return helperKind == HELPER_REVERSIBLE_SIGNED_TWO;
  }

  /// Checks whether one helper uses the reversible result-slot ABI.
  public boolean resultSlotHelper(long helperKind) {
    if (helperKind == HELPER_REVERSIBLE_SIGNED) {
      return true;
    }

    if (helperKind == HELPER_REVERSIBLE_SIGNED_ONE) {
      return true;
    }

    return helperKind == HELPER_REVERSIBLE_SIGNED_TWO;
  }

  /// Checks whether one helper returns a Boolean value.
  public boolean booleanResultHelper(long helperKind) {
    if (helperKind < HELPER_BOOLEAN) {
      return false;
    }

    if (helperKind < HELPER_BOOLEAN_SIGNED_TWO) {
      return true;
    }

    return helperKind == HELPER_BOOLEAN_SIGNED_TWO;
  }

  /// Checks whether one helper receives Boolean parameters.
  public boolean booleanParameterHelper(long helperKind) {
    if (helperKind == HELPER_BOOLEAN_ONE) {
      return true;
    }

    return helperKind == HELPER_BOOLEAN_TWO;
  }
}
