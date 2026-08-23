package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.runtime.SemanticCoverage;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Proves native semantic coordinates for imported calls and conditional branches. */
final class NativeBranchCoverageExampleTest {
  private static final String HELPER = """
      module pkg.branch_helper;
      classical class BranchHelper {
        public boolean accepts(long value) {
          if (value == 7) {
            return true;
          }

          return value == 8;
        }
      }
      """;
  private static final String SUBJECT = """
      module pkg.branch;
      import pkg.branch_helper;
      classical class BranchSubject {
        entry void main() {
          boolean accepted = accepts(7);
          assert(accepted);
          boolean second = accepts(8);
          assert(second);
        }
      }
      """;

  @Test
  void nativeCallAndBranchCoverageMatchesStageZero() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, HELPER, SUBJECT);
    SemanticCoverage stageZero = new SemanticCoverage();
    new WheelerRuntime().executeObserved(new BytecodeReader().read(artifact), stageZero);

    VirtualMachine machine = VirtualMachine.withBinaryInput(
        NativeCoverageRunExampleTest.runner(), artifact, 32_768);
    CompilerMachineRunner.runWithoutRewindHistory(machine);

    byte[] expected = stageZero.canonicalReport().getBytes(StandardCharsets.UTF_8);
    assertArrayEquals(expected, machine.hostOutput());
    String report = new String(machine.hostOutput(), StandardCharsets.UTF_8);
    assertTrue(report.contains("\"function\":1"));
    assertTrue(report.contains("\"branch\":\"fallthrough\""));
    assertTrue(report.contains("\"branch\":\"taken\""));
  }
}
