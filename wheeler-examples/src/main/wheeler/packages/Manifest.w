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
        QuotedRange targetModule,
        QuotedRange targetSource,
        long targetSourceCount,
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

    private boolean sameTokenText(
        utf8 source,
        words starts,
        words lengths,
        long left,
        long right
    ) {
        if (lengths[left] < lengths[right]) {
            return false;
        }
        if (lengths[right] < lengths[left]) {
            return false;
        }
        long offset = 0;
        while (offset < lengths[left]) limit 256 {
            if (utf8Scalar(source, starts[left] + offset)
                    == utf8Scalar(source, starts[right] + offset)) {
                offset += 1;
            } else {
                return false;
            }
        }
        return true;
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

    private boolean targetKindValid(
        utf8 source,
        words starts,
        words lengths
    ) {
        long hash = tokenHash(source, starts, lengths, 8);
        if (hash == 2906000385) {
            return true;
        }
        if (hash == 98950456507) {
            return true;
        }
        if (hash == 3565976) {
            return true;
        }
        if (hash == 3556498) {
            return true;
        }
        return hash == 93166309738;
    }

    private boolean dependencyKindValid(
        utf8 source,
        words starts,
        words lengths,
        long recordStart
    ) {
        long hash = tokenHash(
            source, starts, lengths, recordStart + 1);
        if (hash == 3255221479) {
            return true;
        }
        if (hash == 84736749587766587) {
            return true;
        }
        return hash == 94094958;
    }

    private boolean targetValid(
        utf8 source,
        words kinds,
        words starts,
        words lengths,
        long modular
    ) {
        boolean validRoot = validLogicalPath(
            source,
            starts[11] + 1,
            lengths[11] - 2);
        boolean baseValid = false;
        if (keywordAt(source, starts, lengths, 7, 3414061457)) {
            if (targetKindValid(source, starts, lengths)) {
                if (quoted(kinds, lengths, 9)) {
                    if (keywordAt(source, starts, lengths, 10, 3506402)) {
                        if (quoted(kinds, lengths, 11)) {
                            baseValid = validRoot;
                        }
                    }
                }
            }
        }
        if (baseValid) {
            if (modular == 0) {
                return semicolonAt(source, kinds, starts, 12);
            }
            boolean validModule = validModuleName(
                source, starts[13] + 1, lengths[13] - 2);
            boolean validSource = validLogicalPath(
                source, starts[15] + 1, lengths[15] - 2);
            boolean sourceIncludesRoot = sameTokenText(
                source, starts, lengths, 11, 15);
            if (keywordAt(source, starts, lengths, 12, 3226183276)) {
                if (quoted(kinds, lengths, 13)) {
                    if (validModule) {
                        if (keywordAt(
                                source, starts, lengths, 14, 3398461467)) {
                            if (quoted(kinds, lengths, 15)) {
                                if (validSource) {
                                    if (sourceIncludesRoot) {
                                        return semicolonAt(
                                            source, kinds, starts, 16);
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

    private boolean dependencyValid(
        utf8 source,
        words kinds,
        words starts,
        words lengths,
        long recordStart
    ) {
        boolean validName = validPackageName(
            source,
            starts[recordStart + 2] + 1,
            lengths[recordStart + 2] - 2);
        boolean validVersion = validConstraint(
            source,
            starts[recordStart + 4] + 1,
            lengths[recordStart + 4] - 2);
        if (keywordAt(
                source,
                starts,
                lengths,
                recordStart,
                2733278506177355)) {
            if (dependencyKindValid(
                    source, starts, lengths, recordStart)) {
                if (quoted(kinds, lengths, recordStart + 2)) {
                    if (validName) {
                        if (keywordAt(
                                source,
                                starts,
                                lengths,
                                recordStart + 3,
                                107725790424)) {
                            if (quoted(kinds, lengths, recordStart + 4)) {
                                if (validVersion) {
                                    return semicolonAt(
                                        source,
                                        kinds,
                                        starts,
                                        recordStart + 5);
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
        words lengths,
        long recordStart
    ) {
        boolean validPath = validLogicalPath(
            source,
            starts[recordStart + 3] + 1,
            lengths[recordStart + 3] - 2);
        if (keywordAt(
                source,
                starts,
                lengths,
                recordStart,
                2703423431124248)) {
            if (quoted(kinds, lengths, recordStart + 1)) {
                if (keywordAt(
                        source,
                        starts,
                        lengths,
                        recordStart + 2,
                        3433509)) {
                    if (quoted(kinds, lengths, recordStart + 3)) {
                        if (validPath) {
                            return semicolonAt(
                                source,
                                kinds,
                                starts,
                                recordStart + 4);
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
        long capabilityCount,
        long recordShift
    ) {
        QuotedRange empty = new QuotedRange(0, 0);
        QuotedRange targetName = empty;
        QuotedRange targetRoot = empty;
        QuotedRange targetModule = empty;
        QuotedRange targetSource = empty;
        long targetSourceCount = 0;
        QuotedRange dependencyName = empty;
        QuotedRange dependencyVersion = empty;
        QuotedRange capabilityName = empty;
        QuotedRange capabilityPath = empty;
        if (targetCount == 1) {
            targetName = quotedRange(starts, lengths, 9);
            targetRoot = quotedRange(starts, lengths, 11);
        }
        if (recordShift == 4) {
            targetModule = quotedRange(starts, lengths, 13);
            targetSource = quotedRange(starts, lengths, 15);
            targetSourceCount = 1;
        }
        if (dependencyCount == 1) {
            dependencyName = quotedRange(
                starts, lengths, 15 + recordShift);
            dependencyVersion = quotedRange(
                starts, lengths, 17 + recordShift);
        }
        if (capabilityCount == 1) {
            capabilityName = quotedRange(
                starts, lengths, 20 + recordShift);
            capabilityPath = quotedRange(
                starts, lengths, 22 + recordShift);
        }
        return new ManifestHeader(
            quotedRange(starts, lengths, 1),
            quotedRange(starts, lengths, 3),
            quotedRange(starts, lengths, 5),
            targetName,
            targetRoot,
            targetModule,
            targetSource,
            targetSourceCount,
            targetCount,
            dependencyName,
            dependencyVersion,
            dependencyCount,
            capabilityName,
            capabilityPath,
            capabilityCount);
    }

    private ManifestResult parseRecords(
        utf8 source,
        words kinds,
        words starts,
        words lengths,
        long count,
        long modular,
        long recordShift
    ) {
        if (targetValid(
                source, kinds, starts, lengths, modular)) {
            if (count == 13 + recordShift) {
                return new ManifestResult.Value(
                    header(starts, lengths, 1, 0, 0, recordShift));
            }
            if (count == 19 + recordShift) {
                if (dependencyValid(
                        source,
                        kinds,
                        starts,
                        lengths,
                        13 + recordShift)) {
                    return new ManifestResult.Value(
                        header(starts, lengths, 1, 1, 0, recordShift));
                }
            }
            if (count == 24 + recordShift) {
                if (dependencyValid(
                        source,
                        kinds,
                        starts,
                        lengths,
                        13 + recordShift)) {
                    if (capabilityValid(
                            source,
                            kinds,
                            starts,
                            lengths,
                            19 + recordShift)) {
                        return new ManifestResult.Value(
                            header(starts, lengths, 1, 1, 1, recordShift));
                    }
                }
            }
        }
        return new ManifestResult.Error(0);
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
                    header(starts, lengths, 0, 0, 0, 0));
            }
            if (count == 13) {
                return parseRecords(
                    source, kinds, starts, lengths, count, 0, 0);
            }
            if (count == 19) {
                return parseRecords(
                    source, kinds, starts, lengths, count, 0, 0);
            }
            if (count == 24) {
                return parseRecords(
                    source, kinds, starts, lengths, count, 0, 0);
            }
            if (count == 17) {
                return parseRecords(
                    source, kinds, starts, lengths, count, 1, 4);
            }
            if (count == 23) {
                return parseRecords(
                    source, kinds, starts, lengths, count, 1, 4);
            }
            if (count == 28) {
                return parseRecords(
                    source, kinds, starts, lengths, count, 1, 4);
            }
        }
        return new ManifestResult.Error(0);
    }
}
