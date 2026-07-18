module examples.arithmetic;
classical class Arithmetic {
    private long add(long left, long right) {
        return left + right;
    }

    public long twice(long value) {
        return add(value, value);
    }
}
