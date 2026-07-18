// A complete classical reversible Wheeler program.
classical class Counter {
    state long count = 0;

    rev void increment() {
        count += 1;
    }

    theorem incrementInverse proves inverse(increment);

    entry void main() {
        increment();
        increment();
        assert count == 2;

        // A reverse block invokes method inverses in reverse lexical order.
        reverse {
            increment();
            increment();
        }
        assert count == 0;
    }
}
