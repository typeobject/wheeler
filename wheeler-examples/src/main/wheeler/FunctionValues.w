// Typed parameters, return values, nested expressions, and static value calls.
classical class FunctionValues {
    state long result = 0;

    long add(long left, long right) {
        return left + right;
    }

    long triangular(long limit) {
        long i = 0;
        long sum = 0;
        while (i < limit) limit 8 {
            sum += i;
            i += 1;
        }
        return sum;
    }

    entry void main() {
        long base = add(2, 3);
        long total = triangular(base);
        result = total;
        assert result == 10;
    }
}
