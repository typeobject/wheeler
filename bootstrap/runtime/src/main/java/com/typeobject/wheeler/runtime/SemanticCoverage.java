package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.vm.TransitionObserver;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.Map;
import java.util.Objects;
import java.util.TreeMap;

/** Collects deterministic typed VM transition coverage without instrumenting Wheeler programs. */
public final class SemanticCoverage implements TransitionObserver {
  private final Map<Point, Long> hits = new TreeMap<>();
  private final Map<PathEdge, Long> pathHits = new TreeMap<>();
  private final Map<PathOwner, Observation> pathTails = new HashMap<>();

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
    PathOwner owner = new PathOwner(
        observation.eventId().workflowEpoch(),
        observation.eventId().taskId().canonicalName(),
        point.direction());
    Observation previous = pathTails.put(owner, observation);
    if (previous != null && consecutive(previous, observation)) {
      pathHits.merge(new PathEdge(
          owner.workflowEpoch(),
          owner.task(),
          owner.direction(),
          endpoint(previous),
          endpoint(observation)), 1L, Math::addExact);
    }
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

  /** Returns an immutable point table for presentation adapters. */
  public Map<Point, Long> points() {
    return Map.copyOf(hits);
  }

  /** Returns immutable adjacent path-edge hits without claiming complete path enumeration. */
  public Map<PathEdge, Long> paths() {
    return Map.copyOf(pathHits);
  }

  /** Returns canonical adjacent-edge coverage with exact task and direction dimensions. */
  public String canonicalPathReport() {
    StringBuilder json = new StringBuilder("{\"paths\":[");
    int index = 0;
    for (Map.Entry<PathEdge, Long> entry : pathHits.entrySet()) {
      if (index++ > 0) {
        json.append(',');
      }
      PathEdge edge = entry.getKey();
      json.append("{\"count\":").append(entry.getValue())
          .append(",\"direction\":\"").append(edge.direction())
          .append("\",\"from_branch\":\"").append(edge.from().branch())
          .append("\",\"from_function\":").append(edge.from().function())
          .append(",\"from_instruction\":").append(edge.from().instruction())
          .append(",\"from_opcode\":\"").append(edge.from().opcode())
          .append("\",\"task\":\"").append(edge.task())
          .append("\",\"to_branch\":\"").append(edge.to().branch())
          .append("\",\"to_function\":").append(edge.to().function())
          .append(",\"to_instruction\":").append(edge.to().instruction())
          .append(",\"to_opcode\":\"").append(edge.to().opcode())
          .append("\",\"workflow_epoch\":").append(edge.workflowEpoch()).append('}');
    }
    return json.append("],\"profile\":\"wheeler-transition-path-coverage-1\"}\n")
        .toString();
  }

  /** Returns the domain-separated identity of adjacent path-edge coverage. */
  public String pathIdentity() {
    return digest("wheeler-transition-path-coverage-1\0", canonicalPathReport());
  }

  /** Counts successful assertion transitions without conflating them with test-case status. */
  public long successfulAssertions() {
    return hits.entrySet().stream()
        .filter(entry -> !entry.getKey().direction().startsWith("rewind_"))
        .filter(entry -> entry.getKey().opcode().equals(Opcode.EXPECT_EQ.name())
            || entry.getKey().opcode().equals(Opcode.EXPECT_TRUE.name()))
        .mapToLong(Map.Entry::getValue)
        .reduce(0L, Math::addExact);
  }

  /** Returns the domain-separated identity of the canonical transition report. */
  public String identity() {
    return digest("wheeler-transition-coverage-1\0", canonicalReport());
  }

  private static String digest(String domain, String report) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      digest.update(domain.getBytes(StandardCharsets.UTF_8));
      return HexFormat.of().formatHex(digest.digest(report.getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static boolean consecutive(Observation previous, Observation current) {
    long left = previous.eventId().taskLocalSequence();
    long right = current.eventId().taskLocalSequence();
    if (current.direction() == Direction.REWIND_FORWARD
        || current.direction() == Direction.REWIND_INVERSE) {
      return right + 1 == left;
    }
    return left + 1 == right;
  }

  private static PathEndpoint endpoint(Observation observation) {
    return new PathEndpoint(
        observation.functionId(),
        observation.instructionIndex(),
        observation.opcode().name(),
        switch (observation.branchOutcome()) {
          case 0 -> "fallthrough";
          case 1 -> "taken";
          default -> "none";
        });
  }

  private record PathOwner(long workflowEpoch, String task, String direction) {}

  /** One endpoint of an observed adjacent semantic path edge. */
  public record PathEndpoint(int function, int instruction, String opcode, String branch)
      implements Comparable<PathEndpoint> {
    public PathEndpoint {
      Objects.requireNonNull(opcode, "opcode");
      Objects.requireNonNull(branch, "branch");
      if (function < 0 || instruction < 0 || !opcode.matches("[A-Z][A-Z0-9_]*")
          || !(branch.equals("none") || branch.equals("taken")
              || branch.equals("fallthrough"))) {
        throw new IllegalArgumentException("path endpoint is not canonical");
      }
    }

    @Override
    public int compareTo(PathEndpoint other) {
      int order = Integer.compare(function, other.function);
      if (order == 0) {
        order = Integer.compare(instruction, other.instruction);
      }
      if (order == 0) {
        order = opcode.compareTo(other.opcode);
      }
      return order == 0 ? branch.compareTo(other.branch) : order;
    }
  }

  /** One task- and direction-specific adjacent transition edge. */
  public record PathEdge(
      long workflowEpoch,
      String task,
      String direction,
      PathEndpoint from,
      PathEndpoint to) implements Comparable<PathEdge> {
    public PathEdge {
      Objects.requireNonNull(task, "task");
      Objects.requireNonNull(direction, "direction");
      Objects.requireNonNull(from, "from");
      Objects.requireNonNull(to, "to");
      if (workflowEpoch < 0 || !task.matches("root(?:/[0-9]+\\.[0-9]+)*")
          || !(direction.equals("forward") || direction.equals("inverse")
              || direction.equals("rewind_forward") || direction.equals("rewind_inverse"))) {
        throw new IllegalArgumentException("path edge owner is not canonical");
      }
    }

    @Override
    public int compareTo(PathEdge other) {
      int order = Long.compare(workflowEpoch, other.workflowEpoch);
      if (order == 0) {
        order = task.compareTo(other.task);
      }
      if (order == 0) {
        order = direction.compareTo(other.direction);
      }
      if (order == 0) {
        order = from.compareTo(other.from);
      }
      return order == 0 ? to.compareTo(other.to) : order;
    }
  }

  /** One typed bytecode transition point; it does not claim a source-line mapping. */
  public record Point(
      String direction, int function, int instruction, String opcode, String branch)
      implements Comparable<Point> {
    public Point {
      Objects.requireNonNull(direction, "direction");
      Objects.requireNonNull(opcode, "opcode");
      Objects.requireNonNull(branch, "branch");
      if (function < 0 || instruction < 0) {
        throw new IllegalArgumentException("coverage point coordinates must be nonnegative");
      }
    }

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
