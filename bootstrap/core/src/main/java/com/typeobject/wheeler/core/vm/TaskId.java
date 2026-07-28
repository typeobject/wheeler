package com.typeobject.wheeler.core.vm;

import java.util.ArrayList;
import java.util.List;

/** Canonical hierarchical identity for one semantic Wheeler task. */
public record TaskId(List<Segment> path) implements Comparable<TaskId> {
  public static final int MAX_DEPTH = 1_024;
  public static final TaskId ROOT = new TaskId(List.of());

  public TaskId {
    path = List.copyOf(path);
    if (path.size() > MAX_DEPTH) {
      throw new IllegalArgumentException("TaskId exceeds maximum depth");
    }
  }

  /** Returns a deterministic child identity for one lexical scope and spawn ordinal. */
  public TaskId child(int scopeOrdinal, int spawnOrdinal) {
    if (path.size() == MAX_DEPTH) {
      throw new IllegalArgumentException("TaskId exceeds maximum depth");
    }
    var child = new ArrayList<>(path);
    child.add(new Segment(scopeOrdinal, spawnOrdinal));
    return new TaskId(child);
  }

  /** Returns the canonical diagnostic spelling. */
  public String canonicalName() {
    StringBuilder name = new StringBuilder("root");
    for (Segment segment : path) {
      name.append('/').append(segment.scopeOrdinal()).append('.')
          .append(segment.spawnOrdinal());
    }
    return name.toString();
  }

  @Override
  public int compareTo(TaskId other) {
    int common = Math.min(path.size(), other.path.size());
    for (int index = 0; index < common; index++) {
      int comparison = path.get(index).compareTo(other.path.get(index));
      if (comparison != 0) {
        return comparison;
      }
    }
    return Integer.compare(path.size(), other.path.size());
  }

  /** One deterministic lexical scope and spawn position. */
  public record Segment(int scopeOrdinal, int spawnOrdinal) implements Comparable<Segment> {
    public Segment {
      if (scopeOrdinal < 0 || spawnOrdinal < 0) {
        throw new IllegalArgumentException("TaskId ordinals cannot be negative");
      }
    }

    @Override
    public int compareTo(Segment other) {
      int scope = Integer.compare(scopeOrdinal, other.scopeOrdinal);
      return scope != 0 ? scope : Integer.compare(spawnOrdinal, other.spawnOrdinal);
    }
  }
}
