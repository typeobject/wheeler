//! Emits closure function local types with final aggregate descriptor IDs.

module wheeler.compiler.closure.linked_local_types;

import wheeler.core.encoding.binary;

classical class LinkedLocalTypes {
  private const long CLOSURE_AGGREGATE_ROWS = 36864;
  private const long CARRIER_PROJECTION_ROWS = 65536;
  private const long CLOSURE_FUNCTION_ROWS = 49152;
  private const long MAX_AGGREGATES = 4096;
  private const long MAX_ARTIFACTS = 512;
  private const long MAX_CLOSURE_FUNCTIONS = 4096;
  private const long MAX_CLOSURE_LOCAL_TYPES = 1048576;
  private const long MAX_MODULES = 512;
  private const long MAX_CARRIER_PROJECTIONS = 16384;
  private const long MAX_PROJECTIONS = 16384;
  private const long PROJECTION_ROWS = 49152;
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

  /// Rewrites one source-local primitive or nominal code to its final descriptor row.
  public long linkedTypeCode(
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

  /// Resolves one temporary nominal descriptor through its stable aggregate projection.
  public long linkedProjectedTypeCode(
    long sourceCode,
    long moduleOwner,
    long aggregateCount,
    borrow mut words closureAggregateRows,
    borrow mut words finalDescriptorRows,
    long projectionCount,
    borrow mut words projectionRows
  ) {
    assert(-1 < projectionCount);
    assert(projectionCount < MAX_PROJECTIONS + 1);
    assert(bufferLength(projectionRows) == PROJECTION_ROWS);
    long selected = -1;
    long projection = 0;
    while (projection < projectionCount) limit MAX_PROJECTIONS {
      if (projectionRows[projection] == moduleOwner) {
        if (projectionRows[16384 + projection] == sourceCode) {
          assert(selected == -1);
          selected = projectionRows[32768 + projection];
        }
      }

      projection += 1;
    }

    if (selected < 0) {
      return linkedTypeCode(
        sourceCode,
        moduleOwner,
        aggregateCount,
        closureAggregateRows,
        finalDescriptorRows
      );
    }

    assert(selected < aggregateCount);
    long kind = aggregateKind(sourceCode);
    assert(0 < kind);
    assert(closureAggregateRows[selected] == kind);
    long tag = sourceCode & TYPE_KIND_MASK;
    return tag + finalDescriptorRows[selected];
  }

  private long linkedCarrierTypeCode(
    long sourceCode,
    long moduleOwner,
    long localFunction,
    long localType,
    long aggregateCount,
    borrow mut words closureAggregateRows,
    borrow mut words finalDescriptorRows,
    long projectionCount,
    borrow mut words projectionRows,
    long carrierProjectionCount,
    borrow mut words carrierProjectionRows
  ) {
    long selected = -1;
    long projection = 0;
    while (projection < carrierProjectionCount) limit MAX_CARRIER_PROJECTIONS {
      if (carrierProjectionRows[projection] == moduleOwner) {
        if (carrierProjectionRows[16384 + projection] == localFunction) {
          if (carrierProjectionRows[32768 + projection] == localType) {
            assert(selected == -1);
            selected = carrierProjectionRows[49152 + projection];
          }
        }
      }

      projection += 1;
    }

    if (selected < 0) {
      return linkedProjectedTypeCode(
        sourceCode,
        moduleOwner,
        aggregateCount,
        closureAggregateRows,
        finalDescriptorRows,
        projectionCount,
        projectionRows
      );
    }

    assert(sourceCode == 1);
    assert(selected < aggregateCount);
    long kind = closureAggregateRows[selected];
    long tag = 0;
    if (kind == 1) {
      tag = 268435456;
    }

    if (kind == 4) {
      tag = 536870912;
    }

    assert(0 < tag);
    return tag + finalDescriptorRows[selected];
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
    long projectionCount,
    borrow mut words projectionRows,
    long carrierProjectionCount,
    borrow mut words carrierProjectionRows,
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
    assert(-1 < projectionCount);
    assert(projectionCount < MAX_PROJECTIONS + 1);
    assert(bufferLength(projectionRows) == PROJECTION_ROWS);
    assert(-1 < carrierProjectionCount);
    assert(carrierProjectionCount < MAX_CARRIER_PROJECTIONS + 1);
    if (0 < carrierProjectionCount) {
      assert(bufferLength(carrierProjectionRows) == CARRIER_PROJECTION_ROWS);
    }

    assert(bufferLength(outputTypes) == MAX_CLOSURE_LOCAL_TYPES);

    long carrierProjection = 0;
    while (carrierProjection < carrierProjectionCount) limit MAX_CARRIER_PROJECTIONS {
      long carrierOwner = carrierProjectionRows[carrierProjection];
      long carrierFunction = carrierProjectionRows[16384 + carrierProjection];
      long carrierLocal = carrierProjectionRows[32768 + carrierProjection];
      long carrierTarget = carrierProjectionRows[49152 + carrierProjection];
      assert(-1 < carrierOwner);
      assert(carrierOwner < MAX_MODULES);
      assert(-1 < carrierFunction);
      assert(carrierFunction < 64);
      assert(-1 < carrierLocal);
      assert(carrierLocal < 256);
      assert(-1 < carrierTarget);
      assert(carrierTarget < aggregateCount);
      long carrierKind = closureAggregateRows[carrierTarget];
      boolean carrierKindValid = carrierKind == 1;
      if (carrierKind == 4) {
        carrierKindValid = true;
      }

      assert(carrierKindValid);
      long priorCarrier = 0;
      while (priorCarrier < carrierProjection) limit MAX_CARRIER_PROJECTIONS {
        boolean sameCarrier = carrierProjectionRows[priorCarrier] == carrierOwner;
        if (carrierProjectionRows[16384 + priorCarrier] != carrierFunction) {
          sameCarrier = false;
        }

        if (carrierProjectionRows[32768 + priorCarrier] != carrierLocal) {
          sameCarrier = false;
        }

        assert(sameCarrier == false);
        priorCarrier += 1;
      }

      carrierProjection += 1;
    }

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
        long validated = linkedCarrierTypeCode(
          sourceCode,
          owner,
          closureFunctionRows[4096 + function],
          localType,
          aggregateCount,
          closureAggregateRows,
          finalDescriptorRows,
          projectionCount,
          projectionRows,
          carrierProjectionCount,
          carrierProjectionRows
        );
        assert(0 < validated);
        localType += 1;
      }

      typeCount += functionTypeCount;
      function += 1;
    }

    carrierProjection = 0;
    while (carrierProjection < carrierProjectionCount) limit MAX_CARRIER_PROJECTIONS {
      long selectedCarrierOwner = carrierProjectionRows[carrierProjection];
      long selectedCarrierFunction = carrierProjectionRows[16384 + carrierProjection];
      long selectedCarrierLocal = carrierProjectionRows[32768 + carrierProjection];
      long carrierMatches = 0;
      long carrierCandidate = 0;
      while (carrierCandidate < functionCount) limit MAX_CLOSURE_FUNCTIONS {
        if (closureFunctionRows[carrierCandidate] == selectedCarrierOwner) {
          if (closureFunctionRows[4096 + carrierCandidate] == selectedCarrierFunction) {
            long carrierTypeCount = closureFunctionRows[45056 + carrierCandidate];
            if (selectedCarrierLocal < carrierTypeCount) {
              long carrierArtifact = closureFunctionRows[12288 + carrierCandidate];
              long carrierTypeStart = closureFunctionRows[40960 + carrierCandidate];
              assert(
                readUnsigned(
                  archive,
                  artifactStarts[carrierArtifact] + carrierTypeStart + selectedCarrierLocal * 4,
                  4
                ) == 1
              );
              carrierMatches += 1;
            }
          }
        }

        carrierCandidate += 1;
      }

      assert(carrierMatches == 1);
      carrierProjection += 1;
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
          linkedCarrierTypeCode(
            selectedCode,
            selectedOwner,
            closureFunctionRows[4096 + function],
            selectedType,
            aggregateCount,
            closureAggregateRows,
            finalDescriptorRows,
            projectionCount,
            projectionRows,
            carrierProjectionCount,
            carrierProjectionRows
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
