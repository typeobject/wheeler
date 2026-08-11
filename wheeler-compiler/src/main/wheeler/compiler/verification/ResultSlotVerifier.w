//! Verifies bounded scalar result-slot transition operands.
module wheeler.compiler.result_slot_verifier;

classical class ResultSlotVerifier {
  private const long RESULT_SLOT_FIELD_ONE_OFFSET = 8;
  private const long RESULT_SLOT_FIELD_TWO_OFFSET = 16;
  private const long RESULT_SLOT_FIELD_THREE_OFFSET = 24;
  private const long RESULT_SLOT_FIELD_FOUR_OFFSET = 32;
  private const long OCTET_ONE_SCALE = 256;
  private const long OCTET_TWO_SCALE = 65536;
  private const long OCTET_THREE_SCALE = 16777216;
  private const long OCTET_FOUR_SCALE = 4294967296;
  private const long OCTET_FIVE_SCALE = 1099511627776;
  private const long OCTET_SIX_SCALE = 281474976710656;
  private const long OCTET_SEVEN_SCALE = 72057594037927936;

  private long readResultSlotField(borrow byteview artifact, long offset) {
    long zero = artifact[offset];
    long oneOffset = offset + 1;
    long one = artifact[oneOffset];
    long oneWeighted = one * OCTET_ONE_SCALE;
    long lowPair = zero + oneWeighted;
    long twoOffset = offset + 2;
    long two = artifact[twoOffset];
    long twoWeighted = two * OCTET_TWO_SCALE;
    long threeOffset = offset + 3;
    long three = artifact[threeOffset];
    long threeWeighted = three * OCTET_THREE_SCALE;
    long lowThree = lowPair + twoWeighted;
    long lowFour = lowThree + threeWeighted;
    long fourOffset = offset + 4;
    long four = artifact[fourOffset];
    long fourWeighted = four * OCTET_FOUR_SCALE;
    long lowFive = lowFour + fourWeighted;
    long fiveOffset = offset + 5;
    long five = artifact[fiveOffset];
    long fiveWeighted = five * OCTET_FIVE_SCALE;
    long lowSix = lowFive + fiveWeighted;
    long sixOffset = offset + 6;
    long six = artifact[sixOffset];
    long sixWeighted = six * OCTET_SIX_SCALE;
    long sevenOffset = offset + 7;
    long seven = artifact[sevenOffset];
    long sevenWeighted = seven * OCTET_SEVEN_SCALE;
    long lowSeven = lowSix + sixWeighted;
    return lowSeven + sevenWeighted;
  }

  /// Checks that the active function declares a result-slot body.
  public boolean resultSlotBodyValid(long resultSlotBody) {
    return resultSlotBody == 1;
  }

  /// Reads the result-slot local index.
  public long resultSlotOperand(borrow byteview artifact, long cursor) {
    long field = cursor + RESULT_SLOT_FIELD_ONE_OFFSET;
    return readResultSlotField(artifact, field);
  }

  /// Reads the first result-slot source local.
  public long resultSlotSourceOperand(borrow byteview artifact, long cursor) {
    long field = cursor + RESULT_SLOT_FIELD_TWO_OFFSET;
    return readResultSlotField(artifact, field);
  }

  /// Checks that one source precedes the result slot.
  public boolean resultSlotSourcePrecedes(long resultSlot, long source) {
    return source < resultSlot;
  }

  /// Reads the bounded result-slot operation.
  public long resultSlotOperationOperand(borrow byteview artifact, long cursor) {
    long field = cursor + RESULT_SLOT_FIELD_THREE_OFFSET;
    return readResultSlotField(artifact, field);
  }

  /// Reads the second result-slot source local.
  public long resultSlotRightSourceOperand(borrow byteview artifact, long cursor) {
    long field = cursor + RESULT_SLOT_FIELD_FOUR_OFFSET;
    return readResultSlotField(artifact, field);
  }
}
