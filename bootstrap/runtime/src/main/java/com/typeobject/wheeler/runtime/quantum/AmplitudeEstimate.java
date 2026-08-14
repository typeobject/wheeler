package com.typeobject.wheeler.runtime.quantum;

import java.util.Objects;

/** Bounded sampled amplitude estimate with explicit resource and uncertainty fields. */
public record AmplitudeEstimate(
    long successes,
    int shots,
    double probability,
    double standardError,
    int qubits,
    long circuitApplications,
    String resultIdentity) {
  public AmplitudeEstimate {
    Objects.requireNonNull(resultIdentity, "resultIdentity");
    if (shots < 1 || successes < 0 || shots < successes
        || !Double.isFinite(probability) || probability < 0 || 1 < probability
        || !Double.isFinite(standardError) || standardError < 0
        || qubits < 1 || StateVectorTarget.MAX_QUBITS < qubits
        || circuitApplications < 1 || resultIdentity.isBlank()) {
      throw new IllegalArgumentException("amplitude estimate is outside its bounded schema");
    }
    double expectedProbability = (double) successes / shots;
    double expectedError = Math.sqrt(
        expectedProbability * (1 - expectedProbability) / shots);
    if (Double.compare(probability, expectedProbability) != 0
        || Double.compare(standardError, expectedError) != 0) {
      throw new IllegalArgumentException("amplitude estimate statistics do not match counts");
    }
  }

  /** Reduces one complete sampled result under an explicit good-outcome mask. */
  public static AmplitudeEstimate from(
      QuantumResult result,
      long goodMask,
      long goodValue,
      int qubits,
      long circuitApplications) {
    Objects.requireNonNull(result, "result");
    if (goodMask < 1 || goodValue < 0 || (goodValue & ~goodMask) != 0) {
      throw new IllegalArgumentException("good outcome must be contained by a nonempty mask");
    }
    long successes = result.outcomes().stream()
        .filter(outcome -> (outcome & goodMask) == goodValue)
        .count();
    int shots = result.outcomes().size();
    double probability = (double) successes / shots;
    double standardError = Math.sqrt(probability * (1 - probability) / shots);
    return new AmplitudeEstimate(
        successes,
        shots,
        probability,
        standardError,
        qubits,
        circuitApplications,
        result.submissionIdentity());
  }

  /** Lower endpoint of a visible two-standard-error interval, clipped to probability bounds. */
  public double lowerBound() {
    return Math.max(0, probability - 2 * standardError);
  }

  /** Upper endpoint of a visible two-standard-error interval, clipped to probability bounds. */
  public double upperBound() {
    return Math.min(1, probability + 2 * standardError);
  }
}
