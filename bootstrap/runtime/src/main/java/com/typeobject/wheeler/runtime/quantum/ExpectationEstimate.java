package com.typeobject.wheeler.runtime.quantum;

/** Finite sampled estimate with standard error and shot provenance. */
public record ExpectationEstimate(double value, double standardError, int shots) {
  public ExpectationEstimate {
    if (!Double.isFinite(value)
        || !Double.isFinite(standardError)
        || standardError < 0
        || shots <= 0) {
      throw new IllegalArgumentException("Invalid expectation estimate");
    }
  }
}
