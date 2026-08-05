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

    if (helperKind == HELPER_SIGNED_NINE) {
      return 9;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_NINE) {
      return 9;
    }

    if (helperKind == HELPER_SIGNED_TEN) {
      return 10;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_TEN) {
      return 10;
    }

    if (helperKind == HELPER_SIGNED_ELEVEN) {
      return 11;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_ELEVEN) {
      return 11;
    }

    if (helperKind == HELPER_SIGNED_TWELVE) {
      return 12;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_TWELVE) {
      return 12;
    }

    if (helperKind == HELPER_SIGNED_THIRTEEN) {
      return 13;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_THIRTEEN) {
      return 13;
    }

    if (helperKind == HELPER_SIGNED_FOURTEEN) {
      return 14;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_FOURTEEN) {
      return 14;
    }

    if (helperKind == HELPER_SIGNED_FIFTEEN) {
      return 15;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_FIFTEEN) {
      return 15;
    }

    if (helperKind == HELPER_SIGNED_SIXTEEN) {
      return 16;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_SIXTEEN) {
      return 16;
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

    if (parameterCount == 9) {
      return HELPER_SIGNED_NINE;
    }

    if (parameterCount == 10) {
      return HELPER_SIGNED_TEN;
    }

    if (parameterCount == 11) {
      return HELPER_SIGNED_ELEVEN;
    }

    if (parameterCount == 12) {
      return HELPER_SIGNED_TWELVE;
    }

    if (parameterCount == 13) {
      return HELPER_SIGNED_THIRTEEN;
    }

    if (parameterCount == 14) {
      return HELPER_SIGNED_FOURTEEN;
    }

    if (parameterCount == 15) {
      return HELPER_SIGNED_FIFTEEN;
    }

    if (parameterCount == 16) {
      return HELPER_SIGNED_SIXTEEN;
    }

    return -1;
  }

  /// Returns one Boolean helper kind for an exact signed-parameter count.
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

    if (parameterCount == 9) {
      return HELPER_BOOLEAN_SIGNED_NINE;
    }

    if (parameterCount == 10) {
      return HELPER_BOOLEAN_SIGNED_TEN;
    }

    if (parameterCount == 11) {
      return HELPER_BOOLEAN_SIGNED_ELEVEN;
    }

    if (parameterCount == 12) {
      return HELPER_BOOLEAN_SIGNED_TWELVE;
    }

    if (parameterCount == 13) {
      return HELPER_BOOLEAN_SIGNED_THIRTEEN;
    }

    if (parameterCount == 14) {
      return HELPER_BOOLEAN_SIGNED_FOURTEEN;
    }

    if (parameterCount == 15) {
      return HELPER_BOOLEAN_SIGNED_FIFTEEN;
    }

    if (parameterCount == 16) {
      return HELPER_BOOLEAN_SIGNED_SIXTEEN;
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
    if (helperKind == HELPER_BOOLEAN) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_ONE) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_TWO) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_ONE) {
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

    if (helperKind == HELPER_BOOLEAN_SIGNED_EIGHT) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_NINE) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_TEN) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_ELEVEN) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_TWELVE) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_THIRTEEN) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_FOURTEEN) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_FIFTEEN) {
      return true;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_SIXTEEN) {
      return true;
    }

    return false;
  }

  /// Checks whether one helper receives Boolean parameters.
  public boolean booleanParameterHelper(long helperKind) {
    if (helperKind == HELPER_BOOLEAN_ONE) {
      return true;
    }

    return helperKind == HELPER_BOOLEAN_TWO;
  }
}
