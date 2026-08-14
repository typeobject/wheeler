//! Carries stable callable product identities through instruction composition.

module wheeler.compiler.closure.callable_product_identity_plans;

classical class CallableProductIdentityPlans {
  private const long IDENTITY_BYTES = 32;
  private const long IDENTITY_CAPACITY = 4096;
  private const long IDENTITY_ROWS = 20480;
  private const long KIND_AGGREGATE = 1;
  private const long KIND_CALL = 0;
  private const long KIND_OWNERSHIP = 2;
  private const long KIND_PROOF = 3;
  private const long OUTPUT_ROWS = 20480;

  /// Reports one complete source-independent identity carriage pass.
  public record CallableProductIdentityPlan(long identityCount, boolean valid) {}

  /// Rebases instruction-bound identities and preserves all 32 identity bytes.
  public CallableProductIdentityPlan materializeCallableProductIdentityPlans(
    long compositionCount,
    borrow mut words compositionRows,
    long identityCount,
    borrow mut words identityRows,
    borrow byteview identities,
    borrow mut words outputRows,
    borrow mut bytes outputIdentities
  ) {
    assert(-1 < compositionCount);
    assert(compositionCount < IDENTITY_CAPACITY + 1);
    assert(bufferLength(compositionRows) == 33024);
    assert(-1 < identityCount);
    assert(identityCount < IDENTITY_CAPACITY + 1);
    assert(bufferLength(identityRows) == IDENTITY_ROWS);
    assert(bufferLength(identities) == 131072);
    assert(bufferLength(outputRows) == OUTPUT_ROWS);
    assert(bufferLength(outputIdentities) == 131072);

    region staging = new region(/* bytes= */ 294912, /* allocations= */ 2);
    words stagedRows = allocate(staging, OUTPUT_ROWS);
    bytes stagedIdentities = allocateBytes(staging, 131072);
    boolean valid = true;
    long previousOwner = -1;
    long previousInstruction = -2;
    long previousKind = -1;
    long previousSourceProduct = -1;
    long identity = 0;
    while (identity < identityCount) limit IDENTITY_CAPACITY {
      long owner = identityRows[identity];
      long composition = identityRows[4096 + identity];
      long instructionOffset = identityRows[8192 + identity];
      long kind = identityRows[12288 + identity];
      long sourceProduct = identityRows[16384 + identity];
      if (owner < 0) {
        valid = false;
      } else {
        if (63 < owner) {
          valid = false;
        }
      }

      if (kind < KIND_CALL) {
        valid = false;
      } else {
        if (KIND_PROOF < kind) {
          valid = false;
        }
      }

      if (sourceProduct < 0) {
        valid = false;
      }

      long finalInstruction = -1;
      boolean instructionBound = kind == KIND_CALL;
      if (kind == KIND_AGGREGATE) {
        instructionBound = true;
      }

      if (instructionBound) {
        if (composition < 0) {
          valid = false;
        } else {
          if (compositionCount < composition + 1) {
            valid = false;
          } else {
            if (compositionRows[composition] != owner) {
              valid = false;
            }

            long instructionCount = compositionRows[20480 + composition];
            if (instructionOffset < 0) {
              valid = false;
            } else {
              if (instructionCount < instructionOffset + 1) {
                valid = false;
              } else {
                finalInstruction = compositionRows[16384 + composition] + instructionOffset;
              }
            }
          }
        }
      } else {
        if (composition + 1 != 0) {
          valid = false;
        }

        if (instructionOffset + 1 != 0) {
          valid = false;
        }
      }

      if (owner < previousOwner) {
        valid = false;
      }

      if (owner == previousOwner) {
        if (finalInstruction < previousInstruction) {
          valid = false;
        }

        if (finalInstruction == previousInstruction) {
          if (kind < previousKind) {
            valid = false;
          }

          if (kind == previousKind) {
            if (sourceProduct < previousSourceProduct + 1) {
              valid = false;
            }
          }
        }
      }

      set(stagedRows, identity, owner);
      set(stagedRows, 4096 + identity, finalInstruction);
      set(stagedRows, 8192 + identity, kind);
      set(stagedRows, 12288 + identity, sourceProduct);
      set(stagedRows, 16384 + identity, composition);
      long identityByte = 0;
      while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
        long offset = identity * IDENTITY_BYTES + identityByte;
        setByte(stagedIdentities, offset, identities[offset]);
        identityByte += 1;
      }

      previousOwner = owner;
      previousInstruction = finalInstruction;
      previousKind = kind;
      previousSourceProduct = sourceProduct;
      identity += 1;
    }

    if (valid) {
      long row = 0;
      while (row < OUTPUT_ROWS) limit OUTPUT_ROWS {
        set(outputRows, row, stagedRows[row]);
        row += 1;
      }

      long outputByte = 0;
      while (outputByte < 131072) limit 131072 {
        setByte(outputIdentities, outputByte, stagedIdentities[outputByte]);
        outputByte += 1;
      }
    }

    drop(stagedIdentities);
    drop(stagedRows);
    drop(staging);
    if (valid == false) {
      return new CallableProductIdentityPlan(0, false);
    }

    return new CallableProductIdentityPlan(identityCount, true);
  }
}
