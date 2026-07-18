module examples.packages.manifest;
import examples.lexer.scanner;
classical class Manifest {
    public record QuotedRange(long start, long length) {}

    public record ManifestHeader(
        QuotedRange name,
        QuotedRange version,
        QuotedRange profile
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

    private boolean quoted(words kinds, words lengths, long token) {
        if (kinds[token] == 6) {
            return 1 < lengths[token];
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

    public ManifestResult parseHeader(
        utf8 source,
        words kinds,
        words starts,
        words lengths,
        long count
    ) {
        if (count == 7) {
            if (tokenHash(source, starts, lengths, 0) == 102272152646) {
                if (quoted(kinds, lengths, 1)) {
                    if (tokenHash(source, starts, lengths, 2)
                            == 107725790424) {
                        if (quoted(kinds, lengths, 3)) {
                            if (tokenHash(source, starts, lengths, 4)
                                    == 102769789353) {
                                if (quoted(kinds, lengths, 5)) {
                                    if (kinds[6] == 3) {
                                        if (utf8Scalar(source, starts[6]) == 59) {
                                            ManifestHeader header =
                                                new ManifestHeader(
                                                    quotedRange(
                                                        starts, lengths, 1),
                                                    quotedRange(
                                                        starts, lengths, 3),
                                                    quotedRange(
                                                        starts, lengths, 5));
                                            return new ManifestResult.Value(header);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return new ManifestResult.Error(0);
    }
}
