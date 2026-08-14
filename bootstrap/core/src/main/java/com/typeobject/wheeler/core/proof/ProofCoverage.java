package com.typeobject.wheeler.core.proof;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Map;
import java.util.TreeMap;

/** Deterministic nominal coverage for proof-kernel stage transitions. */
public final class ProofCoverage implements ProofObserver {
  private final Map<Point, Long> hits = new TreeMap<>();

  @Override
  public void observe(Observation observation) {
    Point point = new Point(
        observation.rule().name(),
        observation.subjectId(),
        observation.stage().name());
    hits.merge(point, 1L, Math::addExact);
  }

  /** Returns canonical proof-stage coverage without a fabricated percentage. */
  public String canonicalReport() {
    StringBuilder report = new StringBuilder(
        "{\"profile\":\"wheeler-proof-coverage-1\",\"points\":[");
    int index = 0;
    for (Map.Entry<Point, Long> entry : hits.entrySet()) {
      if (index++ > 0) {
        report.append(',');
      }
      Point point = entry.getKey();
      report.append("{\"rule\":\"").append(point.rule())
          .append("\",\"subject\":").append(point.subject())
          .append(",\"stage\":\"").append(point.stage())
          .append("\",\"count\":").append(entry.getValue()).append('}');
    }
    return report.append("]}\n").toString();
  }

  /** Returns the domain-separated identity of the exact proof-stage report. */
  public String identity() {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      digest.update("wheeler-proof-coverage-1\0".getBytes(StandardCharsets.UTF_8));
      return HexFormat.of().formatHex(digest.digest(
          canonicalReport().getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private record Point(String rule, int subject, String stage) implements Comparable<Point> {
    @Override
    public int compareTo(Point other) {
      int order = rule.compareTo(other.rule);
      if (order == 0) {
        order = Integer.compare(subject, other.subject);
      }
      return order == 0 ? stage.compareTo(other.stage) : order;
    }
  }
}
