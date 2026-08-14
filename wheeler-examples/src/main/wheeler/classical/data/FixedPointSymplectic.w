//! Advances one fixed-point phase-space state through a reversible symplectic step.
classical class FixedPointSymplectic {
  const long SCALE = 1024;
  const long INITIAL_POSITION = SCALE * 7;
  const long INITIAL_MOMENTUM = SCALE * 5;
  const long FORCE_KICK = SCALE * 2;
  const long POSITION_DRIFT = SCALE * 3;

  state long position = INITIAL_POSITION;
  state long momentum = INITIAL_MOMENTUM;
  state long observedPosition = 0;
  state long observedMomentum = 0;

  /// Applies one fixed-point kick-drift symplectic step.
  ///
  /// - Inverse: Removes the drift and kick in reverse order without rounding.
  rev void advance() {
    momentum -= FORCE_KICK;
    position += POSITION_DRIFT;
  }

  /// Checks the generated reverse symplectic step.
  theorem advanceInverse proves inverse(advance);

  /// Executes and reverses one fixed-point phase-space step.
  ///
  /// - Effects: Mutates only fixture state and restores the initial phase point.
  entry void main() {
    advance();
    observedPosition = position;
    observedMomentum = momentum;
    assert(observedPosition == 10240);
    assert(observedMomentum == 3072);

    reverse {
      advance();
    }

    assert(position == INITIAL_POSITION);
    assert(momentum == INITIAL_MOMENTUM);
  }
}
