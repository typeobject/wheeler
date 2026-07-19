package com.typeobject.wheeler.core.vm;

/** Observable lifecycle state of one verified virtual machine invocation. */
public enum MachineStatus {
  READY,
  RUNNING,
  HALTED,
  TRAPPED
}
