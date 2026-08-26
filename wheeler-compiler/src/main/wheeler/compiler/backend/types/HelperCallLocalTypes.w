//! Encodes local type windows for bounded helper-call forms.

module wheeler.compiler.helper_call_local_types;

import wheeler.compiler.assignment_call_arities;
import wheeler.compiler.assignment_call_identities;
import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.call_arguments;
import wheeler.compiler.call_forms;
import wheeler.compiler.conditionals;
import wheeler.compiler.early_comparison_forms;
import wheeler.compiler.early_utf8_call_forms;
import wheeler.compiler.encoding;
import wheeler.compiler.four_argument_calls;
import wheeler.compiler.literal_comparison_operations;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_type_encoding;
import wheeler.compiler.named_comparison_kinds;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.owned_storage_forms;
import wheeler.compiler.owned_utf8_copy_loops;
import wheeler.compiler.resolved_boolean_literal_assertions;
import wheeler.compiler.resolved_boolean_literal_comparisons;
import wheeler.compiler.resolved_early_result_kinds;
import wheeler.compiler.resolved_less_than_assertions;
import wheeler.compiler.resolved_literal_comparison_kinds;
import wheeler.compiler.resolved_local_assignments;
import wheeler.compiler.resolved_local_conditional_kinds;
import wheeler.compiler.resolved_local_copy_kinds;
import wheeler.compiler.resolved_local_equality_kinds;
import wheeler.compiler.resolved_local_inequality_kinds;
import wheeler.compiler.resolved_local_less_than_kinds;
import wheeler.compiler.resolved_local_literal_comparisons;
import wheeler.compiler.resolved_local_loop_kinds;
import wheeler.compiler.resolved_local_pair_assertions;
import wheeler.compiler.resolved_local_returns;
import wheeler.compiler.resolved_local_updates;
import wheeler.compiler.resolved_return_call_kinds;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.three_argument_calls;
import wheeler.compiler.two_argument_call_kinds;
import wheeler.compiler.type_codes;
import wheeler.compiler.void_call_kinds;
import wheeler.compiler.wide_local_calls;

