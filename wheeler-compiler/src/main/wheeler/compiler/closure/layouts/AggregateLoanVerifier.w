//! Verifies bounded owner moves and nonescaping loans against aggregate products.

module wheeler.compiler.closure.aggregate_loan_verifier;

classical class AggregateLoanVerifier {
  private const long CLOSURE_AGGREGATE_ROWS = 36864;
  private const long CLOSURE_MEMBER_ROWS = 65536;
  private const long EVENT_ROWS = 49152;
  private const long MAX_CLOSURE_AGGREGATES = 4096;
  private const long MAX_CLOSURE_EVENTS = 16384;
  private const long MAX_CLOSURE_MEMBERS = 16384;
  private const long MAX_SHARED_LOANS = 64;
  private const long STATE_ARENA_BYTES = 98304;

  /// Verifies one complete body event stream and publishes only final owner states.
  public void verifyAggregateProjectionEvents(
    long aggregateCount,
    long memberCount,
    borrow mut words closureAggregates,
    borrow mut words closureMembers,
    borrow mut words initialOwned,
    borrow mut words eventRows,
    long eventCount,
    borrow mut words finalOwned,
    borrow mut words finalSharedLoans,
    borrow mut words finalMutableLoans
  ) {
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_CLOSURE_AGGREGATES + 1);
    assert(-1 < memberCount);
    assert(memberCount < MAX_CLOSURE_MEMBERS + 1);
    assert(bufferLength(closureAggregates) == CLOSURE_AGGREGATE_ROWS);
    assert(bufferLength(closureMembers) == CLOSURE_MEMBER_ROWS);
    assert(bufferLength(initialOwned) == MAX_CLOSURE_AGGREGATES);
    assert(bufferLength(eventRows) == EVENT_ROWS);
    assert(-1 < eventCount);
    assert(eventCount < MAX_CLOSURE_EVENTS + 1);
    assert(bufferLength(finalOwned) == MAX_CLOSURE_AGGREGATES);
    assert(bufferLength(finalSharedLoans) == MAX_CLOSURE_AGGREGATES);
    assert(bufferLength(finalMutableLoans) == MAX_CLOSURE_AGGREGATES);

    region stateArena = new region(/* bytes= */ STATE_ARENA_BYTES, /* allocations= */ 3);
    words owned = allocate(stateArena, MAX_CLOSURE_AGGREGATES);
    words sharedLoans = allocate(stateArena, MAX_CLOSURE_AGGREGATES);
    words mutableLoans = allocate(stateArena, MAX_CLOSURE_AGGREGATES);
    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_CLOSURE_AGGREGATES {
      if (initialOwned[aggregate] != 0) {
        assert(initialOwned[aggregate] == 1);
      }

      set(owned, aggregate, initialOwned[aggregate]);
      aggregate += 1;
    }

    long event = 0;
    while (event < eventCount) limit MAX_CLOSURE_EVENTS {
      long eventKind = eventRows[event];
      long eventAggregate = eventRows[MAX_CLOSURE_EVENTS + event];
      long eventMember = eventRows[MAX_CLOSURE_EVENTS * 2 + event];
      assert(0 < eventKind);
      assert(eventKind < 6);
      assert(-1 < eventAggregate);
      assert(eventAggregate < aggregateCount);
      assert(-1 < eventMember);
      assert(eventMember < memberCount);
      assert(closureMembers[eventMember] == eventAggregate);

      if (eventKind == 1) {
        assert(owned[eventAggregate] == 1);
        assert(sharedLoans[eventAggregate] == 0);
        assert(mutableLoans[eventAggregate] == 0);
        set(owned, eventAggregate, 0);
      }

      if (eventKind == 2) {
        assert(owned[eventAggregate] == 1);
        assert(mutableLoans[eventAggregate] == 0);
        assert(sharedLoans[eventAggregate] < MAX_SHARED_LOANS);
        set(sharedLoans, eventAggregate, sharedLoans[eventAggregate] + 1);
      }

      if (eventKind == 3) {
        assert(owned[eventAggregate] == 1);
        assert(sharedLoans[eventAggregate] == 0);
        assert(mutableLoans[eventAggregate] == 0);
        set(mutableLoans, eventAggregate, 1);
      }

      if (eventKind == 4) {
        assert(0 < sharedLoans[eventAggregate]);
        set(sharedLoans, eventAggregate, sharedLoans[eventAggregate] - 1);
      }

      if (eventKind == 5) {
        assert(mutableLoans[eventAggregate] == 1);
        set(mutableLoans, eventAggregate, 0);
      }

      event += 1;
    }

    aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_CLOSURE_AGGREGATES {
      assert(sharedLoans[aggregate] == 0);
      assert(mutableLoans[aggregate] == 0);
      set(finalOwned, aggregate, owned[aggregate]);
      set(finalSharedLoans, aggregate, 0);
      set(finalMutableLoans, aggregate, 0);
      aggregate += 1;
    }

    drop(mutableLoans);
    drop(sharedLoans);
    drop(owned);
    drop(stateArena);
  }
}
