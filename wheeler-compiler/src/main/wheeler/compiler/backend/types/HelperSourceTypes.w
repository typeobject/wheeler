//! Selects canonical source types for typed helper statements.

module wheeler.compiler.helper_source_types;

import wheeler.compiler.assignment_call_kinds;
import wheeler.compiler.assignment_call_operands;
import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.call_argument_sources;
import wheeler.compiler.call_forms;
import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.early_utf8_call_forms;
import wheeler.compiler.four_argument_calls;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_resolution;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.resolved_local_copy_kinds;
import wheeler.compiler.resolved_local_returns;
import wheeler.compiler.resolved_return_call_kinds;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.three_argument_calls;
import wheeler.compiler.two_argument_call_kinds;
import wheeler.compiler.type_codes;
import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_operands;
import wheeler.compiler.wide_local_calls;
import wheeler.compiler.wide_return_sources;

classical class HelperSourceTypes {
  /// Returns one exact named type or the signed expression-temporary type.
  public long helperLocalType(HelperBody body, long local) {
    if (local < 0) {
      return TYPE_SIGNED;
    }

    if (local < body.parameterCount) {
      return body.parameterTypes[local];
    }

    long localBase = body.parameterCount;
    long statement = 0;
    while (statement < body.statementCount) limit MAX_MINIMAL_STATEMENTS {
      long opcode = body.opcodes[statement];
      long result = statementResultLocal(opcode, localBase);
      if (result == local) {
        if (opcode == STATEMENT_LOCAL_BYTES_ALLOCATE_NAMED) {
          return TYPE_BYTES;
        }

        if (booleanResultCallStatement(opcode)) {
          return TYPE_BOOLEAN;
        }

        if (resolvedLocalBooleanCopy(opcode)) {
          return TYPE_BOOLEAN;
        }

        if (resolvedLocalBooleanNot(opcode)) {
          return TYPE_BOOLEAN;
        }

        if (declarationMatches(opcode, false)) {
          return TYPE_BOOLEAN;
        }

        if (declarationMatches(opcode, true)) {
          return TYPE_SIGNED;
        }

        return TYPE_SIGNED;
      }

      localBase += statementLocalCount(opcode);
      statement += 1;
    }

    return TYPE_SIGNED;
  }

  private long firstSource(long opcode, long operand) {
    if (resolvedLocalLongCopy(opcode)) {
      return opcode - STATEMENT_LOCAL_LONG_COPY_BASE;
    }

    if (resolvedLocalBooleanCopy(opcode)) {
      return opcode - STATEMENT_LOCAL_BOOLEAN_COPY_BASE;
    }

    if (resolvedLocalBooleanNot(opcode)) {
      return opcode - STATEMENT_LOCAL_BOOLEAN_NOT_BASE;
    }

    if (resolvedLocalReturn(opcode)) {
      return resolvedLocalReturnSource(opcode);
    }

    if (earlyUtf8Call(opcode)) {
      return operand / EARLY_UTF8_CALL_SOURCE_SCALE;
    }

    long callArity = voidCallArity(opcode);
    if (callArity == 1) {
      return operand;
    }

    if (callArity == 2) {
      return operand;
    }

    if (callArity == 3) {
      return operand;
    }

    if (opcode == STATEMENT_SET_WORD) {
      return operand;
    }

    if (opcode == STATEMENT_SET_BYTE) {
      return operand;
    }

    if (opcode == STATEMENT_SET_OWNED_BYTE) {
      return operand;
    }

    if (opcode == STATEMENT_MAP_PUT) {
      return operand;
    }

    if (opcode == STATEMENT_LOCAL_MAP_GET) {
      return operand;
    }

    if (opcode == STATEMENT_LOCAL_MAP_HAS) {
      return operand;
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_GET) {
      return operand;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_GET) {
      return operand;
    }

    if (opcode == STATEMENT_RETURN_UTF8_SCALAR) {
      return operand;
    }

    if (opcode == STATEMENT_RETURN_UTF8_WIDTH) {
      return operand;
    }

    if (opcode == STATEMENT_RETURN_MAP_GET) {
      return operand;
    }

    if (opcode == STATEMENT_RETURN_MAP_HAS) {
      return operand;
    }

    if (opcode == STATEMENT_LOCAL_UTF8_WIDTH) {
      return operand;
    }

    if (opcode == STATEMENT_LOCAL_UTF8_SCALAR) {
      return operand;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_LENGTH) {
      return operand;
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH) {
      return operand;
    }

    if (oneArgumentCallNamed(opcode)) {
      return operand;
    }

    if (twoArgumentCallFirstNamed(opcode)) {
      return operand;
    }

    if (threeArgumentCallStatement(opcode)) {
      return operand;
    }

    if (fourArgumentCallStatement(opcode)) {
      return operand;
    }

    long returnArity = returnHelperCallArity(opcode);
    if (4 < returnArity) {
      return wideReturnFirstSource(operand);
    }

    if (returnArity == 1) {
      return returnHelperCallFirstSource(opcode);
    }

    if (returnArity == 4) {
      return returnHelperCallFirstSource(opcode);
    }

    if (returnArity == 3) {
      return returnHelperCallFirstSource(opcode);
    }

    if (returnArity == 2) {
      return returnHelperCallFirstSource(opcode) - RETURN_HELPER_CALL_TWO_SOURCE_OFFSET;
    }

    return -1;
  }

  private long thirdSource(long opcode, long operand) {
    if (threeArgumentCallStatement(opcode)) {
      return threeArgumentThirdSource(opcode);
    }

    if (fourArgumentCallStatement(opcode)) {
      return fourArgumentCallThirdSource(opcode);
    }

    long directSource = voidCallThirdSource(opcode);
    long returnArity = returnHelperCallArity(opcode);
    if (4 < returnArity) {
      return wideReturnThirdSource(operand);
    }

    if (returnArity == 3) {
      return returnHelperCallThirdSource(opcode);
    }

    if (returnArity == 4) {
      return returnHelperCallThirdSource(opcode);
    }

    return directSource;
  }

  private long secondSource(long opcode, long operand) {
    if (earlyUtf8Call(opcode)) {
      return operand % EARLY_UTF8_CALL_SOURCE_SCALE;
    }

    long callArity = voidCallArity(opcode);
    if (callArity == 2) {
      return operand;
    }

    if (opcode == STATEMENT_LOCAL_MAP_GET) {
      return operand;
    }

    if (opcode == STATEMENT_LOCAL_MAP_HAS) {
      return operand;
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_GET) {
      return operand;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_GET) {
      return operand;
    }

    if (opcode == STATEMENT_RETURN_UTF8_SCALAR) {
      return operand;
    }

    if (opcode == STATEMENT_RETURN_UTF8_WIDTH) {
      return operand;
    }

    if (opcode == STATEMENT_RETURN_MAP_GET) {
      return operand;
    }

    if (opcode == STATEMENT_RETURN_MAP_HAS) {
      return operand;
    }

    if (opcode == STATEMENT_LOCAL_UTF8_WIDTH) {
      return operand;
    }

    if (opcode == STATEMENT_LOCAL_UTF8_SCALAR) {
      return operand;
    }

    if (twoArgumentCallSecondNamed(opcode)) {
      return operand;
    }

    if (threeArgumentCallStatement(opcode)) {
      return operand;
    }

    if (fourArgumentCallStatement(opcode)) {
      return operand;
    }

    long returnArity = returnHelperCallArity(opcode);
    if (4 < returnArity) {
      return wideReturnSecondSource(operand);
    }

    if (returnArity == 2) {
      return returnHelperCallSecondSource(opcode);
    }

    if (returnArity == 3) {
      return returnHelperCallSecondSource(opcode);
    }

    if (returnArity == 4) {
      return returnHelperCallSecondSource(opcode);
    }

    return -1;
  }

  private long fourthSource(long opcode, long operand) {
    if (fourArgumentCallStatement(opcode)) {
      return fourArgumentCallFourthSource(opcode);
    }

    long returnArity = returnHelperCallArity(opcode);
    if (4 < returnArity) {
      return wideReturnFourthSource(operand);
    }

    if (returnArity == 4) {
      return returnHelperCallFourthSource(opcode);
    }

    return -1;
  }

  private long fifthSource(long opcode, long operand) {
    if (4 < returnHelperCallArity(opcode)) {
      return wideReturnFifthSource(operand);
    }

    return -1;
  }

  private long sixthSource(long opcode, long operand) {
    if (5 < returnHelperCallArity(opcode)) {
      return wideReturnSixthSource(operand);
    }

    return -1;
  }

  private long seventhSource(long opcode, long operand) {
    if (6 < returnHelperCallArity(opcode)) {
      return wideReturnSeventhSource(operand);
    }

    return -1;
  }

  private long statementSource(long opcode, long operand, long secondaryOperand, long source) {
    if (assignmentCallStatement(opcode)) {
      return assignmentCallSource(opcode, operand, secondaryOperand, source);
    }

    if (voidCallStatement(opcode)) {
      return voidCallSource(opcode, operand, secondaryOperand, source);
    }

    if (wideLocalCallStatement(opcode)) {
      return wideLocalCallSource(opcode, operand, secondaryOperand, source);
    }

    if (source == 0) {
      return firstSource(opcode, operand);
    }

    if (source == 1) {
      if (4 < returnHelperCallArity(opcode)) {
        return wideReturnSecondSource(operand);
      }

      return secondSource(opcode, secondaryOperand);
    }

    if (source == 2) {
      return thirdSource(opcode, operand);
    }

    if (source == 3) {
      return fourthSource(opcode, operand);
    }

    if (source == 4) {
      return fifthSource(opcode, secondaryOperand);
    }

    if (source == 5) {
      return sixthSource(opcode, secondaryOperand);
    }

    return seventhSource(opcode, secondaryOperand);
  }

  private boolean localDeclaredBefore(HelperBody body, long statement, long local) {
    if (local < 0) {
      return false;
    }

    if (local < body.parameterCount) {
      return true;
    }

    long localBase = body.parameterCount;
    long previous = 0;
    while (previous < statement) limit MAX_MINIMAL_STATEMENTS {
      if (statementResultLocal(body.opcodes[previous], localBase) == local) {
        return true;
      }

      localBase += statementLocalCount(body.opcodes[previous]);
      previous += 1;
    }

    return false;
  }

  /// Checks whether every source names a parameter or prior statement result.
  public boolean statementUsesDeclaredSources(HelperBody body, long statement) {
    long source = 0;
    boolean found = false;
    while (source < 7) limit 7 {
      long selected = statementSource(
        body.opcodes[statement],
        body.operands[statement],
        body.secondaryOperands[statement],
        source
      );
      if (-1 < selected) {
        if (!localDeclaredBefore(body, statement, selected)) {
          return false;
        }

        found = true;
      }

      source += 1;
    }

    return found;
  }

  /// Returns one canonical source type for a typed statement.
  public long helperSourceType(
    long opcode,
    long operand,
    long secondaryOperand,
    long source,
    HelperBody body
  ) {
    if (source == 0) {
      if (opcode == STATEMENT_SET_OWNED_BYTE) {
        return TYPE_BYTES;
      }
    }

    if (oneArgumentBooleanCall(opcode)) {
      return TYPE_BOOLEAN;
    }

    if (twoArgumentBooleanCall(opcode)) {
      return TYPE_BOOLEAN;
    }

    return helperLocalType(body, statementSource(opcode, operand, secondaryOperand, source));
  }
}
