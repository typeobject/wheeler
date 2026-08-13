//! Validates loop back-edge local, ownership, and loan state.

module wheeler.compiler.closure.loop_back_edge_products;

classical class LoopBackEdgeProducts {
  private const long EVENT_COUNT_LIMIT = 8192;
  private const long EVENT_FUNCTION_ROW = 16384;
  private const long EVENT_INSTRUCTION_ROW = 8192;
  private const long EVENT_KIND_ACQUIRE = 2;
  private const long EVENT_KIND_RELEASE = 3;
  private const long EVENT_KIND_ROW = 0;
  private const long EVENT_ROWS = 40960;
  private const long EVENT_SOURCE_ROW = 32768;
  private const long EVENT_VALUE_ROW = 24576;
  private const long LOOP_COUNT_LIMIT = 256;
  private const long LOOP_OWNER_ROW = 0;
  private const long LOOP_ROWS = 2304;
  private const long STATE_COUNT_LIMIT = 4096;
  private const long STATE_KIND_ROW = 4096;
  private const long STATE_ROWS = 8192;

  /// Reports one complete loop back-edge validation pass.
  public record LoopBackEdgePlan(long loopCount, boolean valid) {}

  private boolean stateMatches(
    long stateStart,
    long stateCount,
    borrow mut words entryStateRows,
    borrow mut words backEdgeStateRows
  ) {
    long stateOffset = 0;
    while (stateOffset < stateCount) limit STATE_COUNT_LIMIT {
      long state = stateStart + stateOffset;
      if (entryStateRows[state] != backEdgeStateRows[state]) {
        return false;
      }

      if (
        entryStateRows[STATE_KIND_ROW + state] != backEdgeStateRows[STATE_KIND_ROW + state]
      ) {
        return false;
      }

      stateOffset += 1;
    }

    return true;
  }

  private boolean loansCloseWithinWindow(
    long owner,
    long firstInstruction,
    long backEdgeInstruction,
    long eventCount,
    borrow mut words eventRows
  ) {
    long event = 0;
    while (event < eventCount) limit EVENT_COUNT_LIMIT {
      long instruction = eventRows[EVENT_INSTRUCTION_ROW + event];
      if (eventRows[EVENT_FUNCTION_ROW + event] == owner) {
        if (firstInstruction < instruction + 1) {
          if (instruction < backEdgeInstruction) {
            if (eventRows[EVENT_KIND_ROW + event] == EVENT_KIND_ACQUIRE) {
              long value = eventRows[EVENT_VALUE_ROW + event];
              long source = eventRows[EVENT_SOURCE_ROW + event];
              long releases = 0;
              long candidate = event + 1;
              while (candidate < eventCount) limit EVENT_COUNT_LIMIT {
                long candidateInstruction = eventRows[EVENT_INSTRUCTION_ROW + candidate];
                if (backEdgeInstruction < candidateInstruction + 1) {
                  candidate = eventCount;
                } else {
                  if (eventRows[EVENT_FUNCTION_ROW + candidate] == owner) {
                    if (eventRows[EVENT_KIND_ROW + candidate] == EVENT_KIND_RELEASE) {
                      if (eventRows[EVENT_VALUE_ROW + candidate] == value) {
                        if (eventRows[EVENT_SOURCE_ROW + candidate] == source) {
                          releases += 1;
                        }
                      }
                    }
                  }

                  candidate += 1;
                }
              }

              if (releases != 1) {
                return false;
              }
            }
          }
        }
      }

      event += 1;
    }

    return true;
  }

  /// Accepts only identical ownership states and loans closed before every back edge.
  public LoopBackEdgePlan validateLoopBackEdges(
    long loopCount,
    borrow mut words loopRows,
    borrow mut words loopInstructionStarts,
    borrow mut words loopInstructionCounts,
    borrow mut words loopEntryStateStarts,
    borrow mut words loopEntryStateCounts,
    long stateCount,
    borrow mut words entryStateRows,
    borrow mut words backEdgeStateRows,
    long eventCount,
    borrow mut words eventRows
  ) {
    assert(-1 < loopCount);
    assert(loopCount < LOOP_COUNT_LIMIT + 1);
    assert(bufferLength(loopRows) == LOOP_ROWS);
    assert(bufferLength(loopInstructionStarts) == LOOP_COUNT_LIMIT);
    assert(bufferLength(loopInstructionCounts) == LOOP_COUNT_LIMIT);
    assert(bufferLength(loopEntryStateStarts) == LOOP_COUNT_LIMIT);
    assert(bufferLength(loopEntryStateCounts) == LOOP_COUNT_LIMIT);
    assert(-1 < stateCount);
    assert(stateCount < STATE_COUNT_LIMIT + 1);
    assert(bufferLength(entryStateRows) == STATE_ROWS);
    assert(bufferLength(backEdgeStateRows) == STATE_ROWS);
    assert(-1 < eventCount);
    assert(eventCount < EVENT_COUNT_LIMIT + 1);
    assert(bufferLength(eventRows) == EVENT_ROWS);

    boolean valid = true;
    long previousStateEnd = 0;
    long loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      long owner = loopRows[LOOP_OWNER_ROW + loop];
      long firstInstruction = loopInstructionStarts[loop];
      long instructionCount = loopInstructionCounts[loop];
      long stateStart = loopEntryStateStarts[loop];
      long selectedStateCount = loopEntryStateCounts[loop];
      if (owner < 0) {
        valid = false;
      }

      if (63 < owner) {
        valid = false;
      }

      if (firstInstruction < 0) {
        valid = false;
      }

      if (instructionCount < 1) {
        valid = false;
      }

      if (4096 - firstInstruction < instructionCount) {
        valid = false;
      }

      if (stateStart != previousStateEnd) {
        valid = false;
      }

      if (selectedStateCount < 0) {
        valid = false;
      }

      if (stateCount - stateStart < selectedStateCount) {
        valid = false;
      }

      if (valid) {
        if (
          stateMatches(stateStart, selectedStateCount, entryStateRows, backEdgeStateRows) == false
        ) {
          valid = false;
        }
      }

      if (valid) {
        if (
          loansCloseWithinWindow(
            owner,
            firstInstruction,
            firstInstruction + instructionCount - 1,
            eventCount,
            eventRows
          ) == false
        ) {
          valid = false;
        }
      }

      previousStateEnd = stateStart + selectedStateCount;
      loop += 1;
    }

    if (previousStateEnd != stateCount) {
      valid = false;
    }

    if (valid == false) {
      return new LoopBackEdgePlan(0, false);
    }

    return new LoopBackEdgePlan(loopCount, true);
  }
}
