//! Owns root-statement staging bounds and the atomic publication of complete products.

module wheeler.compiler.closure.direct_statement_publication;

import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.compiler_token_limits;

classical class DirectStatementPublication {
  /// Bounds root statements and their counted output columns.
  public const long MAX_STATEMENTS = 4096;
  /// Bounds the complete staged instruction stream.
  public const long MAX_CODE_BYTES = 262144;
  /// Counts statement, owner, instruction count, byte start/length, and type start/count.
  public const long DIRECT_COLUMNS = 7;
  /// Sizes the complete root-statement product window.
  public const long DIRECT_ROWS = MAX_STATEMENTS * DIRECT_COLUMNS;
  /// Counts owner, local index, and type columns.
  public const long TYPE_COLUMNS = 3;
  /// Sizes the complete direct local-type product window.
  public const long TYPE_ROWS = MAX_STATEMENTS * TYPE_COLUMNS;
  /// Bounds source-local functions.
  public const long DIRECT_FUNCTIONS = 64;
  /// Bounds source-local calls.
  public const long DIRECT_CALLS = 256;
  private const long TOKEN_COLUMNS = 3;
  private const long FUNCTION_COLUMNS = 3;
  private const long CALL_COLUMNS = 2;
  private const long WORD_BYTES = 8;
  private const long STAGING_WORDS = MAX_COMPILER_TOKENS * TOKEN_COLUMNS + DIRECT_ROWS + BODY_ROWS
    + TYPE_ROWS + DIRECT_FUNCTIONS * FUNCTION_COLUMNS + DIRECT_CALLS * CALL_COLUMNS
    + MAX_STATEMENTS;
  /// Includes every scanner, row, type, coordinate, and code allocation.
  public const long DIRECT_STAGING_BYTES = STAGING_WORDS * WORD_BYTES + MAX_CODE_BYTES;
  /// Counts token columns, direct/body/type tables, function/call columns, widths, and code.
  public const long DIRECT_STAGING_BUFFERS = TOKEN_COLUMNS + 3 + FUNCTION_COLUMNS + CALL_COLUMNS
    + 2;

  /// Reports the complete published prefix or one failing private statement coordinate.
  public record DirectStatementPlan(
    long productCount,
    long instructionCount,
    long length,
    long typeCount,
    long failureStatement,
    long failureCode,
    boolean valid
  ) {}

  /// Constructs the result before copying any caller-visible product, type, or code byte.
  public DirectStatementPlan publishDirectStatements(
    long productCount,
    long instructionCount,
    long length,
    long typeCount,
    long callCount,
    long functionCount,
    long statementCount,
    long failureStatement,
    long failureCode,
    boolean valid,
    borrow mut words stagedRows,
    borrow mut words stagedCallKinds,
    borrow mut words stagedCallConditionalValues,
    borrow mut words stagedResultTypes,
    borrow mut words stagedTypes,
    borrow mut words stagedWidths,
    borrow byteview stagedCode,
    borrow mut words directRows,
    borrow mut words callRows,
    borrow mut words callConditionalValues,
    borrow mut words functionResultTypes,
    borrow mut words typeRows,
    borrow mut words statementPhysicalWidths,
    borrow mut bytes output
  ) {
    if (valid == false) {
      return new DirectStatementPlan(0, 0, 0, 0, failureStatement, failureCode, false);
    }

    assert(-1 < instructionCount);
    assert(-1 < productCount);
    assert(productCount < MAX_STATEMENTS + 1);
    assert(-1 < typeCount);
    assert(typeCount < MAX_STATEMENTS + 1);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(-1 < callCount);
    assert(callCount < DIRECT_CALLS + 1);
    assert(-1 < functionCount);
    assert(functionCount < DIRECT_FUNCTIONS + 1);
    assert(-1 < length);
    assert(length < MAX_CODE_BYTES + 1);
    assert(bufferLength(stagedRows) == DIRECT_ROWS);
    assert(bufferLength(directRows) == DIRECT_ROWS);
    assert(bufferLength(stagedTypes) == TYPE_ROWS);
    assert(bufferLength(typeRows) == TYPE_ROWS);
    assert(bufferLength(stagedWidths) == MAX_STATEMENTS);
    assert(bufferLength(statementPhysicalWidths) == MAX_STATEMENTS);
    assert(bufferLength(stagedResultTypes) == DIRECT_FUNCTIONS);
    assert(bufferLength(functionResultTypes) == DIRECT_FUNCTIONS);
    assert(bufferLength(stagedCode) == MAX_CODE_BYTES);
    assert(bufferLength(output) == MAX_CODE_BYTES);
    if (0 < callCount) {
      assert(bufferLength(stagedCallKinds) == DIRECT_CALLS);
      assert(bufferLength(stagedCallConditionalValues) == DIRECT_CALLS);
      assert(bufferLength(callRows) == DIRECT_CALLS * 4);
      assert(bufferLength(callConditionalValues) == DIRECT_CALLS);
    }

    DirectStatementPlan result = new DirectStatementPlan(
      productCount,
      instructionCount,
      length,
      typeCount,
      -1,
      0,
      true
    );
    long column = 0;
    while (column < DIRECT_COLUMNS) limit DIRECT_COLUMNS {
      long row = 0;
      while (row < productCount) limit MAX_STATEMENTS {
        long cell = column * MAX_STATEMENTS + row;
        set(directRows, cell, stagedRows[cell]);
        row += 1;
      }

      column += 1;
    }

    long call = 0;
    while (call < callCount) limit DIRECT_CALLS {
      set(callRows, DIRECT_CALLS + call, stagedCallKinds[call]);
      set(callConditionalValues, call, stagedCallConditionalValues[call]);
      call += 1;
    }

    long function = 0;
    while (function < functionCount) limit DIRECT_FUNCTIONS {
      set(functionResultTypes, function, stagedResultTypes[function]);
      function += 1;
    }

    long typeColumn = 0;
    while (typeColumn < TYPE_COLUMNS) limit TYPE_COLUMNS {
      long type = 0;
      while (type < typeCount) limit MAX_STATEMENTS {
        long typeCell = typeColumn * MAX_STATEMENTS + type;
        set(typeRows, typeCell, stagedTypes[typeCell]);
        type += 1;
      }

      typeColumn += 1;
    }

    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      set(statementPhysicalWidths, statement, stagedWidths[statement]);
      statement += 1;
    }

    long codeByte = 0;
    while (codeByte < length) limit MAX_CODE_BYTES {
      setByte(output, codeByte, stagedCode[codeByte]);
      codeByte += 1;
    }

    return result;
  }
}
