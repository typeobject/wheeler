//! Decodes bounded resolved void-call source operands.

module wheeler.compiler.void_call_operands;

import wheeler.compiler.void_call_kinds;

classical class VoidCallOperands {
  /// Names the positive gap between one valid source and its arity bound.
  private const long VOID_CALL_MINIMUM_SOURCE_GAP = 1;
  /// Names the first source stored in the trailing packed operand.
  private const long VOID_CALL_TRAILING_SOURCE = 4;
  /// Selects the third source digit in one packed operand.
  private const long VOID_CALL_SOURCE_SCALE_TWO = 65536;
  /// Selects the fourth source digit in one packed operand.
  private const long VOID_CALL_SOURCE_SCALE_THREE = 16777216;

  /// Decodes one source from a call with fewer than four arguments.
  private long narrowVoidCallSource(long kind, long operand, long secondaryOperand, long source) {
    if (source == 0) {
      return operand;
    }

    if (source == 1) {
      return secondaryOperand;
    }

    return voidCallThirdSource(kind);
  }

  /// Decodes one source digit from a four-source packed operand.
  private long packedVoidCallSource(long packed, long source, long first) {
    long index = source - first;
    long sourceZero = packed % VOID_CALL_LOCAL_SOURCE_COUNT;
    long scaledOne = packed / VOID_CALL_LOCAL_SOURCE_COUNT;
    long sourceOne = scaledOne % VOID_CALL_LOCAL_SOURCE_COUNT;
    long scaledTwo = packed / VOID_CALL_SOURCE_SCALE_TWO;
    long sourceTwo = scaledTwo % VOID_CALL_LOCAL_SOURCE_COUNT;
    long scaledThree = packed / VOID_CALL_SOURCE_SCALE_THREE;
    long sourceThree = scaledThree % VOID_CALL_LOCAL_SOURCE_COUNT;
    if (index == 0) {
      return sourceZero;
    }

    if (index == 1) {
      return sourceOne;
    }

    if (index == 2) {
      return sourceTwo;
    }

    return sourceThree;
  }

  /// Decodes one validated void-call source from its bounded operands.
  public long voidCallSource(long kind, long operand, long secondaryOperand, long source) {
    long arity = voidCallArity(kind);
    if (source < 0) {
      return -1;
    }

    long sourceGap = arity - source;
    if (sourceGap < VOID_CALL_MINIMUM_SOURCE_GAP) {
      return -1;
    }

    long narrowSource = narrowVoidCallSource(kind, operand, secondaryOperand, source);
    long firstSource = 0;
    long trailingStart = VOID_CALL_TRAILING_SOURCE;
    long leadingSource = packedVoidCallSource(operand, source, firstSource);
    long trailingSource = packedVoidCallSource(secondaryOperand, source, trailingStart);
    if (arity < VOID_CALL_TRAILING_SOURCE) {
      return narrowSource;
    }

    if (source < VOID_CALL_TRAILING_SOURCE) {
      return leadingSource;
    }

    return trailingSource;
  }
}
