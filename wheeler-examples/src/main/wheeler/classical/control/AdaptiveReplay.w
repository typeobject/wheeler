//! Executes and replays one bounded adaptive decision path.

module examples.adaptive.replay;

classical class AdaptiveReplay {
  state long liveResult = 0;
  state long replayResult = 0;
  state long upperResult = 0;
  state long liveObservations = 0;
  state long replayObservations = 0;
  state long replayTargetCalls = 0;

  private long selectedChild(long node, long value) {
    if (node == 0) {
      if (value < 10) {
        return 1;
      }

      return 2;
    }

    assert(node == 1);
    if (value < 3) {
      return 3;
    }

    return 4;
  }

  private long terminalValue(long node) {
    if (node == 2) {
      return 100;
    }

    if (node == 3) {
      return -1;
    }

    assert(node == 4);
    return 1;
  }

  private long executeLive(long firstValue, long secondValue) {
    long child = selectedChild(0, firstValue);
    liveObservations += 1;
    if (child == 2) {
      return terminalValue(child);
    }

    child = selectedChild(child, secondValue);
    liveObservations += 1;
    return terminalValue(child);
  }

  private long replay(
    long firstNode,
    long firstValue,
    long firstChild,
    long secondNode,
    long secondValue,
    long secondChild
  ) {
    assert(firstNode == 0);
    assert(selectedChild(firstNode, firstValue) == firstChild);
    replayObservations += 1;
    if (firstChild == 2) {
      return terminalValue(firstChild);
    }

    assert(secondNode == firstChild);
    assert(selectedChild(secondNode, secondValue) == secondChild);
    replayObservations += 1;
    return terminalValue(secondChild);
  }

  /// Executes live branches and replays one accepted path without another target call.
  ///
  /// - Effects: Mutates declared state without invoking an external target.
  entry void main() {
    liveResult = executeLive(5, 4);
    replayResult = replay(0, 5, 1, 1, 4, 4);
    upperResult = executeLive(10, 0);
    assert(liveResult == replayResult);
    assert(replayTargetCalls == 0);
  }
}
