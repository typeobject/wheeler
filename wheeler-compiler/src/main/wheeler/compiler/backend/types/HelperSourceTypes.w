//! Selects canonical source types for typed helper statements.

module wheeler.compiler.helper_source_types;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.call_argument_sources;
import wheeler.compiler.early_utf8_call_forms;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.resolved_return_call_kinds;
import wheeler.compiler.type_codes;
import wheeler.compiler.void_call_kinds;
import wheeler.compiler.wide_return_sources;

classical class HelperSourceTypes {
  private long sequenceLocalType(long[16] parameterTypes, long parameterCount, long local) {
    if (local < 0) {
      return TYPE_SIGNED;
    }

    long remaining = parameterCount - local;
    if (remaining < 1) {
      return TYPE_SIGNED;
    }

    return parameterTypes[local];
  }

  private long firstSource(long opcode, long operand) {
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

    long returnArity = returnHelperCallArity(opcode);
    if (4 < returnArity) {
      return wideReturnFirstSource(operand);
    }

    long helperSource = returnHelperCallFirstSource(opcode);
    if (returnArity == 1) {
      return helperSource;
    }

    if (returnArity == 4) {
      return helperSource;
    }

    if (returnArity == 3) {
      return helperSource;
    }

    if (returnArity == 2) {
      return helperSource - RETURN_HELPER_CALL_TWO_SOURCE_OFFSET;
    }

    return -1;
  }

  private long thirdSource(long opcode, long operand) {
    long directSource = voidCallThirdSource(opcode);
    long returnArity = returnHelperCallArity(opcode);
    if (4 < returnArity) {
      return wideReturnThirdSource(operand);
    }

    long helperSource = returnHelperCallThirdSource(opcode);
    if (returnArity == 3) {
      return helperSource;
    }

    if (returnArity == 4) {
      return helperSource;
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

    long returnArity = returnHelperCallArity(opcode);
    if (4 < returnArity) {
      return wideReturnSecondSource(operand);
    }

    long helperSource = returnHelperCallSecondSource(opcode);
    if (returnArity == 2) {
      return helperSource;
    }

    if (returnArity == 3) {
      return helperSource;
    }

    if (returnArity == 4) {
      return helperSource;
    }

    return -1;
  }

  private long fourthSource(long opcode, long operand) {
    long returnArity = returnHelperCallArity(opcode);
    if (4 < returnArity) {
      return wideReturnFourthSource(operand);
    }

    long helperSource = returnHelperCallFourthSource(opcode);
    if (returnArity == 4) {
      return helperSource;
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

  /// Returns the canonical first source type for one typed statement.
  public long helperFirstSourceType(
    long opcode,
    long operand,
    long[16] parameterTypes,
    long parameterCount
  ) {
    if (opcode == STATEMENT_SET_OWNED_BYTE) {
      return TYPE_BYTES;
    }

    long selected = firstSource(opcode, operand);
    return sequenceLocalType(parameterTypes, parameterCount, selected);
  }

  /// Returns the canonical third source type for one typed statement.
  public long helperThirdSourceType(
    long opcode,
    long operand,
    long[16] parameterTypes,
    long parameterCount
  ) {
    long selected = thirdSource(opcode, operand);
    return sequenceLocalType(parameterTypes, parameterCount, selected);
  }

  /// Returns the canonical second source type for one typed statement.
  public long helperSecondSourceType(
    long opcode,
    long operand,
    long secondaryOperand,
    long[16] parameterTypes,
    long parameterCount
  ) {
    long selected = secondSource(opcode, secondaryOperand);
    if (4 < returnHelperCallArity(opcode)) {
      selected = wideReturnSecondSource(operand);
    }

    return sequenceLocalType(parameterTypes, parameterCount, selected);
  }

  /// Returns the canonical fourth source type for one typed statement.
  public long helperFourthSourceType(
    long opcode,
    long operand,
    long[16] parameterTypes,
    long parameterCount
  ) {
    long selected = fourthSource(opcode, operand);
    return sequenceLocalType(parameterTypes, parameterCount, selected);
  }

  /// Returns the canonical fifth source type for one typed statement.
  public long helperFifthSourceType(
    long opcode,
    long operand,
    long[16] parameterTypes,
    long parameterCount
  ) {
    long selected = fifthSource(opcode, operand);
    return sequenceLocalType(parameterTypes, parameterCount, selected);
  }

  /// Returns the canonical sixth source type for one typed statement.
  public long helperSixthSourceType(
    long opcode,
    long operand,
    long[16] parameterTypes,
    long parameterCount
  ) {
    long selected = sixthSource(opcode, operand);
    return sequenceLocalType(parameterTypes, parameterCount, selected);
  }

  /// Returns the canonical seventh source type for one typed statement.
  public long helperSeventhSourceType(
    long opcode,
    long operand,
    long[16] parameterTypes,
    long parameterCount
  ) {
    long selected = seventhSource(opcode, operand);
    return sequenceLocalType(parameterTypes, parameterCount, selected);
  }
}
