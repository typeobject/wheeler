//! Assigns final aggregate descriptor IDs and resolves stable aggregate references.

module wheeler.compiler.closure.aggregate_descriptor_rows;

classical class AggregateDescriptorRows {
  private const long CLOSURE_AGGREGATE_ROWS = 36864;
  private const long MAX_AGGREGATES = 4096;
  private const long MAX_MODULES = 512;
  private const long MODULE_IDENTITY_BYTES = 16384;
  private const long RELOCATION_IDENTITY_BYTES = 131072;

  private boolean relocationOwnerMatches(
    borrow byteview relocationIdentities,
    long relocation,
    borrow byteview moduleIdentities,
    long module
  ) {
    long identityByte = 0;
    while (identityByte < 32) limit 32 {
      if (
        relocationIdentities[relocation * 32 + identityByte] != moduleIdentities[module * 32
          + identityByte]
      ) {
        return false;
      }

      identityByte += 1;
    }

    return true;
  }

  /// Publishes per-kind final descriptor IDs in closure aggregate order.
  public void assignFinalAggregateDescriptorRows(
    long aggregateCount,
    borrow mut words closureAggregateRows,
    borrow mut words moduleIdentityPublished,
    borrow byteview moduleIdentities,
    borrow mut words finalDescriptorRows,
    borrow mut words publishedRows
  ) {
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES + 1);
    assert(bufferLength(closureAggregateRows) == CLOSURE_AGGREGATE_ROWS);
    assert(bufferLength(moduleIdentityPublished) == MAX_MODULES);
    assert(bufferLength(moduleIdentities) == MODULE_IDENTITY_BYTES);
    assert(bufferLength(finalDescriptorRows) == MAX_AGGREGATES);
    assert(bufferLength(publishedRows) == MAX_AGGREGATES);

    region staging = new region(/* bytes= */ 32768, /* allocations= */ 1);
    words stagedRows = allocate(staging, MAX_AGGREGATES);
    long records = 0;
    long arrays = 0;
    long slices = 0;
    long variants = 0;
    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      long kind = closureAggregateRows[aggregate];
      long owner = closureAggregateRows[4096 + aggregate];
      long sourceTypeId = closureAggregateRows[8192 + aggregate];
      assert(0 < kind);
      assert(kind < 5);
      assert(-1 < owner);
      assert(owner < MAX_MODULES);
      assert(moduleIdentityPublished[owner] == 1);
      assert(-1 < sourceTypeId);
      long previous = 0;
      while (previous < aggregate) limit MAX_AGGREGATES {
        if (closureAggregateRows[4096 + previous] == owner) {
          if (closureAggregateRows[previous] == kind) {
            assert(closureAggregateRows[8192 + previous] != sourceTypeId);
          }
        }

        previous += 1;
      }

      if (kind == 1) {
        set(stagedRows, aggregate, records);
        records += 1;
      }

      if (kind == 2) {
        set(stagedRows, aggregate, arrays);
        arrays += 1;
      }

      if (kind == 3) {
        set(stagedRows, aggregate, slices);
        slices += 1;
      }

      if (kind == 4) {
        set(stagedRows, aggregate, variants);
        variants += 1;
      }

      aggregate += 1;
    }

    aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      set(finalDescriptorRows, aggregate, stagedRows[aggregate]);
      set(publishedRows, aggregate, 1);
      aggregate += 1;
    }

    drop(stagedRows);
    drop(staging);
  }

  /// Resolves stable module identity, kind, and source type ID triples to final IDs.
  public void resolveAggregateIdentityDescriptorTargets(
    long relocationCount,
    borrow byteview relocationIdentities,
    borrow mut words relocationKinds,
    borrow mut words relocationTypeIds,
    long aggregateCount,
    borrow mut words closureAggregateRows,
    borrow byteview moduleIdentities,
    borrow mut words finalDescriptorRows,
    borrow mut words targetRows
  ) {
    assert(-1 < relocationCount);
    assert(relocationCount < MAX_AGGREGATES + 1);
    assert(bufferLength(relocationIdentities) == RELOCATION_IDENTITY_BYTES);
    assert(bufferLength(relocationKinds) == MAX_AGGREGATES);
    assert(bufferLength(relocationTypeIds) == MAX_AGGREGATES);
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES + 1);
    assert(bufferLength(closureAggregateRows) == CLOSURE_AGGREGATE_ROWS);
    assert(bufferLength(moduleIdentities) == MODULE_IDENTITY_BYTES);
    assert(bufferLength(finalDescriptorRows) == MAX_AGGREGATES);
    assert(bufferLength(targetRows) == MAX_AGGREGATES);

    region staging = new region(/* bytes= */ 32768, /* allocations= */ 1);
    words stagedTargets = allocate(staging, MAX_AGGREGATES);
    long relocation = 0;
    while (relocation < relocationCount) limit MAX_AGGREGATES {
      long kind = relocationKinds[relocation];
      long typeId = relocationTypeIds[relocation];
      assert(0 < kind);
      assert(kind < 5);
      assert(-1 < typeId);
      long selected = -1;
      long aggregate = 0;
      while (aggregate < aggregateCount) limit MAX_AGGREGATES {
        if (closureAggregateRows[aggregate] == kind) {
          if (closureAggregateRows[8192 + aggregate] == typeId) {
            long owner = closureAggregateRows[4096 + aggregate];
            if (
              relocationOwnerMatches(relocationIdentities, relocation, moduleIdentities, owner)
            ) {
              assert(selected == -1);
              selected = aggregate;
            }
          }
        }

        aggregate += 1;
      }

      assert(-1 < selected);
      set(stagedTargets, relocation, finalDescriptorRows[selected]);
      relocation += 1;
    }

    relocation = 0;
    while (relocation < relocationCount) limit MAX_AGGREGATES {
      set(targetRows, relocation, stagedTargets[relocation]);
      relocation += 1;
    }

    drop(stagedTargets);
    drop(staging);
  }
}
