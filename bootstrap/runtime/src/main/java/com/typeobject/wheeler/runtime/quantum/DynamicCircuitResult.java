package com.typeobject.wheeler.runtime.quantum;

import java.util.Map;

/** Final bounded evidence from one target-resident dynamic circuit execution. */
public record DynamicCircuitResult(long basisState, Map<Integer, Boolean> resultSlots) {
  public DynamicCircuitResult {
    resultSlots = Map.copyOf(resultSlots);
  }
}
