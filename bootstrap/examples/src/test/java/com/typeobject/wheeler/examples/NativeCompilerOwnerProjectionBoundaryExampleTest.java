package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeOwnerProjectionFixture.check;
import static com.typeobject.wheeler.examples.NativeOwnerProjectionFixture.traps;

import com.typeobject.wheeler.examples.NativeOwnerProjectionFixture.Input;
import org.junit.jupiter.api.Test;

/** Checks owner-event projection without claiming a loan-verifier or final carrier schema. */
final class NativeCompilerOwnerProjectionBoundaryExampleTest {
  @Test
  void publishesBothWholeColumnsForEveryEventKindAndPreservesTails() throws Exception {
    Input input = new Input()
        .event(5, 3, 1, -1)
        .event(1, 3, 2, 1)
        .event(2, 3, 4, 2)
        .event(3, 3, 4, 2)
        .event(4, 3, -1, 2)
        .projection(3, 1, 4095, 16383)
        .projection(3, 2, 4095, 16383)
        .projection(4, 2, 0, 0);
    check(input, true);
    check(new Input(), true);
  }

  @Test
  void rejectsLateMissingOrDuplicateKeysWithoutPublishingAnEarlierEvent() throws Exception {
    check(new Input().event(5, 0, 1, -1).event(4, 0, -1, 2)
        .projection(0, 1, 3, 5), false);
    check(new Input().event(5, 0, 1, -1).event(4, 0, -1, 2)
        .projection(0, 1, 3, 5).projection(0, 2, 3, 5).projection(0, 2, 3, 5), false);
    check(new Input().event(5, 0, 1, -1).event(4, 0, -1, 2)
        .projection(0, 1, 3, 5).projection(1, 2, 3, 5), false);
  }

  @Test
  void requiresBothMoveTargetsToAgreeWithoutConflatingAggregateAndMemberRows() throws Exception {
    check(new Input().event(1, 0, 2, 1)
        .projection(0, 1, 3, 5).projection(0, 2, 4, 5), false);
    check(new Input().event(1, 0, 2, 1)
        .projection(0, 1, 3, 5).projection(0, 2, 3, 6), false);
    check(new Input().event(1, 0, 2, 1).projection(0, 1, 3, 5), false);
  }

  @Test
  void rejectsInvalidEventsAndSelectedCoordinatesAtomically() throws Exception {
    for (long kind : new long[] {-1, 0, 6, Long.MAX_VALUE}) {
      check(new Input().event(5, 0, 1, -1).event(kind, 0, 1, 1)
          .projection(0, 1, 3, 5), false);
    }
    check(new Input().event(5, -1, 1, -1).projection(0, 1, 3, 5), false);
    check(new Input().event(5, 0, -1, 1).projection(0, 1, 3, 5), false);
    check(new Input().event(4, 0, 1, -1).projection(0, 1, 3, 5), false);
    for (long aggregate : new long[] {-1, 4096, Long.MAX_VALUE}) {
      check(new Input().event(5, 0, 1, -1).projection(0, 1, aggregate, 5), false);
    }
    for (long member : new long[] {-1, 16384, Long.MAX_VALUE}) {
      check(new Input().event(5, 0, 1, -1).projection(0, 1, 3, member), false);
    }
  }

  @Test
  void selectsTheLastUnscopedRowWithBothPayloadColumns() throws Exception {
    Input input = new Input().event(5, 3, 1, -1).projection(3, 1, 4095, 16383);
    input.lastProjection = true;
    input.projectionCount = 16384L;
    check(input, true);
  }

  @Test
  void rejectsCountsAndEveryColumnBeforePrivateAllocation() throws Exception {
    for (int column = 0; column < 3; column++) {
      for (int delta : new int[] {-1, 1}) {
        Input input = new Input();
        input.capacities[column] += delta;
        traps(input);
      }
    }
    for (long count : new long[] {-1, 8193, Long.MAX_VALUE}) {
      Input input = new Input();
      input.eventCount = count;
      traps(input);
    }
    for (long count : new long[] {-1, 16385, Long.MAX_VALUE}) {
      Input input = new Input();
      input.projectionCount = count;
      traps(input);
    }
  }
}
