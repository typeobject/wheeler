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
        QuotedRange targetSecondSource,
        QuotedRange targetThirdSource,
        QuotedRange targetFourthSource,
        long targetSourceCount,
        long targetCount,
        QuotedRange dependencyName,
        QuotedRange dependencyVersion,
        QuotedRange secondDependencyName,
        QuotedRange secondDependencyVersion,
        long dependencyCount,
        QuotedRange capabilityName,
        QuotedRange capabilityPath,
        QuotedRange secondCapabilityName,
        QuotedRange secondCapabilityPath,
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

    private long compareTokenText(
        utf8 source,
        words starts,
        words lengths,
        long left,
        long right
    ) {
        long offset = 0;
        long commonLength = lengths[left];
        if (lengths[right] < commonLength) {
            commonLength = lengths[right];
        }
        while (offset < commonLength) limit 256 {
            long leftScalar = utf8Scalar(source, starts[left] + offset);
            long rightScalar = utf8Scalar(source, starts[right] + offset);
            if (leftScalar < rightScalar) {
                return -1;
            }
            if (rightScalar < leftScalar) {
                return 1;
            }
            offset += 1;
        }
        if (lengths[left] < lengths[right]) {
            return -1;
        }
        if (lengths[right] < lengths[left]) {
            return 1;
        }
        return 0;
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

    private long moduleSourceCount(
        utf8 source,
        words kinds,
        words starts,
        words lengths
    ) {
        if (semicolonAt(source, kinds, starts, 12)) {
            return 0;
        }
        if (keywordAt(source, starts, lengths, 12, 3226183276)) {
            if (quoted(kinds, lengths, 13)) {
                long count = 0;
                long cursor = 14;
                boolean scanning = true;
                while (scanning) limit 5 {
                    if (keywordAt(
                            source, starts, lengths, cursor, 3398461467)) {
                        if (quoted(kinds, lengths, cursor + 1)) {
                            count += 1;
                            cursor += 2;
                        } else {
                            scanning = false;
                        }
                    } else {
                        scanning = false;
                    }
                }
                if (0 < count) {
                    if (semicolonAt(source, kinds, starts, cursor)) {
                        return count;
                    }
                }
            }
        }
        return -1;
    }

    private boolean targetValid(
        utf8 source,
        words kinds,
        words starts,
        words lengths,
        long sourceCount
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
            if (sourceCount == 0) {
                return semicolonAt(source, kinds, starts, 12);
            }
            boolean validModule = validModuleName(
                source, starts[13] + 1, lengths[13] - 2);
            if (keywordAt(source, starts, lengths, 12, 3226183276)) {
                if (quoted(kinds, lengths, 13)) {
                    if (validModule) {
                        long sourceNumber = 0;
                        long sourceToken = 15;
                        long previousToken = -1;
                        boolean sourcesValid = true;
                        boolean sourceIncludesRoot = false;
                        while (sourceNumber < sourceCount) limit 4 {
                            boolean validSource = validLogicalPath(
                                source,
                                starts[sourceToken] + 1,
                                lengths[sourceToken] - 2);
                            if (validSource) {
                                if (sameTokenText(
                                        source,
                                        starts,
                                        lengths,
                                        11,
                                        sourceToken)) {
                                    sourceIncludesRoot = true;
                                }
                                if (-1 < previousToken) {
                                    long sourceOrder = compareTokenText(
                                        source,
                                        starts,
                                        lengths,
                                        previousToken,
                                        sourceToken);
                                    if (sourceOrder == 0) {
                                        sourcesValid = false;
                                    }
                                    if (0 < sourceOrder) {
                                        sourcesValid = false;
                                    }
                                }
                            } else {
                                sourcesValid = false;
                            }
                            previousToken = sourceToken;
                            sourceToken += 2;
                            sourceNumber += 1;
                        }
                        if (sourcesValid) {
                            if (sourceIncludesRoot) {
                                return semicolonAt(
                                    source,
                                    kinds,
                                    starts,
                                    14 + sourceCount * 2);
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
        long recordShift,
        long sourceCount
    ) {
        QuotedRange empty = new QuotedRange(0, 0);
        QuotedRange targetName = empty;
        QuotedRange targetRoot = empty;
        QuotedRange targetModule = empty;
        QuotedRange targetSource = empty;
        QuotedRange targetSecondSource = empty;
        QuotedRange targetThirdSource = empty;
        QuotedRange targetFourthSource = empty;
        long targetSourceCount = 0;
        QuotedRange dependencyName = empty;
        QuotedRange dependencyVersion = empty;
        QuotedRange secondDependencyName = empty;
        QuotedRange secondDependencyVersion = empty;
        QuotedRange capabilityName = empty;
        QuotedRange capabilityPath = empty;
        QuotedRange secondCapabilityName = empty;
        QuotedRange secondCapabilityPath = empty;
        if (targetCount == 1) {
            targetName = quotedRange(starts, lengths, 9);
            targetRoot = quotedRange(starts, lengths, 11);
        }
        if (0 < sourceCount) {
            targetModule = quotedRange(starts, lengths, 13);
            targetSource = quotedRange(starts, lengths, 15);
            targetSourceCount = sourceCount;
        }
        if (1 < sourceCount) {
            targetSecondSource = quotedRange(starts, lengths, 17);
        }
        if (2 < sourceCount) {
            targetThirdSource = quotedRange(starts, lengths, 19);
        }
        if (3 < sourceCount) {
            targetFourthSource = quotedRange(starts, lengths, 21);
        }
        long dependencyStart = 13 + recordShift;
        if (0 < dependencyCount) {
            dependencyName = quotedRange(
                starts, lengths, dependencyStart + 2);
            dependencyVersion = quotedRange(
                starts, lengths, dependencyStart + 4);
        }
        if (1 < dependencyCount) {
            secondDependencyName = quotedRange(
                starts, lengths, dependencyStart + 8);
            secondDependencyVersion = quotedRange(
                starts, lengths, dependencyStart + 10);
        }
        long capabilityStart = dependencyStart + dependencyCount * 6;
        if (0 < capabilityCount) {
            capabilityName = quotedRange(
                starts, lengths, capabilityStart + 1);
            capabilityPath = quotedRange(
                starts, lengths, capabilityStart + 3);
        }
        if (1 < capabilityCount) {
            secondCapabilityName = quotedRange(
                starts, lengths, capabilityStart + 6);
            secondCapabilityPath = quotedRange(
                starts, lengths, capabilityStart + 8);
        }
        return new ManifestHeader(
            quotedRange(starts, lengths, 1),
            quotedRange(starts, lengths, 3),
            quotedRange(starts, lengths, 5),
            targetName,
            targetRoot,
            targetModule,
            targetSource,
            targetSecondSource,
            targetThirdSource,
            targetFourthSource,
            targetSourceCount,
            targetCount,
            dependencyName,
            dependencyVersion,
            secondDependencyName,
            secondDependencyVersion,
            dependencyCount,
            capabilityName,
            capabilityPath,
            secondCapabilityName,
            secondCapabilityPath,
            capabilityCount);
    }

    private ManifestResult parseRecords(
        utf8 source,
        words kinds,
        words starts,
        words lengths,
        long count,
        long sourceCount,
        long recordShift
    ) {
        if (targetValid(
                source, kinds, starts, lengths, sourceCount)) {
            long cursor = 13 + recordShift;
            long dependencyCount = 0;
            boolean dependenciesSorted = true;
            if (dependencyValid(
                    source, kinds, starts, lengths, cursor)) {
                dependencyCount = 1;
                cursor += 6;
                if (dependencyValid(
                        source, kinds, starts, lengths, cursor)) {
                    long dependencyOrder = compareTokenText(
                        source,
                        starts,
                        lengths,
                        cursor - 4,
                        cursor + 2);
                    if (dependencyOrder < 0) {
                        dependencyCount = 2;
                        cursor += 6;
                    } else {
                        dependenciesSorted = false;
                    }
                }
            }
            if (dependenciesSorted) {
                long capabilityCount = 0;
                boolean capabilitiesSorted = true;
                if (capabilityValid(
                        source, kinds, starts, lengths, cursor)) {
                    capabilityCount = 1;
                    cursor += 5;
                    if (capabilityValid(
                            source, kinds, starts, lengths, cursor)) {
                        long capabilityNameOrder = compareTokenText(
                            source,
                            starts,
                            lengths,
                            cursor - 4,
                            cursor + 1);
                        long capabilityPathOrder = compareTokenText(
                            source,
                            starts,
                            lengths,
                            cursor - 2,
                            cursor + 3);
                        if (capabilityNameOrder < 0) {
                            capabilityCount = 2;
                            cursor += 5;
                        } else {
                            if (capabilityNameOrder == 0) {
                                if (capabilityPathOrder < 0) {
                                    capabilityCount = 2;
                                    cursor += 5;
                                } else {
                                    capabilitiesSorted = false;
                                }
                            } else {
                                capabilitiesSorted = false;
                            }
                        }
                    }
                }
                if (capabilitiesSorted) {
                    if (count == cursor) {
                        return new ManifestResult.Value(
                            header(
                                starts,
                                lengths,
                                1,
                                dependencyCount,
                                capabilityCount,
                                recordShift,
                                sourceCount));
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
                    header(starts, lengths, 0, 0, 0, 0, 0));
            }
            long sourceCount = moduleSourceCount(
                source, kinds, starts, lengths);
            if (-1 < sourceCount) {
                long recordShift = 0;
                if (0 < sourceCount) {
                    recordShift = 2 + sourceCount * 2;
                }
                return parseRecords(
                    source,
                    kinds,
                    starts,
                    lengths,
                    count,
                    sourceCount,
                    recordShift);
            }
        }
        return new ManifestResult.Error(0);
    }
}
