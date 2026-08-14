//! Reduces reordered, duplicated, conflicting, and checkpointed events.

module examples.events.reducer;

import wheeler.core.collections.long_map;

classical class EventReducer {
  state long lastEvent = -1;
  state long reduced = 0;
  state long duplicates = 0;
  state long conflicts = 0;
  state long checkpointSequence = 0;
  state long checkpointValue = 0;
  state long resumedValue = 0;

  long eventIdentity(long sequence, long value) {
    return sequence * 257 + value;
  }

  /// Applies one content-identified event exactly once per sequence occupant.
  void applyEvent(borrow mut longmap events, long sequence, long value) {
    long identity = eventIdentity(sequence, value);
    if (mapHas(events, sequence)) {
      if (mapGet(events, sequence) == identity) {
        duplicates += 1;
      } else {
        conflicts += 1;
      }
    } else {
      put(events, sequence, identity);
      reduced += value;
      if (lastEvent < sequence) {
        lastEvent = sequence;
      }
    }
  }

  /// Writes the canonical two-event checkpoint in ascending sequence order.
  void writeCheckpoint(borrow mut bytes checkpoint) {
    setByte(checkpoint, 0, 1);
    setByte(checkpoint, 1, 5);
    setByte(checkpoint, 2, 2);
    setByte(checkpoint, 3, 7);
  }

  /// Restores event identities and the reduced value from one exact checkpoint.
  void recoverCheckpoint(
    borrow mut bytes checkpoint,
    borrow mut longmap recovered
  ) {
    put(
      recovered,
      checkpoint[0],
      eventIdentity(checkpoint[0], checkpoint[1])
    );
    put(
      recovered,
      checkpoint[2],
      eventIdentity(checkpoint[2], checkpoint[3])
    );
    checkpointSequence = checkpoint[2];
    checkpointValue = checkpoint[1] + checkpoint[3];
    resumedValue = checkpointValue;
  }

  /// Reduces reordered delivery and resumes one persisted checkpoint.
  ///
  /// - Effects: Mutates declared state and bounded region-owned maps and bytes.
  entry void main() {
    region arena = new region(256, 4);
    longmap events = allocateMap(arena, 4);
    bytes checkpoint = allocateBytes(arena, 4);
    longmap recovered = allocateMap(arena, 4);
    bytes repeatedCheckpoint = allocateBytes(arena, 4);
    applyEvent(events, 2, 7);
    applyEvent(events, 1, 5);
    applyEvent(events, 2, 7);
    applyEvent(events, 1, 6);
    writeCheckpoint(checkpoint);
    writeCheckpoint(repeatedCheckpoint);
    assert(repeatedCheckpoint[0] == checkpoint[0]);
    assert(repeatedCheckpoint[1] == checkpoint[1]);
    assert(repeatedCheckpoint[2] == checkpoint[2]);
    assert(repeatedCheckpoint[3] == checkpoint[3]);
    recoverCheckpoint(checkpoint, recovered);
    applyEvent(recovered, 2, 7);
    assert(lastEvent == 2);
    assert(reduced == 12);
    assert(duplicates == 2);
    assert(conflicts == 1);
    assert(checkpointSequence == 2);
    assert(checkpointValue == 12);
    assert(resumedValue == 12);
    drop(repeatedCheckpoint);
    drop(recovered);
    drop(checkpoint);
    drop(events);
    drop(arena);
  }
}
