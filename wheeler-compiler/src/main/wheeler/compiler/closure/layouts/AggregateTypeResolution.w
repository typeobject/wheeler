//! Resolves source-local aggregate member type references into counted rows.

module wheeler.compiler.closure.aggregate_type_resolution;

classical class AggregateTypeResolution {
  private const long AGGREGATE_TAG = 268435456;
  private const long CLOSURE_AGGREGATE_ROWS = 36864;
  private const long CLOSURE_MEMBER_ROWS = 65536;
  private const long MAX_CLOSURE_AGGREGATES = 4096;
  private const long MAX_CLOSURE_MEMBERS = 16384;
  private const long MAX_MODULE_AGGREGATES = 64;
  private const long MAX_MODULE_MEMBERS = 256;

  /// Resolves one module window and publishes target rows after the complete pass.
  public void resolveModuleAggregateMemberTypes(
    long firstAggregate,
    long aggregateCount,
    long firstMember,
    long memberCount,
    borrow mut words closureAggregates,
    borrow mut words closureMembers,
    borrow mut words memberTypeTargets
  ) {
    assert(-1 < firstAggregate);
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_MODULE_AGGREGATES + 1);
    assert(firstAggregate < MAX_CLOSURE_AGGREGATES + 1);
    assert(aggregateCount < MAX_CLOSURE_AGGREGATES - firstAggregate + 1);
    assert(-1 < firstMember);
    assert(-1 < memberCount);
    assert(memberCount < MAX_MODULE_MEMBERS + 1);
    assert(firstMember < MAX_CLOSURE_MEMBERS + 1);
    assert(memberCount < MAX_CLOSURE_MEMBERS - firstMember + 1);
    assert(bufferLength(closureAggregates) == CLOSURE_AGGREGATE_ROWS);
    assert(bufferLength(closureMembers) == CLOSURE_MEMBER_ROWS);
    assert(bufferLength(memberTypeTargets) == MAX_CLOSURE_MEMBERS);

    region scratchArena = new region(/* bytes= */ 2048, /* allocations= */ 1);
    words targets = allocate(scratchArena, MAX_MODULE_MEMBERS);
    long member = 0;
    while (member < memberCount) limit MAX_MODULE_MEMBERS {
      long closureMember = firstMember + member;
      long memberAggregate = closureMembers[closureMember];
      assert(firstAggregate - 1 < memberAggregate);
      assert(memberAggregate < firstAggregate + aggregateCount);
      long typeCode = closureMembers[49152 + closureMember];
      assert(-1 < typeCode);
      long typeTag = typeCode / AGGREGATE_TAG;
      long target = -1;
      if (0 < typeTag) {
        assert(typeTag < 5);
        long descriptor = typeCode % AGGREGATE_TAG;
        long owner = closureAggregates[4096 + memberAggregate];
        long aggregate = 0;
        while (aggregate < aggregateCount) limit MAX_MODULE_AGGREGATES {
          long candidate = firstAggregate + aggregate;
          if (closureAggregates[candidate] == typeTag) {
            if (closureAggregates[4096 + candidate] == owner) {
              if (closureAggregates[8192 + candidate] == descriptor) {
                assert(target == -1);
                target = candidate;
              }
            }
          }

          aggregate += 1;
        }

        assert(-1 < target);
      }

      set(targets, member, target);
      member += 1;
    }

    member = 0;
    while (member < memberCount) limit MAX_MODULE_MEMBERS {
      set(memberTypeTargets, firstMember + member, targets[member]);
      member += 1;
    }

    drop(targets);
    drop(scratchArena);
  }
}
