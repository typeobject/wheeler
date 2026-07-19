//! A one-bit coherent layer exercised classically and as a quantum permutation.
hybrid class QuantumNeuralNetwork {
    state long activation = 1;
    state long measured = 0;
    qreg layer = new qreg(1);

    /// Applies the reversible `flipActivation` state transition.
    ///
    /// - Inverse: Applies the compiler-generated inverse transition.
    /// - Coherent: Preserves amplitudes while permuting the declared basis state.
    coherent rev void flipActivation() {
        activation ^= 1;
    }

    /// Applies the `forwardLayer` unitary.
    ///
    /// - Adjoint: Applies the compiler-generated reversed gate sequence.
    unitary void forwardLayer() {
        layer.apply(flipActivation);
    }

    /// Runs the bounded `QuantumNeuralNetwork` fixture.
    ///
    /// - Effects: Mutates declared state and submits one bounded task to the explicit quantum target.
    entry void main() {
        flipActivation();
        assert(activation == 0);
        reverse flipActivation();
        assert(activation == 1);

        prepare(layer, 1);
        forwardLayer();
        measured = measure(layer);
        assert(measured == 0);
    }
}
