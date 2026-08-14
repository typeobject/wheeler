//! Recovers one copy-on-write index root from an ordered bounded commit log.

module examples.index.transactional;

import wheeler.core.collections.long_map;

classical class TransactionalPersistentIndex {
  variant ApplyResult {
    case Applied(long root, long sequence);
    case Duplicate(long sequence);
    case Torn(long sequence);
  }

  const long RECORDS = 3;
  const long RECORD_WIDTH = 3;

  state long committedRoot = 7;
  state long stagedRoot = 0;
  state long reopenedRoot = 0;
  state long reopenedSequence = 0;
  state long duplicateRejected = 0;
  state long tornRecovered = 0;
  state long commitMarkerObserved = 0;

  long recordBase(long sequence) {
    return sequence * RECORD_WIDTH;
  }

  ApplyResult applyTransaction(
    borrow mut bytes log,
    borrow mut longmap applied,
    long identity,
    long sequence,
    long replacement,
    boolean complete
  ) {
    if (mapHas(applied, identity)) {
      return new ApplyResult.Duplicate(mapGet(applied, identity));
    }

    long base = recordBase(sequence);
    setByte(log, base, replacement);
    setByte(log, base + 1, sequence);
    if (complete) {
      setByte(log, base + 2, 1);
      put(applied, identity, sequence);
      return new ApplyResult.Applied(replacement, sequence);
    }

    return new ApplyResult.Torn(sequence);
  }

  long recoverRoot(borrow mut bytes log) {
    long selectedRoot = 0;
    long selectedSequence = -1;
    long record = 0;
    while (record < RECORDS) limit RECORDS {
      long base = record * RECORD_WIDTH;
      if (log[base + 2] == 1) {
        if (selectedSequence < log[base + 1]) {
          selectedRoot = log[base];
          selectedSequence = log[base + 1];
        }
      }

      record += 1;
    }

    reopenedSequence = selectedSequence;
    return selectedRoot;
  }

  /// Stages, commits, replays, tears, and reopens one bounded index log.
  ///
  /// - Effects: Mutates declared state and bounded region-owned log storage.
  entry void main() {
    region arena = new region(128, 2);
    bytes log = allocateBytes(arena, RECORDS * RECORD_WIDTH);
    longmap applied = allocateMap(arena, 4);
    setByte(log, 0, committedRoot);
    setByte(log, 1, 0);
    setByte(log, 2, 1);
    stagedRoot = 11;
    assert(committedRoot == 7);
    ApplyResult first = applyTransaction(log, applied, 101, 1, stagedRoot, true);
    match (first) {
      case ApplyResult.Applied(long firstRoot, long firstSequence) {
        committedRoot = firstRoot;
        commitMarkerObserved = log[recordBase(firstSequence) + 2];
      }
      case ApplyResult.Duplicate(long firstDuplicateSequence) {
        duplicateRejected = firstDuplicateSequence;
      }
      case ApplyResult.Torn(long firstTornSequence) {
        tornRecovered = firstTornSequence;
      }
    }

    ApplyResult duplicate = applyTransaction(log, applied, 101, 1, stagedRoot, true);
    match (duplicate) {
      case ApplyResult.Applied(long duplicateRoot, long duplicateAppliedSequence) {
        committedRoot = duplicateRoot + duplicateAppliedSequence;
      }
      case ApplyResult.Duplicate(long duplicateSequence) {
        duplicateRejected = duplicateSequence;
      }
      case ApplyResult.Torn(long duplicateTornSequence) {
        tornRecovered = duplicateTornSequence;
      }
    }

    ApplyResult torn = applyTransaction(log, applied, 102, 2, 19, false);
    match (torn) {
      case ApplyResult.Applied(long tornRoot, long tornAppliedSequence) {
        committedRoot = tornRoot + tornAppliedSequence;
      }
      case ApplyResult.Duplicate(long tornDuplicateSequence) {
        duplicateRejected = tornDuplicateSequence + 1;
      }
      case ApplyResult.Torn(long tornSequence) {
        tornRecovered = tornSequence;
      }
    }

    reopenedRoot = recoverRoot(log);
    assert(committedRoot == 11);
    assert(stagedRoot == 11);
    assert(commitMarkerObserved == 1);
    assert(duplicateRejected == 1);
    assert(tornRecovered == 2);
    assert(reopenedRoot == 11);
    assert(reopenedSequence == 1);
    drop(applied);
    drop(log);
    drop(arena);
  }
}
