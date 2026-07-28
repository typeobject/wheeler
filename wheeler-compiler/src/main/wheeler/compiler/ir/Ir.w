//! Defines the bounded source IR exchanged by parser and code generator.

module wheeler.compiler.ir;

classical class CompilerIr {
  /// Caps source statements in one bounded entry or helper body.
  public const long MAX_MINIMAL_STATEMENTS = 64;
  /// Holds two parameter names before a full helper statement table.
  public const long MAX_HELPER_RESOLUTION_STARTS = MAX_MINIMAL_STATEMENTS + 2;
  /// Holds disjoint helper and entry statement-resolution tables.
  public const long MAX_PROGRAM_RESOLUTION_STARTS = MAX_HELPER_RESOLUTION_STARTS
    + MAX_MINIMAL_STATEMENTS;

  /// Defines immutable `SourceRange` values for this module.
  public record SourceRange(long start, long length) {}

  /// Defines immutable `MinimalProgram` values for this module.
  public record MinimalProgram(
    SourceRange name,
    SourceRange global,
    long globalCount,
    long initialValue,
    long statementCount,
    long[64] statementOpcodes,
    long[64] statementOperands,
    long[64] statementSecondaryOperands,
    SourceRange helperName,
    long helperCount,
    long[64] helperOpcodes,
    long[64] helperOperands,
    long[64] helperSecondaryOperands,
    long helperReversible,
    SourceRange proofName,
    long proofCount,
    long helperCallCount,
    long preReverseStatementCount,
    long helperStatementCount
  ) {}

  /// Returns the sole empty opcode column used before a parse succeeds.
  public long[64] emptyStatementOpcodes() {
    return new long[64](
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1
    );
  }

  /// Returns the sole empty operand column used before a parse succeeds.
  public long[64] emptyStatementOperands() {
    return new long[64](
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0
    );
  }

  /// Defines the closed `MinimalProgramResult` cases exported by this module.
  public variant MinimalProgramResult {
    case Value(MinimalProgram program);
    case Error(long offset);
  }
}
