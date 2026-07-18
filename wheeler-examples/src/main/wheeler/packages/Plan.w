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

    private long writeLength(bytes output, long cursor, long length) {
        setByte(output, cursor, length % 256);
        setByte(output, cursor + 1, length / 256 % 256);
        setByte(output, cursor + 2, length / 65536 % 256);
        setByte(output, cursor + 3, length / 16777216 % 256);
        return cursor + 4;
    }

    private long copyField(
        byteview source,
        long start,
        long length,
        bytes output,
        long cursor
    ) {
        cursor = writeLength(output, cursor, length);
        long offset = 0;
        while (offset < length) limit 4096 {
            setByte(output, cursor + offset, source[start + offset]);
            offset += 1;
        }
        return cursor + length;
    }

    private long hexScalar(long value) {
        if (value < 10) {
            return value + 48;
        }
        return value + 87;
    }

    private long copyHashField(
        byteview source,
        long start,
        bytes output,
        long cursor
    ) {
        cursor = writeLength(output, cursor, 64);
        long offset = 0;
        while (offset < 32) limit 32 {
            long value = source[start + offset];
            setByte(output, cursor + offset * 2, hexScalar(value / 16));
            setByte(output, cursor + offset * 2 + 1, hexScalar(value % 16));
            offset += 1;
        }
        return cursor + 64;
    }

    private long decimalDigits(long value) {
        long digits = 1;
        long remaining = value;
        while (9 < remaining) limit 19 {
            remaining = remaining / 10;
            digits += 1;
        }
        return digits;
    }

    private long writeDecimalField(
        long value,
        bytes output,
        long cursor
    ) {
        long digits = decimalDigits(value);
        cursor = writeLength(output, cursor, digits);
        long divisor = 1;
        long scale = 1;
        while (scale < digits) limit 19 {
            divisor = divisor * 10;
            scale += 1;
        }
        long offset = 0;
        while (offset < digits) limit 19 {
            setByte(output, cursor + offset, value / divisor % 10 + 48);
            if (1 < divisor) {
                divisor = divisor / 10;
            }
            offset += 1;
        }
        return cursor + digits;
    }

    private long writeKindField(
        long kind,
        bytes output,
        long cursor
    ) {
        if (kind == 1) {
            cursor = writeLength(output, cursor, 7);
            writeAscii(output, cursor, "LIBRARY");
            return cursor + 7;
        }
        if (kind == 2) {
            cursor = writeLength(output, cursor, 6);
            writeAscii(output, cursor, "BINARY");
            return cursor + 6;
        }
        if (kind == 3) {
            cursor = writeLength(output, cursor, 4);
            writeAscii(output, cursor, "TOOL");
            return cursor + 4;
        }
        if (kind == 4) {
            cursor = writeLength(output, cursor, 4);
            writeAscii(output, cursor, "TEST");
            return cursor + 4;
        }
        cursor = writeLength(output, cursor, 7);
        writeAscii(output, cursor, "EXAMPLE");
        return cursor + 7;
    }

    private boolean nodeIdentityMatches(
        byteview source,
        long expectedStart,
        long packageStart,
        long packageLength,
        long versionStart,
        long versionLength,
        long manifestIdentityStart,
        long targetStart,
        long targetLength,
        long targetKind,
        long sourceIdentityStart,
        long outputStart,
        long outputLength,
        long maxSteps,
        long maxMemory,
        long maxInput,
        long maxOutput,
        long timeout,
        bytes digest,
        region arena
    ) {
        bytes identity = allocateBytes(arena, 320);
        long cursor = writeLength(identity, 0, 20);
        writeAscii(identity, cursor, "wheeler-build-node-1");
        cursor += 20;
        cursor = copyField(
            source, packageStart, packageLength, identity, cursor);
        cursor = copyField(
            source, versionStart, versionLength, identity, cursor);
        cursor = copyHashField(
            source, manifestIdentityStart, identity, cursor);
        cursor = copyField(
            source, targetStart, targetLength, identity, cursor);
        cursor = writeKindField(targetKind, identity, cursor);
        cursor = copyHashField(
            source, sourceIdentityStart, identity, cursor);
        cursor = copyField(
            source, outputStart, outputLength, identity, cursor);
        cursor = writeDecimalField(0, identity, cursor);
        cursor = writeDecimalField(0, identity, cursor);
        cursor = writeDecimalField(maxSteps, identity, cursor);
        cursor = writeDecimalField(maxMemory, identity, cursor);
        cursor = writeDecimalField(maxInput, identity, cursor);
        cursor = writeDecimalField(maxOutput, identity, cursor);
        cursor = writeDecimalField(timeout, identity, cursor);
        cursor = writeDecimalField(0, identity, cursor);
        hashSha256Range(identity, 0, cursor, digest, arena);
        drop(identity);
        long offset = 0;
        while (offset < 32) limit 32 {
            if (digest[offset] == source[expectedStart + offset]) {
                offset += 1;
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
        long nodeIdentityStart = cursor;
        cursor += 32;
        long packageLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        long packageStart = cursor;
        if (validAsciiName(source, cursor, packageLength)) {
        } else {
            return new PlanResult.Error(cursor);
        }
        cursor += packageLength;
        long versionLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        long versionStart = cursor;
        if (validNumericRelease(source, cursor, versionLength)) {
        } else {
            return new PlanResult.Error(cursor);
        }
        cursor += versionLength;
        long manifestIdentityStart = cursor;
        cursor += 32;
        long targetLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        long targetStart = cursor;
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
        cursor += 4;
        long sourceIdentityStart = cursor;
        cursor += 32;
        long outputLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        long outputStart = cursor;
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
        } else {
            return new PlanResult.Error(cursor);
        }
        if (nodeIdentityMatches(
                source,
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
                maxSteps,
                maxMemory,
                maxInput,
                maxOutput,
                timeout,
                digest,
                arena)) {
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
        return new PlanResult.Error(nodeIdentityStart);
    }
}
