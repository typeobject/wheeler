module examples.runtime.native_vm;
import examples.compiler.interpreter;
import examples.compiler.opcodes;
import examples.compiler.verifier;
import examples.packages.binary;
classical class NativeVm {
    state long finalGlobal = 0;
    state long finalGlobalOne = 0;
    state long interpretedGlobalCount = 0;
    state long interpretedSteps = 0;
    state long artifactLength = 0;

    entry void main(byteview artifact) {
        region arena = new region(4416, 11);
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
            aggregateFields);
        match (result) {
            case ExecutionResult.Value(Execution execution) {
                finalGlobal = execution.globalZero;
                finalGlobalOne = execution.globalOne;
                interpretedGlobalCount = execution.globalCount;
                interpretedSteps = execution.steps;
            }
            case ExecutionResult.Error(long offset) {
                assert artifactLength == 1;
            }
        }
        artifactLength = bufferLength(artifact);
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
