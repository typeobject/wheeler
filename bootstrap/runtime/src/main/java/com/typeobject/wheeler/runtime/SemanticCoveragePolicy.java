package com.typeobject.wheeler.runtime;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;

/** Content-identified exclusion and threshold policy over semantic transition points. */
public final class SemanticCoveragePolicy {
  /** Immutable policy evaluation that keeps exclusions and thresholds visible. */
  public record Evaluation(
      String policyIdentity,
      String coverageIdentity,
      long includedPoints,
      long excludedPoints,
      long minimumPoints,
      long minimumHitsPerPoint,
      boolean passed,
      String identity,
      String canonicalReport) {
    public Evaluation {
      requireHash(policyIdentity, "policy identity");
      requireHash(coverageIdentity, "coverage identity");
      requireHash(identity, "evaluation identity");
      Objects.requireNonNull(canonicalReport, "canonicalReport");
      if (includedPoints < 0 || excludedPoints < 0
          || minimumPoints < 0 || minimumHitsPerPoint < 0) {
        throw new IllegalArgumentException("coverage policy counts must be nonnegative");
      }
    }
  }

  private final Set<String> excludedDirections;
  private final Set<String> excludedOpcodes;
  private final long minimumPoints;
  private final long minimumHitsPerPoint;
  private final String identity;

  /** Creates one explicit policy without an ambient exclusion or percentage denominator. */
  public SemanticCoveragePolicy(
      Set<String> excludedDirections,
      Set<String> excludedOpcodes,
      long minimumPoints,
      long minimumHitsPerPoint) {
    this.excludedDirections = names(excludedDirections, "excluded direction");
    this.excludedOpcodes = names(excludedOpcodes, "excluded opcode");
    if (minimumPoints < 0 || minimumPoints > 1_000_000
        || minimumHitsPerPoint < 0 || minimumHitsPerPoint > 1_000_000_000L) {
      throw new IllegalArgumentException("coverage threshold is out of bounds");
    }
    this.minimumPoints = minimumPoints;
    this.minimumHitsPerPoint = minimumHitsPerPoint;
    identity = sha256(canonicalPolicy());
  }

  /** Returns the content identity of every exclusion and threshold. */
  public String identity() {
    return identity;
  }

  /** Evaluates one immutable report and emits a policy-visible canonical result. */
  public Evaluation evaluate(SemanticCoverage coverage) {
    Objects.requireNonNull(coverage, "coverage");
    TreeMap<SemanticCoverage.Point, Long> included = new TreeMap<>();
    long excluded = 0;
    boolean hitsPass = true;
    for (Map.Entry<SemanticCoverage.Point, Long> entry
        : new TreeMap<>(coverage.points()).entrySet()) {
      SemanticCoverage.Point point = entry.getKey();
      if (excludedDirections.contains(point.direction())
          || excludedOpcodes.contains(point.opcode())) {
        excluded++;
      } else {
        included.put(point, entry.getValue());
        if (entry.getValue() < minimumHitsPerPoint) {
          hitsPass = false;
        }
      }
    }
    boolean passed = included.size() >= minimumPoints && hitsPass;
    String report = report(coverage.identity(), included, excluded, passed);
    String evaluationIdentity = sha256(
        "wheeler-semantic-coverage-evaluation-1\0" + report);
    return new Evaluation(
        identity,
        coverage.identity(),
        included.size(),
        excluded,
        minimumPoints,
        minimumHitsPerPoint,
        passed,
        evaluationIdentity,
        report);
  }

  private String report(
      String coverageIdentity,
      Map<SemanticCoverage.Point, Long> included,
      long excluded,
      boolean passed) {
    StringBuilder report = new StringBuilder("{\"profile\":")
        .append(quote("wheeler-semantic-coverage-policy/1"))
        .append(",\"policy\":").append(quote(identity))
        .append(",\"coverage\":").append(quote(coverageIdentity))
        .append(",\"excluded_directions\":");
    appendNames(report, excludedDirections);
    report.append(",\"excluded_opcodes\":");
    appendNames(report, excludedOpcodes);
    report.append(",\"minimum_points\":").append(minimumPoints)
        .append(",\"minimum_hits_per_point\":").append(minimumHitsPerPoint)
        .append(",\"included_points\":").append(included.size())
        .append(",\"excluded_points\":").append(excluded)
        .append(",\"passed\":").append(passed)
        .append(",\"points\":[");
    int index = 0;
    for (Map.Entry<SemanticCoverage.Point, Long> entry : included.entrySet()) {
      if (index++ > 0) {
        report.append(',');
      }
      SemanticCoverage.Point point = entry.getKey();
      report.append("{\"direction\":").append(quote(point.direction()))
          .append(",\"function\":").append(point.function())
          .append(",\"instruction\":").append(point.instruction())
          .append(",\"opcode\":").append(quote(point.opcode()))
          .append(",\"branch\":").append(quote(point.branch()))
          .append(",\"count\":").append(entry.getValue()).append('}');
    }
    return report.append("]}\n").toString();
  }

  private String canonicalPolicy() {
    StringBuilder canonical = new StringBuilder("wheeler-semantic-coverage-policy-1");
    excludedDirections.forEach(name -> canonical.append('\0').append("direction:").append(name));
    excludedOpcodes.forEach(name -> canonical.append('\0').append("opcode:").append(name));
    return canonical.append('\0').append(minimumPoints)
        .append('\0').append(minimumHitsPerPoint).toString();
  }

  private static Set<String> names(Set<String> values, String field) {
    Objects.requireNonNull(values, field);
    TreeSet<String> result = new TreeSet<>();
    for (String value : values) {
      Objects.requireNonNull(value, field);
      if (value.isBlank() || value.length() > 128 || !value.equals(value.trim())) {
        throw new IllegalArgumentException(field + " must be bounded canonical text");
      }
      if (!result.add(value)) {
        throw new IllegalArgumentException("duplicate " + field + ": " + value);
      }
    }
    return Collections.unmodifiableSet(result);
  }

  private static void appendNames(StringBuilder output, Set<String> names) {
    output.append('[');
    List<String> ordered = new ArrayList<>(names);
    ordered.sort(String::compareTo);
    for (int index = 0; index < ordered.size(); index++) {
      if (index > 0) {
        output.append(',');
      }
      output.append(quote(ordered.get(index)));
    }
    output.append(']');
  }

  private static String quote(String value) {
    return '"' + value.replace("\\", "\\\\").replace("\"", "\\\"") + '"';
  }

  private static String sha256(String value) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(
          value.getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static void requireHash(String value, String field) {
    if (value == null || !value.matches("[0-9a-f]{64}")) {
      throw new IllegalArgumentException(field + " must be lowercase SHA-256");
    }
  }
}
