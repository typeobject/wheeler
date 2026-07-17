// The same finite XOR permutation executes classically and coherently.
hybrid class CoherentOracle {
    state long bit = 0;
    state long measured = 0;
    qreg q = new qreg(1);

    coherent rev void flip() {
        bit ^= 1;
    }

    unitary void oracle() {
        q.apply(flip);
    }

    entry void main() {
        flip();
        assert bit == 1;
        reverse flip();
        assert bit == 0;

        prepare(q, 0);
        oracle();
        measured = measure(q);
        assert measured == 1;
    }
}
