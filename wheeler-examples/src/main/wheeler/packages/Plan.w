module examples.packages.plan;
import examples.crypto.sha256;
import examples.packages.binary;
classical class Plan {
    public record PlanModel(
        long profileLength,
        long packageLength,
        long versionLength,
        long targetLength,
        long outputLength,
        long targetKind,
        long maxSteps,
        long maxMemory,
        long maxInput,
        long maxOutput,
        long timeout
    ) {}

    public variant PlanResult {
        case Value(PlanModel plan);
        case Error(long offset);
    }

    private boolean magicValid(byteview source) {
        if (source[0] == 87) {
            if (source[1] == 80) {
                if (source[2] == 76) {
                    if (source[3] == 78) {
                        if (source[4] == 0) {
                            if (source[5] == 0) {
                                if (source[6] == 0) {
                                    return source[7] == 1;
                                }
                            }
                        }
                    }
                }
            }
        }
        return false;
    }

    private boolean digestMatches(
        byteview source,
        long payloadLength,
        bytes digest,
        region arena
    ) {
        hashSha256Range(source, 16, payloadLength, digest, arena);
        long expectedStart = 16 + payloadLength;
        long cursor = 0;
        while (cursor < 32) limit 32 {
            if (digest[cursor] == source[expectedStart + cursor]) {
                cursor += 1;
            } else {
                return false;
            }
        }
        return true;
    }

    public PlanResult inspectPlan(
        byteview source,
        bytes digest,
        region arena
    ) {
        long fileLength = bufferLength(source);
        if (fileLength < 320) {
            return new PlanResult.Error(0);
        }
        if (magicValid(source)) {
        } else {
            return new PlanResult.Error(0);
        }
        if (readUnsigned(source, 8, 4) == 1) {
        } else {
            return new PlanResult.Error(8);
        }
        long payloadLength = readUnsigned(source, 12, 4);
        long payloadEnd = 16 + payloadLength;
        if (payloadEnd + 32 == fileLength) {
        } else {
            return new PlanResult.Error(12);
        }
        if (digestMatches(source, payloadLength, digest, arena)) {
        } else {
            return new PlanResult.Error(payloadEnd);
        }
        long cursor = 80;
        long profileLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        if (profileLength < 4097) {
            if (payloadEnd < cursor + profileLength) {
                return new PlanResult.Error(cursor);
            }
        } else {
            return new PlanResult.Error(cursor);
        }
        if (validAsciiName(source, cursor, profileLength)) {
        } else {
            return new PlanResult.Error(cursor);
        }
        cursor += profileLength;
        if (readUnsigned(source, cursor, 4) == 1) {
            cursor += 4;
        } else {
            return new PlanResult.Error(cursor);
        }
        cursor += 32;
        long packageLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        if (validAsciiName(source, cursor, packageLength)) {
        } else {
            return new PlanResult.Error(cursor);
        }
        cursor += packageLength;
        long versionLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        if (validNumericRelease(source, cursor, versionLength)) {
        } else {
            return new PlanResult.Error(cursor);
        }
        cursor += versionLength + 32;
        long targetLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        if (validAsciiName(source, cursor, targetLength)) {
        } else {
            return new PlanResult.Error(cursor);
        }
        cursor += targetLength;
        long targetKind = readUnsigned(source, cursor, 4);
        if (targetKind < 1) {
            return new PlanResult.Error(cursor);
        }
        if (5 < targetKind) {
            return new PlanResult.Error(cursor);
        }
        cursor += 4 + 32;
        long outputLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        if (validAsciiPath(source, cursor, outputLength)) {
        } else {
            return new PlanResult.Error(cursor);
        }
        cursor += outputLength;
        if (readUnsigned(source, cursor, 4) == 0) {
            cursor += 4;
        } else {
            return new PlanResult.Error(cursor);
        }
        if (readUnsigned(source, cursor, 4) == 0) {
            cursor += 4;
        } else {
            return new PlanResult.Error(cursor);
        }
        long maxSteps = readUnsigned(source, cursor, 8);
        cursor += 8;
        long maxMemory = readUnsigned(source, cursor, 8);
        cursor += 8;
        long maxInput = readUnsigned(source, cursor, 8);
        cursor += 8;
        long maxOutput = readUnsigned(source, cursor, 8);
        cursor += 8;
        long timeout = readUnsigned(source, cursor, 8);
        cursor += 8;
        if (maxSteps < 1) { return new PlanResult.Error(cursor); }
        if (1000000000000 < maxSteps) { return new PlanResult.Error(cursor); }
        if (maxMemory < 1) { return new PlanResult.Error(cursor); }
        if (1099511627776 < maxMemory) { return new PlanResult.Error(cursor); }
        if (maxInput < 1) { return new PlanResult.Error(cursor); }
        if (1099511627776 < maxInput) { return new PlanResult.Error(cursor); }
        if (maxOutput < 1) { return new PlanResult.Error(cursor); }
        if (1099511627776 < maxOutput) { return new PlanResult.Error(cursor); }
        if (timeout < 1) { return new PlanResult.Error(cursor); }
        if (86400000 < timeout) { return new PlanResult.Error(cursor); }
        if (readUnsigned(source, cursor, 4) == 0) {
            cursor += 4;
        } else {
            return new PlanResult.Error(cursor);
        }
        if (cursor == payloadEnd) {
            PlanModel plan = new PlanModel(
                profileLength,
                packageLength,
                versionLength,
                targetLength,
                outputLength,
                targetKind,
                maxSteps,
                maxMemory,
                maxInput,
                maxOutput,
                timeout);
            return new PlanResult.Value(plan);
        }
        return new PlanResult.Error(cursor);
    }
}
