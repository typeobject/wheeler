// A one-bit coherent layer exercised classically and as a quantum permutation.
hybrid class QuantumNeuralNetwork {
    state long activation = 1;
    state long measured = 0;
    qreg layer = new qreg(1);

    coherent rev void flipActivation() {
        activation ^= 1;
    }

    unitary void forwardLayer() {
        layer.apply(flipActivation);
    }

    entry void main() {
        flipActivation();
        assert activation == 0;
        reverse flipActivation();
        assert activation == 1;

        prepare(layer, 1);
        forwardLayer();
        measured = measure(layer);
        assert measured == 0;
    }
}
