//! A static correction-kernel fixture; dynamic syndrome feedback requires a dynamic target.
quantum class SurfaceCode {
    state long measured = 0;
    qreg code = new qreg(3);

    /// Applies the `syndromeRound` unitary.
    ///
    /// - Adjoint: Applies the compiler-generated reversed gate sequence.
    unitary void syndromeRound() {
        X(code[0]);
        CNOT(code[0], code[1]);
        CNOT(code[0], code[2]);
    }

    /// Runs the bounded `SurfaceCode` fixture.
    ///
    /// - Effects: Mutates declared state and submits one bounded task to the explicit quantum target.
    entry void main() {
        prepare(code, 0);
        syndromeRound();
        reverse syndromeRound();
        measured = measure(code);
        assert(measured == 0);
    }
}
