package com.typeobject.wheeler.runtime.quantum;

/** Capability-based asynchronous quantum execution target. */
public interface QuantumTarget {
  TargetDescriptor descriptor();

  QuantumJob submit(QuantumTask task);
}
