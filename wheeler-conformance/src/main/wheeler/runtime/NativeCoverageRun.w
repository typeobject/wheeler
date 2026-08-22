//! Executes and reduces one bounded compiler artifact without host transition collection.

module wheeler.conformance.runtime.native_coverage_run;

import wheeler.compiler.opcodes;
import wheeler.core.encoding.binary;
import wheeler.runtime.artifact_execution;
import wheeler.runtime.bootstrap_coverage_fragments;
import wheeler.runtime.coverage_reducer;
import wheeler.runtime.interpreter;

classical class NativeCoverageRun {
  state long transitionCount = 0;
  state long reportLength = 0;
  state long finalGlobal = 0;

  private long sectionOffset(borrow byteview artifact, long section) {
    return readUnsigned(artifact, 40 + section * 32 + 8, 8);
  }

  private long entryFunction(borrow byteview artifact) {
    long manifestOffset = sectionOffset(artifact, 0);
    return readUnsigned(artifact, manifestOffset + 4, 4);
  }

  /// Executes one linear bootstrap fixture and publishes its canonical profile-1 report.
  ///
  /// - Effects: Publishes output only after native execution and complete reduction succeed.
  entry void main(borrow byteview artifact, borrow mut bytes output) {
    region arena = new region(/* bytes= */ 65536, /* allocations= */ 2);
    bytes traceOpcodes = allocateBytes(arena, MAX_INTERPRETED_STEPS * 2);
    ArtifactOutcome outcome = executeBoundedArtifact(artifact, traceOpcodes);
    assert(outcome.passed);
    transitionCount = outcome.steps;
    assert(0 < transitionCount);
    assert(transitionCount < 65);
    finalGlobal = outcome.finalGlobal;

    long function = entryFunction(artifact);
    long fragmentLength = measuredTransitionFragments(traceOpcodes, transitionCount, function);
    bytes fragments = allocateBytes(arena, /* length= */ 32768);
    writeTransitionFragments(traceOpcodes, transitionCount, function, fragments);
    reportLength = reduceRange(fragments, fragmentLength, output);
    setOutputLength(output, reportLength);
    drop(fragments);
    drop(traceOpcodes);
    drop(arena);
  }
}
