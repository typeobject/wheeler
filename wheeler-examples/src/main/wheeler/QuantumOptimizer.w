//! Two deterministic candidate evaluations with a committed classical update.
hybrid class QuantumOptimizer {
    state long sample = 0;
    state long bestCost = 2;
    state long accepted = 0;
    qreg candidate = new qreg(1);

    /// Applies the `candidateOne` unitary.
    ///
    /// - Adjoint: Applies the compiler-generated reversed gate sequence.
    unitary void candidateOne() {
        X(candidate[0]);
    }

    /// Applies the reversible `acceptCandidate` state transition.
    ///
    /// - Inverse: Applies the compiler-generated inverse transition.
    rev void acceptCandidate() {
        bestCost -= 1;
        accepted ^= 1;
    }

    /// Runs the bounded `QuantumOptimizer` fixture.
    ///
    /// - Effects: Mutates declared state and submits one bounded task to the explicit quantum target.
    entry void main() {
        prepare(candidate, 0);
        sample = measure(candidate);
        assert(sample == 0);

        prepare(candidate, 0);
        candidateOne();
        sample = measure(candidate);
        assert(sample == 1);

        acceptCandidate();
        assert(bestCost == 1);
        assert(accepted == 1);
        commit();
    }
}
