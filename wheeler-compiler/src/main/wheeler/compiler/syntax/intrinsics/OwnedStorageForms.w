//! Defines bounded source and register forms for owned byte storage.

module wheeler.compiler.owned_storage_forms;

import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;

classical class OwnedStorageForms {
  /// Names resolved destruction after a mutation has already moved the owner.
  public const long STATEMENT_DROP_MOVED_OWNED = 131347;
  /// Names a UTF-8 result from an owner already advanced by mutation.
  public const long STATEMENT_RETURN_FREEZE_MOVED_UTF8 = 131348;
  /// Names the exact token width of `bytes name = allocateBytes(region, length);`.
  private const long BYTES_ALLOCATION_TOKEN_WIDTH = 10;
  /// Names the exact token width of `drop(name);`.
  private const long OWNED_DROP_TOKEN_WIDTH = 5;
  /// Names the exact token width of `return freezeUtf8(name);`.
  private const long UTF8_FREEZE_RETURN_TOKEN_WIDTH = 6;
  /// Names the local frame for two allocation sources and one owned result.
  private const long BYTES_ALLOCATION_LOCAL_COUNT = 3;
  /// Names the allocated owner after canonical source moves.
  private const long BYTES_ALLOCATION_RESULT_OFFSET = 2;
  /// Names two source moves followed by one ternary byte allocation.
  private const long BYTES_ALLOCATION_CODE_LENGTH = 80;
  /// Names the allocation instruction count after canonical source moves.
  private const long BYTES_ALLOCATION_INSTRUCTION_COUNT = 3;
  /// Names the local frame for one canonical owned move before destruction.
  private const long OWNED_DROP_LOCAL_COUNT = 1;
  /// Names one owned move followed by one unary owned drop.
  private const long OWNED_DROP_CODE_LENGTH = 40;
  /// Names the explicit destruction instruction count.
  private const long OWNED_DROP_INSTRUCTION_COUNT = 2;
  /// Names direct destruction after a mutation has already moved the owner.
  private const long MOVED_OWNED_DROP_CODE_LENGTH = 16;
  /// Names direct destruction as one unary instruction.
  private const long MOVED_OWNED_DROP_INSTRUCTION_COUNT = 1;
  /// Names an owned move and frozen UTF-8 result local.
  private const long UTF8_FREEZE_RETURN_LOCAL_COUNT = 2;
  /// Names one owned move, freeze, and return instruction.
  private const long UTF8_FREEZE_RETURN_CODE_LENGTH = 64;
  /// Names the owned move, freeze, and return instruction count.
  private const long UTF8_FREEZE_RETURN_INSTRUCTION_COUNT = 3;
  /// Names one result local after mutation has already moved the owner.
  private const long MOVED_UTF8_FREEZE_RETURN_LOCAL_COUNT = 1;
  /// Names one freeze and one return after owner-advancing mutation.
  private const long MOVED_UTF8_FREEZE_RETURN_CODE_LENGTH = 40;
  /// Names the moved-owner freeze and return instruction count.
  private const long MOVED_UTF8_FREEZE_RETURN_INSTRUCTION_COUNT = 2;

  /// Checks whether one opcode belongs to the bounded owned-storage profile.
  public boolean ownedStorageStatement(long opcode) {
    if (opcode == STATEMENT_LOCAL_BYTES_ALLOCATE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_DROP_OWNED_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_FREEZE_UTF8_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_FREEZE_MOVED_UTF8;
  }

  /// Validates and sizes one bounded owned-storage source statement.
  public long ownedStorageStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long opcode
  ) {
    if (opcode == STATEMENT_LOCAL_BYTES_ALLOCATE_NAMED) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
      ) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_OPEN_PAREN
        )
      ) {} else {
        return -1;
      }

      if (tokenKinds[statementStart + 5] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 6, PUNCTUATION_COMMA)
      ) {} else {
        return -1;
      }

      if (tokenKinds[statementStart + 7] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 8,
          PUNCTUATION_CLOSE_PAREN
        )
      ) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 9,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return BYTES_ALLOCATION_TOKEN_WIDTH;
      }

      return -1;
    }

    if (opcode == STATEMENT_DROP_OWNED_NAMED) {
      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 1,
          PUNCTUATION_OPEN_PAREN
        )
      ) {} else {
        return -1;
      }

      if (tokenKinds[statementStart + 2] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 3,
          PUNCTUATION_CLOSE_PAREN
        )
      ) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return OWNED_DROP_TOKEN_WIDTH;
      }
    }

    if (opcode == STATEMENT_RETURN_FREEZE_UTF8_NAMED) {
      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 2,
          PUNCTUATION_OPEN_PAREN
        )
      ) {} else {
        return -1;
      }

      if (tokenKinds[statementStart + 3] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_CLOSE_PAREN
        )
      ) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 5,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return UTF8_FREEZE_RETURN_TOKEN_WIDTH;
      }
    }

    return -1;
  }

  /// Returns the local width of one owned-storage statement, or `-1` for another owner.
  public long ownedStorageLocalCount(long opcode) {
    if (opcode == STATEMENT_LOCAL_BYTES_ALLOCATE_NAMED) {
      return BYTES_ALLOCATION_LOCAL_COUNT;
    }

    if (opcode == STATEMENT_DROP_OWNED_NAMED) {
      return OWNED_DROP_LOCAL_COUNT;
    }

    if (opcode == STATEMENT_DROP_MOVED_OWNED) {
      return 0;
    }

    if (opcode == STATEMENT_RETURN_FREEZE_UTF8_NAMED) {
      return UTF8_FREEZE_RETURN_LOCAL_COUNT;
    }

    if (opcode == STATEMENT_RETURN_FREEZE_MOVED_UTF8) {
      return MOVED_UTF8_FREEZE_RETURN_LOCAL_COUNT;
    }

    return -1;
  }

  /// Returns the initialized-local offset of one owned-storage statement.
  public long ownedStorageResultOffset(long opcode) {
    if (opcode == STATEMENT_LOCAL_BYTES_ALLOCATE_NAMED) {
      return BYTES_ALLOCATION_RESULT_OFFSET;
    }

    if (opcode == STATEMENT_RETURN_FREEZE_UTF8_NAMED) {
      return 1;
    }

    if (opcode == STATEMENT_RETURN_FREEZE_MOVED_UTF8) {
      return 0;
    }

    return -1;
  }

  /// Returns the code width of one owned-storage statement, or `-1` for another owner.
  public long ownedStorageCodeLength(long opcode) {
    if (opcode == STATEMENT_LOCAL_BYTES_ALLOCATE_NAMED) {
      return BYTES_ALLOCATION_CODE_LENGTH;
    }

    if (opcode == STATEMENT_DROP_OWNED_NAMED) {
      return OWNED_DROP_CODE_LENGTH;
    }

    if (opcode == STATEMENT_DROP_MOVED_OWNED) {
      return MOVED_OWNED_DROP_CODE_LENGTH;
    }

    if (opcode == STATEMENT_RETURN_FREEZE_UTF8_NAMED) {
      return UTF8_FREEZE_RETURN_CODE_LENGTH;
    }

    if (opcode == STATEMENT_RETURN_FREEZE_MOVED_UTF8) {
      return MOVED_UTF8_FREEZE_RETURN_CODE_LENGTH;
    }

    return -1;
  }

  /// Returns the instruction count of one owned-storage statement, or `-1` otherwise.
  public long ownedStorageInstructionCount(long opcode) {
    if (opcode == STATEMENT_LOCAL_BYTES_ALLOCATE_NAMED) {
      return BYTES_ALLOCATION_INSTRUCTION_COUNT;
    }

    if (opcode == STATEMENT_DROP_OWNED_NAMED) {
      return OWNED_DROP_INSTRUCTION_COUNT;
    }

    if (opcode == STATEMENT_DROP_MOVED_OWNED) {
      return MOVED_OWNED_DROP_INSTRUCTION_COUNT;
    }

    if (opcode == STATEMENT_RETURN_FREEZE_UTF8_NAMED) {
      return UTF8_FREEZE_RETURN_INSTRUCTION_COUNT;
    }

    if (opcode == STATEMENT_RETURN_FREEZE_MOVED_UTF8) {
      return MOVED_UTF8_FREEZE_RETURN_INSTRUCTION_COUNT;
    }

    return -1;
  }
}
