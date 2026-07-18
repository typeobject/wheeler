// Signed and Boolean parameters/results, nested expressions, and typed static calls.
classical class FunctionValues {
    state long result = 0;

    long add(long left, long right) {
        return left + right;
    }

    theorem addBound proves steps(add, 4);

    boolean same(boolean left, boolean right) {
        return left == right;
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
        boolean valid = same(total == 10, true);
        if (valid) {
            result = total;
        } else {
            result = 0;
        }
        assert result == 10;
    }
}
