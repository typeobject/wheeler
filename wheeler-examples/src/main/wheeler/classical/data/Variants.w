//! Exhaustive tagged selection with typed payload bindings and structural equality.
classical class Variants {
  variant LookupResult {
    case Missing();
    case Found(long value);
  }

  state long selected = 0;
  state long equal = 0;

  LookupResult choose(boolean present, long value) {
    if (present) {
      return new LookupResult.Found(value);
    }

    return new LookupResult.Missing();
  }

  /// Runs the bounded `Variants` fixture.
  ///
  /// - Effects: Mutates only the fixture's declared state.
  entry void main() {
    LookupResult first = choose(true, 9);
    LookupResult second = new LookupResult.Found(9);
    if (first == second) {
      equal = 1;
    }

    match (first) {
      case LookupResult.Missing() {
        selected = 1;
      }
      case LookupResult.Found(long value) {
        selected = value;
      }
    }

    assert(selected == 9);
    assert(equal == 1);
  }
}
