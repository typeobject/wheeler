//! Composes exact callable-local type windows from counted source products.

module wheeler.compiler.closure.callable_local_type_plans;

classical class CallableLocalTypePlans {
  private const long CALLABLE_CAPACITY = 64;
  private const long LOCAL_CAPACITY = 65535;
  private const long OUTPUT_ROWS = 327808;
  private const long TYPE_CAPACITY = 65536;
  private const long TYPE_CODE_MAX = 4294967295;
  private const long TYPE_ROWS = 327680;

  /// Reports one complete callable-local type composition.
  public record CallableLocalTypePlan(long typeCount, long maxLocalCount, boolean valid) {}

  /// Publishes source-kind-preserving local types after every callable extent validates.
  public CallableLocalTypePlan materializeCallableLocalTypePlans(
    long callableCount,
    borrow mut words localCounts,
    long typeCount,
    borrow mut words typeRows,
    borrow mut words outputRows
  ) {
    assert(-1 < callableCount);
    assert(callableCount < CALLABLE_CAPACITY + 1);
    assert(bufferLength(localCounts) == CALLABLE_CAPACITY);
    assert(-1 < typeCount);
    assert(typeCount < TYPE_CAPACITY + 1);
    assert(bufferLength(typeRows) == TYPE_ROWS);
    assert(bufferLength(outputRows) == OUTPUT_ROWS);

    region staging = new region(/* bytes= */ 2622464, /* allocations= */ 1);
    words staged = allocate(staging, OUTPUT_ROWS);
    boolean valid = true;
    long expectedTypeCount = 0;
    long maxLocalCount = 0;
    long callable = 0;
    while (callable < callableCount) limit CALLABLE_CAPACITY {
      long localCount = localCounts[callable];
      if (localCount < 0) {
        valid = false;
      } else {
        if (LOCAL_CAPACITY < localCount) {
          valid = false;
        } else {
          if (TYPE_CAPACITY - expectedTypeCount < localCount) {
            valid = false;
          } else {
            expectedTypeCount += localCount;
          }

          if (maxLocalCount < localCount) {
            maxLocalCount = localCount;
          }
        }
      }

      callable += 1;
    }

    if (expectedTypeCount != typeCount) {
      valid = false;
    }

    long type = 0;
    callable = 0;
    while (callable < callableCount) limit CALLABLE_CAPACITY {
      long callableLocalCount = localCounts[callable];
      if (callableLocalCount < 0) {
        callableLocalCount = 0;
      }

      if (LOCAL_CAPACITY < callableLocalCount) {
        callableLocalCount = LOCAL_CAPACITY;
      }

      set(staged, 327680 + callable, type);
      set(staged, 327744 + callable, callableLocalCount);
      long local = 0;
      while (local < callableLocalCount) limit LOCAL_CAPACITY {
        if (typeCount < type + 1) {
          valid = false;
        } else {
          long owner = typeRows[type];
          long productLocal = typeRows[65536 + type];
          long typeCode = typeRows[131072 + type];
          long sourceKind = typeRows[196608 + type];
          long sourceProduct = typeRows[262144 + type];
          if (owner != callable) {
            valid = false;
          }

          if (productLocal != local) {
            valid = false;
          }

          if (typeCode < 1) {
            valid = false;
          } else {
            if (TYPE_CODE_MAX < typeCode) {
              valid = false;
            }
          }

          if (sourceKind < 0) {
            valid = false;
          } else {
            if (2 < sourceKind) {
              valid = false;
            }
          }

          if (sourceProduct < 0) {
            valid = false;
          }

          set(staged, type, owner);
          set(staged, 65536 + type, productLocal);
          set(staged, 131072 + type, typeCode);
          set(staged, 196608 + type, sourceKind);
          set(staged, 262144 + type, sourceProduct);
          type += 1;
        }

        local += 1;
      }

      callable += 1;
    }

    if (type != typeCount) {
      valid = false;
    }

    if (valid) {
      long row = 0;
      while (row < OUTPUT_ROWS) limit OUTPUT_ROWS {
        set(outputRows, row, staged[row]);
        row += 1;
      }
    }

    drop(staged);
    drop(staging);
    if (valid == false) {
      return new CallableLocalTypePlan(0, 0, false);
    }

    return new CallableLocalTypePlan(typeCount, maxLocalCount, true);
  }
}
