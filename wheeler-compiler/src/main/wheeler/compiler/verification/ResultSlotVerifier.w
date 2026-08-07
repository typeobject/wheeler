//! Verifies bounded scalar result-slot transition operands.
module wheeler.compiler.result_slot_verifier;

import wheeler.core.encoding.fixed_binary;

classical class ResultSlotVerifier {
  /// Checks that the active function declares a result-slot body.
  public boolean resultSlotBodyValid(long resultSlotBody) {
    return resultSlotBody == 1;
  }

  /// Reads the result-slot local index.
  public long resultSlotOperand(borrow byteview artifact, long cursor) {
    long field = cursor + FIXED_BINARY_FIELD_ONE_OFFSET;
    return readUnsignedEight(artifact, field);
  }

  /// Reads the first result-slot source local.
  public long resultSlotSourceOperand(borrow byteview artifact, long cursor) {
    long field = cursor + FIXED_BINARY_FIELD_TWO_OFFSET;
    return readUnsignedEight(artifact, field);
  }

  /// Checks that one source precedes the result slot.
  public boolean resultSlotSourcePrecedes(long resultSlot, long source) {
    return source < resultSlot;
  }

  /// Reads the bounded result-slot operation.
  public long resultSlotOperationOperand(borrow byteview artifact, long cursor) {
    long field = cursor + FIXED_BINARY_FIELD_THREE_OFFSET;
    return readUnsignedEight(artifact, field);
  }

  /// Reads the second result-slot source local.
  public long resultSlotRightSourceOperand(borrow byteview artifact, long cursor) {
    long field = cursor + FIXED_BINARY_FIELD_FOUR_OFFSET;
    return readUnsignedEight(artifact, field);
  }
}
