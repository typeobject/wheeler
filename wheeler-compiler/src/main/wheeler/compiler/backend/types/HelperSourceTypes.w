//! Selects canonical source types for typed helper statements.

module wheeler.compiler.helper_source_types;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.resolved_return_call_kinds;
import wheeler.compiler.type_codes;
import wheeler.compiler.void_call_kinds;

classical class HelperSourceTypes {
  private long sequenceLocalType(long[16] parameterTypes, long parameterCount, long local) {
    if (local < 0) {} else {
      if (local < parameterCount) {
        return parameterTypes[local];
      }
    }

    return TYPE_SIGNED;
  }

  /// Returns the canonical first source type for one typed statement.
  public long helperFirstSourceType(
    long opcode,
    long operand,
    long[16] parameterTypes,
    long parameterCount
  ) {
    if (0 < voidCallArity(opcode)) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_SET_WORD) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_SET_BYTE) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_MAP_PUT) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_LOCAL_MAP_GET) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_LOCAL_MAP_HAS) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_GET) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_RETURN_BUFFER_GET) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_RETURN_UTF8_SCALAR) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_RETURN_UTF8_WIDTH) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_RETURN_MAP_GET) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_RETURN_MAP_HAS) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_LOCAL_UTF8_WIDTH) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_LOCAL_UTF8_SCALAR) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_RETURN_BUFFER_LENGTH) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH) {
      return sequenceLocalType(parameterTypes, parameterCount, operand);
    }

    if (returnHelperCallArity(opcode) == 1) {
      return sequenceLocalType(
        parameterTypes,
        parameterCount,
        returnHelperCallFirstSource(opcode)
      );
    }

    if (returnHelperCallArity(opcode) == 3) {
      return sequenceLocalType(
        parameterTypes,
        parameterCount,
        returnHelperCallFirstSource(opcode)
      );
    }

    if (returnHelperCallArity(opcode) == 2) {
      return sequenceLocalType(
        parameterTypes,
        parameterCount,
        returnHelperCallFirstSource(opcode) - RETURN_HELPER_CALL_TWO_SOURCE_OFFSET
      );
    }

    return TYPE_SIGNED;
  }

  /// Returns the canonical third source type for one typed statement.
  public long helperThirdSourceType(long opcode, long[16] parameterTypes, long parameterCount) {
    long thirdSource = voidCallThirdSource(opcode);
    if (returnHelperCallArity(opcode) == 3) {
      thirdSource = returnHelperCallThirdSource(opcode);
    }

    if (-1 < thirdSource) {
      return sequenceLocalType(parameterTypes, parameterCount, thirdSource);
    }

    return TYPE_SIGNED;
  }

  /// Returns the canonical second source type for one typed statement.
  public long helperSecondSourceType(
    long opcode,
    long secondaryOperand,
    long[16] parameterTypes,
    long parameterCount
  ) {
    if (voidCallArity(opcode) == 2) {
      return sequenceLocalType(parameterTypes, parameterCount, secondaryOperand);
    }

    if (opcode == STATEMENT_LOCAL_MAP_GET) {
      return sequenceLocalType(parameterTypes, parameterCount, secondaryOperand);
    }

    if (opcode == STATEMENT_LOCAL_MAP_HAS) {
      return sequenceLocalType(parameterTypes, parameterCount, secondaryOperand);
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_GET) {
      return sequenceLocalType(parameterTypes, parameterCount, secondaryOperand);
    }

    if (opcode == STATEMENT_RETURN_BUFFER_GET) {
      return sequenceLocalType(parameterTypes, parameterCount, secondaryOperand);
    }

    if (opcode == STATEMENT_RETURN_UTF8_SCALAR) {
      return sequenceLocalType(parameterTypes, parameterCount, secondaryOperand);
    }

    if (opcode == STATEMENT_RETURN_UTF8_WIDTH) {
      return sequenceLocalType(parameterTypes, parameterCount, secondaryOperand);
    }

    if (opcode == STATEMENT_RETURN_MAP_GET) {
      return sequenceLocalType(parameterTypes, parameterCount, secondaryOperand);
    }

    if (opcode == STATEMENT_RETURN_MAP_HAS) {
      return sequenceLocalType(parameterTypes, parameterCount, secondaryOperand);
    }

    if (opcode == STATEMENT_LOCAL_UTF8_WIDTH) {
      return sequenceLocalType(parameterTypes, parameterCount, secondaryOperand);
    }

    if (opcode == STATEMENT_LOCAL_UTF8_SCALAR) {
      return sequenceLocalType(parameterTypes, parameterCount, secondaryOperand);
    }

    long returnArity = returnHelperCallArity(opcode);
    if (returnArity == 2) {
      return sequenceLocalType(
        parameterTypes,
        parameterCount,
        returnHelperCallSecondSource(opcode)
      );
    }

    if (returnArity == 3) {
      return sequenceLocalType(
        parameterTypes,
        parameterCount,
        returnHelperCallSecondSource(opcode)
      );
    }

    return TYPE_SIGNED;
  }
}
