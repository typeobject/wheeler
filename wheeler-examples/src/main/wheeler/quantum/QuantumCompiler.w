//! Source and normalized circuits must preserve the same basis-state behavior.
quantum class QuantumCompiler {
  state long sourceResult = 0;
  state long normalizedResult = 0;
  qreg program = new qreg(2);

  /// Applies the `sourceCircuit` unitary.
  ///
  /// - Adjoint: Applies the compiler-generated reversed gate sequence.
  unitary void sourceCircuit() {
    X(program[0]);
    H(program[1]);
    H(program[1]);
  }

  /// Applies the `normalizedCircuit` unitary.
  ///
  /// - Adjoint: Applies the compiler-generated reversed gate sequence.
  unitary void normalizedCircuit() {
    X(program[0]);
  }

  /// Checks the declared `normalizationPreservesCircuit` proof certificate.
  theorem normalizationPreservesCircuit proves equivalent(sourceCircuit, normalizedCircuit);

  /// Runs the bounded `QuantumCompiler` fixture.
  ///
  /// - Effects: Mutates declared state and submits one bounded task to the explicit quantum target.
  entry void main() {
    prepare(program, 0);
    sourceCircuit();
    sourceResult = measure(program);
    assert(sourceResult == 1);

    prepare(program, 0);
    normalizedCircuit();
    normalizedResult = measure(program);
    assert(normalizedResult == 1);
  }
}
