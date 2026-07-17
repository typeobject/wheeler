package com.typeobject.wheeler.runtime.hybrid;

/** Hard semantic limits for one hybrid run. */
public record HybridRunLimits(int maxEvents, int maxBranches, int maxRetries) {
  public static final HybridRunLimits DEFAULT = new HybridRunLimits(10_000, 64, 16);

  public HybridRunLimits {
    if (maxEvents < 1 || maxEvents > 1_000_000) {
      throw new IllegalArgumentException("maxEvents must be between 1 and 1000000");
    }
    if (maxBranches < 1 || maxBranches > 10_000) {
      throw new IllegalArgumentException("maxBranches must be between 1 and 10000");
    }
    if (maxRetries < 0 || maxRetries > 10_000) {
      throw new IllegalArgumentException("maxRetries must be between 0 and 10000");
    }
  }
}
