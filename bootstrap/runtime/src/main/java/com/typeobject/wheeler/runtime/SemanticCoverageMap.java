package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/** Validated source, bytecode, generated-body, and runtime coverage relations. */
public final class SemanticCoverageMap {
  private static final Set<String> DIRECTIONS = Set.of(
      "forward", "inverse", "rewind_forward", "rewind_inverse");

  /** Distinguishes authored code from compiler-generated inverse code. */
  public enum Origin {
    AUTHORED,
    GENERATED_INVERSE
  }

  /** One nonempty half-open source range under an exact source identity. */
  public record SourceRange(
      String identity,
      String path,
      int startLine,
      int startColumn,
      int endLine,
      int endColumn) implements Comparable<SourceRange> {
    public SourceRange {
      requireHash(identity, "source identity");
      Objects.requireNonNull(path, "path");
      if (path.isBlank() || path.startsWith("/") || path.contains("\\")
          || path.contains("//") || path.length() > 4_096
          || !path.matches("[A-Za-z0-9._/-]+")) {
        throw new IllegalArgumentException("source path must be bounded and normalized");
      }
      for (String component : path.split("/")) {
        if (component.equals(".") || component.equals("..")) {
          throw new IllegalArgumentException("source path must be bounded and normalized");
        }
      }
      if (startLine < 1 || startColumn < 1 || endLine < startLine || endColumn < 1
          || (endLine == startLine && endColumn <= startColumn)) {
        throw new IllegalArgumentException("source range must be nonempty and ordered");
      }
    }

    @Override
    public int compareTo(SourceRange other) {
      return Comparator.comparing(SourceRange::identity)
          .thenComparing(SourceRange::path)
          .thenComparingInt(SourceRange::startLine)
          .thenComparingInt(SourceRange::startColumn)
          .thenComparingInt(SourceRange::endLine)
          .thenComparingInt(SourceRange::endColumn)
          .compare(this, other);
    }
  }

  /** One source range related to a contiguous bytecode instruction window. */
  public record Relation(
      SourceRange source,
      String direction,
      int function,
      int firstInstruction,
      int instructionCount,
      Origin origin,
      String opcodeIdentity) implements Comparable<Relation> {
    public Relation {
      Objects.requireNonNull(source, "source");
      Objects.requireNonNull(direction, "direction");
      Objects.requireNonNull(origin, "origin");
      requireHash(opcodeIdentity, "opcode identity");
      if (!DIRECTIONS.contains(direction) || function < 0 || firstInstruction < 0
          || instructionCount < 1) {
        throw new IllegalArgumentException("bytecode relation coordinates are invalid");
      }
    }

    @Override
    public int compareTo(Relation other) {
      int order = direction.compareTo(other.direction);
      if (order == 0) {
        order = Integer.compare(function, other.function);
      }
      if (order == 0) {
        order = Integer.compare(firstInstruction, other.firstInstruction);
      }
      if (order == 0) {
        order = Integer.compare(instructionCount, other.instructionCount);
      }
      if (order == 0) {
        order = origin.compareTo(other.origin);
      }
      if (order == 0) {
        order = source.compareTo(other.source);
      }
      return order == 0 ? opcodeIdentity.compareTo(other.opcodeIdentity) : order;
    }
  }

  private final Program program;
  private final String artifactIdentity;
  private final List<Relation> relations;
  private final String identity;

