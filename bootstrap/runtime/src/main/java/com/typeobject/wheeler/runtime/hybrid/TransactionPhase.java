package com.typeobject.wheeler.runtime.hybrid;

/** External-effect phase governing the strongest available transaction abort. */
public enum TransactionPhase {
  NONE,
  REVERSIBLE,
  PREPARED_EXTERNAL,
  OBSERVED,
  COMMITTED
}
