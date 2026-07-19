package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.vm.TransitionObserver;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Map;
import java.util.TreeMap;

/** Collects deterministic typed VM transition coverage without instrumenting Wheeler programs. */
public final class SemanticCoverage implements TransitionObserver {
  private final Map<Point, Long> hits = new TreeMap<>();

  @Override
  public void observe(Observation observation) {
    Point point = new Point(
        observation.direction().name().toLowerCase(java.util.Locale.ROOT),
        observation.functionId(),
        observation.instructionIndex(),
        observation.opcode().name(),
        switch (observation.branchOutcome()) {
          case 0 -> "fallthrough";
          case 1 -> "taken";
          default -> "none";
        });
    hits.merge(point, 1L, Math::addExact);
  }

  /** Returns canonical JSON with separate execution and rewind dimensions and no invented score. */
  public String canonicalReport() {
    StringBuilder json = new StringBuilder(
        "{\"points\":[");
    int index = 0;
    for (Map.Entry<Point, Long> entry : hits.entrySet()) {
      if (index++ > 0) {
        json.append(',');
      }
      Point point = entry.getKey();
      json.append("{\"branch\":\"").append(point.branch())
          .append("\",\"count\":").append(entry.getValue())
          .append(",\"direction\":\"").append(point.direction())
          .append("\",\"function\":").append(point.function())
          .append(",\"instruction\":").append(point.instruction())
          .append(",\"opcode\":\"").append(point.opcode()).append("\"}");
    }
    return json.append("],\"profile\":\"wheeler-transition-coverage-1\"}\n").toString();
  }

  /** Returns the domain-separated identity of the canonical transition report. */
  public String identity() {
    byte[] report = canonicalReport().getBytes(StandardCharsets.UTF_8);
    byte[] domain = "wheeler-transition-coverage-1\0".getBytes(StandardCharsets.UTF_8);
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      digest.update(domain);
      return HexFormat.of().formatHex(digest.digest(report));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private record Point(
      String direction, int function, int instruction, String opcode, String branch)
      implements Comparable<Point> {
    @Override
    public int compareTo(Point other) {
      int order = direction.compareTo(other.direction);
      if (order == 0) {
        order = Integer.compare(function, other.function);
      }
      if (order == 0) {
        order = Integer.compare(instruction, other.instruction);
      }
      if (order == 0) {
        order = opcode.compareTo(other.opcode);
      }
      return order == 0 ? branch.compareTo(other.branch) : order;
    }
  }
}
