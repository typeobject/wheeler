// A static correction-kernel fixture; dynamic syndrome feedback requires a dynamic target.
quantum class SurfaceCode {
    state long measured = 0;
    qreg code = new qreg(3);

    unitary void syndromeRound() {
        X(code[0]);
        CNOT(code[0], code[1]);
        CNOT(code[0], code[2]);
    }

    entry void main() {
        prepare(code, 0);
        syndromeRound();
        reverse syndromeRound();
        measured = measure(code);
        assert measured == 0;
    }
}
