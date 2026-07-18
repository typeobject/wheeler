package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

class NativeVmExampleTest {
  @Test
  void wheelerInterpretsBoundedArtifactsIncludingCounter() throws Exception {
    Path root = Path.of("src/main/wheeler");
    Program interpreter = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Binary.w", Files.readString(root.resolve("packages/Binary.w")),
            "Interpreter.w", Files.readString(root.resolve("compiler/Interpreter.w")),
            "NativeVm.w", Files.readString(root.resolve("NativeVm.w")),
            "Verifier.w", Files.readString(root.resolve("compiler/Verifier.w"))),
        "examples.runtime.native_vm");
    WheelerCompiler compiler = new WheelerCompiler();
    byte[] update = compiler.compileToBytecode(
        "classical class NativeSubject { state long value = 7; "
            + "entry void main() { value += 5; assert value == 12; } }");
    VirtualMachine machine = VirtualMachine.withBinaryInput(interpreter, update);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(12, machine.global("finalGlobal"));
    assertEquals(update.length, machine.global("artifactLength"));
    assertTrue(machine.global("interpretedSteps") > 0);
    VirtualMachine stageZero = new VirtualMachine(new BytecodeReader().read(update));
    stageZero.run();
    assertEquals(stageZero.global("value"), machine.global("finalGlobal"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    byte[] counter = compiler.compileToBytecode(
        Files.readString(root.resolve("Counter.w")));
    VirtualMachine counterMachine = VirtualMachine.withBinaryInput(
        interpreter, counter);
    counterMachine.run();
    assertEquals(0, counterMachine.global("finalGlobal"));
    assertTrue(counterMachine.global("interpretedSteps") > 8);

    byte[] malformed = update.clone();
    malformed[0] = 0;
    VirtualMachine rejected = VirtualMachine.withBinaryInput(
        interpreter, malformed);
    assertThrows(VmTrap.class, rejected::run);
  }
}
