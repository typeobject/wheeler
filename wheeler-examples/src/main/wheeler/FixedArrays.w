// Fixed immutable arrays with typed calls, checked indexing, and value equality.
classical class FixedArrays {
    state long selected = 0;
    state long sum = 0;
    state long equal = 0;
    state long middleSum = 0;

    long[4] sequence() {
        return new long[4](2, 4, 6, 8);
    }

    long total(long[4] values) {
        long result = 0;
        for (long index = 0; index < 4; index += 1) limit 4 {
            result += values[index];
        }
        return result;
    }

    long subtotal(long[] values, long count) {
        long result = 0;
        for (long index = 0; index < count; index += 1) limit 4 {
            result += values[index];
        }
        return result;
    }

    entry void main() {
        long[4] first = sequence();
        long[4] second = new long[4](2, 4, 6, 8);
        long[] middle = slice(first, 1, 2);
        selected = middle[1];
        sum = total(first);
        middleSum = subtotal(middle, 2);
        if (first == second) {
            equal = 1;
        }
        assert selected == 6;
        assert sum == 20;
        assert middleSum == 10;
        assert equal == 1;
    }
}
