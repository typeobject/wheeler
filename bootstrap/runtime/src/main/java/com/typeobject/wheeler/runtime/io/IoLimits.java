package com.typeobject.wheeler.runtime.io;

/** Closed resource limits for one deterministic I/O scope. */
public record IoLimits(
    int maxOperations,
    int maxCompletions,
    int maxBatchSize,
    int maxGraphNodes,
    int maxGraphEdges,
    long maxWork) {
  private static final int HARD_COLLECTION_LIMIT = 10_000;

  public IoLimits {
    boundedPositive("maxOperations", maxOperations);
    boundedPositive("maxCompletions", maxCompletions);
    boundedPositive("maxBatchSize", maxBatchSize);
    boundedPositive("maxGraphNodes", maxGraphNodes);
    boundedPositive("maxGraphEdges", maxGraphEdges);
    if (maxWork < 1 || maxWork > 1_000_000_000L) {
      throw new IllegalArgumentException("maxWork must be between 1 and 1000000000");
    }
    if (maxCompletions < maxOperations) {
      throw new IllegalArgumentException("completion capacity cannot be below operation capacity");
    }
  }

  private static void boundedPositive(String name, int value) {
    if (value < 1 || value > HARD_COLLECTION_LIMIT) {
      throw new IllegalArgumentException(name + " must be between 1 and 10000");
    }
  }
}
