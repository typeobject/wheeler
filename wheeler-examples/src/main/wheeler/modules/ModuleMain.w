module examples.main;
import examples.arithmetic;
import examples.collections;
import examples.results;
classical class ModuleMain {
    state long result = 0;
    state long decoded = 0;
    state long arrayValue = 0;
    state long sliceValue = 0;

    entry void main() {
        Pair selected = pair(9);
        result = selected.right;
        long[3] values = new long[3](4, 5, 6);
        long[] all = slice(values, 0, 3);
        arrayValue = middle(values);
        sliceValue = total(all, 3);
        Outcome outcome = classify(9);
        match (outcome) {
            case Outcome.Error(long offset) {
                decoded = 0 - offset;
            }
            case Outcome.Value(long value) {
                decoded = value;
            }
        }
        assert result == 18;
        assert decoded == 9;
        assert arrayValue == 5;
        assert sliceValue == 15;
    }
}
