package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for compiler modules accepted by the Wheeler-native compiler. */
final class NativeCompilerSelfSourceExampleTest {
  private static final int OUTPUT_CAPACITY = 32_768;

  @Test
  void compilesTheCanonicalProofRuleOwnerByteForByte() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = CompilerSources.read("compiler/ir/ProofRules.w");
    VirtualMachine writer = new VirtualMachine(
        compiler,
        source.getBytes(StandardCharsets.UTF_8),
        OUTPUT_CAPACITY);

    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("ProofRules.w", source),
        "wheeler.compiler.proof_rules");
    byte[] artifact = writer.hostOutput();
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals("$library", decoded.functions().getFirst().name());
    VirtualMachine library = new VirtualMachine(decoded);
    library.run();
    assertEquals(MachineStatus.HALTED, library.status());
  }

  @Test
  void rejectsFunctionBearingSelfSourceUntilMultipleHelpersLand() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = CompilerSources.read("compiler/ir/TypeCodes.w");
    VirtualMachine writer = new VirtualMachine(
        compiler,
        source.getBytes(StandardCharsets.UTF_8),
        OUTPUT_CAPACITY);

    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(writer));
    assertArrayEquals(new byte[OUTPUT_CAPACITY], writer.hostOutput());
  }
}
