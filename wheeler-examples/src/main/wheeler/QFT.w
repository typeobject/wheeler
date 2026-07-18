//! A three-qubit QFT region followed by its compiler-generated adjoint.
quantum class QFT {
    const long QUBITS = 3;
    state long measured = 0;
    qreg q = new qreg(QUBITS);

    /// Applies the `qft` unitary.
    ///
    /// - Adjoint: Applies the compiler-generated reversed gate sequence.
    unitary void qft() {
        H(q[0]);
        CPhase(q[1], q[0], 1.5707963267948966);
        CPhase(q[2], q[0], 0.7853981633974483);
        H(q[1]);
        CPhase(q[2], q[1], 1.5707963267948966);
        H(q[2]);
        Swap(q[0], q[2]);
    }

    /// Checks the declared `qftAdjoint` proof certificate.
    theorem qftAdjoint proves adjoint(qft);

    /// Runs the bounded `QFT` fixture.
    ///
    /// - Effects: Mutates declared state and submits one bounded task to the explicit quantum target.
    entry void main() {
        prepare(q, 5);
        qft();
        reverse qft();
        measured = measure(q);
        assert measured == 5;
    }
}
