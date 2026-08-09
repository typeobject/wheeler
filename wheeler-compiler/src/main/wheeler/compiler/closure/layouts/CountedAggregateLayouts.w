//! Appends validated source-local aggregate products into bounded closure windows.

module wheeler.compiler.closure.counted_aggregate_layouts;

import wheeler.compiler.closure.compiled_aggregate_layouts;
import wheeler.compiler.closure.source_aggregate_layouts;
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
  private const long SOURCE_AGGREGATE_ROWS = 832;
  private const long SOURCE_CASE_ROWS = 640;
  private const long SOURCE_MEMBER_ROWS = 2048;

  /// Reports the complete counted extent after one atomic append.
  public record CountedAggregateLayoutPlan(
    long moduleCount,
    long aggregateCount,
    long caseCount,
    long memberCount
  ) {}

  private CountedAggregateLayoutPlan appendLocalAggregateLayouts(
    long owner,
    long moduleCount,
    long aggregateCount,
    long caseCount,
    long memberCount,
    long localAggregateCount,
    long localCaseCount,
    long localMemberCount,
    borrow mut words aggregates,
    borrow mut words cases,
    borrow mut words members,
    borrow mut words processedModules,
    borrow mut words closureAggregates,
    borrow mut words closureCases,
    borrow mut words closureMembers
  ) {
    assert(bufferLength(aggregates) == LOCAL_AGGREGATE_ROWS);
    assert(bufferLength(cases) == LOCAL_CASE_ROWS);
    assert(bufferLength(members) == LOCAL_MEMBER_ROWS);
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
    assert(-1 < localAggregateCount);
    assert(localAggregateCount < 65);
    assert(-1 < localCaseCount);
    assert(localCaseCount < 129);
    assert(-1 < localMemberCount);
    assert(localMemberCount < 257);
    assert(localAggregateCount < MAX_CLOSURE_AGGREGATES - aggregateCount + 1);
    assert(localCaseCount < MAX_CLOSURE_CASES - caseCount + 1);
    assert(localMemberCount < MAX_CLOSURE_MEMBERS - memberCount + 1);

    long validatedAggregate = 0;
    while (validatedAggregate < localAggregateCount) limit 64 {
      long kind = aggregates[validatedAggregate];
      boolean kindValid = kind == 1;
      if (kind == 2) {
        kindValid = true;
      }

      if (kind == 3) {
        kindValid = true;
      }

      if (kind == 4) {
        kindValid = true;
      }

      assert(kindValid);
      assert(-1 < aggregates[128 + validatedAggregate]);
      long firstLocalCase = aggregates[256 + validatedAggregate];
      long selectedCaseCount = aggregates[320 + validatedAggregate];
      long firstLocalMember = aggregates[384 + validatedAggregate];
      long aggregateMemberCount = aggregates[448 + validatedAggregate];
      assert(firstLocalCase < localCaseCount + 1);
      assert(selectedCaseCount < localCaseCount - firstLocalCase + 1);
      assert(firstLocalMember < localMemberCount + 1);
      assert(aggregateMemberCount < localMemberCount - firstLocalMember + 1);
      validatedAggregate += 1;
    }

    long validatedCase = 0;
    while (validatedCase < localCaseCount) limit 128 {
      assert(-1 < cases[validatedCase]);
      assert(cases[validatedCase] < localAggregateCount);
      long firstCaseMember = cases[256 + validatedCase];
      long caseMemberCount = cases[384 + validatedCase];
      assert(firstCaseMember < localMemberCount + 1);
      assert(caseMemberCount < localMemberCount - firstCaseMember + 1);
      validatedCase += 1;
    }

    long validatedMember = 0;
    while (validatedMember < localMemberCount) limit 256 {
      assert(-1 < members[validatedMember]);
      assert(members[validatedMember] < localAggregateCount);
      long selectedCase = members[256 + validatedMember];
      assert(-2 < selectedCase);
      assert(selectedCase < localCaseCount);
      assert(0 < members[768 + validatedMember]);
      validatedMember += 1;
    }

    long aggregate = 0;
    while (aggregate < localAggregateCount) limit 64 {
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
    while (nextCase < localCaseCount) limit 128 {
      long closureCase = caseCount + nextCase;
      set(closureCases, closureCase, aggregateCount + cases[nextCase]);
      set(closureCases, 8192 + closureCase, cases[128 + nextCase]);
      set(closureCases, 16384 + closureCase, memberCount + cases[256 + nextCase]);
      set(closureCases, 24576 + closureCase, cases[384 + nextCase]);
      nextCase += 1;
    }

    long member = 0;
    while (member < localMemberCount) limit 256 {
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
    return new CountedAggregateLayoutPlan(
      moduleCount + 1,
      aggregateCount + localAggregateCount,
      caseCount + localCaseCount,
      memberCount + localMemberCount
    );
  }

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
    CountedAggregateLayoutPlan result = appendLocalAggregateLayouts(
      owner,
      moduleCount,
      aggregateCount,
      caseCount,
      memberCount,
      local.aggregateCount - generatedAggregateCount,
      local.caseCount - generatedCaseCount,
      local.memberCount - generatedMemberCount,
      aggregates,
      cases,
      members,
      processedModules,
      closureAggregates,
      closureCases,
      closureMembers
    );
    drop(members);
    drop(cases);
    drop(aggregates);
    drop(localRows);
    return result;
  }

  /// Appends descriptor-compatible source products without a temporary artifact.
  public CountedAggregateLayoutPlan appendProjectedAggregateLayouts(
    long owner,
    long moduleCount,
    long aggregateCount,
    long caseCount,
    long memberCount,
    long localAggregateCount,
    long localCaseCount,
    long localMemberCount,
    borrow mut words sourceAggregates,
    borrow mut words sourceCases,
    borrow mut words sourceMembers,
    borrow mut words processedModules,
    borrow mut words closureAggregates,
    borrow mut words closureCases,
    borrow mut words closureMembers
  ) {
    assert(bufferLength(sourceAggregates) == SOURCE_AGGREGATE_ROWS);
    assert(bufferLength(sourceCases) == SOURCE_CASE_ROWS);
    assert(bufferLength(sourceMembers) == SOURCE_MEMBER_ROWS);
    region localRows = new region(/* bytes= */ 16896, /* allocations= */ 3);
    words aggregates = allocate(localRows, LOCAL_AGGREGATE_ROWS);
    words cases = allocate(localRows, LOCAL_CASE_ROWS);
    words members = allocate(localRows, LOCAL_MEMBER_ROWS);
    long row = 0;
    while (row < LOCAL_AGGREGATE_ROWS) limit LOCAL_AGGREGATE_ROWS {
      set(aggregates, row, sourceAggregates[row]);
      row += 1;
    }

    row = 0;
    while (row < LOCAL_CASE_ROWS) limit LOCAL_CASE_ROWS {
      set(cases, row, sourceCases[row]);
      row += 1;
    }

    row = 0;
    while (row < LOCAL_MEMBER_ROWS) limit LOCAL_MEMBER_ROWS {
      set(members, row, sourceMembers[row]);
      row += 1;
    }

    CountedAggregateLayoutPlan result = appendLocalAggregateLayouts(
      owner,
      moduleCount,
      aggregateCount,
      caseCount,
      memberCount,
      localAggregateCount,
      localCaseCount,
      localMemberCount,
      aggregates,
      cases,
      members,
      processedModules,
      closureAggregates,
      closureCases,
      closureMembers
    );
    drop(members);
    drop(cases);
    drop(aggregates);
    drop(localRows);
    return result;
  }
}
