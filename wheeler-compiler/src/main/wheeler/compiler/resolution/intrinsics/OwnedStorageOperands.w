//! Resolves bounded owned-storage operands against prior declarations.

module wheeler.compiler.owned_storage_operands;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_resolution;
import wheeler.compiler.owned_storage_forms;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.tokens;

classical class OwnedStorageOperands {
  /// Carries the current owner local and whether a mutation has advanced it.
  public record OwnedBytesOperand(long value, boolean moved) {}

  /// Carries one resolved owned-storage opcode and whether this owner applies.
  public record ResolvedOwnedStorage(long opcode, boolean applies) {}

  /// Resolves the current local for one bounded owned byte value.
  public OwnedBytesOperand resolvePriorOwnedBytes(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long assertedName
  ) {
    if (previousCount < 0) {
      return new OwnedBytesOperand(-1, false);
    }

    if (MAX_HELPER_RESOLUTION_STARTS < previousCount) {
      return new OwnedBytesOperand(-1, false);
    }

    long localBase = 0;
    long matchedLocal = -1;
    long matchCount = 0;
    boolean moved = false;
    long previous = 0;
    while (previous < previousCount) limit MAX_HELPER_RESOLUTION_STARTS {
      long previousStart = previousStarts[previous];
      if (previousStart < 0) {
        localBase += 1;
      } else {
        if (0 < previousStart) {
          long previousOpcode = statementOpcode(
            source,
            tokenStarts,
            tokenLengths,
            previousStart
          );
          if (previousOpcode == STATEMENT_LOCAL_BYTES_ALLOCATE_NAMED) {
            if (
              sameTokenText(source, tokenStarts, tokenLengths, previousStart + 1, assertedName)
            ) {
              matchedLocal = statementResultLocal(previousOpcode, localBase);
              matchCount += 1;
              moved = false;
            }
          }

          if (previousOpcode == STATEMENT_SET_BYTE_NAMED) {
            if (0 < matchCount) {
              if (
                sameTokenText(
                  source,
                  tokenStarts,
                  tokenLengths,
                  previousStart + 2,
                  assertedName
                )
              ) {
                matchedLocal = localBase;
                moved = true;
              }
            }
          }

          localBase += statementLocalCount(previousOpcode);
        }
      }

      previous += 1;
    }

    if (matchCount == 1) {
      return new OwnedBytesOperand(matchedLocal, moved);
    }

    return new OwnedBytesOperand(-1, false);
  }

  /// Resolves an owned drop after any canonical owner-advancing mutations.
  public ResolvedOwnedStorage resolveOwnedStorageOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long opcode
  ) {
    if (opcode == STATEMENT_DROP_OWNED_NAMED) {
      OwnedBytesOperand owner = resolvePriorOwnedBytes(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2
      );
      if (owner.value < 0) {
        return new ResolvedOwnedStorage(-1, true);
      }

      if (owner.moved) {
        return new ResolvedOwnedStorage(STATEMENT_DROP_MOVED_OWNED, true);
      }

      return new ResolvedOwnedStorage(opcode, true);
    }

    return new ResolvedOwnedStorage(-1, false);
  }

  /// Resolves the region or owned-value operand of one owned-storage statement.
  public long ownedStorageOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long opcode
  ) {
    if (opcode == STATEMENT_DROP_OWNED_NAMED) {
      OwnedBytesOperand owner = resolvePriorOwnedBytes(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2
      );
      return owner.value;
    }

    return resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 5,
      true
    );
  }

  /// Resolves the allocation length, or returns zero for an owned drop.
  public long ownedStorageSecondaryOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long opcode
  ) {
    if (opcode == STATEMENT_LOCAL_BYTES_ALLOCATE_NAMED) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 7,
        true
      );
    }

    return 0;
  }
}
