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
}
