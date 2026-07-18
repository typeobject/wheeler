module examples.packages.lock;
import examples.packages.names;
import examples.packages.semver;
import examples.packages.tokens;
classical class Lock {
    public record LockedPackage(
        long nameStart,
        long nameLength,
        long versionLength,
        long archiveStart,
        long manifestStart
    ) {}

    public record LockModel(
        long rootStart,
        LockedPackage first,
        LockedPackage second,
        long packageCount,
        long edgeSourceStart,
        long edgeTargetStart,
        long edgeCount
    ) {}

    public variant LockResult {
        case Value(LockModel lock);
        case Error(long offset);
    }

    private boolean hexDigest(
        utf8 source,
        words starts,
        words lengths,
        long token
    ) {
        if (lengths[token] == 66) {
            long cursor = starts[token] + 1;
            long end = cursor + 64;
            while (cursor < end) limit 64 {
                long scalar = utf8Scalar(source, cursor);
                boolean valid = false;
                if (47 < scalar) {
                    if (scalar < 58) {
                        valid = true;
                    }
                }
                if (96 < scalar) {
                    if (scalar < 103) {
                        valid = true;
                    }
                }
                if (valid) {
                    cursor += 1;
                } else {
                    return false;
                }
            }
            return true;
        }
        return false;
    }

    private boolean packageValid(
        utf8 source,
        words kinds,
        words starts,
        words lengths,
        long recordStart
    ) {
        boolean validName = validPackageName(
            source,
            starts[recordStart + 1] + 1,
            lengths[recordStart + 1] - 2);
        boolean validVersion = validRelease(
            source,
            starts[recordStart + 3] + 1,
            lengths[recordStart + 3] - 2);
        if (keywordAt(
                source, starts, lengths, recordStart, 102272152646)) {
            if (quoted(kinds, lengths, recordStart + 1)) {
                if (validName) {
                    if (keywordAt(
                            source,
                            starts,
                            lengths,
                            recordStart + 2,
                            107725790424)) {
                        if (quoted(kinds, lengths, recordStart + 3)) {
                            if (validVersion) {
                                if (keywordAt(
                                        source,
                                        starts,
                                        lengths,
                                        recordStart + 4,
                                        89446211778)) {
                                    if (hexDigest(
                                            source,
                                            starts,
                                            lengths,
                                            recordStart + 5)) {
                                        if (keywordAt(
                                                source,
                                                starts,
                                                lengths,
                                                recordStart + 6,
                                                3088212110895)) {
                                            if (hexDigest(
                                                    source,
                                                    starts,
                                                    lengths,
                                                    recordStart + 7)) {
                                                return semicolonAt(
                                                    source,
                                                    kinds,
                                                    starts,
                                                    recordStart + 8);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return false;
    }

    private LockedPackage lockedPackage(
        words starts,
        words lengths,
        long recordStart
    ) {
        return new LockedPackage(
            starts[recordStart + 1] + 1,
            lengths[recordStart + 1] - 2,
            lengths[recordStart + 3] - 2,
            starts[recordStart + 5] + 1,
            starts[recordStart + 7] + 1);
    }

    private boolean edgeValid(
        utf8 source,
        words kinds,
        words starts,
        words lengths,
        long recordStart
    ) {
        if (keywordAt(
                source, starts, lengths, recordStart, 3108285)) {
            if (quoted(kinds, lengths, recordStart + 1)) {
                if (quoted(kinds, lengths, recordStart + 2)) {
                    boolean sourceKnown = sameTokenText(
                        source, starts, lengths, 6, recordStart + 1);
                    boolean targetKnown = sameTokenText(
                        source, starts, lengths, 15, recordStart + 2);
                    if (sourceKnown) {
                        if (targetKnown) {
                            return semicolonAt(
                                source,
                                kinds,
                                starts,
                                recordStart + 3);
                        }
                    }
                }
            }
        }
        return false;
    }

    public LockResult parse(
        utf8 source,
        words kinds,
        words starts,
        words lengths,
        long count
    ) {
        if (keywordAt(source, starts, lengths, 0, 3327275)) {
            if (kinds[1] == 2) {
                if (tokenHash(source, starts, lengths, 1) == 49) {
                    if (keywordAt(source, starts, lengths, 2, 3506402)) {
                        if (hexDigest(source, starts, lengths, 3)) {
                            if (semicolonAt(source, kinds, starts, 4)) {
                                if (packageValid(
                                        source,
                                        kinds,
                                        starts,
                                        lengths,
                                        5)) {
                                    LockedPackage first = lockedPackage(
                                        starts, lengths, 5);
                                    LockedPackage empty = new LockedPackage(
                                        0, 0, 0, 0, 0);
                                    if (count == 14) {
                                        LockModel one = new LockModel(
                                            starts[3] + 1,
                                            first,
                                            empty,
                                            1,
                                            0,
                                            0,
                                            0);
                                        return new LockResult.Value(one);
                                    }
                                    if (packageValid(
                                            source,
                                            kinds,
                                            starts,
                                            lengths,
                                            14)) {
                                        long packageOrder = compareTokenText(
                                            source,
                                            starts,
                                            lengths,
                                            6,
                                            15);
                                        if (packageOrder < 0) {
                                            LockedPackage second = lockedPackage(
                                                starts, lengths, 14);
                                            if (count == 23) {
                                                LockModel two = new LockModel(
                                                    starts[3] + 1,
                                                    first,
                                                    second,
                                                    2,
                                                    0,
                                                    0,
                                                    0);
                                                return new LockResult.Value(two);
                                            }
                                            if (count == 27) {
                                                if (edgeValid(
                                                        source,
                                                        kinds,
                                                        starts,
                                                        lengths,
                                                        23)) {
                                                    LockModel edge = new LockModel(
                                                        starts[3] + 1,
                                                        first,
                                                        second,
                                                        2,
                                                        starts[24] + 1,
                                                        starts[25] + 1,
                                                        1);
                                                    return new LockResult.Value(edge);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return new LockResult.Error(0);
    }
}
