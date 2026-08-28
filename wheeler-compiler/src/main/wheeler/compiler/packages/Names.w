//! Validates canonical package, module, and workspace names.

module wheeler.compiler.packages.names;

classical class Names {
  private boolean lowercase(long scalar) {
    if (scalar < 97) {
      return false;
    }

    if (scalar < 123) {
      return true;
    }

    return false;
  }

  private boolean uppercase(long scalar) {
    if (scalar < 65) {
      return false;
    }

    if (scalar < 91) {
      return true;
    }

    return false;
  }

  private boolean digit(long scalar) {
    if (scalar < 48) {
      return false;
    }

    if (scalar < 58) {
      return true;
    }

    return false;
  }

  private boolean moduleStart(long scalar) {
    boolean lower = lowercase(scalar);
    if (lower == true) {
      return true;
    }

    boolean upper = uppercase(scalar);
    if (upper == true) {
      return true;
    }

    return scalar == 95;
  }

  private long moduleStartState(long scalar) {
    long invalid = 0;
    long following = 2;
    boolean allowed = moduleStart(scalar);
    if (allowed == true) {
      return following;
    }

    return invalid;
  }

  private long moduleFollowingState(long scalar) {
    long invalid = 0;
    long segmentStart = 1;
    long following = 2;
    boolean identifier = moduleStart(scalar);
    if (identifier == true) {
      return following;
    }

    boolean numeric = digit(scalar);
    if (numeric == true) {
      return following;
    }

    if (scalar == 46) {
      return segmentStart;
    }

    return invalid;
  }

  private long moduleNameState(long scalar, long state) {
    long invalid = 0;
    long segmentStart = 1;
    long startState = moduleStartState(scalar);
    long followingState = moduleFollowingState(scalar);
    if (state == invalid) {
      return invalid;
    }

    if (state == segmentStart) {
      return startState;
    }

    return followingState;
  }

  private long workspaceStartState(long scalar) {
    long invalid = 0;
    long value = 2;
    boolean letter = lowercase(scalar);
    if (letter == true) {
      return value;
    }

    boolean numeric = digit(scalar);
    if (numeric == true) {
      return value;
    }

    return invalid;
  }

  private long workspaceFollowingState(long scalar) {
    long invalid = 0;
    long needValue = 1;
    long value = 2;
    boolean letter = lowercase(scalar);
    if (letter == true) {
      return value;
    }

    boolean numeric = digit(scalar);
    if (numeric == true) {
      return value;
    }

    if (scalar == 45) {
      return needValue;
    }

    if (scalar == 46) {
      return needValue;
    }

    return invalid;
  }

  private long workspaceNameState(long scalar, long state) {
    long invalid = 0;
    long needValue = 1;
    long firstValue = 3;
    long firstState = packageStartState(scalar);
    long startState = workspaceStartState(scalar);
    long followingState = workspaceFollowingState(scalar);
    if (state == invalid) {
      return invalid;
    }

    if (state == firstValue) {
      return firstState;
    }

    if (state == needValue) {
      return startState;
    }

    return followingState;
  }

  private long packageStartState(long scalar) {
    long invalid = 0;
    long following = 2;
    boolean letter = lowercase(scalar);
    if (letter == true) {
      return following;
    }

    return invalid;
  }

  private long packageFollowingState(long scalar) {
    long invalid = 0;
    long segmentStart = 1;
    long following = 2;
    boolean letter = lowercase(scalar);
    if (letter == true) {
      return following;
    }

    boolean numeric = digit(scalar);
    if (numeric == true) {
      return following;
    }

    if (scalar == 46) {
      return segmentStart;
    }

    return invalid;
  }

  private long packageNameState(long scalar, long state) {
    long invalid = 0;
    long segmentStart = 1;
    long startState = packageStartState(scalar);
    long followingState = packageFollowingState(scalar);
    if (state == invalid) {
      return invalid;
    }

    if (state == segmentStart) {
      return startState;
    }

    return followingState;
  }

  /// Checks whether `moduleName` satisfies the canonical profile.
  public boolean validModuleName(borrow utf8 source, long start, long length) {
    if (length == 0) {
      return false;
    }

    long cursor = start;
    long end = start + length;
    long state = 1;
    while (cursor < end) limit 4096 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long nextState = moduleNameState(scalar, state);
      state = nextState;
      cursor += width;
    }

    return state == 2;
  }

  /// Checks whether `workspaceName` satisfies the canonical profile.
  public boolean validWorkspaceName(borrow utf8 source, long start, long length) {
    if (length == 0) {
      return false;
    }

    long cursor = start;
    long end = start + length;
    long state = 3;
    while (cursor < end) limit 4096 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long nextState = workspaceNameState(scalar, state);
      state = nextState;
      cursor += width;
    }

    return state == 2;
  }

  /// Checks whether `packageName` satisfies the canonical profile.
  public boolean validPackageName(borrow utf8 source, long start, long length) {
    if (length == 0) {
      return false;
    }

    long cursor = start;
    long end = start + length;
    long state = 1;
    while (cursor < end) limit 4096 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long nextState = packageNameState(scalar, state);
      state = nextState;
      cursor += width;
    }

    return state == 2;
  }
}
