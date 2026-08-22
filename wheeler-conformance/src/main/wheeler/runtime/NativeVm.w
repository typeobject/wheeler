//! Verifies and executes a bounded canonical artifact entirely in Wheeler.

module wheeler.conformance.runtime.native_vm;

import wheeler.compiler.opcodes;
import wheeler.compiler.verifier;
import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;
import wheeler.runtime.interpreter;

classical class NativeVm {
  state long finalGlobal = 0;
  state long finalGlobalOne = 0;
  state long finalGlobalTwo = 0;
  state long finalGlobalThree = 0;
  state long finalGlobalFour = 0;
  state long finalGlobalFive = 0;
  state long finalGlobalSix = 0;
  state long finalGlobalSeven = 0;
  state long interpretedGlobalCount = 0;
  state long interpretedSteps = 0;
  state long traceZero = 0;
  state long traceOne = 0;
  state long traceTwo = 0;
  state long traceThree = 0;
  state long traceFour = 0;
  state long traceFive = 0;
  state long traceSix = 0;
  state long traceSeven = 0;
  state long artifactLength = 0;

  private long digestWord(borrow mut bytes digest, long start) {
    return digest[start] * 16777216 + digest[start + 1] * 65536 + digest[start + 2] * 256
      + digest[start + 3];
  }

  /// Runs the bounded `NativeVm` fixture.
  ///
  /// - Effects: Mutates only the fixture's declared state.
  entry void main(borrow byteview artifact) {
    region arena = new region(24000, 25);
    words globals = allocate(arena, INTERPRETER_GLOBAL_COUNT);
    words locals = allocate(arena, INTERPRETER_LOCAL_CAPACITY);
    words returnCursors = allocate(arena, INTERPRETER_FRAME_COUNT);
    words returnStarts = allocate(arena, INTERPRETER_FRAME_COUNT);
    words returnEnds = allocate(arena, INTERPRETER_FRAME_COUNT);
    words returnDestinations = allocate(arena, INTERPRETER_FRAME_COUNT);
    words aggregateTypes = allocate(arena, INTERPRETER_AGGREGATE_COUNT);
    words aggregateTags = allocate(arena, INTERPRETER_AGGREGATE_COUNT);
    words aggregateStarts = allocate(arena, INTERPRETER_AGGREGATE_COUNT);
    words aggregateCounts = allocate(arena, INTERPRETER_AGGREGATE_COUNT);
    words aggregateFields = allocate(arena, INTERPRETER_AGGREGATE_FIELDS);
    words storageKinds = allocate(arena, INTERPRETER_STORAGE_COUNT);
    words storageStarts = allocate(arena, INTERPRETER_STORAGE_COUNT);
    words storageLengths = allocate(arena, INTERPRETER_STORAGE_COUNT);
    words storageSizes = allocate(arena, INTERPRETER_STORAGE_COUNT);
    words storageOwners = allocate(arena, INTERPRETER_STORAGE_COUNT);
    words storageLive = allocate(arena, INTERPRETER_STORAGE_COUNT);
    words storageRegionUsedBytes = allocate(arena, INTERPRETER_STORAGE_COUNT);
    words storageRegionLiveObjects = allocate(arena, INTERPRETER_STORAGE_COUNT);
    words storageData = allocate(arena, INTERPRETER_STORAGE_WORDS);
    bytes traceOpcodes = allocateBytes(arena, MAX_INTERPRETED_STEPS * 2);
    bytes traceDigest = allocateBytes(arena, 32);
    assert(verifyArtifact(artifact, bufferLength(artifact)) == 1);
    ExecutionResult result = executeVerifiedArtifact(
      artifact,
      MAX_INTERPRETED_STEPS,
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
        finalGlobal = execution.globalZero;
        finalGlobalOne = execution.globalOne;
        finalGlobalTwo = execution.globalTwo;
        finalGlobalThree = execution.globalThree;
        finalGlobalFour = execution.globalFour;
        finalGlobalFive = execution.globalFive;
        finalGlobalSix = execution.globalSix;
        finalGlobalSeven = execution.globalSeven;
        interpretedGlobalCount = execution.globalCount;
        interpretedSteps = execution.steps;
        hashSha256Range(traceOpcodes, 0, execution.steps * 2, traceDigest, arena);
        traceZero = digestWord(traceDigest, 0);
        traceOne = digestWord(traceDigest, 4);
        traceTwo = digestWord(traceDigest, 8);
        traceThree = digestWord(traceDigest, 12);
        traceFour = digestWord(traceDigest, 16);
        traceFive = digestWord(traceDigest, 20);
        traceSix = digestWord(traceDigest, 24);
        traceSeven = digestWord(traceDigest, 28);
      }
      case ExecutionResult.Error(long offset) {
        assert(artifactLength == 1);
      }
      case ExecutionResult.Limit(long limitOffset) {
        assert(artifactLength == 1);
      }
    }

    artifactLength = bufferLength(artifact);
    drop(traceDigest);
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
    drop(arena);
  }
}
