// Source and normalized circuits must preserve the same basis-state behavior.
quantum class QuantumCompiler {
    state long sourceResult = 0;
    state long normalizedResult = 0;
    qreg program = new qreg(2);

    unitary void sourceCircuit() {
        X(program[0]);
        H(program[1]);
        H(program[1]);
    }

    unitary void normalizedCircuit() {
        X(program[0]);
    }

    entry void main() {
        prepare(program, 0);
        sourceCircuit();
        sourceResult = measure(program);
        assert sourceResult == 1;

        prepare(program, 0);
        normalizedCircuit();
        normalizedResult = measure(program);
        assert normalizedResult == 1;
    }
}
