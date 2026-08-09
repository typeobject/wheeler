//! Appends validated source-local aggregate products into bounded closure windows.

module wheeler.compiler.closure.counted_aggregate_layouts;

import wheeler.compiler.closure.compiled_aggregate_layouts;
import wheeler.compiler.closure.source_aggregate_products;

classical class CountedAggregateLayouts {
  private const long CLOSURE_AGGREGATE_ROWS = 36864;
  private const long CLOSURE_CASE_ROWS = 32768;
  private const long CLOSURE_MEMBER_ROWS = 65536;
  private const long LOCAL_AGGREGATE_ROWS = 576;
  private const long LOCAL_CASE_ROWS = 512;
  private const long LOCAL_MEMBER_ROWS = 1024;
  private const long MAX_CLOSURE_AGGREGATES = 4096;
  private const long MAX_CLOSURE_CASES = 8192;
  private const long MAX_CLOSURE_MEMBERS = 16384;
  private const long MAX_LOCAL_MODULES = 512;

  /// Reports the complete counted extent after one atomic append.
  public record CountedAggregateLayoutPlan(
    long moduleCount,
    long aggregateCount,
    long caseCount,
    long memberCount
  ) {}

  /// Appends one immutable compiled module product without retaining its source.
  public CountedAggregateLayoutPlan appendCompiledAggregateLayouts(
    borrow byteview artifact,
    long artifactLength,
    long owner,
    long moduleCount,
    long aggregateCount,
    long caseCount,
    long memberCount,
    long generatedAggregateCount,
    long generatedCaseCount,
    long generatedMemberCount,
    borrow mut words processedModules,
    borrow mut words closureAggregates,
    borrow mut words closureCases,
    borrow mut words closureMembers
  ) {
    assert(bufferLength(processedModules) == MAX_LOCAL_MODULES);
    assert(bufferLength(closureAggregates) == CLOSURE_AGGREGATE_ROWS);
    assert(bufferLength(closureCases) == CLOSURE_CASE_ROWS);
    assert(bufferLength(closureMembers) == CLOSURE_MEMBER_ROWS);
    assert(-1 < owner);
    assert(owner < MAX_LOCAL_MODULES);
    assert(processedModules[owner] == 0);
    assert(-1 < moduleCount);
    assert(moduleCount < MAX_LOCAL_MODULES);
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_CLOSURE_AGGREGATES + 1);
    assert(-1 < caseCount);
    assert(caseCount < MAX_CLOSURE_CASES + 1);
    assert(-1 < memberCount);
    assert(memberCount < MAX_CLOSURE_MEMBERS + 1);
    assert(-1 < generatedAggregateCount);
    assert(generatedAggregateCount < 65);
    assert(-1 < generatedCaseCount);
    assert(generatedCaseCount < 129);
    assert(-1 < generatedMemberCount);
    assert(generatedMemberCount < 257);

    region localRows = new region(/* bytes= */ 16896, /* allocations= */ 3);
    words aggregates = allocate(localRows, LOCAL_AGGREGATE_ROWS);
    words cases = allocate(localRows, LOCAL_CASE_ROWS);
    words members = allocate(localRows, LOCAL_MEMBER_ROWS);
    CompiledAggregatePlan local = indexCompiledAggregateLayouts(
      artifact,
      artifactLength,
      owner,
      aggregates,
      cases,
      members
    );
    assert(generatedAggregateCount < local.aggregateCount + 1);
    assert(generatedCaseCount < local.caseCount + 1);
    assert(generatedMemberCount < local.memberCount + 1);
    long retainedAggregateCount = local.aggregateCount - generatedAggregateCount;
    long retainedCaseCount = local.caseCount - generatedCaseCount;
    long retainedMemberCount = local.memberCount - generatedMemberCount;
    assert(retainedAggregateCount < MAX_CLOSURE_AGGREGATES - aggregateCount + 1);
    assert(retainedCaseCount < MAX_CLOSURE_CASES - caseCount + 1);
    assert(retainedMemberCount < MAX_CLOSURE_MEMBERS - memberCount + 1);

    long validatedAggregate = 0;
    while (validatedAggregate < retainedAggregateCount) limit 64 {
      long firstLocalCase = aggregates[256 + validatedAggregate];
      long localCaseCount = aggregates[320 + validatedAggregate];
      long firstLocalMember = aggregates[384 + validatedAggregate];
      long localMemberCount = aggregates[448 + validatedAggregate];
      assert(firstLocalCase < retainedCaseCount + 1);
      assert(localCaseCount < retainedCaseCount - firstLocalCase + 1);
      assert(firstLocalMember < retainedMemberCount + 1);
      assert(localMemberCount < retainedMemberCount - firstLocalMember + 1);
      validatedAggregate += 1;
    }

    long validatedCase = 0;
    while (validatedCase < retainedCaseCount) limit 128 {
      long firstCaseMember = cases[256 + validatedCase];
      long caseMemberCount = cases[384 + validatedCase];
      assert(firstCaseMember < retainedMemberCount + 1);
      assert(caseMemberCount < retainedMemberCount - firstCaseMember + 1);
      validatedCase += 1;
    }

    long aggregate = 0;
    while (aggregate < retainedAggregateCount) limit 64 {
      long closureAggregate = aggregateCount + aggregate;
      set(closureAggregates, closureAggregate, aggregates[aggregate]);
      set(closureAggregates, 4096 + closureAggregate, owner);
      set(closureAggregates, 8192 + closureAggregate, aggregates[128 + aggregate]);
      set(closureAggregates, 12288 + closureAggregate, aggregates[192 + aggregate]);
      set(closureAggregates, 16384 + closureAggregate, caseCount + aggregates[256 + aggregate]);
      set(closureAggregates, 20480 + closureAggregate, aggregates[320 + aggregate]);
      set(
        closureAggregates,
        24576 + closureAggregate,
        memberCount + aggregates[384 + aggregate]
      );
      set(closureAggregates, 28672 + closureAggregate, aggregates[448 + aggregate]);
      set(closureAggregates, 32768 + closureAggregate, aggregates[512 + aggregate]);
      aggregate += 1;
    }

    long nextCase = 0;
    while (nextCase < retainedCaseCount) limit 128 {
      long closureCase = caseCount + nextCase;
      set(closureCases, closureCase, aggregateCount + cases[nextCase]);
      set(closureCases, 8192 + closureCase, cases[128 + nextCase]);
      set(closureCases, 16384 + closureCase, memberCount + cases[256 + nextCase]);
      set(closureCases, 24576 + closureCase, cases[384 + nextCase]);
      nextCase += 1;
    }

    long member = 0;
    while (member < retainedMemberCount) limit 256 {
      long closureMember = memberCount + member;
      set(closureMembers, closureMember, aggregateCount + members[member]);
      long localCase = members[256 + member];
      long closureCaseOwner = -1;
      if (-1 < localCase) {
        closureCaseOwner = caseCount + localCase;
      }

      set(closureMembers, 16384 + closureMember, closureCaseOwner);
      set(closureMembers, 32768 + closureMember, members[512 + member]);
      set(closureMembers, 49152 + closureMember, members[768 + member]);
      member += 1;
    }

    set(processedModules, owner, 1);
    long nextAggregateCount = aggregateCount + retainedAggregateCount;
    long nextCaseCount = caseCount + retainedCaseCount;
    long nextMemberCount = memberCount + retainedMemberCount;
    drop(members);
    drop(cases);
    drop(aggregates);
    drop(localRows);
    return new CountedAggregateLayoutPlan(
      moduleCount + 1,
      nextAggregateCount,
      nextCaseCount,
      nextMemberCount
    );
  }
}
