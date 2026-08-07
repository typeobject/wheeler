//! Computes the content identity of one bounded canonical build plan.

module wheeler.conformance.packages.plan_identity;

import wheeler.crypto.content_identity;
import wheeler.packages.plan;

classical class NativePlanIdentity {
  state long packageLength = 0;
  state long targetLength = 0;
  state long sourceLength = 0;
  state long diagnosticOffset = 0;
  state long published = 0;

  /// Validates and identifies one plan without publishing partial output.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview source, borrow mut bytes identity) {
    if (4096 < bufferLength(source)) {
      long oversized = source[-1];
    }

    region arena = new region(4500, 7);
    bytes scratchDigest = allocateBytes(arena, 32);
    PlanResult inspected = inspectPlan(source, scratchDigest, arena);
    match (inspected) {
      case PlanResult.Value(PlanModel plan) {
        packageLength = plan.packageLength;
        targetLength = plan.targetLength;
        sourceLength = bufferLength(source);
        publishSha256(source, identity, arena);
        published = 1;
      }
      case PlanResult.Error(long offset) {
        diagnosticOffset = offset;
        assert(published == 1);
      }
    }

    setOutputLength(identity, published * 32);
    drop(scratchDigest);
    drop(arena);
  }
}
