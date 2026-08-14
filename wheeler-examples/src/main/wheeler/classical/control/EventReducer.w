//! Reduces a fixed event stream with explicit duplicate-delivery accounting.
classical class EventReducer {
  state long lastEvent = -1;
  state long reduced = 0;
  state long duplicates = 0;

  /// Applies one event unless it repeats the immediately settled identity.
  void applyEvent(long event, long value) {
    if (event == lastEvent) {
      duplicates += 1;
    } else {
      reduced += value;
      lastEvent = event;
    }
  }

  /// Reduces one deterministic stream containing a duplicate delivery.
  ///
  /// - Effects: Mutates only the declared reducer state.
  entry void main() {
    applyEvent(1, 5);
    applyEvent(1, 5);
    applyEvent(2, 7);
    assert(lastEvent == 2);
    assert(reduced == 12);
    assert(duplicates == 1);
  }
}
