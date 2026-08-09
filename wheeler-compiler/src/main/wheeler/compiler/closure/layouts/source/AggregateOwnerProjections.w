//! Maps instruction-local owners to stable aggregate and member rows.

module wheeler.compiler.closure.aggregate_owner_projections;

classical class AggregateOwnerProjections {
  private const long EVENT_PROJECTION_ROWS = 16384;
  private const long INSTRUCTION_EVENT_ROWS = 40960;
  private const long MAX_EVENTS = 8192;
  private const long MAX_PROJECTIONS = 16384;
  private const long PROJECTION_ROWS = 65536;

  /// Reports whether every owner event received one unique aggregate projection.
  public record AggregateOwnerProjectionPlan(long eventCount, boolean valid) {}

  private long projectionAt(
    long function,
    long local,
    long projectionCount,
    borrow mut words projectionRows
  ) {
    long selected = -1;
    long projection = 0;
    while (projection < projectionCount) limit MAX_PROJECTIONS {
      if (projectionRows[projection] == function) {
        if (projectionRows[16384 + projection] == local) {
          if (-1 < selected) {
            return -2;
          }

          selected = projection;
        }
      }

      projection += 1;
    }

    return selected;
  }

  /// Publishes aggregate and member rows for one validated instruction event stream.
  public AggregateOwnerProjectionPlan projectInstructionOwnerEvents(
    long eventCount,
    borrow mut words instructionEvents,
    long projectionCount,
    borrow mut words projectionRows,
    borrow mut words eventProjectionRows
  ) {
    assert(-1 < eventCount);
    assert(eventCount < MAX_EVENTS + 1);
    assert(bufferLength(instructionEvents) == INSTRUCTION_EVENT_ROWS);
    assert(-1 < projectionCount);
    assert(projectionCount < MAX_PROJECTIONS + 1);
    assert(bufferLength(projectionRows) == PROJECTION_ROWS);
    assert(bufferLength(eventProjectionRows) == EVENT_PROJECTION_ROWS);

    region scratch = new region(/* bytes= */ 131072, /* allocations= */ 1);
    words staged = allocate(scratch, EVENT_PROJECTION_ROWS);
    boolean valid = true;
    long event = 0;
    while (event < eventCount) limit MAX_EVENTS {
      long kind = instructionEvents[event];
      long function = instructionEvents[16384 + event];
      long destination = instructionEvents[24576 + event];
      long source = instructionEvents[32768 + event];
      if (kind < 1) {
        valid = false;
      }

      if (5 < kind) {
        valid = false;
      }

      if (function < 0) {
        valid = false;
      }

      long ownerLocal = source;
      if (kind == 5) {
        ownerLocal = destination;
      }

      if (ownerLocal < 0) {
        valid = false;
      }

      long selected = -1;
      if (valid) {
        selected = projectionAt(function, ownerLocal, projectionCount, projectionRows);
        if (selected < 0) {
          valid = false;
        }
      }

      if (valid) {
        long aggregate = projectionRows[32768 + selected];
        long member = projectionRows[49152 + selected];
        if (aggregate < 0) {
          valid = false;
        }

        if (4095 < aggregate) {
          valid = false;
        }

        if (member < 0) {
          valid = false;
        }

        if (16383 < member) {
          valid = false;
        }

        if (kind == 1) {
          long moved = projectionAt(function, destination, projectionCount, projectionRows);
          if (moved < 0) {
            valid = false;
          } else {
            if (projectionRows[32768 + moved] != aggregate) {
              valid = false;
            }

            if (projectionRows[49152 + moved] != member) {
              valid = false;
            }
          }
        }

        if (valid) {
          set(staged, event, aggregate);
          set(staged, 8192 + event, member);
        }
      }

      event += 1;
    }

    if (valid) {
      long row = 0;
      while (row < EVENT_PROJECTION_ROWS) limit EVENT_PROJECTION_ROWS {
        set(eventProjectionRows, row, staged[row]);
        row += 1;
      }
    }

    drop(staged);
    drop(scratch);
    return new AggregateOwnerProjectionPlan(eventCount, valid);
  }
}
