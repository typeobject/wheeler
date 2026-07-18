module examples.main;
import examples.arithmetic;
import examples.results;
classical class ModuleMain {
    state long result = 0;
    state long decoded = 0;

    entry void main() {
        Pair selected = pair(9);
        result = selected.right;
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
    }
}
