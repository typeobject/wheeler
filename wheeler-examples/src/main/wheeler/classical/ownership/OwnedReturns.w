//! Moves bounded storage owners from factory functions into their callers.
classical class OwnedReturns {
  state long wordValue = 0;
  state long byteValue = 0;
  state long scalarCount = 0;
  state long mapValue = 0;

  region makeRegion() {
    region result = new region(64, 4);
    return result;
  }

  words makeWords(borrow mut region arena) {
    words result = allocate(arena, 1);
    set(result, 0, 17);
    return result;
  }

  bytes makeBytes(borrow mut region arena) {
    bytes result = allocateBytes(arena, 1);
    setByte(result, 0, 65);
    return result;
  }

  utf8 makeText(borrow mut region arena) {
    bytes raw = allocateBytes(arena, 3);
    setByte(raw, 0, 65);
    setByte(raw, 1, 194);
    setByte(raw, 2, 162);
    utf8 result = freezeUtf8(raw);
    return result;
  }

  longmap makeMap(borrow mut region arena) {
    longmap result = allocateMap(arena, 1);
    put(result, 7, 23);
    return result;
  }

  void disposeAll(region arena, words numbers, bytes packet, utf8 text, longmap values) {
    drop(values);
    drop(text);
    drop(packet);
    drop(numbers);
    drop(arena);
  }

  /// Runs the bounded ownership-return fixture.
  ///
  /// - Effects: Mutates declared state and explicitly drops every returned owner.
  entry void main() {
    region arena = makeRegion();
    words numbers = makeWords(arena);
    bytes packet = makeBytes(arena);
    utf8 text = makeText(arena);
    longmap values = makeMap(arena);

    wordValue = numbers[0];
    byteValue = packet[0];
    scalarCount = utf8Count(text);
    mapValue = mapGet(values, 7);
    assert(wordValue == 17);
    assert(byteValue == 65);
    assert(scalarCount == 2);
    assert(mapValue == 23);

    disposeAll(arena, numbers, packet, text, values);
  }
}
