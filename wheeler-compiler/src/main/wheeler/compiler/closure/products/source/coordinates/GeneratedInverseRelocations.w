//! Reorders stable call relocations onto generated inverse instruction windows.

module wheeler.compiler.closure.generated_inverse_relocations;

classical class GeneratedInverseRelocations {
  private const long CALLABLE_INSTRUCTION_COUNT_ROW = 64;
  private const long CALLABLE_ROWS = 320;
  private const long IDENTITY_BYTES = 32;
  private const long MAX_CALLABLES = 64;
  private const long MAX_CALLS = 256;
  private const long RELOCATION_IDENTITY_BYTES = 8192;
  private const long RELOCATION_ROWS = 768;

  /// Reports one complete inverse relocation product.
  public record GeneratedInverseRelocationPlan(long relocationCount, boolean valid) {}

  private long inverseInstruction(
    long relocation,
    borrow mut words callableRows,
    borrow mut words relocationRows,
    borrow mut words relocationOwners
  ) {
    long owner = relocationOwners[relocation];
    return callableRows[CALLABLE_INSTRUCTION_COUNT_ROW + owner] - 2 - relocationRows[relocation];
  }

  private long nextRelocation(
    long relocationCount,
    long priorOwner,
    long priorInstruction,
    borrow mut words callableRows,
    borrow mut words relocationRows,
    borrow mut words relocationOwners
  ) {
    long selected = relocationCount;
    long selectedOwner = MAX_CALLABLES;
    long selectedInstruction = 32768;
    long relocation = 0;
    while (relocation < relocationCount) limit MAX_CALLS {
      long owner = relocationOwners[relocation];
      long instruction = inverseInstruction(
        relocation,
        callableRows,
        relocationRows,
        relocationOwners
      );
      boolean afterPrior = priorOwner < owner;
      if (owner == priorOwner) {
        afterPrior = priorInstruction < instruction;
      }

      if (afterPrior) {
        if (owner < selectedOwner) {
          selected = relocation;
          selectedOwner = owner;
          selectedInstruction = instruction;
        } else {
          if (owner == selectedOwner) {
            if (instruction < selectedInstruction) {
              selected = relocation;
              selectedInstruction = instruction;
            }
          }
        }
      }

      relocation += 1;
    }

    return selected;
  }

  /// Publishes inverse call coordinates while retaining exact targets and identities.
  public GeneratedInverseRelocationPlan materializeGeneratedInverseRelocations(
    long callableCount,
    borrow mut words callableRows,
    long relocationCount,
    borrow mut words relocationRows,
    borrow mut words relocationOwners,
    borrow byteview relocationIdentities,
    borrow mut words inverseRelocationRows,
    borrow mut words inverseRelocationOwners,
    borrow mut bytes inverseRelocationIdentities
  ) {
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(callableRows) == CALLABLE_ROWS);
    assert(-1 < relocationCount);
    assert(relocationCount < MAX_CALLS + 1);
    assert(bufferLength(relocationRows) == RELOCATION_ROWS);
    assert(bufferLength(relocationOwners) == MAX_CALLS);
    assert(bufferLength(relocationIdentities) == RELOCATION_IDENTITY_BYTES);
    assert(bufferLength(inverseRelocationRows) == RELOCATION_ROWS);
    assert(bufferLength(inverseRelocationOwners) == MAX_CALLS);
    assert(bufferLength(inverseRelocationIdentities) == RELOCATION_IDENTITY_BYTES);

    boolean valid = true;
    long relocation = 0;
    while (relocation < relocationCount) limit MAX_CALLS {
      long owner = relocationOwners[relocation];
      if (owner < 0) {
        valid = false;
      }

      if (callableCount - 1 < owner) {
        valid = false;
      }

      if (valid) {
        if (relocationRows[512 + relocation] != owner) {
          valid = false;
        }

        long instructionCount = callableRows[CALLABLE_INSTRUCTION_COUNT_ROW + owner];
        long instruction = relocationRows[relocation];
        if (instruction < 0) {
          valid = false;
        }

        if (instructionCount - 2 < instruction) {
          valid = false;
        }

        long prior = 0;
        while (prior < relocation) limit MAX_CALLS {
          if (relocationOwners[prior] == owner) {
            if (relocationRows[prior] == instruction) {
              valid = false;
            }
          }

          prior += 1;
        }
      }

      relocation += 1;
    }

    if (valid == false) {
      return new GeneratedInverseRelocationPlan(0, false);
    }

    region staging = new region(/* bytes= */ 18432, /* allocations= */ 3);
    words stagedRows = allocate(staging, RELOCATION_ROWS);
    words stagedOwners = allocate(staging, MAX_CALLS);
    bytes stagedIdentities = allocateBytes(staging, RELOCATION_IDENTITY_BYTES);
    long priorOwner = -1;
    long priorInstruction = -1;
    long published = 0;
    while (published < relocationCount) limit MAX_CALLS {
      long selected = nextRelocation(
        relocationCount,
        priorOwner,
        priorInstruction,
        callableRows,
        relocationRows,
        relocationOwners
      );
      if (selected == relocationCount) {
        valid = false;
        published = relocationCount;
      } else {
        long selectedOwner = relocationOwners[selected];
        long selectedInstruction = inverseInstruction(
          selected,
          callableRows,
          relocationRows,
          relocationOwners
        );
        set(stagedRows, published, selectedInstruction);
        set(stagedRows, 256 + published, relocationRows[256 + selected]);
        set(stagedRows, 512 + published, selectedOwner);
        set(stagedOwners, published, selectedOwner);
        long identityByte = 0;
        while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
          setByte(
            stagedIdentities,
            published * IDENTITY_BYTES + identityByte,
            relocationIdentities[selected * IDENTITY_BYTES + identityByte]
          );
          identityByte += 1;
        }

        priorOwner = selectedOwner;
        priorInstruction = selectedInstruction;
        published += 1;
      }
    }

    if (valid) {
      long row = 0;
      while (row < RELOCATION_ROWS) limit RELOCATION_ROWS {
        set(inverseRelocationRows, row, stagedRows[row]);
        row += 1;
      }

      row = 0;
      while (row < MAX_CALLS) limit MAX_CALLS {
        set(inverseRelocationOwners, row, stagedOwners[row]);
        row += 1;
      }

      long identityOffset = 0;
      while (identityOffset < RELOCATION_IDENTITY_BYTES) limit RELOCATION_IDENTITY_BYTES {
        setByte(inverseRelocationIdentities, identityOffset, stagedIdentities[identityOffset]);
        identityOffset += 1;
      }
    }

    drop(stagedIdentities);
    drop(stagedOwners);
    drop(stagedRows);
    drop(staging);
    if (valid == false) {
      return new GeneratedInverseRelocationPlan(0, false);
    }

    return new GeneratedInverseRelocationPlan(relocationCount, true);
  }
}
