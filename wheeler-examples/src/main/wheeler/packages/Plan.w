module examples.packages.plan;
import examples.crypto.sha256;
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

    private long readUnsigned(
        byteview source,
        long offset,
        long width
    ) {
        long result = 0;
        long multiplier = 1;
        long cursor = 0;
        while (cursor < width) limit 8 {
            result += source[offset + cursor] * multiplier;
            cursor += 1;
            if (cursor < width) {
                multiplier = multiplier * 256;
            }
        }
        return result;
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

    private boolean lowercase(long value) {
        if (96 < value) {
            return value < 123;
        }
        return false;
    }

    private boolean digit(long value) {
        if (47 < value) {
            return value < 58;
        }
        return false;
    }

    private boolean validName(
        byteview source,
        long start,
        long length
    ) {
        if (length == 0) {
            return false;
        }
        if (lowercase(source[start])) {
        } else {
            return false;
        }
        boolean needValue = false;
        long cursor = 1;
        while (cursor < length) limit 256 {
            long value = source[start + cursor];
            if (needValue) {
                if (lowercase(value)) {
                    needValue = false;
                } else {
                    if (digit(value)) {
                        needValue = false;
                    } else {
                        return false;
                    }
                }
            } else {
                if (lowercase(value)) {
                } else {
                    if (digit(value)) {
                    } else {
                        if (value == 45) {
                            needValue = true;
                        } else {
                            if (value == 46) {
                                needValue = true;
                            } else {
                                return false;
                            }
                        }
                    }
                }
            }
            cursor += 1;
        }
        if (needValue) {
            return false;
        }
        return true;
    }

    private boolean validRelease(
        byteview source,
        long start,
        long length
    ) {
        if (length < 5) {
            return false;
        }
        long component = 0;
        long digits = 0;
        long cursor = 0;
        boolean leadingZero = false;
        while (cursor < length) limit 64 {
            long value = source[start + cursor];
            if (digit(value)) {
                if (digits == 0) {
                    leadingZero = value == 48;
                } else {
                    if (leadingZero) {
                        return false;
                    }
                }
                digits += 1;
            } else {
                if (value == 46) {
                    if (digits == 0) {
                        return false;
                    }
                    component += 1;
                    digits = 0;
                    leadingZero = false;
                } else {
                    return false;
                }
            }
            cursor += 1;
        }
        if (digits == 0) {
            return false;
        }
        return component == 2;
    }

    private boolean validPath(
        byteview source,
        long start,
        long length
    ) {
        if (length == 0) {
            return false;
        }
        if (source[start] == 47) {
            return false;
        }
        if (source[start + length - 1] == 47) {
            return false;
        }
        long componentStart = 0;
        long cursor = 0;
        while (cursor < length) limit 256 {
            long value = source[start + cursor];
            if (value < 32) {
                return false;
            }
            if (126 < value) {
                return false;
            }
            if (value == 92) {
                return false;
            }
            if (value == 47) {
                long componentLength = cursor - componentStart;
                if (componentLength == 0) {
                    return false;
                }
                if (componentLength == 1) {
                    if (source[start + componentStart] == 46) {
                        return false;
                    }
                }
                if (componentLength == 2) {
                    if (source[start + componentStart] == 46) {
                        if (source[start + componentStart + 1] == 46) {
                            return false;
                        }
                    }
                }
                componentStart = cursor + 1;
            }
            cursor += 1;
        }
        long finalLength = length - componentStart;
        if (finalLength == 1) {
            if (source[start + componentStart] == 46) {
                return false;
            }
        }
        if (finalLength == 2) {
            if (source[start + componentStart] == 46) {
                if (source[start + componentStart + 1] == 46) {
                    return false;
                }
            }
        }
        return true;
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
        if (validName(source, cursor, profileLength)) {
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
        if (validName(source, cursor, packageLength)) {
        } else {
            return new PlanResult.Error(cursor);
        }
        cursor += packageLength;
        long versionLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        if (validRelease(source, cursor, versionLength)) {
        } else {
            return new PlanResult.Error(cursor);
        }
        cursor += versionLength + 32;
        long targetLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        if (validName(source, cursor, targetLength)) {
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
        if (validPath(source, cursor, outputLength)) {
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
