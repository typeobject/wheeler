//! The same finite XOR permutation executes classically and coherently.
hybrid class CoherentOracle {
  state long bit = 0;
  state long measured = 0;
  qreg q = new qreg(1);

  /// Applies the reversible `flip` state transition.
  ///
  /// - Inverse: Applies the compiler-generated inverse transition.
  /// - Coherent: Preserves amplitudes while permuting the declared basis state.
  coherent rev void flip() {
    bit ^= 1;
  }

  /// Applies the `oracle` unitary.
  ///
  /// - Adjoint: Applies the compiler-generated reversed gate sequence.
  unitary void oracle() {
    q.apply(flip);
  }

  /// Runs the bounded `CoherentOracle` fixture.
  ///
  /// - Effects: Mutates declared state and submits one bounded task to the explicit quantum target.
  entry void main() {
    flip();
    assert(bit == 1);
    reverse flip();
    assert(bit == 0);

    prepare(q, 0);
    oracle();
    measured = measure(q);
    assert(measured == 1);
  }
}
