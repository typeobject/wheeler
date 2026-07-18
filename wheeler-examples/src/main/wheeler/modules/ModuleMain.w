module examples.main;
import examples.arithmetic;
classical class ModuleMain {
    state long result = 0;

    entry void main() {
        Pair selected = pair(9);
        result = selected.right;
        assert result == 18;
    }
}
