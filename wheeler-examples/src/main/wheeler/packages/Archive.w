module examples.packages.archive;
import examples.crypto.sha256;
import examples.packages.binary;
classical class Archive {
    public record ArchiveModel(
        long manifestLength,
        long entryCount,
        long pathLength,
        long dataLength
    ) {}

    public variant ArchiveResult {
        case Value(ArchiveModel archive);
        case Error(long offset);
    }

    private boolean magicValid(byteview source) {
        if (source[0] == 87) {
            if (source[1] == 80) {
                if (source[2] == 75) {
                    if (source[3] == 71) {
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
        long sourceStart,
        long sourceLength,
        long digestStart,
        bytes digest,
        region arena
    ) {
        hashSha256Range(
            source, sourceStart, sourceLength, digest, arena);
        long cursor = 0;
        while (cursor < 32) limit 32 {
            if (digest[cursor] == source[digestStart + cursor]) {
                cursor += 1;
            } else {
                return false;
            }
        }
        return true;
    }

    private boolean canonicalManifestEnvelope(
        byteview source,
        long start,
        long length
    ) {
        if (length == 0) {
            return false;
        }
        if (source[start + length - 1] == 10) {
        } else {
            return false;
        }
        long cursor = 0;
        while (cursor < length) limit 4096 {
            long value = source[start + cursor];
            if (value == 10) {
            } else {
                if (value < 32) {
                    return false;
                }
                if (126 < value) {
                    return false;
                }
            }
            cursor += 1;
        }
        return true;
    }

    public ArchiveResult inspectArchive(
        byteview source,
        bytes digest,
        region arena
    ) {
        long fileLength = bufferLength(source);
        if (fileLength < 64) {
            return new ArchiveResult.Error(0);
        }
        long payloadLength = fileLength - 32;
        if (digestMatches(
                source, 0, payloadLength, payloadLength, digest, arena)) {
        } else {
            return new ArchiveResult.Error(payloadLength);
        }
        if (magicValid(source)) {
        } else {
            return new ArchiveResult.Error(0);
        }
        long manifestLength = readUnsigned(source, 8, 4);
        long entryCount = readUnsigned(source, 12, 4);
        if (manifestLength < 1) {
            return new ArchiveResult.Error(8);
        }
        if (4096 < manifestLength) {
            return new ArchiveResult.Error(8);
        }
        if (entryCount == 1) {
        } else {
            return new ArchiveResult.Error(12);
        }
        long manifestStart = 16;
        long cursor = manifestStart + manifestLength;
        if (payloadLength < cursor + 12) {
            return new ArchiveResult.Error(cursor);
        }
        if (canonicalManifestEnvelope(
                source, manifestStart, manifestLength)) {
        } else {
            return new ArchiveResult.Error(manifestStart);
        }
        long pathLength = readUnsigned(source, cursor, 4);
        cursor += 4;
        long dataLength = readUnsigned(source, cursor, 8);
        cursor += 8;
        if (pathLength < 1) {
            return new ArchiveResult.Error(cursor);
        }
        if (4096 < pathLength) {
            return new ArchiveResult.Error(cursor);
        }
        if (16777216 < dataLength) {
            return new ArchiveResult.Error(cursor);
        }
        long pathStart = cursor;
        long entryDigest = pathStart + pathLength;
        long dataStart = entryDigest + 32;
        if (dataStart + dataLength == payloadLength) {
        } else {
            return new ArchiveResult.Error(cursor);
        }
        if (validAsciiPath(source, pathStart, pathLength)) {
        } else {
            return new ArchiveResult.Error(pathStart);
        }
        if (digestMatches(
                source,
                dataStart,
                dataLength,
                entryDigest,
                digest,
                arena)) {
            ArchiveModel archive = new ArchiveModel(
                manifestLength, entryCount, pathLength, dataLength);
            return new ArchiveResult.Value(archive);
        }
        return new ArchiveResult.Error(entryDigest);
    }
}
