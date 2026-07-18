module examples.arithmetic;
classical class Arithmetic {
    public record Pair(long left, long right) {}

    private long add(long left, long right) {
        return left + right;
    }

    public long twice(long value) {
        return add(value, value);
    }

    public Pair pair(long value) {
        return new Pair(value, twice(value));
    }

    public long lastRight(Pair[2] values) {
        return values[1].right;
    }

    public long rightTotal(Pair[] values, long count) {
        long result = 0;
        for (long index = 0; index < count; index += 1) limit 2 {
            result += values[index].right;
        }
        return result;
    }
}
