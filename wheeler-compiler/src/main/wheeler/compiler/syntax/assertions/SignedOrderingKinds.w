//! Classifies signed ordering assertions by the origin of each operand.

module wheeler.compiler.signed_ordering_kinds;

classical class SignedOrderingKinds {
  /// Names an immediate signed value, including an evaluated constant.
  public const long ASSERTION_LITERAL = 0;
  /// Names one admitted signed frame slot.
  public const long ASSERTION_LOCAL = 1;
  /// Names one admitted signed class-state slot.
  public const long ASSERTION_GLOBAL = 2;
  private const long ORIGIN_COUNT = 3;
  private const long ASSERTION_FRAME_SLOTS = 256;
  private const long ORDERING_FIRST = 43008;
  private const long ORDERING_COUNT = ORIGIN_COUNT * ORIGIN_COUNT;

  /// Returns one ordered origin identity, or rejects an unknown origin.
  public long signedOrderingKind(long left, long right) {
    long leftKind = checkedOrigin(left);
    if (leftKind < 0) {
      return -1;
    }

    long rightKind = checkedOrigin(right);
    if (rightKind < 0) {
      return -1;
    }

    long row = leftKind * ORIGIN_COUNT;
    long base = row + ORDERING_FIRST;
    return base + rightKind;
  }

  /// Validates a signed value or its independently bounded storage index.
  public boolean signedOrderingValueValid(long kind, long value) {
    if (kind == ASSERTION_LITERAL) {
      return true;
    }

    if (value < 0) {
      return false;
    }

    boolean localValue = value < ASSERTION_FRAME_SLOTS;
    boolean globalValue = value == 0;
    if (kind == ASSERTION_LOCAL) {
      return localValue;
    }

    if (kind == ASSERTION_GLOBAL) {
      return globalValue;
    }

    return false;
  }

  /// Checks the complete finite identity range before projection.
  public boolean signedOrderingStatement(long opcode) {
    long offset = orderingOffset(opcode);
    if (offset < 0) {
      return false;
    }

    return true;
  }

  /// Returns the left operand origin of an admitted ordering identity.
  public long signedOrderingLeftKind(long opcode) {
    long offset = orderingOffset(opcode);
    if (offset < 0) {
      return -1;
    }

    return offset / ORIGIN_COUNT;
  }

  /// Returns the right operand origin of an admitted ordering identity.
  public long signedOrderingRightKind(long opcode) {
    long offset = orderingOffset(opcode);
    if (offset < 0) {
      return -1;
    }

    return offset % ORIGIN_COUNT;
  }

  private long orderingOffset(long opcode) {
    if (opcode < ORDERING_FIRST) {
      return -1;
    }

    long offset = opcode - ORDERING_FIRST;
    if (offset < ORDERING_COUNT) {
      return offset;
    }

    return -1;
  }

  private long checkedOrigin(long origin) {
    if (origin < 0) {
      return -1;
    }

    if (origin < ORIGIN_COUNT) {
      return origin;
    }

    return -1;
  }
}
