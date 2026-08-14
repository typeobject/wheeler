package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.runtime.io.IoCompletion.CancellationRelation;
import com.typeobject.wheeler.runtime.io.IoCompletion.TerminalKind;
import com.typeobject.wheeler.runtime.io.IoLifecycleEncoding;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Executes the Wheeler-native WIP-0032 lifecycle kernel. */
final class NativeIoLifecycleExampleTest {
  @Test
  void wheelerEnforcesTerminalCompletionCancellationAndExactReaping() throws Exception {
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Lifecycle.w", RuntimeSources.read("runtime/io/Lifecycle.w"),
            "NativeIoLifecycle.w", Files.readString(
                Path.of("../wheeler-conformance/src/main/wheeler/io/NativeIoLifecycle.w"))),
        "wheeler.conformance.io.io_lifecycle");
    VirtualMachine machine = new VirtualMachine(program);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(4, machine.global("finalOperationCount"));
    assertEquals(23, machine.global("finalChargedWork"));
    assertEquals(
        IoLifecycleEncoding.terminal(TerminalKind.SUCCESS),
        machine.global("successTerminal"));
    assertEquals(
        IoLifecycleEncoding.terminal(TerminalKind.CANCELED),
        machine.global("canceledTerminal"));
    assertEquals(
        IoLifecycleEncoding.cancellation(CancellationRelation.CANCELED_AFTER_PARTIAL_EFFECT),
        machine.global("partialRelation"));
    assertEquals(
        IoLifecycleEncoding.terminal(TerminalKind.UNCERTAIN),
        machine.global("uncertainTerminal"));
    assertEquals(
        IoLifecycleEncoding.cancellation(CancellationRelation.COMPLETED_BEFORE_CANCELLATION),
        machine.global("completionWonRelation"));
    assertEquals(
        IoLifecycleEncoding.cancellation(CancellationRelation.UNCERTAIN_AFTER_CANCELLATION),
        machine.global("uncertainRelation"));
    assertEquals(0, machine.global("rejectedOperation"));
    assertEquals(1, machine.global("finalClosed"));

    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
