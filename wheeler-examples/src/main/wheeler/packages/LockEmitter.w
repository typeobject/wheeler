module examples.packages.lock_emitter;
classical class LockEmitter {
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

    public long emitCanonicalLock(
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
            long scalar = utf8Scalar(source, starts[token]);
            if (scalar == 59) {
                setByte(output, cursor, 10);
                cursor += 1;
            } else {
                if (token + 1 < count) {
                    long nextScalar = utf8Scalar(
                        source, starts[token + 1]);
                    if (nextScalar == 59) {
                        cursor = cursor;
                    } else {
                        setByte(output, cursor, 32);
                        cursor += 1;
                    }
                }
            }
            token += 1;
        }
        return cursor;
    }
}
