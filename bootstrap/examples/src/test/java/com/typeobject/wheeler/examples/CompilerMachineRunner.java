package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;

/** Executes compiler fixtures across committed transitions without retaining rewind state. */
public final class CompilerMachineRunner {
  private CompilerMachineRunner() {}

  /** Runs from an empty-history boundary without supplying rewind evidence. */
  public static void runWithoutRewindHistory(VirtualMachine machine) {
    while (machine.status() != MachineStatus.HALTED) {
      machine.stepWithoutRewindHistory();
    }
  }
}
