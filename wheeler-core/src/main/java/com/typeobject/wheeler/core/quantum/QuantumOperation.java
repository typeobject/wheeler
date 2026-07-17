package com.typeobject.wheeler.core.quantum;

/** One typed unitary operation in backend-neutral quantum region IR. */
public sealed interface QuantumOperation permits GateOperation, LiftedCall {
  QuantumOperation inverse();
}