  /** Validates every relation against one exact canonical program before retaining it. */
  public SemanticCoverageMap(Program program, List<Relation> relations) {
    Objects.requireNonNull(program, "program");
    Objects.requireNonNull(relations, "relations");
    this.program = program;
    artifactIdentity = sha256(new BytecodeWriter().write(program));
    ArrayList<Relation> ordered = new ArrayList<>(relations);
    ordered.sort(Relation::compareTo);
    for (int index = 0; index < ordered.size(); index++) {
      Relation relation = Objects.requireNonNull(ordered.get(index), "relation");
      List<Instruction> body = body(program, relation.direction(), relation.function());
      long end = (long) relation.firstInstruction() + relation.instructionCount();
      if (end > body.size()) {
        throw new IllegalArgumentException("coverage relation has a dangling bytecode window");
      }
      if (relation.origin() == Origin.GENERATED_INVERSE
          && !relation.direction().endsWith("inverse")) {
        throw new IllegalArgumentException("generated inverse relation names a forward body");
      }
      String expected = opcodeIdentity(
          program,
          relation.direction(),
          relation.function(),
          relation.firstInstruction(),
          relation.instructionCount());
      if (!expected.equals(relation.opcodeIdentity())) {
        throw new IllegalArgumentException("coverage relation has a forged opcode identity");
      }
      if (index > 0) {
        Relation previous = ordered.get(index - 1);
        if (previous.equals(relation)) {
          throw new IllegalArgumentException("duplicate coverage relation");
        }
        if (sameBody(previous, relation)
            && relation.firstInstruction()
                < previous.firstInstruction() + previous.instructionCount()) {
          throw new IllegalArgumentException("overlapping bytecode coverage relations");
        }
      }
    }
    this.relations = List.copyOf(ordered);
    identity = sha256(("wheeler-semantic-coverage-map-1\0" + canonicalRelations())
        .getBytes(StandardCharsets.UTF_8));
  }

  /** Computes the exact opcode-window identity expected by a relation. */
  public static String opcodeIdentity(
      Program program,
      String direction,
      int function,
      int firstInstruction,
      int instructionCount) {
    Objects.requireNonNull(program, "program");
    if (!DIRECTIONS.contains(direction) || firstInstruction < 0 || instructionCount < 1) {
      throw new IllegalArgumentException("opcode identity coordinates are invalid");
    }
    List<Instruction> body = body(program, direction, function);
    long end = (long) firstInstruction + instructionCount;
    if (end > body.size()) {
      throw new IllegalArgumentException("opcode identity window is dangling");
    }
    StringBuilder canonical = new StringBuilder("wheeler-opcode-window-1")
        .append('\0').append(direction)
        .append('\0').append(function)
        .append('\0').append(firstInstruction)
        .append('\0').append(instructionCount);
    for (int index = firstInstruction; index < end; index++) {
      canonical.append('\0').append(body.get(index).opcode().name());
    }
    return sha256(canonical.toString().getBytes(StandardCharsets.UTF_8));
  }

  /** Joins observed runtime points to validated source and generated-body relations. */
  public String join(SemanticCoverage coverage) {
    Objects.requireNonNull(coverage, "coverage");
    StringBuilder json = new StringBuilder("{\"artifact\":\"")
        .append(artifactIdentity)
        .append("\",\"coverage\":\"").append(coverage.identity())
        .append("\",\"mapping\":\"").append(identity)
        .append("\",\"points\":[");
    int emitted = 0;
    for (Map.Entry<SemanticCoverage.Point, Long> entry
        : coverage.points().entrySet().stream().sorted(Map.Entry.comparingByKey()).toList()) {
      SemanticCoverage.Point point = entry.getKey();
      Relation relation = relationFor(point);
      if (relation == null) {
        throw new IllegalArgumentException("runtime coverage point has no source relation");
      }
      if (emitted++ > 0) {
        json.append(',');
      }
      SourceRange source = relation.source();
      json.append("{\"branch\":\"").append(point.branch())
          .append("\",\"column\":").append(source.startColumn())
          .append(",\"count\":").append(entry.getValue())
          .append(",\"direction\":\"").append(point.direction())
          .append("\",\"function\":").append(point.function())
          .append(",\"instruction\":").append(point.instruction())
          .append(",\"line\":").append(source.startLine())
          .append(",\"opcode\":\"").append(point.opcode())
          .append("\",\"origin\":\"").append(
              relation.origin().name().toLowerCase(java.util.Locale.ROOT))
          .append("\",\"source_path\":\"").append(source.path()).append("\"}");
    }
    json.append("],\"path_coverage\":\"").append(coverage.pathIdentity())
        .append("\",\"paths\":[");
    emitted = 0;
    for (Map.Entry<SemanticCoverage.PathEdge, Long> entry
        : coverage.paths().entrySet().stream().sorted(Map.Entry.comparingByKey()).toList()) {
      SemanticCoverage.PathEdge edge = entry.getKey();
      Relation from = relationFor(edge.direction(), edge.from());
      Relation to = relationFor(edge.direction(), edge.to());
      if (from == null || to == null) {
        throw new IllegalArgumentException("runtime path edge has no source relation");
      }
      if (emitted++ > 0) {
        json.append(',');
      }
      json.append("{\"count\":").append(entry.getValue())
          .append(",\"direction\":\"").append(edge.direction())
          .append("\",\"from_branch\":\"").append(edge.from().branch())
          .append("\",\"from_column\":").append(from.source().startColumn())
          .append(",\"from_function\":").append(edge.from().function())
          .append(",\"from_instruction\":").append(edge.from().instruction())
          .append(",\"from_line\":").append(from.source().startLine())
          .append(",\"from_opcode\":\"").append(edge.from().opcode())
          .append("\",\"from_source_path\":\"").append(from.source().path())
          .append("\",\"task\":\"").append(edge.task())
          .append("\",\"to_branch\":\"").append(edge.to().branch())
          .append("\",\"to_column\":").append(to.source().startColumn())
          .append(",\"to_function\":").append(edge.to().function())
          .append(",\"to_instruction\":").append(edge.to().instruction())
          .append(",\"to_line\":").append(to.source().startLine())
          .append(",\"to_opcode\":\"").append(edge.to().opcode())
          .append("\",\"to_source_path\":\"").append(to.source().path())
          .append("\",\"workflow_epoch\":").append(edge.workflowEpoch()).append('}');
    }
    return json.append("],\"profile\":\"wheeler-source-transition-coverage-1\"}\n")
        .toString();
  }

