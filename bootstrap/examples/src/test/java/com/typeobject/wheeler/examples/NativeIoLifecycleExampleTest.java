package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
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
    assertEquals(3, machine.global("completionWonRelation"));
    assertEquals(6, machine.global("uncertainRelation"));
    assertEquals(0, machine.global("rejectedOperation"));
    assertEquals(1, machine.global("finalClosed"));

    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
