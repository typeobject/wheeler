//! Fixed immutable arrays with core reductions, checked indexing, and value equality.

module examples.collections.fixed_arrays_main;
import wheeler.core.collections.fixed_longs;
classical class FixedArrays {
    state long selected = 0;
    state long sum = 0;
    state long equal = 0;
    state long middleSum = 0;

    long[4] sequence() {
        return new long[4](2, 4, 6, 8);
    }

    /// Runs the bounded `FixedArrays` fixture.
    ///
    /// - Effects: Mutates only the fixture's declared state.
    entry void main() {
        long[4] first = sequence();
        long[4] second = new long[4](2, 4, 6, 8);
        long[] middle = slice(first, 1, 2);
        selected = middle[1];
        sum = total4(first);
        middleSum = subtotal2(middle);
        if (first == second) {
            equal = 1;
        }
        assert(selected == 6);
        assert(sum == 20);
        assert(middleSum == 10);
        assert(equal == 1);
    }
}
