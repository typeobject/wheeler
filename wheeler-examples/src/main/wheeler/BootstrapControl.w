// Typed locals, checked expressions, branches, and a source-bounded loop.
classical class BootstrapControl {
    state long sum = 0;
    state long branch = 0;

    entry void main() {
        long i = 0;
        while (i < 5) limit 5 {
            sum += i;
            i += 1;
        }

        boolean complete = sum == 10;
        if (complete) {
            branch = 1;
        } else {
            branch = 2;
        }

        assert sum == 10;
        assert branch == 1;
    }
}
