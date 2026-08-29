//! Projects bounded semantic-version component coordinates and values.

module wheeler.compiler.packages.semver_coordinates;

classical class SemverCoordinates {
  private long componentCursor(long scalar, long cursor, long width, long end) {
    long next = cursor + width;
    if (scalar == 45) {
      return end;
    }

    return next;
  }

  private long componentOrdinal(long scalar, long current) {
    long next = current + 1;
    if (scalar == 46) {
      return next;
    }

    return current;
  }

  private long componentValue(long scalar, long current, long component, long value) {
    long product = value * 10;
    long withScalar = product + scalar;
    long next = withScalar - 48;
    if (scalar == 45) {
      return value;
    }

    if (scalar == 46) {
      return value;
    }

    if (current == component) {
      return next;
    }

    return value;
  }

  /// Returns one major, minor, or patch value from a valid release.
  public long semverCoreComponent(borrow utf8 source, long start, long length, long component) {
    long cursor = start;
    long end = start + length;
    long current = 0;
    long value = 0;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long nextCursor = componentCursor(scalar, cursor, width, end);
      long nextCurrent = componentOrdinal(scalar, current);
      long nextValue = componentValue(scalar, current, component, value);
      cursor = nextCursor;
      current = nextCurrent;
      value = nextValue;
    }

    return value;
  }

  private long prereleaseCursor(long scalar, long cursor, long width, long end) {
    long next = cursor + width;
    if (scalar == 45) {
      return end;
    }

    return next;
  }

  private long projectedPrereleaseStart(long scalar, long cursor, long current) {
    long candidate = cursor + 1;
    if (scalar == 45) {
      return candidate;
    }

    return current;
  }

  /// Returns the first prerelease scalar or the release end.
  public long semverPrereleaseStart(borrow utf8 source, long start, long length) {
    long cursor = start;
    long end = start + length;
    long projected = end;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long nextCursor = prereleaseCursor(scalar, cursor, width, end);
      long nextProjected = projectedPrereleaseStart(scalar, cursor, projected);
      cursor = nextCursor;
      projected = nextProjected;
    }

    return projected;
  }

  private long identifierCursor(long scalar, long cursor, long width, long end) {
    long next = cursor + width;
    if (scalar == 46) {
      return end;
    }

    return next;
  }

  private long projectedIdentifierEnd(long scalar, long cursor, long current) {
    if (scalar == 46) {
      return cursor;
    }

    return current;
  }

  /// Returns the next dot or the prerelease end.
  public long semverIdentifierEnd(borrow utf8 source, long start, long end) {
    long cursor = start;
    long projected = end;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long nextCursor = identifierCursor(scalar, cursor, width, end);
      long nextProjected = projectedIdentifierEnd(scalar, cursor, projected);
      cursor = nextCursor;
      projected = nextProjected;
    }

    return projected;
  }
}
