//! Emits closure function local types with final aggregate descriptor IDs.

module wheeler.compiler.closure.linked_local_types;

import wheeler.core.encoding.binary;

classical class LinkedLocalTypes {
  private const long CLOSURE_AGGREGATE_ROWS = 36864;
  private const long CLOSURE_FUNCTION_ROWS = 49152;
  private const long MAX_AGGREGATES = 4096;
  private const long MAX_ARTIFACTS = 512;
  private const long MAX_CLOSURE_FUNCTIONS = 4096;
  private const long MAX_CLOSURE_LOCAL_TYPES = 1048576;
  private const long MAX_MODULES = 512;
  private const long TYPE_DESCRIPTOR_MASK = 268435455;
  private const long TYPE_KIND_MASK = 4026531840;

  private long aggregateKind(long typeCode) {
    long tag = typeCode & TYPE_KIND_MASK;
    if (tag == 268435456) {
      return 1;
    }

    if (tag == 805306368) {
      return 2;
    }

    if (tag == 1073741824) {
      return 3;
    }

    if (tag == 536870912) {
      return 4;
    }

    return 0;
  }

  private long linkedTypeCode(
    long sourceCode,
    long moduleOwner,
    long aggregateCount,
    borrow mut words closureAggregateRows,
    borrow mut words finalDescriptorRows
  ) {
    long kind = aggregateKind(sourceCode);
    if (kind == 0) {
      assert(0 < sourceCode);
      assert(sourceCode < 15);
      return sourceCode;
    }

    long typeId = sourceCode & TYPE_DESCRIPTOR_MASK;
    long selected = -1;
    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      if (closureAggregateRows[aggregate] == kind) {
        if (closureAggregateRows[4096 + aggregate] == moduleOwner) {
          if (closureAggregateRows[8192 + aggregate] == typeId) {
            assert(selected == -1);
            selected = aggregate;
          }
        }
      }

      aggregate += 1;
    }

    assert(-1 < selected);
    long linkedTag = 0;
    if (kind == 1) {
      linkedTag = 268435456;
    }

    if (kind == 2) {
      linkedTag = 805306368;
    }

    if (kind == 3) {
      linkedTag = 1073741824;
    }

    if (kind == 4) {
      linkedTag = 536870912;
    }

    return linkedTag + finalDescriptorRows[selected];
  }

  /// Emits exact function type windows after validating every source and descriptor range.
  public long emitLinkedLocalTypes(
    borrow byteview archive,
    long archiveBytes,
    borrow mut words artifactStarts,
    borrow mut words artifactLengths,
    long functionCount,
    borrow mut words closureFunctionRows,
    long aggregateCount,
    borrow mut words closureAggregateRows,
    borrow mut words finalDescriptorRows,
    borrow mut words outputTypes
  ) {
    assert(-1 < archiveBytes);
    assert(archiveBytes < bufferLength(archive) + 1);
    assert(bufferLength(artifactStarts) == MAX_ARTIFACTS);
    assert(bufferLength(artifactLengths) == MAX_ARTIFACTS);
    assert(-1 < functionCount);
    assert(functionCount < MAX_CLOSURE_FUNCTIONS + 1);
    assert(bufferLength(closureFunctionRows) == CLOSURE_FUNCTION_ROWS);
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES + 1);
    assert(bufferLength(closureAggregateRows) == CLOSURE_AGGREGATE_ROWS);
    assert(bufferLength(finalDescriptorRows) == MAX_AGGREGATES);
    assert(bufferLength(outputTypes) == MAX_CLOSURE_LOCAL_TYPES);

    long typeCount = 0;
    long function = 0;
    while (function < functionCount) limit MAX_CLOSURE_FUNCTIONS {
      long owner = closureFunctionRows[function];
      long artifactRank = closureFunctionRows[12288 + function];
      long typeStart = closureFunctionRows[40960 + function];
      long functionTypeCount = closureFunctionRows[45056 + function];
      assert(-1 < owner);
      assert(owner < MAX_MODULES);
      assert(-1 < artifactRank);
      assert(artifactRank < MAX_ARTIFACTS);
      assert(-1 < typeStart);
      assert(-1 < functionTypeCount);
      assert(typeStart < artifactLengths[artifactRank] + 1);
      assert(functionTypeCount * 4 < artifactLengths[artifactRank] - typeStart + 1);
      assert(functionTypeCount < MAX_CLOSURE_LOCAL_TYPES - typeCount + 1);
      long localType = 0;
      while (localType < functionTypeCount) limit 257 {
        long sourceCode = readUnsigned(
          archive,
          artifactStarts[artifactRank] + typeStart + localType * 4,
          4
        );
        long validated = linkedTypeCode(
          sourceCode,
          owner,
          aggregateCount,
          closureAggregateRows,
          finalDescriptorRows
        );
        assert(0 < validated);
        localType += 1;
      }

      typeCount += functionTypeCount;
      function += 1;
    }

    long outputType = 0;
    function = 0;
    while (function < functionCount) limit MAX_CLOSURE_FUNCTIONS {
      long selectedOwner = closureFunctionRows[function];
      long selectedArtifact = closureFunctionRows[12288 + function];
      long selectedTypeStart = closureFunctionRows[40960 + function];
      long selectedTypeCount = closureFunctionRows[45056 + function];
      long selectedType = 0;
      while (selectedType < selectedTypeCount) limit 257 {
        long selectedCode = readUnsigned(
          archive,
          artifactStarts[selectedArtifact] + selectedTypeStart + selectedType * 4,
          4
        );
        set(
          outputTypes,
          outputType,
          linkedTypeCode(
            selectedCode,
            selectedOwner,
            aggregateCount,
            closureAggregateRows,
            finalDescriptorRows
          )
        );
        outputType += 1;
        selectedType += 1;
      }

      function += 1;
    }

    assert(outputType == typeCount);
    return typeCount;
  }
}
