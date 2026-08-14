//! Executes and reduces one bounded compiler artifact without host transition collection.

module wheeler.conformance.runtime.native_coverage_run;

import wheeler.compiler.opcodes;
import wheeler.core.encoding.binary;
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
    region executionArena = new region(/* bytes= */ 24000, /* allocations= */ 25);
    words globals = allocate(executionArena, INTERPRETER_GLOBAL_COUNT);
    words locals = allocate(executionArena, INTERPRETER_LOCAL_CAPACITY);
    words returnCursors = allocate(executionArena, INTERPRETER_FRAME_COUNT);
    words returnStarts = allocate(executionArena, INTERPRETER_FRAME_COUNT);
    words returnEnds = allocate(executionArena, INTERPRETER_FRAME_COUNT);
    words returnDestinations = allocate(executionArena, INTERPRETER_FRAME_COUNT);
    words aggregateTypes = allocate(executionArena, INTERPRETER_AGGREGATE_COUNT);
    words aggregateTags = allocate(executionArena, INTERPRETER_AGGREGATE_COUNT);
    words aggregateStarts = allocate(executionArena, INTERPRETER_AGGREGATE_COUNT);
    words aggregateCounts = allocate(executionArena, INTERPRETER_AGGREGATE_COUNT);
    words aggregateFields = allocate(executionArena, INTERPRETER_AGGREGATE_FIELDS);
    words storageKinds = allocate(executionArena, INTERPRETER_STORAGE_COUNT);
    words storageStarts = allocate(executionArena, INTERPRETER_STORAGE_COUNT);
    words storageLengths = allocate(executionArena, INTERPRETER_STORAGE_COUNT);
    words storageSizes = allocate(executionArena, INTERPRETER_STORAGE_COUNT);
    words storageOwners = allocate(executionArena, INTERPRETER_STORAGE_COUNT);
    words storageLive = allocate(executionArena, INTERPRETER_STORAGE_COUNT);
    words storageRegionUsedBytes = allocate(executionArena, INTERPRETER_STORAGE_COUNT);
    words storageRegionLiveObjects = allocate(executionArena, INTERPRETER_STORAGE_COUNT);
    words storageData = allocate(executionArena, INTERPRETER_STORAGE_WORDS);
    bytes traceOpcodes = allocateBytes(executionArena, MAX_INTERPRETED_STEPS * 2);
    ExecutionResult result = executeArtifact(
      artifact,
      globals,
      locals,
      returnCursors,
      returnStarts,
      returnEnds,
      returnDestinations,
      aggregateTypes,
      aggregateTags,
      aggregateStarts,
      aggregateCounts,
      aggregateFields,
      storageKinds,
      storageStarts,
      storageLengths,
      storageSizes,
      storageOwners,
      storageLive,
      storageRegionUsedBytes,
      storageRegionLiveObjects,
      storageData,
      traceOpcodes
    );
    match (result) {
      case ExecutionResult.Value(Execution execution) {
        transitionCount = execution.steps;
        assert(0 < transitionCount);
        assert(transitionCount < 65);
        finalGlobal = execution.globalZero;
      }
      case ExecutionResult.Error(long offset) {
        assert(false);
      }
    }

    long function = entryFunction(artifact);
    long fragmentLength = measuredTransitionFragments(traceOpcodes, transitionCount, function);
    region coverageArena = new region(/* bytes= */ 32768, /* allocations= */ 1);
    bytes fragments = allocateBytes(coverageArena, /* length= */ 32768);
    writeTransitionFragments(traceOpcodes, transitionCount, function, fragments);
    reportLength = reduceRange(fragments, fragmentLength, output);
    setOutputLength(output, reportLength);
    drop(fragments);
    drop(coverageArena);
    drop(traceOpcodes);
    drop(storageData);
    drop(storageRegionLiveObjects);
    drop(storageRegionUsedBytes);
    drop(storageLive);
    drop(storageOwners);
    drop(storageSizes);
    drop(storageLengths);
    drop(storageStarts);
    drop(storageKinds);
    drop(aggregateFields);
    drop(aggregateCounts);
    drop(aggregateStarts);
    drop(aggregateTags);
    drop(aggregateTypes);
    drop(returnDestinations);
    drop(returnEnds);
    drop(returnStarts);
    drop(returnCursors);
    drop(locals);
    drop(globals);
    drop(executionArena);
  }
}
