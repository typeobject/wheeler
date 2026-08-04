//! Defines the bounded source IR exchanged by parser and code generator.

module wheeler.compiler.ir;

classical class CompilerIr {
  /// Names an ordinary void helper.
  public const long HELPER_VOID = 0;
  /// Names a reversible void helper.
  public const long HELPER_REVERSIBLE = 1;
  /// Names a zero-argument signed-result helper.
  public const long HELPER_SIGNED = 2;
  /// Names a one-parameter signed-result helper.
  public const long HELPER_SIGNED_ONE = 3;
  /// Names a two-parameter signed-result helper.
  public const long HELPER_SIGNED_TWO = 4;
  /// Names a zero-argument Boolean-result helper.
  public const long HELPER_BOOLEAN = 5;
  /// Names a one-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_ONE = 6;
  /// Names a two-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_TWO = 7;
  /// Names a one-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_ONE = 8;
  /// Names a two-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_TWO = 9;
  /// Names a zero-argument reversible signed result-slot helper.
  public const long HELPER_REVERSIBLE_SIGNED = 10;
  /// Names a one-parameter reversible signed result-slot helper.
  public const long HELPER_REVERSIBLE_SIGNED_ONE = 11;
  /// Names a two-parameter reversible signed result-slot helper.
  public const long HELPER_REVERSIBLE_SIGNED_TWO = 12;
  /// Names the canonical reversible signed-result function flags.
  public const long RESULT_SLOT_FUNCTION_FLAGS = 13;
  /// Names the adjacent result-slot tag and payload locals.
  public const long RESULT_SLOT_LOCAL_COUNT = 2;
  /// Names the bounded resolver's logical result local before slot expansion.
  public const long RESULT_SLOT_LOGICAL_RESULT_LOCAL = 1;
  /// Names one direct fill-and-return result-slot body width.
  public const long RESULT_SLOT_BODY_LENGTH = 40;
  /// Names one binary fill-and-return result-slot body width.
  public const long RESULT_SLOT_BINARY_BODY_LENGTH = 56;
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
    long helperKind,
    SourceRange proofName,
    long proofCount,
    long helperCallCount,
    long preReverseStatementCount,
    long helperStatementCount,
    long helperResultStatement,
    SourceRange secondHelperName,
    long[64] secondHelperOpcodes,
    long[64] secondHelperOperands,
    long[64] secondHelperSecondaryOperands,
    long secondHelperKind,
    long secondHelperStatementCount,
    long secondHelperResultStatement,
    boolean library
  ) {}

  /// Returns the bounded scalar parameter count for one helper kind.
  public long parameterCountForHelper(long helperKind) {
    if (helperKind == HELPER_SIGNED_ONE) {
      return 1;
    }

    if (helperKind == HELPER_BOOLEAN_ONE) {
      return 1;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_ONE) {
      return 1;
    }

    if (helperKind == HELPER_REVERSIBLE_SIGNED_ONE) {
      return 1;
    }

    if (helperKind == HELPER_SIGNED_TWO) {
      return 2;
    }

    if (helperKind == HELPER_BOOLEAN_TWO) {
      return 2;
    }

    if (helperKind == HELPER_BOOLEAN_SIGNED_TWO) {
      return 2;
    }

    if (helperKind == HELPER_REVERSIBLE_SIGNED_TWO) {
      return 2;
    }

    return 0;
  }

  /// Checks whether one helper uses generated inverse code.
  public boolean reversibleHelper(long helperKind) {
    if (helperKind == HELPER_REVERSIBLE) {
      return true;
    }

    if (helperKind == HELPER_REVERSIBLE_SIGNED) {
      return true;
    }

    if (helperKind == HELPER_REVERSIBLE_SIGNED_ONE) {
      return true;
    }

    return helperKind == HELPER_REVERSIBLE_SIGNED_TWO;
  }

  /// Checks whether one helper uses the reversible result-slot ABI.
  public boolean resultSlotHelper(long helperKind) {
    if (helperKind == HELPER_REVERSIBLE_SIGNED) {
      return true;
    }

    if (helperKind == HELPER_REVERSIBLE_SIGNED_ONE) {
      return true;
    }

    return helperKind == HELPER_REVERSIBLE_SIGNED_TWO;
  }

  /// Checks whether one helper returns a Boolean value.
  public boolean booleanResultHelper(long helperKind) {
    if (helperKind < HELPER_BOOLEAN) {
      return false;
    }

    return helperKind < HELPER_BOOLEAN_SIGNED_TWO + 1;
  }

  /// Checks whether one helper receives Boolean parameters.
  public boolean booleanParameterHelper(long helperKind) {
    if (helperKind == HELPER_BOOLEAN_ONE) {
      return true;
    }

    return helperKind == HELPER_BOOLEAN_TWO;
  }

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
