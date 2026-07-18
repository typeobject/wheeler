//! Classifies and compares package-manifest token ranges.

module wheeler.packages.tokens;
classical class ManifestTokens {
    /// Computes the stable hash of one bounded token range.
    public long tokenHash(utf8 source, words starts, words lengths, long token) {
        long cursor = starts[token];
        long end = cursor + lengths[token];
        long hash = 0;
        while (cursor < end) limit 16 {
            hash = hash * 31 + utf8Scalar(source, cursor);
            cursor += utf8Width(source, cursor);
        }
        return hash;
    }

    /// Checks whether one token carries the requested keyword hash.
    public boolean keywordAt(utf8 source, words starts, words lengths, long token, long hash) {
        return tokenHash(source, starts, lengths, token) == hash;
    }

    /// Checks whether `tokenText` denotes the same canonical value.
    public boolean sameTokenText(
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
            if (
                utf8Scalar(source, starts[left] + offset) == utf8Scalar(
                    source,
                    starts[right] + offset
                )
            ) {
                offset += 1;
            } else {
                return false;
            }
        }
        return true;
    }

    /// Compares `tokenText` under canonical byte ordering.
    public long compareTokenText(
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

    /// Checks whether one token is a quoted ASCII value.
    public boolean quoted(words kinds, words lengths, long token) {
        if (kinds[token] == 6) {
            return 2 < lengths[token];
        }
        return false;
    }

    /// Checks whether one token is the declaration terminator.
    public boolean semicolonAt(utf8 source, words kinds, words starts, long token) {
        if (kinds[token] == 3) {
            return utf8Scalar(source, starts[token]) == 59;
        }
        return false;
    }
}
