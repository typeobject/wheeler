//! Bounded loop exits, continuation edges, and an early typed return.
classical class LoopControl {
    state long sum = 0;
    state long selected = 0;

    long choose(boolean first) {
        if (first) {
            return 7;
        }
        return 9;
    }

    /// Runs the bounded `LoopControl` fixture.
    ///
    /// - Effects: Mutates only the fixture's declared state.
    entry void main() {
        long i = 0;
        while (i < 6) limit 6 {
            i += 1;
            if (i < 3) {
                continue;
            }
            sum += i;
            if (i == 5) {
                break;
            }
        }
        selected = choose(i == 5);
        assert sum == 12;
        assert selected == 7;
    }
}
