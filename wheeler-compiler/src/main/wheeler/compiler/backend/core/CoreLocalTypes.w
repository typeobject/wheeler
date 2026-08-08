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
  /// Encodes local type windows for one entry statement sequence.
  public long writeSequenceLocalTypes(
    borrow mut bytes output,
    long cursor,
    long[64] opcodes,
    long count
  ) {
    long index = 0;
    while (index < count) limit MAX_MINIMAL_STATEMENTS {
      cursor = writeStatementLocalTypes(output, cursor, opcodes[index]);
      index += 1;
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
    long resultType = TYPE_SIGNED;
    if (booleanResultHelper(body.kind)) {
      resultType = TYPE_BOOLEAN;
    }

    if (utf8ResultHelper(body.kind)) {
      resultType = TYPE_UTF8;
    }

    long statement = 0;
    while (statement < body.statementCount) limit MAX_MINIMAL_STATEMENTS {
      long opcode = body.opcodes[statement];
      long firstType = helperSourceType(
        opcode,
        body.operands[statement],
        body.secondaryOperands[statement],
        0,
        body.parameterTypes,
        body.parameterCount
      );
      long secondType = helperSourceType(
        opcode,
        body.operands[statement],
        body.secondaryOperands[statement],
        1,
        body.parameterTypes,
        body.parameterCount
      );
      long thirdType = helperSourceType(
        opcode,
        body.operands[statement],
        body.secondaryOperands[statement],
        2,
        body.parameterTypes,
        body.parameterCount
      );
      long fourthType = helperSourceType(
        opcode,
        body.operands[statement],
        body.secondaryOperands[statement],
        3,
        body.parameterTypes,
        body.parameterCount
      );
      long fifthType = helperSourceType(
        opcode,
        body.operands[statement],
        body.secondaryOperands[statement],
        4,
        body.parameterTypes,
        body.parameterCount
      );
      long sixthType = helperSourceType(
        opcode,
        body.operands[statement],
        body.secondaryOperands[statement],
        5,
        body.parameterTypes,
        body.parameterCount
      );
      long seventhType = helperSourceType(
        opcode,
        body.operands[statement],
        body.secondaryOperands[statement],
        6,
        body.parameterTypes,
        body.parameterCount
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
        cursor = callCursor;
      } else {
        cursor = writeStatementLocalTypes(output, cursor, opcode);
      }

      statement += 1;
    }

    return cursor;
  }

}
