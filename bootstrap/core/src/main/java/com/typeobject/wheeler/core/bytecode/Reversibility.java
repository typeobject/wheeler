package com.typeobject.wheeler.core.bytecode;

/** Describes how an instruction recovers information during machine rewind. */
public enum Reversibility {
  /** The inverse follows from the current state and instruction operands. */
  INTRINSIC,
  /** The operation is reversible when its verified runtime precondition holds. */
  CHECKED,
  /** The operation records a bounded value that it destroys. */
  LOGGED,
  /** The operation creates an observation that local rewind cannot erase. */
  BARRIER
}
