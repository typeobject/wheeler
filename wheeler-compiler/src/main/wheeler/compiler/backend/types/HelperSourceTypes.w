//! Selects canonical source types for typed helper statements.

module wheeler.compiler.helper_source_types;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.call_argument_sources;
import wheeler.compiler.resolved_return_call_kinds;
import wheeler.compiler.type_codes;
import wheeler.compiler.void_call_kinds;

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

    if (twoArgumentCallFirstNamed(opcode)) {
      return operand;
    }

    long returnArity = returnHelperCallArity(opcode);
    long helperSource = returnHelperCallFirstSource(opcode);
    long pairSource = helperSource - RETURN_HELPER_CALL_TWO_SOURCE_OFFSET;
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
      return pairSource;
    }

    return -1;
  }

  private long thirdSource(long opcode) {
    long directSource = voidCallThirdSource(opcode);
    long returnArity = returnHelperCallArity(opcode);
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

  private long fourthSource(long opcode) {
    long returnArity = returnHelperCallArity(opcode);
    long helperSource = returnHelperCallFourthSource(opcode);
    if (returnArity == 4) {
      return helperSource;
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
    long selected = firstSource(opcode, operand);
    return sequenceLocalType(parameterTypes, parameterCount, selected);
  }

  /// Returns the canonical third source type for one typed statement.
  public long helperThirdSourceType(long opcode, long[16] parameterTypes, long parameterCount) {
    long selected = thirdSource(opcode);
    return sequenceLocalType(parameterTypes, parameterCount, selected);
  }

  /// Returns the canonical second source type for one typed statement.
  public long helperSecondSourceType(
    long opcode,
    long secondaryOperand,
    long[16] parameterTypes,
    long parameterCount
  ) {
    long selected = secondSource(opcode, secondaryOperand);
    return sequenceLocalType(parameterTypes, parameterCount, selected);
  }

  /// Returns the canonical fourth source type for one typed statement.
  public long helperFourthSourceType(long opcode, long[16] parameterTypes, long parameterCount) {
    long selected = fourthSource(opcode);
    return sequenceLocalType(parameterTypes, parameterCount, selected);
  }
}
