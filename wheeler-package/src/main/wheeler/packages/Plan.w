//! Validates bounded canonical build-plan structure.

module wheeler.packages.plan;
import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;
import wheeler.packages.plan_identity;
classical class Plan {
    /// Defines immutable `PlanModel` values for this module.
    public record PlanModel(
        long profileLength,
        long packageLength,
        long versionLength,
        long targetLength,
        long outputLength,
        long targetKind,
        long inputCount,
        long requestCount,
        long grantCount,
        long maxSteps,
        long maxMemory,
        long maxInput,
        long maxOutput,
        long timeout
    ) {}

    /// Defines the closed `PlanResult` cases exported by this module.
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

    /// Validates and decodes `plan` from a bounded canonical input.
    public PlanResult inspectPlan(byteview source, bytes digest, region arena) {
        long fileLength = bufferLength(source);
        if (fileLength < 320) {
            return new PlanResult.Error(0);
        }
        if (magicValid(source)) {} else {
            return new PlanResult.Error(0);
        }
        if (readUnsigned(source, 8, 4) == 1) {} else {
            return new PlanResult.Error(8);
        }
        long payloadLength = readUnsigned(source, 12, 4);
        long payloadEnd = 16 + payloadLength;
        if (payloadEnd + 32 == fileLength) {} else {
            return new PlanResult.Error(12);
        }
        if (digestMatches(source, payloadLength, digest, arena)) {} else {
            return new PlanResult.Error(payloadEnd);
        }
        long cursor = 80;
        long profileLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        if (profileLength < 257) {
            if (payloadEnd < cursor + profileLength) {
                return new PlanResult.Error(cursor);
            }
        } else {
            return new PlanResult.Error(cursor);
        }
        if (validAsciiName(source, cursor, profileLength)) {} else {
            return new PlanResult.Error(cursor);
        }
        cursor += profileLength;
        if (readUnsigned(source, cursor, 4) == 1) {
            cursor += 4;
        } else {
            return new PlanResult.Error(cursor);
        }
        long nodeIdentityStart = cursor;
        cursor += 32;
        long packageLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        long packageStart = cursor;
        if (packageLength < 257) {} else {
            return new PlanResult.Error(cursor);
        }
        if (validAsciiName(source, cursor, packageLength)) {} else {
            return new PlanResult.Error(cursor);
        }
        cursor += packageLength;
        long versionLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        long versionStart = cursor;
        if (versionLength < 257) {} else {
            return new PlanResult.Error(cursor);
        }
        if (validNumericRelease(source, cursor, versionLength)) {} else {
            return new PlanResult.Error(cursor);
        }
        cursor += versionLength;
        long manifestIdentityStart = cursor;
        cursor += 32;
        long targetLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        long targetStart = cursor;
        if (targetLength < 257) {} else {
            return new PlanResult.Error(cursor);
        }
        if (validAsciiName(source, cursor, targetLength)) {} else {
            return new PlanResult.Error(cursor);
        }
        cursor += targetLength;
        long targetKind = readUnsigned(source, cursor, 4);
        if (targetKind < 1) {
            return new PlanResult.Error(cursor);
        }
        if (3 < targetKind) {
            return new PlanResult.Error(cursor);
        }
        cursor += 4;
        long sourceIdentityStart = cursor;
        cursor += 32;
        long outputLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        long outputStart = cursor;
        if (outputLength < 257) {} else {
            return new PlanResult.Error(cursor);
        }
        if (validAsciiPath(source, cursor, outputLength)) {} else {
            return new PlanResult.Error(cursor);
        }
        cursor += outputLength;
        long inputCount = readUnsigned(source, cursor, 4);
        cursor += 4;
        if (1 < inputCount) {
            return new PlanResult.Error(cursor);
        }
        long inputNameStart = 0;
        long inputNameLength = 0;
        long inputArchiveStart = 0;
        if (inputCount == 1) {
            inputNameLength = readUnsigned(source, cursor, 4);
            cursor += 4;
            inputNameStart = cursor;
            if (inputNameLength < 257) {} else {
                return new PlanResult.Error(cursor);
            }
            if (validAsciiName(source, cursor, inputNameLength)) {} else {
                return new PlanResult.Error(cursor);
            }
            cursor += inputNameLength;
            inputArchiveStart = cursor;
            cursor += 32;
        }
        long requestCount = readUnsigned(source, cursor, 4);
        cursor += 4;
        if (1 < requestCount) {
            return new PlanResult.Error(cursor);
        }
        long requestNameStart = 0;
        long requestNameLength = 0;
        long requestPatternStart = 0;
        long requestPatternLength = 0;
        if (requestCount == 1) {
            requestNameLength = readUnsigned(source, cursor, 4);
            cursor += 4;
            requestNameStart = cursor;
            if (requestNameLength < 257) {} else {
                return new PlanResult.Error(cursor);
            }
            if (validAsciiName(source, cursor, requestNameLength)) {} else {
                return new PlanResult.Error(cursor);
            }
            cursor += requestNameLength;
            requestPatternLength = readUnsigned(source, cursor, 4);
            cursor += 4;
            requestPatternStart = cursor;
            if (requestPatternLength < 257) {} else {
                return new PlanResult.Error(cursor);
            }
            if (validAsciiPath(source, cursor, requestPatternLength)) {} else {
                return new PlanResult.Error(cursor);
            }
            cursor += requestPatternLength;
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
        if (maxSteps < 1) {
            return new PlanResult.Error(cursor);
        }
        if (1000000000000 < maxSteps) {
            return new PlanResult.Error(cursor);
        }
        if (maxMemory < 1) {
            return new PlanResult.Error(cursor);
        }
        if (1099511627776 < maxMemory) {
            return new PlanResult.Error(cursor);
        }
        if (maxInput < 1) {
            return new PlanResult.Error(cursor);
        }
        if (1099511627776 < maxInput) {
            return new PlanResult.Error(cursor);
        }
        if (maxOutput < 1) {
            return new PlanResult.Error(cursor);
        }
        if (1099511627776 < maxOutput) {
            return new PlanResult.Error(cursor);
        }
        if (timeout < 1) {
            return new PlanResult.Error(cursor);
        }
        if (86400000 < timeout) {
            return new PlanResult.Error(cursor);
        }
        long grantCount = readUnsigned(source, cursor, 4);
        cursor += 4;
        if (requestCount < grantCount) {
            return new PlanResult.Error(cursor);
        }
        long grantNameStart = 0;
        long grantNameLength = 0;
        long grantPatternStart = 0;
        long grantPatternLength = 0;
        if (grantCount == 1) {
            grantNameLength = readUnsigned(source, cursor, 4);
            cursor += 4;
            grantNameStart = cursor;
            if (grantNameLength < 257) {} else {
                return new PlanResult.Error(cursor);
            }
            cursor += grantNameLength;
            grantPatternLength = readUnsigned(source, cursor, 4);
            cursor += 4;
            grantPatternStart = cursor;
            if (grantPatternLength < 257) {} else {
                return new PlanResult.Error(cursor);
            }
            cursor += grantPatternLength;
            if (
                compareAsciiRanges(
                    source,
                    requestNameStart,
                    requestNameLength,
                    grantNameStart,
                    grantNameLength
                ) == 0
            ) {} else {
                return new PlanResult.Error(grantNameStart);
            }
            if (
                compareAsciiRanges(
                    source,
                    requestPatternStart,
                    requestPatternLength,
                    grantPatternStart,
                    grantPatternLength
                ) == 0
            ) {} else {
                return new PlanResult.Error(grantPatternStart);
            }
        }
        if (cursor == payloadEnd) {} else {
            return new PlanResult.Error(cursor);
        }
        NodeIdentityFields identity = new NodeIdentityFields(
            nodeIdentityStart,
            packageStart,
            packageLength,
            versionStart,
            versionLength,
            manifestIdentityStart,
            targetStart,
            targetLength,
            targetKind,
            sourceIdentityStart,
            outputStart,
            outputLength,
            inputCount,
            inputNameStart,
            inputNameLength,
            inputArchiveStart,
            requestCount,
            requestNameStart,
            requestNameLength,
            requestPatternStart,
            requestPatternLength,
            maxSteps,
            maxMemory,
            maxInput,
            maxOutput,
            timeout,
            grantCount,
            grantNameStart,
            grantNameLength,
            grantPatternStart,
            grantPatternLength
        );
        if (nodeIdentityMatches(source, identity, digest, arena)) {
            PlanModel plan = new PlanModel(
                profileLength,
                packageLength,
                versionLength,
                targetLength,
                outputLength,
                targetKind,
                inputCount,
                requestCount,
                grantCount,
                maxSteps,
                maxMemory,
                maxInput,
                maxOutput,
                timeout
            );
            return new PlanResult.Value(plan);
        }
        return new PlanResult.Error(nodeIdentityStart);
    }
}
