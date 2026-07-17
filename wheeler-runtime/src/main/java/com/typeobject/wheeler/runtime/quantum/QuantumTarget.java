package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;

/** Minimal synchronous semantic target; WIP-0003 adds asynchronous target jobs. */
public interface QuantumTarget {
  void prepare(QuantumRegister register, long basisState);

  void apply(Program program, QuantumCircuit circuit, boolean inverse);

  long measure(QuantumRegister register);

  double[] probabilities(QuantumRegister register);
}
