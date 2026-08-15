//! Maps stable callable identities to final closure function rows.

module wheeler.compiler.closure.callable_function_rows;

classical class CallableFunctionRows {
  private const long HASH_SLOTS = 8192;
  private const long IDENTITY_BYTES = 32;
  private const long IDENTITY_TABLE_BYTES = 131072;
  private const long MAX_FUNCTIONS = 4096;
  private const long TARGET_ROWS = 65536;

  private long identityHash(borrow byteview identities, long identity) {
    long hash = 2166136261;
    long identityByte = 0;
    while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
      hash = ((hash & 4294967295) * 16777619) & 4294967295;
      hash = (hash ^ identities[identity * IDENTITY_BYTES + identityByte]) & 4294967295;
      identityByte += 1;
    }

    return hash % HASH_SLOTS;
  }

  private boolean sameIdentity(
    borrow byteview left,
    long leftIdentity,
    borrow byteview right,
    long rightIdentity
  ) {
    long identityByte = 0;
    while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
      if (
        left[leftIdentity * IDENTITY_BYTES + identityByte] != right[rightIdentity * IDENTITY_BYTES
          + identityByte]
      ) {
        return false;
      }

      identityByte += 1;
    }

    return true;
  }

  /// Publishes one final function row for each callable identity after complete validation.
  public void mapCallableFunctionRows(
    long callableCount,
    borrow byteview callableIdentities,
    long functionCount,
    borrow byteview functionIdentities,
    borrow mut words hashSlots,
    borrow mut words hashFunctions,
    borrow mut words callableFunctionRows,
    borrow mut words publishedRows
  ) {
    assert(-1 < callableCount);
    assert(callableCount < MAX_FUNCTIONS + 1);
    assert(-1 < functionCount);
    assert(functionCount < MAX_FUNCTIONS + 1);
    assert(bufferLength(callableIdentities) == IDENTITY_TABLE_BYTES);
    assert(bufferLength(functionIdentities) == IDENTITY_TABLE_BYTES);
    assert(bufferLength(hashSlots) == HASH_SLOTS);
    assert(bufferLength(hashFunctions) == HASH_SLOTS);
    assert(bufferLength(callableFunctionRows) == MAX_FUNCTIONS);
    assert(bufferLength(publishedRows) == MAX_FUNCTIONS);

    long function = 0;
    while (function < functionCount) limit MAX_FUNCTIONS {
      long slot = identityHash(functionIdentities, function);
      long probes = 0;
      while (hashSlots[slot] != 0) limit HASH_SLOTS {
        long existing = hashFunctions[slot];
        assert(!sameIdentity(functionIdentities, existing, functionIdentities, function));
        slot = (slot + 1) % HASH_SLOTS;
        probes += 1;
        assert(probes < HASH_SLOTS);
      }

      set(hashSlots, slot, 1);
      set(hashFunctions, slot, function);
      function += 1;
    }

    region staging = new region(/* bytes= */ 32768, /* allocations= */ 1);
    words stagedRows = allocate(staging, MAX_FUNCTIONS);
    long callable = 0;
    while (callable < callableCount) limit MAX_FUNCTIONS {
      long selectedSlot = identityHash(callableIdentities, callable);
      long selectedProbes = 0;
      boolean found = false;
      while (hashSlots[selectedSlot] != 0) limit HASH_SLOTS {
        long selectedFunction = hashFunctions[selectedSlot];
        if (
          sameIdentity(callableIdentities, callable, functionIdentities, selectedFunction)
        ) {
          assert(found == false);
          set(stagedRows, callable, selectedFunction);
          found = true;
        }

        selectedSlot = (selectedSlot + 1) % HASH_SLOTS;
        selectedProbes += 1;
        assert(selectedProbes < HASH_SLOTS);
      }

      assert(found);
      callable += 1;
    }

    callable = 0;
    while (callable < callableCount) limit MAX_FUNCTIONS {
      set(callableFunctionRows, callable, stagedRows[callable]);
      set(publishedRows, callable, 1);
      callable += 1;
    }

    drop(stagedRows);
    drop(staging);
  }

  /// Resolves imported stable identities to final function rows without numeric fixtures.
  public void resolveImportedIdentityFunctionTargets(
    long relocationCount,
    borrow byteview relocationIdentities,
    long functionCount,
    borrow byteview functionIdentities,
    borrow mut words hashSlots,
    borrow mut words hashFunctions,
    borrow mut words targetRows
  ) {
    assert(-1 < relocationCount);
    assert(relocationCount < MAX_FUNCTIONS + 1);
    assert(relocationCount * IDENTITY_BYTES < bufferLength(relocationIdentities) + 1);
    assert(-1 < functionCount);
    assert(functionCount < MAX_FUNCTIONS + 1);
    assert(bufferLength(functionIdentities) == IDENTITY_TABLE_BYTES);
    assert(bufferLength(hashSlots) == HASH_SLOTS);
    assert(bufferLength(hashFunctions) == HASH_SLOTS);
    assert(bufferLength(targetRows) == TARGET_ROWS);

    region staging = new region(/* bytes= */ 524288, /* allocations= */ 1);
    words stagedTargets = allocate(staging, TARGET_ROWS);
    long relocation = 0;
    while (relocation < relocationCount) limit MAX_FUNCTIONS {
      long slot = identityHash(relocationIdentities, relocation);
      long probes = 0;
      boolean found = false;
      while (hashSlots[slot] != 0) limit HASH_SLOTS {
        long function = hashFunctions[slot];
        if (
          sameIdentity(relocationIdentities, relocation, functionIdentities, function)
        ) {
          assert(found == false);
          set(stagedTargets, relocation, function);
          found = true;
        }

        slot = (slot + 1) % HASH_SLOTS;
        probes += 1;
        assert(probes < HASH_SLOTS);
      }

      assert(found);
      relocation += 1;
    }

    relocation = 0;
    while (relocation < relocationCount) limit MAX_FUNCTIONS {
      set(targetRows, relocation, stagedTargets[relocation]);
      relocation += 1;
    }

    drop(stagedTargets);
    drop(staging);
  }
}
