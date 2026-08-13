package com.typeobject.wheeler.core.quantum;

/** One typed unitary operation in backend-neutral quantum region IR. */
public sealed interface QuantumOperation permits ConditionalGateOperation, GateOperation,
    LiftedCall, MeasureOperation, ParameterizedGateOperation, PrepareOperation, ResetOperation {
  QuantumOperation inverse();
}
