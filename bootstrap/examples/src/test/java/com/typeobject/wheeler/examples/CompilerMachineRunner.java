package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;

/** Executes compiler fixtures without retaining history that no assertion consumes. */
final class CompilerMachineRunner {
  private static final int HISTORY_COMMIT_INTERVAL = 10_000;

  private CompilerMachineRunner() {}

  static void runWithoutRewindHistory(VirtualMachine machine) {
    while (machine.status() != MachineStatus.HALTED) {
      machine.step();
      if (HISTORY_COMMIT_INTERVAL <= machine.historySize()) {
        machine.commitHistory();
      }
    }
  }
}
