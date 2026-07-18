module examples.packages.manifest;
import examples.lexer.scanner;
classical class Manifest {
    public record QuotedRange(long start, long length) {}

    public record ManifestHeader(
        QuotedRange name,
        QuotedRange version,
        QuotedRange profile,
        QuotedRange targetName,
        QuotedRange targetRoot,
        long targetCount
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
            return 1 < lengths[token];
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
        if (keywordAt(source, starts, lengths, 0, 102272152646)) {
            if (quoted(kinds, lengths, 1)) {
                if (keywordAt(source, starts, lengths, 2, 107725790424)) {
                    if (quoted(kinds, lengths, 3)) {
                        if (keywordAt(
                                source, starts, lengths, 4, 102769789353)) {
                            if (quoted(kinds, lengths, 5)) {
                                return semicolonAt(source, kinds, starts, 6);
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
        if (keywordAt(source, starts, lengths, 7, 3414061457)) {
            if (keywordAt(source, starts, lengths, 8, 93166309738)) {
                if (quoted(kinds, lengths, 9)) {
                    if (keywordAt(source, starts, lengths, 10, 3506402)) {
                        if (quoted(kinds, lengths, 11)) {
                            return semicolonAt(source, kinds, starts, 12);
                        }
                    }
                }
            }
        }
        return false;
    }

    public ManifestResult parseHeader(
        utf8 source,
        words kinds,
        words starts,
        words lengths,
        long count
    ) {
        if (baseHeaderValid(source, kinds, starts, lengths)) {
            QuotedRange name = quotedRange(starts, lengths, 1);
            QuotedRange version = quotedRange(starts, lengths, 3);
            QuotedRange profile = quotedRange(starts, lengths, 5);
            QuotedRange targetName = new QuotedRange(0, 0);
            QuotedRange targetRoot = new QuotedRange(0, 0);
            long targetCount = 0;
            if (count == 13) {
                if (targetValid(source, kinds, starts, lengths)) {
                    targetName = quotedRange(starts, lengths, 9);
                    targetRoot = quotedRange(starts, lengths, 11);
                    targetCount = 1;
                }
            }
            if (count == 7) {
                ManifestHeader header = new ManifestHeader(
                    name,
                    version,
                    profile,
                    targetName,
                    targetRoot,
                    targetCount);
                return new ManifestResult.Value(header);
            }
            if (targetCount == 1) {
                ManifestHeader targetHeader = new ManifestHeader(
                    name,
                    version,
                    profile,
                    targetName,
                    targetRoot,
                    targetCount);
                return new ManifestResult.Value(targetHeader);
            }
        }
        return new ManifestResult.Error(0);
    }
}
