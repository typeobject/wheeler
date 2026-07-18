module examples.packages.manifest;
import examples.lexer.scanner;
import examples.packages.names;
import examples.packages.paths;
import examples.packages.semver;
classical class Manifest {
    public record QuotedRange(long start, long length) {}

    public record ManifestHeader(
        QuotedRange name,
        QuotedRange version,
        QuotedRange profile,
        QuotedRange targetName,
        QuotedRange targetRoot,
        long targetCount,
        QuotedRange dependencyName,
        QuotedRange dependencyVersion,
        long dependencyCount,
        QuotedRange capabilityName,
        QuotedRange capabilityPath,
        long capabilityCount
    ) {}

    public variant ManifestResult {
        case Value(ManifestHeader header);
        case Error(long offset);
    }

    private long tokenHash(
        utf8 source,
        words starts,
        words lengths,
        long token
    ) {
        long cursor = starts[token];
        long end = cursor + lengths[token];
        long hash = 0;
        while (cursor < end) limit 16 {
            hash = hash * 31 + utf8Scalar(source, cursor);
            cursor += utf8Width(source, cursor);
        }
        return hash;
    }

    private boolean keywordAt(
        utf8 source,
        words starts,
        words lengths,
        long token,
        long hash
    ) {
        return tokenHash(source, starts, lengths, token) == hash;
    }

    private boolean quoted(words kinds, words lengths, long token) {
        if (kinds[token] == 6) {
            return 2 < lengths[token];
        }
        return false;
    }

    private boolean semicolonAt(
        utf8 source,
        words kinds,
        words starts,
        long token
    ) {
        if (kinds[token] == 3) {
            return utf8Scalar(source, starts[token]) == 59;
        }
        return false;
    }

    private QuotedRange quotedRange(
        words starts,
        words lengths,
        long token
    ) {
        return new QuotedRange(
            starts[token] + 1,
            lengths[token] - 2);
    }

    private boolean baseHeaderValid(
        utf8 source,
        words kinds,
        words starts,
        words lengths
    ) {
        boolean validName = validPackageName(
            source,
            starts[1] + 1,
            lengths[1] - 2);
        boolean validVersion = validRelease(
            source,
            starts[3] + 1,
            lengths[3] - 2);
        if (keywordAt(source, starts, lengths, 0, 102272152646)) {
            if (quoted(kinds, lengths, 1)) {
                if (validName) {
                    if (keywordAt(
                            source, starts, lengths, 2, 107725790424)) {
                        if (quoted(kinds, lengths, 3)) {
                            if (validVersion) {
                                if (keywordAt(
                                        source,
                                        starts,
                                        lengths,
                                        4,
                                        102769789353)) {
                                    if (quoted(kinds, lengths, 5)) {
                                        return semicolonAt(
                                            source, kinds, starts, 6);
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

    private boolean targetValid(
        utf8 source,
        words kinds,
        words starts,
        words lengths
    ) {
        boolean validRoot = validLogicalPath(
            source,
            starts[11] + 1,
            lengths[11] - 2);
        if (keywordAt(source, starts, lengths, 7, 3414061457)) {
            if (keywordAt(source, starts, lengths, 8, 93166309738)) {
                if (quoted(kinds, lengths, 9)) {
                    if (keywordAt(source, starts, lengths, 10, 3506402)) {
                        if (quoted(kinds, lengths, 11)) {
                            if (validRoot) {
                                return semicolonAt(
                                    source, kinds, starts, 12);
                            }
                        }
                    }
                }
            }
        }
        return false;
    }

    private boolean dependencyValid(
        utf8 source,
        words kinds,
        words starts,
        words lengths
    ) {
        boolean validName = validPackageName(
            source,
            starts[15] + 1,
            lengths[15] - 2);
        boolean validVersion = validConstraint(
            source,
            starts[17] + 1,
            lengths[17] - 2);
        if (keywordAt(
                source, starts, lengths, 13, 2733278506177355)) {
            if (keywordAt(source, starts, lengths, 14, 104630177752)) {
                if (quoted(kinds, lengths, 15)) {
                    if (validName) {
                        if (keywordAt(
                                source,
                                starts,
                                lengths,
                                16,
                                107725790424)) {
                            if (quoted(kinds, lengths, 17)) {
                                if (validVersion) {
                                    return semicolonAt(
                                        source, kinds, starts, 18);
                                }
                            }
                        }
                    }
                }
            }
        }
        return false;
    }

    private boolean capabilityValid(
        utf8 source,
        words kinds,
        words starts,
        words lengths
    ) {
        boolean validPath = validLogicalPath(
            source,
            starts[22] + 1,
            lengths[22] - 2);
        if (keywordAt(
                source, starts, lengths, 19, 2703423431124248)) {
            if (quoted(kinds, lengths, 20)) {
                if (keywordAt(source, starts, lengths, 21, 3433509)) {
                    if (quoted(kinds, lengths, 22)) {
                        if (validPath) {
                            return semicolonAt(
                                source, kinds, starts, 23);
                        }
                    }
                }
            }
        }
        return false;
    }

    private ManifestHeader header(
        words starts,
        words lengths,
        long targetCount,
        long dependencyCount,
        long capabilityCount
    ) {
        QuotedRange empty = new QuotedRange(0, 0);
        QuotedRange targetName = empty;
        QuotedRange targetRoot = empty;
        QuotedRange dependencyName = empty;
        QuotedRange dependencyVersion = empty;
        QuotedRange capabilityName = empty;
        QuotedRange capabilityPath = empty;
        if (targetCount == 1) {
            targetName = quotedRange(starts, lengths, 9);
            targetRoot = quotedRange(starts, lengths, 11);
        }
        if (dependencyCount == 1) {
            dependencyName = quotedRange(starts, lengths, 15);
            dependencyVersion = quotedRange(starts, lengths, 17);
        }
        if (capabilityCount == 1) {
            capabilityName = quotedRange(starts, lengths, 20);
            capabilityPath = quotedRange(starts, lengths, 22);
        }
        return new ManifestHeader(
            quotedRange(starts, lengths, 1),
            quotedRange(starts, lengths, 3),
            quotedRange(starts, lengths, 5),
            targetName,
            targetRoot,
            targetCount,
            dependencyName,
            dependencyVersion,
            dependencyCount,
            capabilityName,
            capabilityPath,
            capabilityCount);
    }

    public ManifestResult parseHeader(
        utf8 source,
        words kinds,
        words starts,
        words lengths,
        long count
    ) {
        if (baseHeaderValid(source, kinds, starts, lengths)) {
            if (count == 7) {
                return new ManifestResult.Value(
                    header(starts, lengths, 0, 0, 0));
            }
            if (targetValid(source, kinds, starts, lengths)) {
                if (count == 13) {
                    return new ManifestResult.Value(
                        header(starts, lengths, 1, 0, 0));
                }
                if (count == 19) {
                    if (dependencyValid(source, kinds, starts, lengths)) {
                        return new ManifestResult.Value(
                            header(starts, lengths, 1, 1, 0));
                    }
                }
                if (count == 24) {
                    if (dependencyValid(source, kinds, starts, lengths)) {
                        if (capabilityValid(source, kinds, starts, lengths)) {
                            return new ManifestResult.Value(
                                header(starts, lengths, 1, 1, 1));
                        }
                    }
                }
            }
        }
        return new ManifestResult.Error(0);
    }
}
