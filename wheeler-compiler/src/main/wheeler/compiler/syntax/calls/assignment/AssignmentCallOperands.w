//! Decodes bounded packed call-assignment source operands.

module wheeler.compiler.assignment_call_operands;

import wheeler.compiler.assignment_call_arities;
import wheeler.compiler.assignment_call_identities;

classical class AssignmentCallOperands {
  /// Names the positive gap to one source still requiring packed traversal.
  private const long ASSIGNMENT_CALL_MINIMUM_SOURCE_GAP = 1;
  /// Names the first source stored in the trailing packed operand.
  private const long ASSIGNMENT_CALL_TRAILING_SOURCE = 4;

  private long packedSource(long packed, long source, long selected) {
    long remaining = source - selected;
    long decoded = packed % ASSIGNMENT_CALL_SOURCE_RADIX;
    if (remaining < ASSIGNMENT_CALL_MINIMUM_SOURCE_GAP) {
      return decoded;
    }

    long scaled = packed / ASSIGNMENT_CALL_SOURCE_RADIX;
    long next = selected + 1;
    return packedSource(scaled, source, next);
  }

  /// Decodes one source from the two bounded packed operands.
  public long assignmentCallSource(
    long opcode,
    long operand,
    long secondaryOperand,
    long source
  ) {
    long arity = assignmentCallArity(opcode);
    if (source < 0) {
      return -1;
    }

    long sourceGap = arity - source;
    if (sourceGap < ASSIGNMENT_CALL_MINIMUM_SOURCE_GAP) {
      return -1;
    }

    long firstSource = 0;
    long trailingStart = ASSIGNMENT_CALL_TRAILING_SOURCE;
    long leadingSource = packedSource(operand, source, firstSource);
    long trailingSource = packedSource(secondaryOperand, source, trailingStart);
    if (source < ASSIGNMENT_CALL_TRAILING_SOURCE) {
      return leadingSource;
    }

    return trailingSource;
  }
}
