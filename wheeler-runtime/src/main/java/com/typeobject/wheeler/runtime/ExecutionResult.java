package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.ProgramKind;
import java.util.List;
import java.util.Map;

/** Immutable completed runtime result. */
public record ExecutionResult(
    String program,
    ProgramKind kind,
    Map<String, Long> globals,
    List<Long> measurements,
    List<String> quantumJobs,
    long workflowSteps,
    byte[] output) {
  public ExecutionResult(
      String program,
      ProgramKind kind,
      Map<String, Long> globals,
      List<Long> measurements,
      List<String> quantumJobs,
      long workflowSteps) {
    this(program, kind, globals, measurements, quantumJobs, workflowSteps, new byte[0]);
  }

  public ExecutionResult {
    globals = Map.copyOf(globals);
    measurements = List.copyOf(measurements);
    quantumJobs = List.copyOf(quantumJobs);
    output = output.clone();
  }

  @Override
  public byte[] output() {
    return output.clone();
  }
}
