//! Projects source aggregate products into descriptor-compatible rows.

module wheeler.compiler.closure.source_aggregate_layouts;

classical class SourceAggregateLayouts {
  private const long AGGREGATE_ROWS = 832;
  private const long CASE_ROWS = 640;
  private const long MAX_AGGREGATES = 64;
  private const long MAX_CASES = 128;
  private const long MAX_MEMBERS = 256;
  private const long MEMBER_ROWS = 2048;

  /// Reports descriptor-compatible rows and their source-string window.
  public record ProjectedSourceAggregatePlan(
    long aggregateCount,
    long caseCount,
    long memberCount,
    long stringCount
  ) {}

  private long aggregateTypeTag(long kind) {
    if (kind == 1) {
      return 268435456;
    }

    if (kind == 2) {
      return 805306368;
    }

    if (kind == 3) {
      return 1073741824;
    }

    if (kind == 4) {
      return 536870912;
    }

    assert(false);
    return 0;
  }

  private long projectedMemberType(
    long member,
    borrow mut words sourceMembers,
    long aggregateCount,
    borrow mut words sourceAggregates,
    borrow mut words projectedAggregates
  ) {
    if (sourceMembers[1536 + member] == 0) {
      long primitive = sourceMembers[1792 + member];
      assert(0 < primitive);
      assert(primitive < 15);
      return primitive;
    }

    assert(sourceMembers[1536 + member] == 1);
    long target = sourceMembers[1792 + member];
    assert(-1 < target);
    assert(target < aggregateCount);
    return aggregateTypeTag(sourceAggregates[target]) + projectedAggregates[128 + target];
  }

  /// Projects validated source rows into descriptor-compatible local layout rows.
  public ProjectedSourceAggregatePlan projectSourceAggregateLayouts(
    borrow utf8 source,
    long moduleOwner,
    long aggregateCount,
    long caseCount,
    long memberCount,
    borrow mut words sourceAggregates,
    borrow mut words sourceCases,
    borrow mut words sourceMembers,
    borrow mut words projectedAggregates,
    borrow mut words projectedCases,
    borrow mut words projectedMembers,
    borrow mut words stringStarts,
    borrow mut words stringLengths
  ) {
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES + 1);
    assert(-1 < caseCount);
    assert(caseCount < MAX_CASES + 1);
    assert(-1 < memberCount);
    assert(memberCount < MAX_MEMBERS + 1);
    assert(bufferLength(sourceAggregates) == AGGREGATE_ROWS);
    assert(bufferLength(sourceCases) == CASE_ROWS);
    assert(bufferLength(sourceMembers) == MEMBER_ROWS);
    assert(bufferLength(projectedAggregates) == AGGREGATE_ROWS);
    assert(bufferLength(projectedCases) == CASE_ROWS);
    assert(bufferLength(projectedMembers) == MEMBER_ROWS);
    assert(bufferLength(stringStarts) == 512);
    assert(bufferLength(stringLengths) == 512);

    region staging = new region(/* bytes= */ 36352, /* allocations= */ 5);
    words stagedAggregates = allocate(staging, AGGREGATE_ROWS);
    words stagedCases = allocate(staging, CASE_ROWS);
    words stagedMembers = allocate(staging, MEMBER_ROWS);
    words stagedStringStarts = allocate(staging, /* length= */ 512);
    words stagedStringLengths = allocate(staging, /* length= */ 512);
    long recordId = 0;
    long arrayId = 0;
    long sliceId = 0;
    long variantId = 0;
    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      long kind = sourceAggregates[aggregate];
      long typeId = 0;
      if (kind == 1) {
        typeId = recordId;
        recordId += 1;
      } else {
        if (kind == 2) {
          typeId = arrayId;
          arrayId += 1;
        } else {
          if (kind == 3) {
            typeId = sliceId;
            sliceId += 1;
          } else {
            assert(kind == 4);
            typeId = variantId;
            variantId += 1;
          }
        }
      }

      set(stagedAggregates, aggregate, kind);
      set(stagedAggregates, 64 + aggregate, moduleOwner);
      set(stagedAggregates, 128 + aggregate, typeId);
      aggregate += 1;
    }

    long outputCaseCount = 0;
    long outputMemberCount = 0;
    long stringCount = 0;
    aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      long selectedKind = sourceAggregates[aggregate];
      long aggregateNameStart = sourceAggregates[64 + aggregate];
      long aggregateNameLength = sourceAggregates[128 + aggregate];
      assert(-1 < aggregateNameStart);
      assert(0 < aggregateNameLength);
      assert(aggregateNameStart < bufferLength(source));
      assert(aggregateNameLength < bufferLength(source) - aggregateNameStart + 1);
      assert(stringCount < 512);
      set(stagedAggregates, 192 + aggregate, stringCount);
      set(stagedStringStarts, stringCount, aggregateNameStart);
      set(stagedStringLengths, stringCount, aggregateNameLength);
      stringCount += 1;
      set(stagedAggregates, 256 + aggregate, outputCaseCount);
      set(stagedAggregates, 384 + aggregate, outputMemberCount);

      if (selectedKind == 1) {
        long firstRecordMember = sourceAggregates[320 + aggregate];
        long recordMemberCount = sourceAggregates[384 + aggregate];
        assert(firstRecordMember < memberCount + 1);
        assert(recordMemberCount < memberCount - firstRecordMember + 1);
        long recordMember = 0;
        while (recordMember < recordMemberCount) limit MAX_MEMBERS {
          long recordSourceMember = firstRecordMember + recordMember;
          assert(sourceMembers[recordSourceMember] == aggregate);
          assert(sourceMembers[256 + recordSourceMember] == -1);
          assert(outputMemberCount < MAX_MEMBERS);
          long recordMemberNameStart = sourceMembers[512 + recordSourceMember];
          long recordMemberNameLength = sourceMembers[768 + recordSourceMember];
          assert(-1 < recordMemberNameStart);
          assert(0 < recordMemberNameLength);
          assert(recordMemberNameStart < bufferLength(source));
          assert(recordMemberNameLength < bufferLength(source) - recordMemberNameStart + 1);
          assert(stringCount < 512);
          set(stagedMembers, outputMemberCount, aggregate);
          set(stagedMembers, 256 + outputMemberCount, -1);
          set(stagedMembers, 512 + outputMemberCount, stringCount);
          set(
            stagedMembers,
            768 + outputMemberCount,
            projectedMemberType(
              recordSourceMember,
              sourceMembers,
              aggregateCount,
              sourceAggregates,
              stagedAggregates
            )
          );
          set(stagedStringStarts, stringCount, recordMemberNameStart);
          set(stagedStringLengths, stringCount, recordMemberNameLength);
          stringCount += 1;
          outputMemberCount += 1;
          recordMember += 1;
        }
      }

      if (selectedKind == 4) {
        long firstVariantCase = sourceAggregates[192 + aggregate];
        long variantCaseCount = sourceAggregates[256 + aggregate];
        assert(firstVariantCase < caseCount + 1);
        assert(variantCaseCount < caseCount - firstVariantCase + 1);
        long variantCase = 0;
        while (variantCase < variantCaseCount) limit MAX_CASES {
          long sourceCase = firstVariantCase + variantCase;
          assert(sourceCases[sourceCase] == aggregate);
          assert(outputCaseCount < MAX_CASES);
          long caseNameStart = sourceCases[128 + sourceCase];
          long caseNameLength = sourceCases[256 + sourceCase];
          assert(-1 < caseNameStart);
          assert(0 < caseNameLength);
          assert(caseNameStart < bufferLength(source));
          assert(caseNameLength < bufferLength(source) - caseNameStart + 1);
          assert(stringCount < 512);
          set(stagedCases, outputCaseCount, aggregate);
          set(stagedCases, 128 + outputCaseCount, stringCount);
          set(stagedCases, 256 + outputCaseCount, outputMemberCount);
          set(stagedStringStarts, stringCount, caseNameStart);
          set(stagedStringLengths, stringCount, caseNameLength);
          stringCount += 1;
          long firstCaseMember = sourceCases[384 + sourceCase];
          long caseMemberCount = sourceCases[512 + sourceCase];
          assert(firstCaseMember < memberCount + 1);
          assert(caseMemberCount < memberCount - firstCaseMember + 1);
          long caseMember = 0;
          while (caseMember < caseMemberCount) limit MAX_MEMBERS {
            long caseSourceMember = firstCaseMember + caseMember;
            assert(sourceMembers[caseSourceMember] == aggregate);
            assert(sourceMembers[256 + caseSourceMember] == sourceCase);
            assert(outputMemberCount < MAX_MEMBERS);
            long caseMemberNameStart = sourceMembers[512 + caseSourceMember];
            long caseMemberNameLength = sourceMembers[768 + caseSourceMember];
            assert(-1 < caseMemberNameStart);
            assert(0 < caseMemberNameLength);
            assert(caseMemberNameStart < bufferLength(source));
            assert(caseMemberNameLength < bufferLength(source) - caseMemberNameStart + 1);
            assert(stringCount < 512);
            set(stagedMembers, outputMemberCount, aggregate);
            set(stagedMembers, 256 + outputMemberCount, outputCaseCount);
            set(stagedMembers, 512 + outputMemberCount, stringCount);
            set(
              stagedMembers,
              768 + outputMemberCount,
              projectedMemberType(
                caseSourceMember,
                sourceMembers,
                aggregateCount,
                sourceAggregates,
                stagedAggregates
              )
            );
            set(stagedStringStarts, stringCount, caseMemberNameStart);
            set(stagedStringLengths, stringCount, caseMemberNameLength);
            stringCount += 1;
            outputMemberCount += 1;
            caseMember += 1;
          }

          set(stagedCases, 384 + outputCaseCount, caseMemberCount);
          outputCaseCount += 1;
          variantCase += 1;
        }
      }

      if (selectedKind == 2) {
        assert(outputMemberCount < MAX_MEMBERS);
        long arrayElementType = sourceAggregates[640 + aggregate];
        assert(0 < arrayElementType);
        assert(arrayElementType < 15);
        set(stagedMembers, outputMemberCount, aggregate);
        set(stagedMembers, 256 + outputMemberCount, -1);
        set(stagedMembers, 512 + outputMemberCount, -1);
        set(stagedMembers, 768 + outputMemberCount, arrayElementType);
        set(stagedAggregates, 512 + aggregate, sourceAggregates[704 + aggregate]);
        outputMemberCount += 1;
      }

      if (selectedKind == 3) {
        assert(outputMemberCount < MAX_MEMBERS);
        long sliceElementType = sourceAggregates[640 + aggregate];
        assert(0 < sliceElementType);
        assert(sliceElementType < 15);
        set(stagedMembers, outputMemberCount, aggregate);
        set(stagedMembers, 256 + outputMemberCount, -1);
        set(stagedMembers, 512 + outputMemberCount, -1);
        set(stagedMembers, 768 + outputMemberCount, sliceElementType);
        outputMemberCount += 1;
      }

      set(
        stagedAggregates,
        320 + aggregate,
        outputCaseCount - stagedAggregates[256 + aggregate]
      );
      set(
        stagedAggregates,
        448 + aggregate,
        outputMemberCount - stagedAggregates[384 + aggregate]
      );
      aggregate += 1;
    }

    long row = 0;
    while (row < AGGREGATE_ROWS) limit AGGREGATE_ROWS {
      set(projectedAggregates, row, stagedAggregates[row]);
      row += 1;
    }

    row = 0;
    while (row < CASE_ROWS) limit CASE_ROWS {
      set(projectedCases, row, stagedCases[row]);
      row += 1;
    }

    row = 0;
    while (row < MEMBER_ROWS) limit MEMBER_ROWS {
      set(projectedMembers, row, stagedMembers[row]);
      row += 1;
    }

    row = 0;
    while (row < 512) limit 512 {
      set(stringStarts, row, stagedStringStarts[row]);
      set(stringLengths, row, stagedStringLengths[row]);
      row += 1;
    }

    drop(stagedStringLengths);
    drop(stagedStringStarts);
    drop(stagedMembers);
    drop(stagedCases);
    drop(stagedAggregates);
    drop(staging);
    return new ProjectedSourceAggregatePlan(
      aggregateCount,
      outputCaseCount,
      outputMemberCount,
      stringCount
    );
  }
}
