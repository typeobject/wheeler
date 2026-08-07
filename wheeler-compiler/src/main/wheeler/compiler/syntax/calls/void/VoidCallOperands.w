//! Decodes bounded resolved void-call source operands.

module wheeler.compiler.void_call_operands;

import wheeler.compiler.void_call_kinds;

classical class VoidCallOperands {
  /// Names the first source stored in the trailing packed operand.
  private const long VOID_CALL_TRAILING_SOURCE = 4;
  /// Selects the third source digit in one packed operand.
  private const long VOID_CALL_SOURCE_SCALE_TWO = 65536;
  /// Selects the fourth source digit in one packed operand.
  private const long VOID_CALL_SOURCE_SCALE_THREE = 16777216;

  private long packedVoidCallSource(long packed, long source, long first) {
    long index = source - first;
    if (index == 0) {
      return packed % VOID_CALL_LOCAL_SOURCE_COUNT;
    }

    if (index == 1) {
      return packed / VOID_CALL_LOCAL_SOURCE_COUNT % VOID_CALL_LOCAL_SOURCE_COUNT;
    }

    if (index == 2) {
      return packed / VOID_CALL_SOURCE_SCALE_TWO % VOID_CALL_LOCAL_SOURCE_COUNT;
    }

    return packed / VOID_CALL_SOURCE_SCALE_THREE % VOID_CALL_LOCAL_SOURCE_COUNT;
  }

  /// Decodes one validated void-call source from its bounded operands.
  public long voidCallSource(long kind, long operand, long secondaryOperand, long source) {
    long arity = voidCallArity(kind);
    if (source < 0) {
      return -1;
    }

    if (source < arity) {} else {
      return -1;
    }

    if (arity < VOID_CALL_TRAILING_SOURCE) {
      if (source == 0) {
        return operand;
      }

      if (source == 1) {
        return secondaryOperand;
      }

      return voidCallThirdSource(kind);
    }

    if (source < VOID_CALL_TRAILING_SOURCE) {
      return packedVoidCallSource(operand, source, 0);
    }

    return packedVoidCallSource(secondaryOperand, source, VOID_CALL_TRAILING_SOURCE);
  }
}
