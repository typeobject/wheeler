//! Compares the packed wires of the seven-owner source-order network.

module wheeler.compiler.helper_source_network;

classical class HelperSourceNetwork {
  /// Leaves three source-index bits below one bounded source start.
  public const long SOURCE_PACK_SCALE = 8;

  /// Returns the lower packed source without requiring a local-pair guard form.
  public long lowerPacked(long left, long right) {
    long order = right - left;
    if (order < 0) {
      return right;
    }

    return left;
  }

  /// Returns the upper packed source without requiring a local-pair guard form.
  public long upperPacked(long left, long right) {
    long order = left - right;
    if (order < 0) {
      return right;
    }

    return left;
  }

}
