//! Defines the bounded source IR exchanged by parser and code generator.

module wheeler.compiler.ir;

import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.helper_abi;

classical class CompilerIr {

  /// Defines immutable `SourceRange` values for this module.
  public record SourceRange(long start, long length) {}

  /// Defines one bounded helper body and its resolved scalar signature.
  public record HelperBody(
    SourceRange name,
    long[64] opcodes,
    long[64] operands,
    long[64] secondaryOperands,
    long kind,
    long statementCount,
    long resultStatement,
    SourceRange firstCallTargetName,
    long firstCallStatement,
    long firstCallFunction,
    SourceRange secondCallTargetName,
    long secondCallStatement,
    long secondCallFunction
  ) {}

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
    long helperCount,
    HelperBody firstHelper,
    HelperBody secondHelper,
    HelperBody thirdHelper,
    HelperBody fourthHelper,
    HelperBody fifthHelper,
    HelperBody sixthHelper,
    HelperBody seventhHelper,
    HelperBody eighthHelper,
    SourceRange proofName,
    long proofCount,
    long helperCallCount,
    long preReverseStatementCount,
    boolean library
  ) {}

  /// Selects one helper from a validated bounded function table.
  public HelperBody helperAt(MinimalProgram program, long index) {
    if (index == 0) {
      return program.firstHelper;
    }

    if (index == 1) {
      return program.secondHelper;
    }

    if (index == 2) {
      return program.thirdHelper;
    }

    if (index == 3) {
      return program.fourthHelper;
    }

    if (index == 4) {
      return program.fifthHelper;
    }

    if (index == 5) {
      return program.sixthHelper;
    }

    if (index == 6) {
      return program.seventhHelper;
    }

    return program.eighthHelper;
  }

  /// Returns one absent helper used to fill a bounded helper table.
  public HelperBody emptyHelperBody() {
    return new HelperBody(
      new SourceRange(0, 0),
      emptyStatementOpcodes(),
      emptyStatementOperands(),
      emptyStatementOperands(),
      HELPER_VOID,
      0,
      0,
      new SourceRange(0, 0),
      -1,
      -1,
      new SourceRange(0, 0),
      -1,
      -1
    );
  }

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
