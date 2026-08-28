//! Validates canonical logical and workspace-relative paths.

module wheeler.compiler.packages.paths;

classical class Paths {
  private boolean invalidDotComponent(long componentLength, long dotCount) {
    boolean oneLength = componentLength == 1;
    boolean oneDot = dotCount == 1;
    if (oneLength == true) {
      return oneDot;
    }

    boolean twoLength = componentLength == 2;
    boolean twoDots = dotCount == 2;
    if (twoLength == true) {
      return twoDots;
    }

    return false;
  }

  private boolean workspacePathScalar(long scalar) {
    if (scalar == 45) {
      return true;
    }

    if (scalar == 95) {
      return true;
    }

    if (scalar < 48) {
      return false;
    }

    if (scalar < 58) {
      return true;
    }

    if (scalar < 65) {
      return false;
    }

    if (scalar < 91) {
      return true;
    }

    if (scalar < 97) {
      return false;
    }

    return scalar < 123;
  }

  private long workspaceSeparatorState(long state) {
    long invalid = 0;
    long needValue = 1;
    if (state == needValue) {
      return invalid;
    }

    return needValue;
  }

  private long workspacePathState(long scalar, long state) {
    long invalid = 0;
    long value = 2;
    long separatorState = workspaceSeparatorState(state);
    boolean allowed = workspacePathScalar(scalar);
    if (state == invalid) {
      return invalid;
    }

    if (scalar == 47) {
      return separatorState;
    }

    if (scalar == 46) {
      return separatorState;
    }

    if (allowed == true) {
      return value;
    }

    return invalid;
  }

  private long logicalSeparatorMode(long componentLength, long dotCount) {
    long invalid = 0;
    long normal = 1;
    if (componentLength == 0) {
      return invalid;
    }

    boolean dots = invalidDotComponent(componentLength, dotCount);
    if (dots == true) {
      return invalid;
    }

    return normal;
  }

  private long logicalBackslashMode(long mode) {
    long invalid = 0;
    long escaped = 2;
    if (mode == escaped) {
      return invalid;
    }

    return escaped;
  }

  private long logicalPathMode(long scalar, long mode, long componentLength, long dotCount) {
    long invalid = 0;
    long normal = 1;
    long backslashMode = logicalBackslashMode(mode);
    long separatorMode = logicalSeparatorMode(componentLength, dotCount);
    if (mode == invalid) {
      return invalid;
    }

    if (scalar == 0) {
      return invalid;
    }

    if (scalar == 92) {
      return backslashMode;
    }

    if (scalar == 47) {
      return separatorMode;
    }

    return normal;
  }

  private long logicalComponentLength(long scalar, long componentLength) {
    if (scalar == 47) {
      return 0;
    }

    if (scalar == 92) {
      return componentLength;
    }

    return componentLength + 1;
  }

  private long logicalDotCount(long scalar, long dotCount) {
    if (scalar == 47) {
      return 0;
    }

    if (scalar == 92) {
      return dotCount;
    }

    if (scalar == 46) {
      return dotCount + 1;
    }

    return dotCount;
  }

  private boolean logicalPathComplete(long mode, long componentLength, long dotCount) {
    long normal = 1;
    if (mode < normal) {
      return false;
    }

    if (normal < mode) {
      return false;
    }

    if (componentLength == 0) {
      return false;
    }

    boolean dots = invalidDotComponent(componentLength, dotCount);
    if (dots == true) {
      return false;
    }

    return true;
  }

  /// Checks whether `workspacePath` satisfies the canonical profile.
  public boolean validWorkspacePath(borrow utf8 source, long start, long length) {
    if (length == 0) {
      return false;
    }

    long cursor = start;
    long end = start + length;
    long state = 1;
    while (cursor < end) limit 4096 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long nextState = workspacePathState(scalar, state);
      state = nextState;
      cursor += width;
    }

    return state == 2;
  }

  /// Checks whether `logicalPath` satisfies the canonical profile.
  public boolean validLogicalPath(borrow utf8 source, long start, long length) {
    if (length == 0) {
      return false;
    }

    long cursor = start;
    long end = start + length;
    long mode = 1;
    long componentLength = 0;
    long dotCount = 0;
    while (cursor < end) limit 4096 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long nextMode = logicalPathMode(scalar, mode, componentLength, dotCount);
      long nextComponentLength = logicalComponentLength(scalar, componentLength);
      long nextDotCount = logicalDotCount(scalar, dotCount);
      mode = nextMode;
      componentLength = nextComponentLength;
      dotCount = nextDotCount;
      cursor += width;
    }

    boolean complete = logicalPathComplete(mode, componentLength, dotCount);
    return complete;
  }
}
