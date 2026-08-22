//! Executes one bounded artifact with Wheeler-owned interpreter storage.

module wheeler.runtime.artifact_execution;

import wheeler.compiler.opcodes;
import wheeler.runtime.interpreter;

classical class ArtifactExecution {
  public record ArtifactOutcome(boolean passed, long steps, long finalGlobal, long errorOffset) {}

  /// Executes one artifact and returns its terminal interpreter outcome.
  public ArtifactOutcome executeBoundedArtifact(
    borrow byteview artifact,
    borrow mut bytes traceOpcodes
  ) {
    assert(bufferLength(traceOpcodes) == MAX_INTERPRETED_STEPS * 2);
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
    boolean passed = false;
    long steps = 0;
    long finalGlobal = 0;
    long errorOffset = 0;
    match (result) {
      case ExecutionResult.Value(Execution execution) {
        passed = true;
        steps = execution.steps;
        finalGlobal = execution.globalZero;
      }
      case ExecutionResult.Error(long offset) {
        errorOffset = offset;
      }
    }

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
    return new ArtifactOutcome(passed, steps, finalGlobal, errorOffset);
  }
}
