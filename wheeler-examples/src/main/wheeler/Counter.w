//! A complete classical reversible Wheeler program.
classical class Counter {
    state long count = 0;

    /// Applies the reversible `increment` state transition.
    ///
    /// - Inverse: Applies the compiler-generated inverse transition.
    rev void increment() {
        count += 1;
    }

    /// Checks the declared `incrementInverse` proof certificate.
    theorem incrementInverse proves inverse(increment);

    /// Runs the bounded `Counter` fixture.
    ///
    /// - Effects: Mutates only the fixture's declared state.
    entry void main() {
        increment();
        increment();
        assert(count == 2);

        // A reverse block invokes method inverses in reverse lexical order.
        reverse {
            increment();
            increment();
        }
        assert(count == 0);
    }
}
