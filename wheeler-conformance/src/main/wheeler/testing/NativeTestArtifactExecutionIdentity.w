//! Executes one verified artifact and publishes its profile-2 execution identity.

module wheeler.conformance.testing.native_test_artifact_execution_identity;

import wheeler.compiler.opcodes;
import wheeler.runtime.artifact_execution;
import wheeler.runtime.testing.test_artifact_execution_identity;

classical class NativeTestArtifactExecutionIdentity {
  entry void main(borrow byteview artifact, borrow mut bytes output) {
    region traceArena = new region(/* bytes= */ 32768, /* allocations= */ 1);
    bytes traceOpcodes = allocateBytes(traceArena, MAX_INTERPRETED_STEPS * 2);
    ArtifactOutcome outcome = executeBoundedArtifact(artifact, traceOpcodes);
    long length = deriveArtifactExecutionIdentity(artifact, outcome, output);
    setOutputLength(output, length);
    drop(traceOpcodes);
    drop(traceArena);
  }
}
