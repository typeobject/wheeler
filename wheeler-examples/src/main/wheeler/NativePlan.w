module examples.packages.plan_main;
import examples.crypto.sha256;
import examples.packages.plan;
classical class NativePlan {
    state long profileLength = 0;
    state long packageLength = 0;
    state long versionLength = 0;
    state long targetLength = 0;
    state long outputLength = 0;
    state long targetKind = 0;
    state long inputCount = 0;
    state long requestCount = 0;
    state long grantCount = 0;
    state long maxSteps = 0;
    state long timeout = 0;
    state long finalLength = 0;

    entry void main(byteview source) {
        region arena = new region(3200, 5);
        bytes digest = allocateBytes(arena, 32);
        PlanResult parsed = inspectPlan(source, digest, arena);
        match (parsed) {
            case PlanResult.Value(PlanModel plan) {
                profileLength = plan.profileLength;
                packageLength = plan.packageLength;
                versionLength = plan.versionLength;
                targetLength = plan.targetLength;
                outputLength = plan.outputLength;
                targetKind = plan.targetKind;
                inputCount = plan.inputCount;
                requestCount = plan.requestCount;
                grantCount = plan.grantCount;
                maxSteps = plan.maxSteps;
                timeout = plan.timeout;
            }
            case PlanResult.Error(long offset) {
                assert finalLength == 1;
            }
        }
        finalLength = bufferLength(source);
        assert profileLength == 11;
        assert packageLength == 9;
        assert versionLength == 5;
        assert targetLength == 4;
        assert outputLength == 12;
        assert targetKind == 2;
        assert maxSteps == 1000;
        assert timeout == 5000;
        drop(digest);
        drop(arena);
    }
}
