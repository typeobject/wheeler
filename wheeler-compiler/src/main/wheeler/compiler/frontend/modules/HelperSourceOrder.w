//! Selects helper source frames with one fixed sorting network.

module wheeler.compiler.helper_source_order;

import wheeler.compiler.helper_source_network;

classical class HelperSourceOrder {
  /// Selects one packed key by validated canonical source rank.
  public long helperSourceKeyAtRank(
    long rank,
    long packedZero,
    long packedOne,
    long packedTwo,
    long packedThree,
    long packedFour,
    long packedFive,
    long packedSix
  ) {
    // Sixteen comparators sort seven packed starts. No topology ritual is required.
    long network0Low = lowerPacked(packedZero, packedSix);
    long network0High = upperPacked(packedZero, packedSix);
    long network1Low = lowerPacked(packedTwo, packedThree);
    long network1High = upperPacked(packedTwo, packedThree);
    long network2Low = lowerPacked(packedFour, packedFive);
    long network2High = upperPacked(packedFour, packedFive);
    long network3Low = lowerPacked(network0Low, network1Low);
    long network3High = upperPacked(network0Low, network1Low);
    long network4Low = lowerPacked(packedOne, network2Low);
    long network4High = upperPacked(packedOne, network2Low);
    long network5Low = lowerPacked(network1High, network0High);
    long network5High = upperPacked(network1High, network0High);
    long network6Low = lowerPacked(network3Low, network4Low);
    long network6High = upperPacked(network3Low, network4Low);
    long network7Low = lowerPacked(network3High, network2High);
    long network7High = upperPacked(network3High, network2High);
    long network8Low = lowerPacked(network5Low, network4High);
    long network8High = upperPacked(network5Low, network4High);
    long network9Low = lowerPacked(network6High, network7Low);
    long network9High = upperPacked(network6High, network7Low);
    long network10Low = lowerPacked(network8High, network5High);
    long network10High = upperPacked(network8High, network5High);
    long network11Low = lowerPacked(network9High, network8Low);
    long network11High = upperPacked(network9High, network8Low);
    long network12Low = lowerPacked(network10Low, network7High);
    long network12High = upperPacked(network10Low, network7High);
    long network13Low = lowerPacked(network9Low, network11Low);
    long network13High = upperPacked(network9Low, network11Low);
    long network14Low = lowerPacked(network11High, network12Low);
    long network14High = upperPacked(network11High, network12Low);
    long network15Low = lowerPacked(network12High, network10High);
    long network15High = upperPacked(network12High, network10High);

    if (rank == 0) {
      return network6Low;
    }

    if (rank == 1) {
      return network13Low;
    }

    if (rank == 2) {
      return network13High;
    }

    if (rank == 3) {
      return network14Low;
    }

    if (rank == 4) {
      return network14High;
    }

    if (rank == 5) {
      return network15Low;
    }

    return network15High;
  }
}
