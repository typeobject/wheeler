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
    long opcode,
    long operand,
    long secondOpcode,
    long secondOperand,
    long thirdOpcode,
    long thirdOperand,
    long fourthOpcode,
    long fourthOperand,
    long fifthOpcode,
    long fifthOperand,
    SourceRange helperName,
    long helperCount,
    long helperOpcode,
    long helperOperand,
    long helperReversible,
    SourceRange proofName,
    long proofCount,
    long helperCallCount,
    long preReverseStatementCount,
    long helperStatementCount,
    long helperSecondOpcode,
    long helperSecondOperand,
    long helperThirdOpcode,
    long helperThirdOperand,
    long helperFourthOpcode,
    long helperFourthOperand
  ) {}

  /// Defines the closed `MinimalProgramResult` cases exported by this module.
  public variant MinimalProgramResult {
    case Value(MinimalProgram program);
    case Error(long offset);
  }
}
