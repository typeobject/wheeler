//! Checks classical and coherent finite permutations over canonical case rows.

module wheeler.core.finite_permutations;

classical class FinitePermutations {
  private const long MAX_COHERENT_CASES = 4096;
  private const long MAX_FINITE_CASES = 65535;

  private boolean writePermutationTable(
    long cardinality,
    borrow mut words mapping,
    borrow mut words table
  ) {
    if (cardinality < 1) {
      return false;
    }

    if (MAX_FINITE_CASES < cardinality) {
      return false;
    }

    if (bufferLength(mapping) < cardinality) {
      return false;
    }

    if (bufferLength(table) < cardinality) {
      return false;
    }

    long input = 0;
    while (input < cardinality) limit MAX_FINITE_CASES {
      long output = mapping[input];
      if (output < 0) {
        return false;
      }

      if (cardinality - 1 < output) {
        return false;
      }

      if (table[output] != 0) {
        return false;
      }

      set(table, output, input + 1);
      input += 1;
    }

    return true;
  }

  private boolean powerOfTwo(long cardinality) {
    if (cardinality < 1) {
      return false;
    }

    if (MAX_COHERENT_CASES < cardinality) {
      return false;
    }

    long width = 1;
    while (width < cardinality) limit 12 {
      width = width * 2;
    }

    return width == cardinality;
  }

  /// Publishes the exact inverse only after checking one complete finite permutation.
  public boolean writeInverseFinitePermutation(
    long cardinality,
    borrow mut words mapping,
    borrow mut words inverse
  ) {
    if (cardinality < 1) {
      return false;
    }

    if (MAX_FINITE_CASES < cardinality) {
      return false;
    }

    if (bufferLength(inverse) < cardinality) {
      return false;
    }

    region scratchArena = new region(/* bytes= */ 524280, /* allocations= */ 1);
    words table = allocate(scratchArena, cardinality);
    boolean valid = writePermutationTable(cardinality, mapping, table);
    if (valid) {
      long output = 0;
      while (output < cardinality) limit MAX_FINITE_CASES {
        set(inverse, output, table[output] - 1);
        output += 1;
      }
    }

    drop(table);
    drop(scratchArena);
    return valid;
  }

  /// Applies one checked classical finite permutation by canonical case row.
  public long applyFinitePermutation(long cardinality, borrow mut words mapping, long input) {
    if (cardinality < 1) {
      return -1;
    }

    if (MAX_FINITE_CASES < cardinality) {
      return -1;
    }

    if (input < 0) {
      return -1;
    }

    if (cardinality - 1 < input) {
      return -1;
    }

    region scratchArena = new region(/* bytes= */ 524280, /* allocations= */ 1);
    words table = allocate(scratchArena, cardinality);
    boolean valid = writePermutationTable(cardinality, mapping, table);
    long result = -1;
    if (valid) {
      result = mapping[input];
    }

    drop(table);
    drop(scratchArena);
    return result;
  }

  /// Returns the exact coherent width or `-1` for an unsupported cardinality.
  public long coherentFiniteQubitCount(long cardinality) {
    if (powerOfTwo(cardinality) == false) {
      return -1;
    }

    long width = 0;
    long basis = 1;
    while (basis < cardinality) limit 12 {
      basis = basis * 2;
      width += 1;
    }

    return width;
  }

  /// Permutes exact split amplitude carriers and publishes no partial output.
  public boolean permuteFiniteAmplitudes(
    long cardinality,
    borrow mut words mapping,
    borrow mut words real,
    borrow mut words imaginary,
    borrow mut words outputReal,
    borrow mut words outputImaginary
  ) {
    if (powerOfTwo(cardinality) == false) {
      return false;
    }

    if (bufferLength(real) < cardinality) {
      return false;
    }

    if (bufferLength(imaginary) < cardinality) {
      return false;
    }

    if (bufferLength(outputReal) < cardinality) {
      return false;
    }

    if (bufferLength(outputImaginary) < cardinality) {
      return false;
    }

    region scratchArena = new region(/* bytes= */ 98304, /* allocations= */ 3);
    words table = allocate(scratchArena, MAX_COHERENT_CASES);
    words stagedReal = allocate(scratchArena, MAX_COHERENT_CASES);
    words stagedImaginary = allocate(scratchArena, MAX_COHERENT_CASES);
    boolean valid = writePermutationTable(cardinality, mapping, table);
    if (valid) {
      long input = 0;
      while (input < cardinality) limit MAX_COHERENT_CASES {
        long target = mapping[input];
        set(stagedReal, target, real[input]);
        set(stagedImaginary, target, imaginary[input]);
        input += 1;
      }

      long published = 0;
      while (published < cardinality) limit MAX_COHERENT_CASES {
        set(outputReal, published, stagedReal[published]);
        set(outputImaginary, published, stagedImaginary[published]);
        published += 1;
      }
    }

    drop(stagedImaginary);
    drop(stagedReal);
    drop(table);
    drop(scratchArena);
    return valid;
  }

  /// Observes one exact basis carrier and returns a classical case row or `-1`.
  public long measureExactFiniteBasis(
    long cardinality,
    long scale,
    borrow mut words real,
    borrow mut words imaginary
  ) {
    if (powerOfTwo(cardinality) == false) {
      return -1;
    }

    if (scale < 1) {
      return -1;
    }

    if (bufferLength(real) < cardinality) {
      return -1;
    }

    if (bufferLength(imaginary) < cardinality) {
      return -1;
    }

    long selected = -1;
    long basis = 0;
    while (basis < cardinality) limit MAX_COHERENT_CASES {
      if (imaginary[basis] != 0) {
        return -1;
      }

      if (real[basis] == scale) {
        if (-1 < selected) {
          return -1;
        }

        selected = basis;
      } else {
        if (real[basis] != 0) {
          return -1;
        }
      }

      basis += 1;
    }

    return selected;
  }
}
