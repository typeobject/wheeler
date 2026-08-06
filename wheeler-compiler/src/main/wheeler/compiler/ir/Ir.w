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
    long[64] callTargetStarts,
    long[64] callTargetLengths,
    long[64] callStatements,
    long[64] callFunctions,
    long callCount
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
    HelperBody ninthHelper,
    HelperBody tenthHelper,
    HelperBody eleventhHelper,
    HelperBody twelfthHelper,
    HelperBody thirteenthHelper,
    HelperBody fourteenthHelper,
    HelperBody fifteenthHelper,
    HelperBody sixteenthHelper,
    HelperBody seventeenthHelper,
    HelperBody eighteenthHelper,
    HelperBody nineteenthHelper,
    HelperBody twentiethHelper,
    HelperBody twentyFirstHelper,
    HelperBody twentySecondHelper,
    HelperBody twentyThirdHelper,
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

    if (index == 7) {
      return program.eighthHelper;
    }

    if (index == 8) {
      return program.ninthHelper;
    }

    if (index == 9) {
      return program.tenthHelper;
    }

    if (index == 10) {
      return program.eleventhHelper;
    }

    if (index == 11) {
      return program.twelfthHelper;
    }

    if (index == 12) {
      return program.thirteenthHelper;
    }

    if (index == 13) {
      return program.fourteenthHelper;
    }

    if (index == 14) {
      return program.fifteenthHelper;
    }

    if (index == 15) {
      return program.sixteenthHelper;
    }

    if (index == 16) {
      return program.seventeenthHelper;
    }

    if (index == 17) {
      return program.eighteenthHelper;
    }

    if (index == 18) {
      return program.nineteenthHelper;
    }

    if (index == 19) {
      return program.twentiethHelper;
    }

    if (index == 20) {
      return program.twentyFirstHelper;
    }

    if (index == 21) {
      return program.twentySecondHelper;
    }

    return program.twentyThirdHelper;
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
      emptyHelperCallOffsets(),
      emptyHelperCallOffsets(),
      emptyHelperCallIdentities(),
      emptyHelperCallIdentities(),
      0
    );
  }

  /// Freezes one mutable helper-call column after bounded parsing or resolution.
  public long[64] freezeHelperCallColumn(borrow mut words values) {
    return new long[64](
      values[0],
      values[1],
      values[2],
      values[3],
      values[4],
      values[5],
      values[6],
      values[7],
      values[8],
      values[9],
      values[10],
      values[11],
      values[12],
      values[13],
      values[14],
      values[15],
      values[16],
      values[17],
      values[18],
      values[19],
      values[20],
      values[21],
      values[22],
      values[23],
      values[24],
      values[25],
      values[26],
      values[27],
      values[28],
      values[29],
      values[30],
      values[31],
      values[32],
      values[33],
      values[34],
      values[35],
      values[36],
      values[37],
      values[38],
      values[39],
      values[40],
      values[41],
      values[42],
      values[43],
      values[44],
      values[45],
      values[46],
      values[47],
      values[48],
      values[49],
      values[50],
      values[51],
      values[52],
      values[53],
      values[54],
      values[55],
      values[56],
      values[57],
      values[58],
      values[59],
      values[60],
      values[61],
      values[62],
      values[63]
    );
  }

  /// Returns one empty helper-call offset column.
  public long[64] emptyHelperCallOffsets() {
    return emptyStatementOperands();
  }

  /// Returns one empty helper-call statement or function column.
  public long[64] emptyHelperCallIdentities() {
    return emptyStatementOpcodes();
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
