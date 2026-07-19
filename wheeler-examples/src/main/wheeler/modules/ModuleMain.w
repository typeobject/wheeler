//! Exercises linked constants, values, aggregates, and qualified calls.

module examples.main;
import examples.arithmetic;
import examples.collections;
import examples.results;
classical class ModuleMain {
    state long result = 0;
    state long decoded = 0;
    state long arrayValue = 0;
    state long sliceValue = 0;
    state long nominalArrayValue = 0;
    state long nominalSliceValue = 0;
    state long qualifiedVariant = 0;

    /// Runs the bounded `ModuleMain` fixture.
    ///
    /// - Effects: Mutates only the fixture's declared state.
    entry void main() {
        Pair selected = pair(9);
        result = selected.right;
        examples.arithmetic::Pair second = pair(4);
        examples.arithmetic::Pair[2] pairs = new examples.arithmetic::Pair[2](selected, second);
        examples.arithmetic::Pair[] pairSlice = slice(pairs, 0, 2);
        nominalArrayValue = examples.arithmetic::lastRight(pairs);
        nominalSliceValue = rightTotal(pairSlice, 2);
        long[3] values = new long[3](4, 5, 6);
        long[] all = slice(values, 0, 3);
        arrayValue = examples.collections::middle(values);
        sliceValue = total(all, 3);
        examples.results::Outcome outcome = classify(9);
        examples.results::Outcome manual = new examples.results::Outcome.Value(9);
        if (outcome == manual) {
            qualifiedVariant = 1;
        }
        match (outcome) {
            case examples.results::Outcome.Error(long offset) {
                decoded = 0 - offset;
            }
            case examples.results::Outcome.Value(long value) {
                decoded = value;
            }
        }
        assert(result == 18);
        assert(decoded == 9);
        assert(arrayValue == 5);
        assert(sliceValue == 15);
        assert(nominalArrayValue == 8);
        assert(nominalSliceValue == 26);
        assert(qualifiedVariant == 1);
    }
}
