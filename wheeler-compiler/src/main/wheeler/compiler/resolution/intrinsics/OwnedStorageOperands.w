//! Resolves bounded owned-storage operands against prior declarations.

module wheeler.compiler.owned_storage_operands;

import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_resolution;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.tokens;

classical class OwnedStorageOperands {
  private long resolvePriorOwnedBytes(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long assertedName
  ) {
    if (previousCount < 0) {
      return -1;
    }

    if (MAX_HELPER_RESOLUTION_STARTS < previousCount) {
      return -1;
    }

    long localBase = 0;
    long matchedLocal = -1;
    long matchCount = 0;
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
            }
          }

          localBase += statementLocalCount(previousOpcode);
        }
      }

      previous += 1;
    }

    if (matchCount == 1) {
      return matchedLocal;
    }

    return -1;
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
      return resolvePriorOwnedBytes(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2
      );
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
