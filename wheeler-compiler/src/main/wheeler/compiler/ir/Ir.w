//! Defines the bounded source IR exchanged by parser and code generator.

module wheeler.compiler.ir;

classical class CompilerIr {
  /// Defines immutable `SourceRange` values for this module.
  public record SourceRange(long start, long length) {}

  /// Defines immutable `MinimalProgram` values for this module.
  public record MinimalProgram(
    SourceRange name,
    SourceRange global,
    long globalCount,
    long initialValue,
    long statementCount,
    long[8] statementOpcodes,
    long[8] statementOperands,
    SourceRange helperName,
    long helperCount,
    long[8] helperOpcodes,
    long[8] helperOperands,
    long helperReversible,
    SourceRange proofName,
    long proofCount,
    long helperCallCount,
    long preReverseStatementCount,
    long helperStatementCount
  ) {}

  /// Defines the closed `MinimalProgramResult` cases exported by this module.
  public variant MinimalProgramResult {
    case Value(MinimalProgram program);
    case Error(long offset);
  }
}