  /** Returns the identity of the validated relation set and exact artifact. */
  public String identity() {
    return identity;
  }

  private Relation relationFor(SemanticCoverage.Point point) {
    return relationFor(
        point.direction(),
        new SemanticCoverage.PathEndpoint(
            point.function(), point.instruction(), point.opcode(), point.branch()));
  }

  private Relation relationFor(String direction, SemanticCoverage.PathEndpoint point) {
    for (Relation relation : relations) {
      if (relation.direction().equals(direction)
          && relation.function() == point.function()
          && relation.firstInstruction() <= point.instruction()
          && point.instruction() < relation.firstInstruction() + relation.instructionCount()) {
        Instruction instruction = body(program, direction, point.function()).get(point.instruction());
        boolean validBranch = instruction.opcode().name().equals(point.opcode());
        if (instruction.opcode() == Opcode.JUMP_IF_ZERO) {
          validBranch = validBranch
              && (point.branch().equals("taken") || point.branch().equals("fallthrough"));
        } else {
          validBranch = validBranch && point.branch().equals("none");
        }
        if (!validBranch) {
          throw new IllegalArgumentException("runtime coverage point is forged");
        }
        return relation;
      }
    }
    return null;
  }

  private String canonicalRelations() {
    StringBuilder canonical = new StringBuilder(artifactIdentity);
    for (Relation relation : relations) {
      SourceRange source = relation.source();
      canonical.append('\0').append(source.identity())
          .append('\0').append(source.path())
          .append('\0').append(source.startLine()).append(':').append(source.startColumn())
          .append('-').append(source.endLine()).append(':').append(source.endColumn())
          .append('\0').append(relation.direction())
          .append('\0').append(relation.function())
          .append('\0').append(relation.firstInstruction())
          .append('\0').append(relation.instructionCount())
          .append('\0').append(relation.origin())
          .append('\0').append(relation.opcodeIdentity());
    }
    return canonical.toString();
  }

  private static boolean sameBody(Relation left, Relation right) {
    return left.direction().equals(right.direction()) && left.function() == right.function();
  }

  private static List<Instruction> body(Program program, String direction, int function) {
    if (!DIRECTIONS.contains(direction)) {
      throw new IllegalArgumentException("unknown coverage direction");
    }
    FunctionBody selected;
    try {
      selected = program.function(function);
    } catch (RuntimeException failure) {
      throw new IllegalArgumentException("coverage relation names an unknown function", failure);
    }
    return direction.endsWith("inverse") ? selected.inverse() : selected.forward();
  }

  private static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
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
