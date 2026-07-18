module examples.runtime.native_vm;
import examples.compiler.interpreter;
import examples.compiler.verifier;
import examples.packages.binary;
classical class NativeVm {
    state long finalGlobal = 0;
    state long interpretedSteps = 0;
    state long artifactLength = 0;

    entry void main(byteview artifact) {
        region arena = new region(640, 3);
        words locals = allocate(arena, 64);
        words returnCursors = allocate(arena, 8);
        words returnEnds = allocate(arena, 8);
        ExecutionResult result = executeArtifact(
            artifact, locals, returnCursors, returnEnds);
        match (result) {
            case ExecutionResult.Value(Execution execution) {
                finalGlobal = execution.globalValue;
                interpretedSteps = execution.steps;
            }
            case ExecutionResult.Error(long offset) {
                assert artifactLength == 1;
            }
        }
        artifactLength = bufferLength(artifact);
        drop(returnEnds);
        drop(returnCursors);
        drop(locals);
        drop(arena);
    }
}
