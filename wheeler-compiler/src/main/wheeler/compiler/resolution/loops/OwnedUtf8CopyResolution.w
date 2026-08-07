//! Resolves the exact bounded UTF-8-to-owned-bytes copy loop.

module wheeler.compiler.owned_utf8_copy_resolution;

import wheeler.compiler.class_constants;
import wheeler.compiler.local_resolution;
import wheeler.compiler.owned_storage_operands;
import wheeler.compiler.owned_utf8_copy_loops;
import wheeler.compiler.tokens;

classical class OwnedUtf8CopyResolution {
  /// Resolves one copy-loop identity carrying its mutable cursor local.
  public long resolveOwnedUtf8CopyOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long cursor = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      ownedUtf8CopyCursorToken(statementStart),
      true
    );
    if (cursor < 0) {
      return -1;
    }

    return STATEMENT_OWNED_UTF8_COPY_LOOP_BASE + cursor;
  }

  /// Packs the current byte owner and immutable UTF-8 source locals.
  public long resolveOwnedUtf8CopyOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    OwnedBytesOperand owner = resolvePriorOwnedBytes(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      ownedUtf8CopyOwnerToken(statementStart)
    );
    if (owner.value < 0) {
      return -1;
    }

    long utf8Source = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      ownedUtf8CopySourceToken(statementStart),
      true
    );
    if (utf8Source < 0) {
      return -1;
    }

    return owner.value * COPY_LOOP_SOURCE_SCALE + utf8Source;
  }

  /// Packs the condition local and exact positive loop limit.
  public long resolveOwnedUtf8CopySecondaryOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long length = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      ownedUtf8CopyLengthToken(statementStart),
      true
    );
    if (length < 0) {
      return -1;
    }

    ConstantResolution limit = resolveClassConstant(
      source,
      tokenStarts,
      tokenLengths,
      ownedUtf8CopyLimitToken(statementStart),
      true
    );
    if (limit.valid) {} else {
      return -1;
    }

    if (0 < limit.value) {} else {
      return -1;
    }

    if (limit.value < COPY_LOOP_LIMIT_SCALE) {} else {
      return -1;
    }

    return length * COPY_LOOP_LIMIT_SCALE + limit.value;
  }
}
