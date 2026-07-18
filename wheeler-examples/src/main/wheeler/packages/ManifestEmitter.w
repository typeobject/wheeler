module examples.packages.emitter;
classical class ManifestEmitter {
    private boolean semicolonToken(
        utf8 source,
        words starts,
        long token
    ) {
        return utf8Scalar(source, starts[token]) == 59;
    }

    private long copyToken(
        utf8 source,
        long start,
        long length,
        bytes output,
        long outputCursor
    ) {
        long sourceCursor = start;
        long sourceEnd = start + length;
        long cursor = outputCursor;
        while (sourceCursor < sourceEnd) limit 256 {
            setByte(output, cursor, utf8Scalar(source, sourceCursor));
            cursor += 1;
            sourceCursor += utf8Width(source, sourceCursor);
        }
        return cursor;
    }

    public long emitCanonical(
        utf8 source,
        words starts,
        words lengths,
        long count,
        bytes output
    ) {
        long token = 0;
        long cursor = 0;
        while (token < count) limit 32 {
            cursor = copyToken(
                source,
                starts[token],
                lengths[token],
                output,
                cursor);
            long next = token + 1;
            if (next < count) {
                boolean beforeSemicolon = semicolonToken(
                    source, starts, next);
                if (beforeSemicolon) {
                    cursor += 0;
                } else {
                    setByte(output, cursor, 32);
                    cursor += 1;
                }
            }
            token += 1;
        }
        return cursor;
    }
}
