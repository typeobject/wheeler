package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

class ModuleExamplesTest {
  @Test
  void classicalFunctionModuleTargetLinksAndExecutes() throws Exception {
    Path directory = Path.of("src/main/wheeler/modules");
    Map<String, String> sources = Map.of(
        "src/main/wheeler/modules/Arithmetic.w",
        Files.readString(directory.resolve("Arithmetic.w")),
        "src/main/wheeler/modules/ModuleMain.w",
        Files.readString(directory.resolve("ModuleMain.w")));
    VirtualMachine machine = new VirtualMachine(
        new WheelerCompiler().compileModuleFiles(sources, "examples.main"));

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(18, machine.global("result"));
  }
}
