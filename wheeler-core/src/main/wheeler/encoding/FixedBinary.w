//! Reads fixed-width little-endian fields without a dynamic loop.
module wheeler.core.encoding.fixed_binary;

classical class FixedBinary {
  /// Locates the first eight-byte field after a header.
  public const long FIXED_BINARY_FIELD_ONE_OFFSET = 8;
  /// Locates the second eight-byte field after a header.
  public const long FIXED_BINARY_FIELD_TWO_OFFSET = 16;
  /// Locates the third eight-byte field after a header.
  public const long FIXED_BINARY_FIELD_THREE_OFFSET = 24;
  /// Locates the fourth eight-byte field after a header.
  public const long FIXED_BINARY_FIELD_FOUR_OFFSET = 32;

  private const long OCTET_ONE_SCALE = 256;
  private const long OCTET_TWO_SCALE = 65536;
  private const long OCTET_THREE_SCALE = 16777216;
  private const long OCTET_FOUR_SCALE = 4294967296;
  private const long OCTET_FIVE_SCALE = 1099511627776;
  private const long OCTET_SIX_SCALE = 281474976710656;
  private const long OCTET_SEVEN_SCALE = 72057594037927936;

  /// Reads one canonical little-endian four-byte field within signed machine range.
  public long readUnsignedFour(borrow byteview source, long offset) {
    long zero = source[offset];
    long oneOffset = offset + 1;
    long one = source[oneOffset];
    long oneWeighted = one * OCTET_ONE_SCALE;
    long lowPair = zero + oneWeighted;
    long twoOffset = offset + 2;
    long two = source[twoOffset];
    long twoWeighted = two * OCTET_TWO_SCALE;
    long threeOffset = offset + 3;
    long three = source[threeOffset];
    long threeWeighted = three * OCTET_THREE_SCALE;
    long highPair = twoWeighted + threeWeighted;
    return lowPair + highPair;
  }

  /// Reads one canonical little-endian eight-byte field within signed machine range.
  public long readUnsignedEight(borrow byteview source, long offset) {
    long low = readUnsignedFour(source, offset);
    long fourOffset = offset + 4;
    long four = source[fourOffset];
    long fourWeighted = four * OCTET_FOUR_SCALE;
    long lowMiddle = low + fourWeighted;
    long fiveOffset = offset + 5;
    long five = source[fiveOffset];
    long fiveWeighted = five * OCTET_FIVE_SCALE;
    long lowThreeQuarters = lowMiddle + fiveWeighted;
    long sixOffset = offset + 6;
    long six = source[sixOffset];
    long sixWeighted = six * OCTET_SIX_SCALE;
    long sevenOffset = offset + 7;
    long seven = source[sevenOffset];
    long sevenWeighted = seven * OCTET_SEVEN_SCALE;
    long highPair = sixWeighted + sevenWeighted;
    return lowThreeQuarters + highPair;
  }
}
