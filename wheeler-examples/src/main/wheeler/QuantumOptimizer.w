// Two deterministic candidate evaluations with a committed classical update.
hybrid class QuantumOptimizer {
    state long sample = 0;
    state long bestCost = 2;
    state long accepted = 0;
    qreg candidate = new qreg(1);

    unitary void candidateOne() {
        X(candidate[0]);
    }

    rev void acceptCandidate() {
        bestCost -= 1;
        accepted ^= 1;
    }

    entry void main() {
        prepare(candidate, 0);
        sample = measure(candidate);
        assert sample == 0;

        prepare(candidate, 0);
        candidateOne();
        sample = measure(candidate);
        assert sample == 1;

        acceptCandidate();
        assert bestCost == 1;
        assert accepted == 1;
        commit();
    }
}
