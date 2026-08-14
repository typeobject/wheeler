//! Advances a fixed-point two-body phase state through a reversible symplectic step.
classical class FixedPointSymplectic {
  const long SCALE = 1024;
  const long INITIAL_POSITION_A = SCALE * 7;
  const long INITIAL_MOMENTUM_A = SCALE * 5;
  const long INITIAL_POSITION_B = -7168;
  const long INITIAL_MOMENTUM_B = -5120;
  const long FORCE_KICK = SCALE * 2;
  const long POSITION_DRIFT = SCALE * 3;

  state long position = INITIAL_POSITION_A;
  state long momentum = INITIAL_MOMENTUM_A;
  state long positionB = INITIAL_POSITION_B;
  state long momentumB = INITIAL_MOMENTUM_B;
  state long observedPosition = 0;
  state long observedMomentum = 0;
  state long observedPositionB = 0;
  state long observedMomentumB = 0;
  state long generatedCases = 0;

  long kick(long momentumValue, long forceValue) {
    return momentumValue - forceValue;
  }

  long drift(long positionValue, long driftValue) {
    return positionValue + driftValue;
  }

  /// Applies equal-and-opposite kicks and position drifts to two bodies.
  ///
  /// - Inverse: Removes both drifts and kicks in exact reverse order.
  rev void advance() {
    momentum -= FORCE_KICK;
    position += POSITION_DRIFT;
    momentumB += FORCE_KICK;
    positionB -= POSITION_DRIFT;
  }

  /// Checks the generated reverse symplectic step.
  theorem advanceInverse proves inverse(advance);

  /// Exhausts a bounded phase grid and reverses one two-body step.
  ///
  /// - Effects: Mutates only fixture state and restores the initial phase point.
  entry void main() {
    long positionCase = 0;
    while (positionCase < 16) limit 16 {
      long momentumCase = 0;
      while (momentumCase < 16) limit 16 {
        long kicked = kick(momentumCase, 2);
        long drifted = drift(positionCase, 3);
        long restoredPosition = drifted - 3;
        long restoredMomentum = kicked + 2;
        assert(restoredPosition == positionCase);
        assert(restoredMomentum == momentumCase);
        generatedCases += 1;
        momentumCase += 1;
      }

      positionCase += 1;
    }

    long extremeMomentum = kick(-1000000, 1000000);
    long extremePosition = drift(1000000, -1000000);
    assert(extremeMomentum == -2000000);
    assert(extremePosition == 0);
    advance();
    observedPosition = position;
    observedMomentum = momentum;
    observedPositionB = positionB;
    observedMomentumB = momentumB;
    assert(observedPosition == 10240);
    assert(observedMomentum == 3072);
    assert(observedPositionB == -10240);
    assert(observedMomentumB == -3072);
    assert(observedMomentum + observedMomentumB == 0);

    reverse {
      advance();
    }

    assert(position == INITIAL_POSITION_A);
    assert(momentum == INITIAL_MOMENTUM_A);
    assert(positionB == INITIAL_POSITION_B);
    assert(momentumB == INITIAL_MOMENTUM_B);
    assert(generatedCases == 256);
  }
}
