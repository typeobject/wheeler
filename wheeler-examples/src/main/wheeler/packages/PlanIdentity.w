//! Checks content-bound build-plan node identities.

module examples.packages.plan_identity;
import examples.crypto.sha256;
classical class PlanIdentity {
    /// Defines immutable `NodeIdentityFields` values for this module.
    public record NodeIdentityFields(
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
        long inputCount,
        long inputNameStart,
        long inputNameLength,
        long inputArchiveStart,
        long requestCount,
        long requestNameStart,
        long requestNameLength,
        long requestPatternStart,
        long requestPatternLength,
        long maxSteps,
        long maxMemory,
        long maxInput,
        long maxOutput,
        long timeout,
        long grantCount,
        long grantNameStart,
        long grantNameLength,
        long grantPatternStart,
        long grantPatternLength
    ) {}

    private long writeLength(bytes output, long cursor, long length) {
        setByte(output, cursor, length % 256);
        setByte(output, cursor + 1, length / 256 % 256);
        setByte(output, cursor + 2, length / 65536 % 256);
        setByte(output, cursor + 3, length / 16777216 % 256);
        return cursor + 4;
    }

    private long copyField(byteview source, long start, long length, bytes output, long cursor) {
        cursor = writeLength(output, cursor, length);
        long offset = 0;
        while (offset < length) limit 256 {
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

    private long copyHashField(byteview source, long start, bytes output, long cursor) {
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

    private long writeDecimalField(long value, bytes output, long cursor) {
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

    private long writeKindField(long kind, bytes output, long cursor) {
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

    /// Checks one build-plan node against its content-derived identity.
    public boolean nodeIdentityMatches(
        byteview source,
        NodeIdentityFields fields,
        bytes digest,
        region arena
    ) {
        bytes identity = allocateBytes(arena, 2048);
        long cursor = writeLength(identity, 0, 20);
        writeAscii(identity, cursor, "wheeler-build-node-1");
        cursor += 20;
        cursor = copyField(source, fields.packageStart, fields.packageLength, identity, cursor);
        cursor = copyField(source, fields.versionStart, fields.versionLength, identity, cursor);
        cursor = copyHashField(source, fields.manifestIdentityStart, identity, cursor);
        cursor = copyField(source, fields.targetStart, fields.targetLength, identity, cursor);
        cursor = writeKindField(fields.targetKind, identity, cursor);
        cursor = copyHashField(source, fields.sourceIdentityStart, identity, cursor);
        cursor = copyField(source, fields.outputStart, fields.outputLength, identity, cursor);
        cursor = writeDecimalField(fields.inputCount, identity, cursor);
        if (fields.inputCount == 1) {
            cursor = copyField(
                source,
                fields.inputNameStart,
                fields.inputNameLength,
                identity,
                cursor
            );
            cursor = copyHashField(source, fields.inputArchiveStart, identity, cursor);
        }
        cursor = writeDecimalField(fields.requestCount, identity, cursor);
        if (fields.requestCount == 1) {
            cursor = copyField(
                source,
                fields.requestNameStart,
                fields.requestNameLength,
                identity,
                cursor
            );
            cursor = copyField(
                source,
                fields.requestPatternStart,
                fields.requestPatternLength,
                identity,
                cursor
            );
        }
        cursor = writeDecimalField(fields.maxSteps, identity, cursor);
        cursor = writeDecimalField(fields.maxMemory, identity, cursor);
        cursor = writeDecimalField(fields.maxInput, identity, cursor);
        cursor = writeDecimalField(fields.maxOutput, identity, cursor);
        cursor = writeDecimalField(fields.timeout, identity, cursor);
        cursor = writeDecimalField(fields.grantCount, identity, cursor);
        if (fields.grantCount == 1) {
            cursor = copyField(
                source,
                fields.grantNameStart,
                fields.grantNameLength,
                identity,
                cursor
            );
            cursor = copyField(
                source,
                fields.grantPatternStart,
                fields.grantPatternLength,
                identity,
                cursor
            );
        }
        hashSha256Range(identity, 0, cursor, digest, arena);
        drop(identity);
        long offset = 0;
        while (offset < 32) limit 32 {
            if (digest[offset] == source[fields.expectedStart + offset]) {
                offset += 1;
            } else {
                return false;
            }
        }
        return true;
    }
}
