package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Deterministic backend supporting equivalent inline and delayed completion delivery. */
public final class DeterministicIo {
  /** Physical delivery policy; it does not alter completion meaning. */
  public enum Delivery {
    INLINE,
    DELAYED
  }

  private final Delivery delivery;
  private long nextScopeId = 1;

  public DeterministicIo(Delivery delivery) {
    this.delivery = Objects.requireNonNull(delivery, "delivery");
  }

  /** Opens one bounded structured I/O scope. */
  public IoScope scope(IoLimits limits) {
    if (nextScopeId == Long.MAX_VALUE) {
      throw new IllegalStateException("deterministic scope identity exhausted");
    }
    return new IoScope(nextScopeId++, delivery, limits);
  }
}
