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

    if (helperKind == HELPER_SIGNED_THREE) {
      return 3;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_THREE) {
      return 3;
    }

    if (helperKind == HELPER_SIGNED_FOUR) {
      return 4;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_FOUR) {
      return 4;
    }

    if (helperKind == HELPER_SIGNED_FIVE) {
      return 5;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_FIVE) {
      return 5;
    }

    if (helperKind == HELPER_SIGNED_SIX) {
      return 6;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_SIX) {
      return 6;
    }

    if (helperKind == HELPER_SIGNED_SEVEN) {
      return 7;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_SEVEN) {
      return 7;
    }

    if (helperKind == HELPER_SIGNED_EIGHT) {
      return 8;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_EIGHT) {
      return 8;
    }

    return 0;
  }

  /// Returns one signed helper kind for an exact signed-parameter count.
  public long signedScalarHelperKind(long parameterCount) {
    if (parameterCount == 0) {
      return HELPER_SIGNED;
    }

    if (parameterCount == 1) {
      return HELPER_SIGNED_ONE;
    }

    if (parameterCount == 2) {
      return HELPER_SIGNED_TWO;
    }

    if (parameterCount == 3) {
      return HELPER_SIGNED_THREE;
    }

    if (parameterCount == 4) {
      return HELPER_SIGNED_FOUR;
    }

    if (parameterCount == 5) {
      return HELPER_SIGNED_FIVE;
    }

    if (parameterCount == 6) {
      return HELPER_SIGNED_SIX;
    }

    if (parameterCount == 7) {
      return HELPER_SIGNED_SEVEN;
    }

    if (parameterCount == 8) {
      return HELPER_SIGNED_EIGHT;
    }

    return -1;
  }

  /// Returns one boolean helper kind for an exact signed-parameter count.
  public long booleanScalarHelperKind(long parameterCount) {
    if (parameterCount == 0) {
      return HELPER_BOOLEAN;
    }

    if (parameterCount == 1) {
      return HELPER_BOOLEAN_SIGNED_ONE;
    }

    if (parameterCount == 2) {
      return HELPER_BOOLEAN_SIGNED_TWO;
    }

    if (parameterCount == 3) {
      return HELPER_BOOLEAN_SIGNED_THREE;
    }

    if (parameterCount == 4) {
      return HELPER_BOOLEAN_SIGNED_FOUR;
    }

    if (parameterCount == 5) {
      return HELPER_BOOLEAN_SIGNED_FIVE;
    }

    if (parameterCount == 6) {
      return HELPER_BOOLEAN_SIGNED_SIX;
    }

    if (parameterCount == 7) {
      return HELPER_BOOLEAN_SIGNED_SEVEN;
    }

    if (parameterCount == 8) {
      return HELPER_BOOLEAN_SIGNED_EIGHT;
    }

    return -1;
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

    if (helperKind == HELPER_BOOLEAN_SIGNED_TWO) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_THREE) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_FOUR) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_FIVE) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_SIX) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_SEVEN) {
      return true;
    }

    return helperKind == HELPER_BOOLEAN_SIGNED_EIGHT;
  }

  /// Checks whether one helper receives Boolean parameters.
  public boolean booleanParameterHelper(long helperKind) {
    if (helperKind == HELPER_BOOLEAN_ONE) {
      return true;
    }

    return helperKind == HELPER_BOOLEAN_TWO;
  }
}
