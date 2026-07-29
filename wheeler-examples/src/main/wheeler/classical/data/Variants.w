//! Exhaustive tagged selection with typed payload bindings and structural equality.
classical class Variants {
  variant LookupResult {
    case Missing();
    case Found(long value);
  }

  state long selected = 0;
  state long equal = 0;
  state long presence = 0;

  Done complete() {
    return done;
  }

  Slot<long> makeSlot(boolean available, long value) {
    if (available) {
      return new Slot<long>.Holding(value);
    }

    return new Slot<long>.Vacant();
  }

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
    Done completed = complete();
    LookupResult first = choose(true, 9);
    LookupResult second = new LookupResult.Found(9);
    Slot<long> slot = makeSlot(true, 11);
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

    match (slot) {
      case Slot<long>.Vacant() {
        presence = -1;
      }
      case Slot<long>.Holding(long presentValue) {
        presence = presentValue;
      }
    }

    assert(selected == 9);
    assert(equal == 1);
    assert(presence == 11);
  }
}
