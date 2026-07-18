module examples.runtime.native_vm;
import examples.compiler.interpreter;
import examples.compiler.opcodes;
import examples.compiler.verifier;
import examples.packages.binary;
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
    state long artifactLength = 0;

    entry void main(byteview artifact) {
        region arena = new region(6464, 20);
        words globals = allocate(arena, INTERPRETER_GLOBAL_COUNT);
        words locals = allocate(arena, INTERPRETER_LOCAL_CAPACITY);
        words returnCursors = allocate(arena, INTERPRETER_FRAME_COUNT);
        words returnStarts = allocate(arena, INTERPRETER_FRAME_COUNT);
        words returnEnds = allocate(arena, INTERPRETER_FRAME_COUNT);
        words returnDestinations = allocate(
            arena, INTERPRETER_FRAME_COUNT);
        words aggregateTypes = allocate(
            arena, INTERPRETER_AGGREGATE_COUNT);
        words aggregateTags = allocate(
            arena, INTERPRETER_AGGREGATE_COUNT);
        words aggregateStarts = allocate(
            arena, INTERPRETER_AGGREGATE_COUNT);
        words aggregateCounts = allocate(
            arena, INTERPRETER_AGGREGATE_COUNT);
        words aggregateFields = allocate(
            arena, INTERPRETER_AGGREGATE_FIELDS);
        words storageKinds = allocate(arena, INTERPRETER_STORAGE_COUNT);
        words storageStarts = allocate(arena, INTERPRETER_STORAGE_COUNT);
        words storageLengths = allocate(arena, INTERPRETER_STORAGE_COUNT);
        words storageSizes = allocate(arena, INTERPRETER_STORAGE_COUNT);
        words storageOwners = allocate(arena, INTERPRETER_STORAGE_COUNT);
        words storageLive = allocate(arena, INTERPRETER_STORAGE_COUNT);
        words storageRegionUsedBytes = allocate(
            arena, INTERPRETER_STORAGE_COUNT);
        words storageRegionLiveObjects = allocate(
            arena, INTERPRETER_STORAGE_COUNT);
        words storageData = allocate(arena, INTERPRETER_STORAGE_WORDS);
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
            storageData);
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
            }
            case ExecutionResult.Error(long offset) {
                assert artifactLength == 1;
            }
        }
        artifactLength = bufferLength(artifact);
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
