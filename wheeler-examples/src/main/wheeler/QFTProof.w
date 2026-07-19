//! Executable inverse law for QFT; this is a conformance check, not a formal theorem.
quantum class QFTProof {
    state long measured = 0;
    qreg register = new qreg(2);

    /// Applies the `qft` unitary.
    ///
    /// - Adjoint: Applies the compiler-generated reversed gate sequence.
    unitary void qft() {
        H(register[0]);
        CPhase(register[1], register[0], 1.5707963267948966);
        H(register[1]);
        Swap(register[0], register[1]);
    }

    /// Runs the bounded `QFTProof` fixture.
    ///
    /// - Effects: Mutates declared state and submits one bounded task to the explicit quantum target.
    entry void main() {
        prepare(register, 2);
        qft();
        reverse qft();
        measured = measure(register);
        assert(measured == 2);
    }
}
