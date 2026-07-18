module examples.main;
import examples.arithmetic;
import examples.results;
classical class ModuleMain {
    state long result = 0;
    state long decoded = 0;

    entry void main() {
        Pair selected = pair(9);
        result = selected.right;
        decoded = unwrap(classify(9));
        assert result == 18;
        assert decoded == 9;
    }
}