classical class HelperCallLocalTypes {
  private const long MAX_STATEMENT_LOCALS = 16;

  /// Writes canonical local types for a helper call with its resolved signature types.
  public long writeHelperCallLocalTypes(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long resultType,
    long firstSourceType,
    long secondSourceType,
    long thirdSourceType,
    long fourthSourceType,
    long fifthSourceType,
    long sixthSourceType,
    long seventhSourceType
  ) {
    if (scalarResultCallStatement(opcode)) {
      resultType = TYPE_SIGNED;
      if (booleanResultCallStatement(opcode)) {
        resultType = TYPE_BOOLEAN;
      }
    }

    if (earlyUtf8Call(opcode)) {
      cursor = writeSignedLocalType(output, cursor);
      cursor = writeSignedLocalType(output, cursor);
      cursor = writeBooleanLocalType(output, cursor);
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      return writeLocalType(output, cursor, TYPE_UTF8);
    }

    long voidArity = voidCallArity(opcode);
    if (voidArity == 0) {
      return cursor;
    }

    if (0 < voidArity) {
      long voidArgument = 0;
      while (voidArgument < voidArity) limit MAX_VOID_CALL_ARGUMENTS {
        cursor = writeLocalType(
          output,
          cursor,
          callSourceType(
            voidArgument,
            firstSourceType,
            secondSourceType,
            thirdSourceType,
            fourthSourceType,
            fifthSourceType,
            sixthSourceType,
            seventhSourceType
          )
        );
        voidArgument += 1;
      }

      voidArgument = 0;
      while (voidArgument < voidArity) limit MAX_VOID_CALL_ARGUMENTS {
        cursor = writeLocalType(
          output,
          cursor,
          callSourceType(
            voidArgument,
            firstSourceType,
            secondSourceType,
            thirdSourceType,
            fourthSourceType,
            fifthSourceType,
            sixthSourceType,
            seventhSourceType
          )
        );
        voidArgument += 1;
      }

      return cursor;
    }

    if (opcode == STATEMENT_SET_WORD) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_SET_BYTE) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_SET_OWNED_BYTE) {
      cursor = writeLocalType(output, cursor, TYPE_BYTES);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_MAP_PUT) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_LOCAL_MAP_GET) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_LOCAL_MAP_HAS) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      cursor = writeLocalType(output, cursor, TYPE_BOOLEAN);
      return writeLocalType(output, cursor, TYPE_BOOLEAN);
    }

    if (opcode == STATEMENT_RETURN_MAP_GET) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_RETURN_MAP_HAS) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      return writeLocalType(output, cursor, TYPE_BOOLEAN);
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_GET) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_RETURN_BUFFER_GET) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_LOCAL_UTF8_WIDTH) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_LOCAL_UTF8_SCALAR) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_RETURN_UTF8_SCALAR) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_RETURN_UTF8_WIDTH) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_RETURN_BUFFER_LENGTH) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      return writeLocalType(output, cursor, resultType);
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    long assignmentArity = assignmentCallArity(opcode);
    if (-1 < assignmentArity) {
      long assignmentArgument = 0;
      while (assignmentArgument < assignmentArity) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
        cursor = writeLocalType(
          output,
          cursor,
          callSourceType(
            assignmentArgument,
            firstSourceType,
            secondSourceType,
            thirdSourceType,
            fourthSourceType,
            fifthSourceType,
            sixthSourceType,
            seventhSourceType
          )
        );
        assignmentArgument += 1;
      }

      assignmentArgument = 0;
      while (assignmentArgument < assignmentArity) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
        cursor = writeLocalType(
          output,
          cursor,
          callSourceType(
            assignmentArgument,
            firstSourceType,
            secondSourceType,
            thirdSourceType,
            fourthSourceType,
            fifthSourceType,
            sixthSourceType,
            seventhSourceType
          )
        );
        assignmentArgument += 1;
      }

      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    long arity = returnHelperCallArity(opcode);
    if (oneArgumentCallStatement(opcode)) {
      arity = 1;
    }

    if (twoArgumentCallStatement(opcode)) {
      arity = 2;
    }

    if (threeArgumentCallStatement(opcode)) {
      arity = 3;
    }

    if (fourArgumentCallStatement(opcode)) {
      arity = 4;
    }

    if (packedWideLocalCall(opcode)) {
      arity = wideLocalCallArity(opcode);
    }

    if (arity == 0) {
      return writeLocalType(output, cursor, resultType);
    }

    if (arity == 1) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, resultType);
      if (oneArgumentCallStatement(opcode)) {
        return writeLocalType(output, cursor, resultType);
      }

      return cursor;
    }

    if (4 < arity) {
      long argument = 0;
      while (argument < arity) limit MAX_FORWARDED_SCALAR_ARGUMENTS {
        long sourceType = callSourceType(
          argument,
          firstSourceType,
          secondSourceType,
          thirdSourceType,
          fourthSourceType,
          fifthSourceType,
          sixthSourceType,
          seventhSourceType
        );
        cursor = writeLocalType(output, cursor, sourceType);
        argument += 1;
      }

      argument = 0;
      while (argument < arity) limit MAX_FORWARDED_SCALAR_ARGUMENTS {
        long transferType = callSourceType(
          argument,
          firstSourceType,
          secondSourceType,
          thirdSourceType,
          fourthSourceType,
          fifthSourceType,
          sixthSourceType,
          seventhSourceType
        );
        cursor = writeLocalType(output, cursor, transferType);
        argument += 1;
      }

      cursor = writeLocalType(output, cursor, resultType);
      if (packedWideLocalCall(opcode)) {
        return writeLocalType(output, cursor, resultType);
      }

      return cursor;
    }

    if (arity == 4) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      cursor = writeLocalType(output, cursor, thirdSourceType);
      cursor = writeLocalType(output, cursor, fourthSourceType);
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      cursor = writeLocalType(output, cursor, thirdSourceType);
      cursor = writeLocalType(output, cursor, fourthSourceType);
      cursor = writeLocalType(output, cursor, resultType);
      if (fourArgumentCallStatement(opcode)) {
        return writeLocalType(output, cursor, resultType);
      }

      return cursor;
    }

    if (arity == 3) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      cursor = writeLocalType(output, cursor, thirdSourceType);
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      cursor = writeLocalType(output, cursor, thirdSourceType);
      cursor = writeLocalType(output, cursor, resultType);
      if (threeArgumentCallStatement(opcode)) {
        return writeLocalType(output, cursor, resultType);
      }

      return cursor;
    }

    if (arity == 2) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, secondSourceType);
      cursor = writeLocalType(output, cursor, resultType);
      if (twoArgumentCallStatement(opcode)) {
        return writeLocalType(output, cursor, resultType);
      }

      return cursor;
    }

    if (resolvedReturnHelperCall(opcode)) {
      cursor = writeLocalType(output, cursor, firstSourceType);
      cursor = writeLocalType(output, cursor, firstSourceType);
      return writeLocalType(output, cursor, resultType);
    }

    return -1;
  }

}
