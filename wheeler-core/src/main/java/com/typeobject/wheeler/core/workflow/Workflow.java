package com.typeobject.wheeler.core.workflow;

import java.util.List;

/** Ordered region graph for the first hybrid profile. */
public record Workflow(List<WorkflowStep> steps) {
  public Workflow {
    steps = List.copyOf(steps);
    if (steps.isEmpty()) {
      throw new IllegalArgumentException("Workflow must not be empty");
    }
  }

  public static Workflow empty() {
    return new Workflow(List.of(WorkflowStep.halt()));
  }
}
