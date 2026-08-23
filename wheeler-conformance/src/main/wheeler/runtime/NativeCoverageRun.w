//! Executes and reduces one bounded compiler artifact without host transition collection.

module wheeler.conformance.runtime.native_coverage_run;

import wheeler.compiler.opcodes;
import wheeler.runtime.artifact_execution;
import wheeler.runtime.bootstrap_coverage_fragments;
import wheeler.runtime.coverage_reducer;

classical class NativeCoverageRun {
  state long transitionCount = 0;
  state long reportLength = 0;
  state long finalGlobal = 0;

  /// Executes one linear bootstrap fixture and publishes its canonical profile-1 report.
  ///
  /// - Effects: Publishes output only after native execution and complete reduction succeed.
  entry void main(borrow byteview artifact, borrow mut bytes output) {
    region arena = new region(/* bytes= */ 65536, /* allocations= */ 5);
    bytes traceOpcodes = allocateBytes(arena, MAX_INTERPRETED_STEPS * 2);
    words traceFunctions = allocate(arena, MAX_INTERPRETED_STEPS);
    words traceInstructions = allocate(arena, MAX_INTERPRETED_STEPS);
    bytes traceBranches = allocateBytes(arena, MAX_INTERPRETED_STEPS);
    ArtifactOutcome outcome = executeBoundedArtifact(
      artifact,
      traceOpcodes,
      traceFunctions,
      traceInstructions,
      traceBranches
    );
    assert(outcome.passed);
    transitionCount = outcome.steps;
    assert(0 < transitionCount);
    assert(transitionCount < 65);
    finalGlobal = outcome.globalZero;

    long fragmentLength = measuredTransitionFragments(
      traceOpcodes,
      traceFunctions,
      traceInstructions,
      traceBranches,
      transitionCount
    );
    bytes fragments = allocateBytes(arena, /* length= */ 32768);
    writeTransitionFragments(
      traceOpcodes,
      traceFunctions,
      traceInstructions,
      traceBranches,
      transitionCount,
      fragments
    );
    reportLength = reduceRange(fragments, fragmentLength, output);
    setOutputLength(output, reportLength);
    drop(fragments);
    drop(traceBranches);
    drop(traceInstructions);
    drop(traceFunctions);
    drop(traceOpcodes);
    drop(arena);
  }
}
