module examples.collections;
classical class Collections {
    public long middle(long[3] values) {
        return values[1];
    }

    public long total(long[] values, long count) {
        long result = 0;
        for (long index = 0; index < count; index += 1) limit 3 {
            result += values[index];
        }
        return result;
    }
}
