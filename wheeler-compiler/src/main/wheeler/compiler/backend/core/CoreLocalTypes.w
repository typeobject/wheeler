//! Encodes local type sequences for compiler entries and helper bodies.

module wheeler.compiler.core_local_types;

import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.fixed_array_types;
import wheeler.compiler.helper_call_local_types;
import wheeler.compiler.helper_signatures;
import wheeler.compiler.helper_source_types;
import wheeler.compiler.ir;
import wheeler.compiler.statement_local_types;
import wheeler.compiler.type_codes;

classical class CoreLocalTypes {
  private long writeTypedStatementLocalTypes(
    borrow mut bytes output,
    long cursor,
    MinimalProgram program,
    HelperBody body,
    long statement
  ) {
    long resultType = TYPE_SIGNED;
    if (booleanResultHelper(body.kind)) {
      resultType = TYPE_BOOLEAN;
    }

    if (utf8ResultHelper(body.kind)) {
      resultType = TYPE_UTF8;
    }

    long opcode = body.opcodes[statement];
    long firstType = helperSourceType(
      opcode,
      body.operands[statement],
      body.secondaryOperands[statement],
      0,
      body
    );
    long secondType = helperSourceType(
      opcode,
      body.operands[statement],
      body.secondaryOperands[statement],
      1,
      body
    );
    long thirdType = helperSourceType(
      opcode,
      body.operands[statement],
      body.secondaryOperands[statement],
      2,
      body
    );
    long fourthType = helperSourceType(
      opcode,
      body.operands[statement],
      body.secondaryOperands[statement],
      3,
      body
    );
    long fifthType = helperSourceType(
      opcode,
      body.operands[statement],
      body.secondaryOperands[statement],
      4,
      body
    );
    long sixthType = helperSourceType(
      opcode,
      body.operands[statement],
      body.secondaryOperands[statement],
      5,
      body
    );
    long seventhType = helperSourceType(
      opcode,
      body.operands[statement],
      body.secondaryOperands[statement],
      6,
      body
    );
    firstType = canonicalProgramType(program, firstType);
    secondType = canonicalProgramType(program, secondType);
    thirdType = canonicalProgramType(program, thirdType);
    fourthType = canonicalProgramType(program, fourthType);
    fifthType = canonicalProgramType(program, fifthType);
    sixthType = canonicalProgramType(program, sixthType);
    seventhType = canonicalProgramType(program, seventhType);

    long callCursor = writeHelperCallLocalTypes(
      output,
      cursor,
      opcode,
      resultType,
      firstType,
      secondType,
      thirdType,
      fourthType,
      fifthType,
      sixthType,
      seventhType
    );
    if (-1 < callCursor) {
      return callCursor;
    }

    return writeStatementLocalTypes(output, cursor, opcode);
  }

  /// Encodes local type windows for one entry statement sequence.
  public long writeSequenceLocalTypes(
    borrow mut bytes output,
    long cursor,
    MinimalProgram program
  ) {
    HelperBody body = entryBody(program);
    long statement = 0;
    while (statement < body.statementCount) limit MAX_MINIMAL_STATEMENTS {
      if (statementUsesDeclaredSources(body, statement)) {
        cursor = writeTypedStatementLocalTypes(output, cursor, program, body, statement);
      } else {
        cursor = writeStatementLocalTypes(output, cursor, body.opcodes[statement]);
      }

      statement += 1;
    }

    return cursor;
  }

  /// Encodes resolved local type windows for one helper statement sequence.
  public long writeHelperSequenceLocalTypes(
    borrow mut bytes output,
    long cursor,
    MinimalProgram program,
    HelperBody body
  ) {
    long statement = 0;
    while (statement < body.statementCount) limit MAX_MINIMAL_STATEMENTS {
      cursor = writeTypedStatementLocalTypes(output, cursor, program, body, statement);
      statement += 1;
    }

    return cursor;
  }
}
