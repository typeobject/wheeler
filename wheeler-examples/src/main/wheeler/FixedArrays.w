// Fixed immutable arrays with typed calls, checked indexing, and value equality.
classical class FixedArrays {
    state long selected = 0;
    state long sum = 0;
    state long equal = 0;

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

    entry void main() {
        long[4] first = sequence();
        long[4] second = new long[4](2, 4, 6, 8);
        selected = first[2];
        sum = total(first);
        if (first == second) {
            equal = 1;
        }
        assert selected == 6;
        assert sum == 20;
        assert equal == 1;
    }
}
