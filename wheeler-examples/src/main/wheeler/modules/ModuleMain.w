module examples.main;
import examples.arithmetic;
classical class ModuleMain {
    state long result = 0;

    entry void main() {
        result = twice(9);
        assert result == 18;
    }
}
