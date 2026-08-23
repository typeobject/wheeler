//! Executes one bounded artifact with Wheeler-owned interpreter storage.

module wheeler.runtime.artifact_execution;

import wheeler.compiler.opcodes;
import wheeler.compiler.verifier;
import wheeler.runtime.artifact_metadata;
import wheeler.runtime.interpreter;

classical class ArtifactExecution {
  public record ArtifactOutcome(
    boolean verified,
    boolean authorized,
    boolean passed,
    boolean exhausted,
    long steps,
    long globalCount,
    long globalZero,
    long globalOne,
    long globalTwo,
    long globalThree,
    long globalFour,
    long globalFive,
    long globalSix,
    long globalSeven,
    long errorOffset
  ) {}

  private long tracedStepCount(borrow byteview traceOpcodes) {
    long steps = 0;
    boolean traced = true;
    while (traced) limit MAX_INTERPRETED_STEPS {
      traced = traceOpcodes[steps * 2] != 0;
      if (!traced) {
        traced = traceOpcodes[steps * 2 + 1] != 0;
      }

      if (traced) {
        steps += 1;
        traced = steps < MAX_INTERPRETED_STEPS;
      }
    }

    return steps;
  }

  private ArtifactOutcome executeBoundedArtifactWithFunction(
    borrow byteview artifact,
    borrow byteview expectedFunction,
    boolean bindFunction,
    long caseKind,
    long caseValue,
    long stepLimit,
    borrow mut bytes traceOpcodes,
    borrow mut words traceFunctions,
    borrow mut words traceInstructions,
    borrow mut bytes traceBranches
  ) {
    assert(bufferLength(traceOpcodes) == MAX_INTERPRETED_STEPS * 2);
    assert(bufferLength(traceFunctions) == MAX_INTERPRETED_STEPS);
    assert(bufferLength(traceInstructions) == MAX_INTERPRETED_STEPS);
    assert(bufferLength(traceBranches) == MAX_INTERPRETED_STEPS);
    assert(0 < stepLimit);
    assert(stepLimit < MAX_INTERPRETED_STEPS + 1);
    region executionArena = new region(/* bytes= */ 24000, /* allocations= */ 25);
    words globals = allocate(executionArena, INTERPRETER_GLOBAL_COUNT);
    words locals = allocate(executionArena, INTERPRETER_LOCAL_CAPACITY);
    words returnCursors = allocate(executionArena, INTERPRETER_FRAME_COUNT);
    words returnStarts = allocate(executionArena, INTERPRETER_FRAME_COUNT);
    words returnEnds = allocate(executionArena, INTERPRETER_FRAME_COUNT);
    words returnDestinations = allocate(executionArena, INTERPRETER_FRAME_COUNT);
    words returnFunctions = allocate(executionArena, INTERPRETER_FRAME_COUNT);
    words returnInstructions = allocate(executionArena, INTERPRETER_FRAME_COUNT);
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
    boolean verified = verifyArtifact(artifact, bufferLength(artifact)) == 1;
    boolean authorized = true;
    if (verified) {
      if (bindFunction) {
        authorized = artifactFunctionMatches(artifact, /* function= */ 0, expectedFunction);
        if (authorized) {
          authorized = artifactTestEntryMatches(
            artifact,
            /* function= */ 0,
            caseKind,
            caseValue
          );
        }
      }
    }

    boolean passed = false;
    boolean exhausted = false;
    long steps = 0;
    long globalCount = 0;
    long globalZero = 0;
    long globalOne = 0;
    long globalTwo = 0;
    long globalThree = 0;
    long globalFour = 0;
    long globalFive = 0;
    long globalSix = 0;
    long globalSeven = 0;
    long errorOffset = 0;
    boolean executable = verified;
    if (authorized == false) {
      executable = false;
    }

    if (executable) {
      ExecutionResult result = executeVerifiedArtifact(
        artifact,
        stepLimit,
        globals,
        locals,
        returnCursors,
        returnStarts,
        returnEnds,
        returnDestinations,
        returnFunctions,
        returnInstructions,
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
        traceOpcodes,
        traceFunctions,
        traceInstructions,
        traceBranches
      );
      match (result) {
        case ExecutionResult.Value(Execution execution) {
          passed = true;
          steps = execution.steps;
          globalCount = execution.globalCount;
          globalZero = execution.globalZero;
          globalOne = execution.globalOne;
          globalTwo = execution.globalTwo;
          globalThree = execution.globalThree;
          globalFour = execution.globalFour;
          globalFive = execution.globalFive;
          globalSix = execution.globalSix;
          globalSeven = execution.globalSeven;
        }
        case ExecutionResult.Error(long offset) {
          errorOffset = offset;
        }
        case ExecutionResult.Limit(long limitOffset) {
          exhausted = true;
          errorOffset = limitOffset;
        }
      }
    }

    if (passed == false) {
      steps = tracedStepCount(traceOpcodes);
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
    drop(returnInstructions);
    drop(returnFunctions);
    drop(returnDestinations);
    drop(returnEnds);
    drop(returnStarts);
    drop(returnCursors);
    drop(locals);
    drop(globals);
    drop(executionArena);
    return new ArtifactOutcome(
      verified,
      authorized,
      passed,
      exhausted,
      steps,
      globalCount,
      globalZero,
      globalOne,
      globalTwo,
      globalThree,
      globalFour,
      globalFive,
      globalSix,
      globalSeven,
      errorOffset
    );
  }

  /// Verifies and executes one artifact without a program-name constraint.
  public ArtifactOutcome executeBoundedArtifact(
    borrow byteview artifact,
    borrow mut bytes traceOpcodes,
    borrow mut words traceFunctions,
    borrow mut words traceInstructions,
    borrow mut bytes traceBranches
  ) {
    return executeBoundedArtifactWithFunction(
      artifact,
      artifact,
      /* bindFunction= */ false,
      /* caseKind= */ 0,
      /* caseValue= */ 0,
      MAX_INTERPRETED_STEPS,
      traceOpcodes,
      traceFunctions,
      traceInstructions,
      traceBranches
    );
  }

  /// Verifies and executes one artifact under a selected source step limit.
  public ArtifactOutcome executeBoundedArtifactWithStepLimit(
    borrow byteview artifact,
    long stepLimit,
    borrow mut bytes traceOpcodes,
    borrow mut words traceFunctions,
    borrow mut words traceInstructions,
    borrow mut bytes traceBranches
  ) {
    return executeBoundedArtifactWithFunction(
      artifact,
      artifact,
      /* bindFunction= */ false,
      /* caseKind= */ 0,
      /* caseValue= */ 0,
      stepLimit,
      traceOpcodes,
      traceFunctions,
      traceInstructions,
      traceBranches
    );
  }

  /// Verifies, authorizes, and executes one exact named test artifact.
  public ArtifactOutcome executeBoundedNamedArtifact(
    borrow byteview artifact,
    borrow byteview expectedFunction,
    long caseKind,
    long caseValue,
    long stepLimit,
    borrow mut bytes traceOpcodes,
    borrow mut words traceFunctions,
    borrow mut words traceInstructions,
    borrow mut bytes traceBranches
  ) {
    return executeBoundedArtifactWithFunction(
      artifact,
      expectedFunction,
      /* bindFunction= */ true,
      caseKind,
      caseValue,
      stepLimit,
      traceOpcodes,
      traceFunctions,
      traceInstructions,
      traceBranches
    );
  }
}
