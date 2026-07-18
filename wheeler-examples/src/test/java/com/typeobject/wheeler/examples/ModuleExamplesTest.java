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
        "src/main/wheeler/modules/Collections.w",
        Files.readString(directory.resolve("Collections.w")),
        "src/main/wheeler/modules/ModuleMain.w",
        Files.readString(directory.resolve("ModuleMain.w")),
        "src/main/wheeler/modules/Results.w",
        Files.readString(directory.resolve("Results.w")));
    var program = new WheelerCompiler().compileModuleFiles(sources, "examples.main");
    VirtualMachine machine = new VirtualMachine(program);

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals("examples.arithmetic::Pair", program.recordTypes().getFirst().name());
    assertEquals("examples.results::Outcome", program.variantTypes().getFirst().name());
    assertEquals(18, machine.global("result"));
    assertEquals(9, machine.global("decoded"));
    assertEquals(5, machine.global("arrayValue"));
    assertEquals(15, machine.global("sliceValue"));
    assertEquals(8, machine.global("nominalArrayValue"));
    assertEquals(26, machine.global("nominalSliceValue"));
  }
}
